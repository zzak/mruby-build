require 'mruby-build/ruby_ext'
require 'mruby-build/load_gems'
require 'mruby-build/toolchain'
require 'mruby-build/build'
require 'mruby-build/cross_build'
require 'mruby-build/command'
require 'mruby-build/gem'
require 'mruby-build/rules'

module MRuby
  class << self
    def targets
      @targets ||= {}
    end

    def each_target(&block)
      return to_enum(:each_target) if block.nil?
      @targets.each do |key, target|
        target.instance_eval(&block)
      end
    end
  end
end
