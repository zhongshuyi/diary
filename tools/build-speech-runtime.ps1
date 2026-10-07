[CmdletBinding()]
param(
    [string] $AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk",
    [string] $NdkVersion = '28.2.13676358',
    [string] $CmakeVersion = '3.22.1',
    [int] $Jobs = 4
)

$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$cache = Join-Path $workspace '.local/offline-speech-runtime'
$revision = '11afbd009a7f8c08f4bcf2fc1b265d0df4670fbf' # sherpa-onnx v1.13.8
$sourceDigest = '0a8db6c55dd318f4a688faba85f7760b99a6c92e8ef8864479d418531bee1ac2'
$archive = Join-Path $cache "sherpa-onnx-$revision.tar.gz"
$source = Join-Path $cache "sherpa-onnx-$revision"
$build = Join-Path $cache 'build-android-arm64'
$output = Join-Path $workspace 'mobile/native/offline-speech/android/arm64-v8a'
$ndk = Join-Path $AndroidSdk "ndk/$NdkVersion"
$cmake = Join-Path $AndroidSdk "cmake/$CmakeVersion/bin/cmake.exe"
$ninja = Join-Path $AndroidSdk "cmake/$CmakeVersion/bin/ninja.exe"
$readelf = Join-Path $ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
$strip = Join-Path $ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe'

foreach ($required in @($cmake, $ninja, $readelf, $strip, (Join-Path $ndk 'build/cmake/android.toolchain.cmake'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing Android native build tool: $required" }
}
[IO.Directory]::CreateDirectory($cache) | Out-Null
if (-not (Test-Path -LiteralPath $archive)) {
    Invoke-WebRequest "https://codeload.github.com/k2-fsa/sherpa-onnx/tar.gz/$revision" -OutFile "$archive.part" -TimeoutSec 1200
    Move-Item -LiteralPath "$archive.part" -Destination $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sourceDigest) {
    throw 'Sherpa source archive checksum mismatch; remove only this archive and retry.'
}
if (-not (Test-Path -LiteralPath (Join-Path $source 'CMakeLists.txt'))) {
    & tar -xf $archive -C $cache
    if ($LASTEXITCODE -ne 0) { throw 'Sherpa source archive extraction failed.' }
}

# Upstream CMake fixes archive SHA256 for ORT and every linked dependency.
# ASR-only excludes eSpeak NG / Piper TTS and their GPL-covered code.
$configure = @(
    '-S', $source, '-B', $build, '-G', 'Ninja',
    "-DCMAKE_MAKE_PROGRAM=$ninja",
    "-DCMAKE_TOOLCHAIN_FILE=$ndk/build/cmake/android.toolchain.cmake",
    '-DCMAKE_BUILD_TYPE=Release', '-DANDROID_ABI=arm64-v8a', '-DANDROID_PLATFORM=android-21',
    '-DANDROID_STL=c++_static', '-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON',
    '-DBUILD_SHARED_LIBS=ON', '-DSHERPA_ONNX_ENABLE_TTS=OFF',
    '-DSHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=OFF',
    '-DSHERPA_ONNX_ENABLE_JNI=OFF', '-DSHERPA_ONNX_ENABLE_C_API=ON',
    '-DSHERPA_ONNX_ENABLE_BINARY=OFF', '-DSHERPA_ONNX_BUILD_C_API_EXAMPLES=OFF',
    '-DSHERPA_ONNX_ENABLE_PYTHON=OFF', '-DSHERPA_ONNX_ENABLE_WEBSOCKET=OFF',
    '-DSHERPA_ONNX_ENABLE_PORTAUDIO=OFF', '-DSHERPA_ONNX_ENABLE_TESTS=OFF',
    '-DSHERPA_ONNX_ENABLE_CHECK=OFF', '-DSHERPA_ONNX_ENABLE_GPU=OFF',
    '-DSHERPA_ONNX_USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE=OFF'
)
& $cmake @configure
if ($LASTEXITCODE -ne 0) { throw 'ASR runtime configuration failed.' }
& $cmake --build $build --target sherpa-onnx-c-api --parallel $Jobs
if ($LASTEXITCODE -ne 0) { throw 'ASR runtime compilation failed.' }

$capi = Join-Path $build 'lib/libsherpa-onnx-c-api.so'
$ort = Join-Path $build '_deps/onnxruntime-src/jni/arm64-v8a/libonnxruntime.so'
foreach ($library in @($capi, $ort)) {
    if (-not (Test-Path -LiteralPath $library)) { throw "Missing compiled library: $library" }
    $dynamic = & $readelf -d $library
    if ($LASTEXITCODE -ne 0) { throw 'Native ELF validation failed.' }
    if ($dynamic -match 'NEEDED.*(espeak|piper|c\+\+_shared)') { throw 'Unexpected ASR runtime dependency.' }
}
if (Get-ChildItem -LiteralPath (Join-Path $build '_deps') -Directory | Where-Object { $_.Name -match '(espeak|piper)' }) {
    throw 'TTS dependency unexpectedly downloaded; inspect configuration before packaging.'
}
[IO.Directory]::CreateDirectory($output) | Out-Null
Copy-Item -LiteralPath $capi -Destination (Join-Path $output 'libsherpa-onnx-c-api.so')
Copy-Item -LiteralPath $ort -Destination (Join-Path $output 'libonnxruntime.so')
& $strip --strip-unneeded (Join-Path $output 'libsherpa-onnx-c-api.so')
if ($LASTEXITCODE -ne 0) { throw 'ASR runtime symbol stripping failed.' }

$manifest = [ordered]@{
    sherpaVersion = '1.13.8'; sherpaRevision = $revision; sourceSha256 = $sourceDigest
    onnxRuntimeVersion = '1.28.2'; ndkVersion = $NdkVersion; androidApi = 21; runtimeMinApi = 27; abi = 'arm64-v8a'
    tts = $false; jni = $false; diarization = $false; stl = 'c++_static'
    libraries = @('libsherpa-onnx-c-api.so', 'libonnxruntime.so') | ForEach-Object {
        $file = Join-Path $output $_
        @{ name = $_; bytes = (Get-Item -LiteralPath $file).Length; sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'build-manifest.json') -Encoding utf8
Write-Output "ASR-only arm64 runtime ready: $output"
$manifest.libraries | ForEach-Object { [PSCustomObject] $_ } | Format-Table name, bytes, sha256 -AutoSize
