require 'rake/tasklib'
require 'mruby-build/tasks/mruby_core'
require 'mruby-build/tasks/mrblib'
require 'mruby-build/tasks/mrbgems'
require 'mruby-build/tasks/libmruby'
require 'mruby-build/tasks/benchmark'
require 'mruby-build/tasks/binfiles'

module MRuby
  module Rules
    def self.define
      MRuby.each_target do |build|
        build.define_rules
      end

      MRuby::Tasks::MRubyCore.new
      MRuby::Tasks::Mrblib.new
      MRuby::Tasks::Mrbgems.new
      MRuby::Tasks::Libmruby.new
      MRuby::Tasks::Benchmark.new
      MRuby::Tasks::Binfiles.new
    end
  end
end
