Gem::Specification.new do |s|
  s.name         = 'asetus'
  s.version      = '0.4.0'
  s.licenses     = ['Apache-2.0']
  s.platform     = Gem::Platform::RUBY
  s.authors      = ['Saku Ytti']
  s.email        = %w[saku@ytti.fi]
  s.homepage     = 'http://github.com/ytti/asetus'
  s.summary      = 'configuration library'
  s.description  = 'configuration library with object access to YAML/JSON/TOML backends'
  s.files        = %w[README.md asetus.gemspec] + Dir["lib/**/*.rb"]
  s.executables  = %w[]
  s.require_path = 'lib'

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 2.7'
end
