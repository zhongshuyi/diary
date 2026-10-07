Pod::Spec.new do |s|
  s.name = 'sherpa_onnx_ios'
  s.version = '1.13.8'
  s.summary = 'Placeholder without native speech or TTS binaries.'
  s.homepage = 'https://github.com/zhongshuyi/diary'
  s.license = { :type => 'MIT' }
  s.author = { 'Diary contributors' => '' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.ios.deployment_target = '13.0'
end

