require 'pathname'
require 'forwardable'
require 'tsort'

require 'mruby-build/gem_box'
require 'mruby-build/gem/specification'
require 'mruby-build/gem/version'
require 'mruby-build/gem/list'

module MRuby
  module Gem
    class << self
      attr_accessor :current
    end
    LinkerConfig = Struct.new(:libraries, :library_paths, :flags, :flags_before_libraries, :flags_after_libraries)
  end
end
