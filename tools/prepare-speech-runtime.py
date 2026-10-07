#!/usr/bin/env python3
"""Prepare the pinned, TTS-disabled runtimes used by Flutter speech bindings."""

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import urllib.request


VERSION = "1.13.8"
REVISION = "11afbd009a7f8c08f4bcf2fc1b265d0df4670fbf"
SOURCE_SHA256 = "0a8db6c55dd318f4a688faba85f7760b99a6c92e8ef8864479d418531bee1ac2"
NDK_VERSION = "28.2.13676358"
WINDOWS_ARCHIVE = "sherpa-onnx-v1.13.8-win-x64-shared-MD-Release-no-tts-lib.tar.bz2"
WINDOWS_SHA256 = "b90992b888710715d613a4fedcd75d5b4db294ef64f3194e4f77ea0a8b387441"
WINDOWS_BYTES = 6907798
ROOT = Path(__file__).resolve().parent.parent


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def download(url, destination, expected_sha256, expected_bytes=None):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.is_file():
        staging = destination.with_name(destination.name + ".part")
        request = urllib.request.Request(url, headers={"User-Agent": "diary-runtime-builder"})
        with urllib.request.urlopen(request, timeout=120) as response, staging.open("wb") as target:
            shutil.copyfileobj(response, target, 1024 * 1024)
        staging.replace(destination)
    if expected_bytes is not None and destination.stat().st_size != expected_bytes:
        raise RuntimeError("Unexpected speech runtime archive size; remove this cached archive and retry")
    if digest(destination) != expected_sha256:
        raise RuntimeError("Speech runtime archive SHA-256 does not match the pinned source")
    return destination


def extract(archive, destination):
    destination.mkdir(parents=True, exist_ok=True)

    def safe_member(member, path):
        # The pinned source contains absolute symlinks in unrelated Go examples.
        # Native compilation needs no archive links. Skip them rather than create
        # paths outside the cache; filter all regular files for traversal too.
        if member.issym() or member.islnk():
            return None
        return tarfile.data_filter(member, path)

    with tarfile.open(archive) as source:
        source.extractall(destination, filter=safe_member)


def run(arguments, capture=False):
    result = subprocess.run([str(argument) for argument in arguments], check=True,
                            text=True, capture_output=capture)
    return result.stdout if capture else ""


def manifest(output, values, names):
    values["libraries"] = [
        {"name": name, "bytes": (output / name).stat().st_size,
         "sha256": digest(output / name)} for name in names
    ]
    (output / "build-manifest.json").write_text(
        json.dumps(values, indent=2) + "\n", encoding="utf-8")


def audit_no_tts(path):
    data = path.read_bytes()
    for marker in (b"espeak_ng_Initialize", b"espeak_SetVoiceByName", b"espeak-ng-data",
                   b"piper_phonemize"):
        if marker in data:
            raise RuntimeError("A TTS-specific dependency was found in the speech runtime")


def windows(args, cache, output):
    url = f"https://github.com/k2-fsa/sherpa-onnx/releases/download/v{VERSION}/{WINDOWS_ARCHIVE}"
    archive = Path(args.archive).resolve() if args.archive else cache / WINDOWS_ARCHIVE
    archive = download(url, archive, WINDOWS_SHA256, WINDOWS_BYTES)
    extracted = cache / "windows-no-tts"
    extract(archive, extracted)
    library_path = extracted / WINDOWS_ARCHIVE.removesuffix(".tar.bz2") / "lib"
    names = ["sherpa-onnx-c-api.dll", "onnxruntime.dll", "onnxruntime_providers_shared.dll"]
    output.mkdir(parents=True, exist_ok=True)
    for name in names:
        source = library_path / name
        if not source.is_file():
            raise RuntimeError("The official no-TTS archive is missing a required DLL")
        audit_no_tts(source)
        shutil.copyfile(source, output / name)
    if sys.platform == "win32":
        with os.add_dll_directory(str(output)):
            native = ctypes.CDLL(str(output / "sherpa-onnx-c-api.dll"))
            native.SherpaOnnxGetVersionStr.restype = ctypes.c_char_p
            if native.SherpaOnnxGetVersionStr().decode() != VERSION:
                raise RuntimeError("The ASR runtime reports a different version")
    manifest(output, {
        "sherpaVersion": VERSION, "origin": url, "archiveSha256": WINDOWS_SHA256,
        "platform": "windows-x64", "tts": False,
    }, names)


def ndk_tools(args):
    value = args.ndk or os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_ROOT")
    if not value:
        sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
        if sdk:
            value = str(Path(sdk) / "ndk" / NDK_VERSION)
    if not value:
        raise RuntimeError("Set ANDROID_NDK_HOME or pass --ndk for Android NDK r28c")
    ndk = Path(value).resolve()
    properties = ndk / "source.properties"
    if not properties.is_file() or f"Pkg.Revision = {NDK_VERSION}" not in properties.read_text():
        raise RuntimeError("The speech runtime build requires Android NDK 28.2.13676358")
    host = "windows-x86_64" if sys.platform == "win32" else "linux-x86_64"
    suffix = ".exe" if sys.platform == "win32" else ""
    tools = ndk / "toolchains" / "llvm" / "prebuilt" / host / "bin"
    return ndk, tools / f"llvm-readelf{suffix}", tools / f"llvm-strip{suffix}"


