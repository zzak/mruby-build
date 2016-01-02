module MRuby
  class CrossBuild < Build
    attr_block %w(test_runner)
    # cross compiling targets for building native extensions.
    # host  - arch of where the built binary will run
    # build - arch of the machine building the binary
    attr_accessor :host_target, :build_target

    def initialize(name, build_dir=nil, &block)
      @test_runner = Command::CrossTestRunner.new(self)
      super
    end

    def mrbcfile
      MRuby.targets['host'].exefile("#{MRuby.targets['host'].build_dir}/bin/mrbc")
    end

    def run_test
      mrbtest = exefile("#{build_dir}/bin/mrbtest")
      if (@test_runner.command == nil)
        puts "You should run #{mrbtest} on target device."
        puts
      else
        @test_runner.run(mrbtest)
      end
    end
  end
end
