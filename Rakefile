MRUBY_ROOT = "mruby"
MRUBY_BUILD_HOST_IS_CYGWIN = RUBY_PLATFORM.include?('cygwin')
MRUBY_BUILD_HOST_IS_OPENBSD = RUBY_PLATFORM.include?('openbsd')

require 'mruby-build'

MRUBY_CONFIG = (ENV['MRUBY_CONFIG'] && ENV['MRUBY_CONFIG'] != '') ? ENV['MRUBY_CONFIG'] : "#{MRUBY_ROOT}/build_config.rb"
load MRUBY_CONFIG

MRuby.each_target do |build|
  build.define_rules
end

MRuby::Rules.define

task :default => :all

desc "build all targets, install (locally) in-repo"
task :all => :binfiles do
  puts
  puts "Build summary:"
  puts
  MRuby.each_target do
    print_build_summary
  end
end

desc "run all mruby tests"
task :test => :all do
  MRuby.each_target do
    run_test if test_enabled?
  end
end
