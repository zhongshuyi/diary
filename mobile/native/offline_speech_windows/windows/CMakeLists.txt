cmake_minimum_required(VERSION 3.14)
project(sherpa_onnx_windows LANGUAGES CXX)
get_filename_component(SPEECH_PLUGIN_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
set(SPEECH_RUNTIME "${SPEECH_PLUGIN_SOURCE}/../../offline-speech/windows/x64")
foreach(SPEECH_DLL sherpa-onnx-c-api.dll onnxruntime.dll onnxruntime_providers_shared.dll)
  if(NOT EXISTS "${SPEECH_RUNTIME}/${SPEECH_DLL}")
    message(FATAL_ERROR "Missing ASR-only speech runtime. Run python tools/prepare-speech-runtime.py --platform windows from the repository root.")
  endif()
endforeach()
# Pin the individual DLLs as well as the archive. Replacing this directory with
# the default upstream (TTS-enabled) plugin cannot silently change a release.
set(SPEECH_DLL_HASHES
  "sherpa-onnx-c-api.dll|5616605dc07ffbcf1cd6a001c2c76e826b9e1710e0fe17dfc3412de3a28df6a5"
  "onnxruntime.dll|422d776ab0e3218260f7f628fcb84606aaa5c21116f720c8619a6da5e0b2e0f9"
  "onnxruntime_providers_shared.dll|0190137dee4933261c065c5d030c3568a68c7aa43cad942b4726a07011738bc2"
)
foreach(SPEECH_DLL_HASH IN LISTS SPEECH_DLL_HASHES)
  string(REPLACE "|" ";" SPEECH_DLL_HASH_PARTS "${SPEECH_DLL_HASH}")
  list(GET SPEECH_DLL_HASH_PARTS 0 SPEECH_DLL)
  list(GET SPEECH_DLL_HASH_PARTS 1 SPEECH_EXPECTED_HASH)
  file(SHA256 "${SPEECH_RUNTIME}/${SPEECH_DLL}" SPEECH_ACTUAL_HASH)
  if(NOT SPEECH_ACTUAL_HASH STREQUAL SPEECH_EXPECTED_HASH)
    message(FATAL_ERROR "Speech DLL checksum mismatch. Regenerate the official no-TTS runtime with tools/prepare-speech-runtime.py.")
  endif()
endforeach()
set(sherpa_onnx_windows_bundled_libraries
  "${SPEECH_RUNTIME}/sherpa-onnx-c-api.dll"
  "${SPEECH_RUNTIME}/onnxruntime.dll"
  "${SPEECH_RUNTIME}/onnxruntime_providers_shared.dll"
  PARENT_SCOPE
)