def audit_elf(path, readelf):
    header = run([readelf, "-h", path], capture=True)
    if "AArch64" not in header:
        raise RuntimeError("An Android speech library has the wrong architecture")
    dynamic = run([readelf, "-d", path], capture=True)
    for marker in ("espeak", "piper", "c++_shared"):
        if marker in dynamic.lower():
            raise RuntimeError("Unexpected Android speech runtime dependency")
    segments = run([readelf, "-lW", path], capture=True)
    load_lines = [line.split() for line in segments.splitlines() if line.strip().startswith("LOAD ")]
    if not load_lines or any(int(line[-1], 16) < 16384 for line in load_lines):
        raise RuntimeError("Android speech libraries must support 16 KB pages")
    audit_no_tts(path)


def android(args, cache, output):
    ndk, readelf, strip = ndk_tools(args)
    archive = download(f"https://codeload.github.com/k2-fsa/sherpa-onnx/tar.gz/{REVISION}",
                       cache / f"sherpa-onnx-{REVISION}.tar.gz", SOURCE_SHA256)
    source = cache / f"sherpa-onnx-{REVISION}"
    source_ready = cache / f"source-{REVISION}.ready"
    if not source_ready.is_file() or source_ready.read_text() != SOURCE_SHA256:
        extract(archive, cache)
        source_ready.write_text(SOURCE_SHA256)
    build = cache / "build-android-arm64-python"
    cmake = args.cmake or shutil.which("cmake")
    if not cmake:
        raise RuntimeError("CMake is required; install cmake and ninja-build before preparing Android")
    configure = [cmake, "-S", source, "-B", build,
                 "-G", "Ninja" if shutil.which("ninja") else "Unix Makefiles",
                 f"-DCMAKE_TOOLCHAIN_FILE={ndk}/build/cmake/android.toolchain.cmake",
                 "-DCMAKE_BUILD_TYPE=Release", "-DANDROID_ABI=arm64-v8a",
                 "-DANDROID_PLATFORM=android-21", "-DANDROID_STL=c++_static",
                 "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON", "-DBUILD_SHARED_LIBS=ON",
                 "-DSHERPA_ONNX_ENABLE_C_API=ON"]
    for option in ["ENABLE_TTS", "ENABLE_SPEAKER_DIARIZATION", "ENABLE_JNI", "ENABLE_BINARY",
                   "BUILD_C_API_EXAMPLES", "ENABLE_PYTHON", "ENABLE_WEBSOCKET", "ENABLE_PORTAUDIO",
                   "ENABLE_TESTS", "ENABLE_CHECK", "ENABLE_GPU",
                   "USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE"]:
        configure.append(f"-DSHERPA_ONNX_{option}=OFF")
    run(configure)
    run([cmake, "--build", build, "--target", "sherpa-onnx-c-api", "--parallel", args.jobs])
    if list((build / "_deps").glob("*espeak*")) or list((build / "_deps").glob("*piper*")):
        raise RuntimeError("TTS dependencies were downloaded; do not package this runtime")
    names = ["libsherpa-onnx-c-api.so", "libonnxruntime.so"]
    sources = [build / "lib" / names[0],
               build / "_deps" / "onnxruntime-src" / "jni" / "arm64-v8a" / names[1]]
    output.mkdir(parents=True, exist_ok=True)
    for source_file, name in zip(sources, names):
        audit_elf(source_file, readelf)
        shutil.copyfile(source_file, output / name)
    run([strip, "--strip-unneeded", output / names[0]])
    for name in names:
        audit_elf(output / name, readelf)
    manifest(output, {
        "sherpaVersion": VERSION, "sherpaRevision": REVISION, "sourceSha256": SOURCE_SHA256,
        "ndkVersion": NDK_VERSION, "androidApi": 21, "runtimeMinApi": 27,
        "onnxRuntimeVersion": "1.28.2", "abi": "arm64-v8a",
        "tts": False, "jni": False, "diarization": False, "stl": "c++_static",
    }, names)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", choices=["windows", "android"], required=True)
    parser.add_argument("--cache", type=Path,
                        default=ROOT / ".local" / "offline-speech-runtime")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--archive", help="Existing Windows no-TTS archive; SHA-256 is still checked")
    parser.add_argument("--ndk")
    parser.add_argument("--cmake")
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    if not 1 <= args.jobs <= 32:
        parser.error("--jobs must be between 1 and 32")
    cache = args.cache.resolve()
    destination = "windows/x64" if args.platform == "windows" else "android/arm64-v8a"
    output = (args.output or ROOT / "mobile" / "native" / "offline-speech" / destination).resolve()
    (windows if args.platform == "windows" else android)(args, cache, output)
    print(f"ASR-only {args.platform} runtime ready: {output}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError, tarfile.TarError) as error:
        print(f"Speech runtime preparation failed: {error}", file=sys.stderr)
        sys.exit(1)
