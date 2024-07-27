# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name = 'telemetry'
  s.version = '0.0.0.0'
  s.summary = "Telemetry recording and handling"
  s.description = ' '

  s.authors = ['The Eventide Project']
  s.email = 'opensource@eventide-project.org'
  s.homepage = 'https://github.com/eventide-core/telemetry'
  s.licenses = %w(MIT)

  s.require_paths = %w(lib)
  s.files = Dir.glob 'lib/**/*'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.3.0'

  s.add_runtime_dependency 'pseudorandom'
end
