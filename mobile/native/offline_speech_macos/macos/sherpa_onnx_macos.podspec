Pod::Spec.new do |s|
  s.name = 'sherpa_onnx_macos'
  s.version = '1.13.8'
  s.summary = 'Placeholder without native speech or TTS binaries.'
  s.homepage = 'https://github.com/zhongshuyi/diary'
  s.license = { :type => 'MIT' }
  s.author = { 'Diary contributors' => '' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.15'
end

