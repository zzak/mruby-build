require 'forwardable'

module MRuby
  class Command; end
end

require 'mruby-build/commands/compiler'
require 'mruby-build/commands/linker'
require 'mruby-build/commands/archiver'
require 'mruby-build/commands/yacc'
require 'mruby-build/commands/gperf'
require 'mruby-build/commands/git'
require 'mruby-build/commands/mrbc'
require 'mruby-build/commands/cross_test_runner'

module MRuby
  class Command
    include Rake::DSL
    extend Forwardable
    def_delegators :@build, :filename, :objfile, :libfile, :exefile, :cygwin_filename
    attr_accessor :build, :command

    def initialize(build)
      @build = build
    end

    # clone is deep clone without @build
    def clone
      target = super
      excepts = %w(@build)
      instance_variables.each do |attr|
        unless excepts.include?(attr.to_s)
          val = Marshal::load(Marshal.dump(instance_variable_get(attr))) # deep clone
          target.instance_variable_set(attr, val)
        end
      end
      target
    end

    NotFoundCommands = {}

    private
    def _run(options, params={})
      return sh command + ' ' + ( options % params ) if NotFoundCommands.key? @command
      begin
        sh build.filename(command) + ' ' + ( options % params )
      rescue RuntimeError
        NotFoundCommands[@command] = true
        _run options, params
      end
    end
  end
end
