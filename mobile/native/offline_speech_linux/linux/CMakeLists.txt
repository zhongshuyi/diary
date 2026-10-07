cmake_minimum_required(VERSION 3.14)
project(sherpa_onnx_linux LANGUAGES CXX)
# Offline speech is currently supported only on Android arm64 and Windows x64.
set(sherpa_onnx_linux_bundled_libraries "" PARENT_SCOPE)

