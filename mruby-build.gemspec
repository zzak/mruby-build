Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'mruby-build'
  s.version     = '0.0.0'
  s.summary     = 'Tool for building MRuby applications and gems'
  s.description = 'This gem is designed to build MRuby, an embedded Ruby implementation.'
  s.license = 'MIT'
  s.author   = 'Zachary Scott'
  s.email    = 'zzak@ruby-lang.org'
  s.homepage = 'https://github.com/zzak/mruby-build'

  s.files = Dir['README.md', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency 'rake'
end
