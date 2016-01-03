module MRuby
  class Toolchain
    class << self
      attr_accessor :toolchains
    end

    def initialize(name, &block)
      @name, @initializer = name.to_s, block
      MRuby::Toolchain.toolchains ||= {}
      MRuby::Toolchain.toolchains[@name] = self
    end

    def setup(conf,params={})
      conf.instance_exec(conf, params, &@initializer)
    end

    def self.load
      Dir.glob("#{MRUBY_ROOT}/tasks/toolchains/*.rake").each do |file|
        Kernel.load file
      end
    end
  end
end
