# Generated speech runtimes

No binaries or speech models are tracked here. Android arm64 libraries are built
from pinned sherpa-onnx source with TTS disabled. Windows x64 libraries are
extracted from the hash-verified official `no-tts` release.

Prepare them before packaging Flutter apps:

```powershell
python tools/prepare-speech-runtime.py --platform windows
./tools/build-speech-runtime.ps1
```

The platform dependency overrides consume `android/arm64-v8a/` and
`windows/x64/` here. Other ABIs/platforms intentionally have no speech runtime.

The project's Android ASR feature supports Android 8.1 (API 27) or newer. The
C API is compiled for API 21; ONNX Runtime's binary build target is API 27. This
is the application's tested capability gate, not a claim about ONNX Runtime's
official minimum version. The application's minimum Android version remains
unchanged; older systems retain diary features.

On Linux, install CMake, a C++ build tool and Android NDK `28.2.13676358`, then run:

```sh
python3 tools/prepare-speech-runtime.py --platform android --ndk "$ANDROID_NDK_HOME"
```

The `Speech runtime builds` workflow repeats both preparation paths. Windows DLL
checksums and the Android manifest checksums are verified again when packaging.

