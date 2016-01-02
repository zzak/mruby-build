module MRuby
  module Gem
    class Specification
      include Rake::DSL
      extend Forwardable
      def_delegators :@build, :filename, :objfile, :libfile, :exefile

      attr_accessor :name, :dir, :build
      alias mruby build
      attr_accessor :build_config_initializer

      attr_accessor :version
      attr_accessor :description, :summary
      attr_accessor :homepage
      attr_accessor :licenses, :authors
      alias :license= :licenses=
      alias :author= :authors=

      attr_accessor :rbfiles, :objs
      attr_accessor :test_objs, :test_rbfiles, :test_args
      attr_accessor :test_preload

      attr_accessor :bins

      attr_accessor :requirements
      attr_reader :dependencies, :conflicts

      attr_accessor :export_include_paths

      attr_reader :generate_functions

      attr_block MRuby::Build::COMMANDS

      def initialize(name, &block)
        @name = name
        @initializer = block
        @version = "0.0.0"
        MRuby::Gem.current = self
      end

      def setup
        MRuby::Gem.current = self
        MRuby::Build::COMMANDS.each do |command|
          instance_variable_set("@#{command}", @build.send(command).clone)
        end
        @linker = LinkerConfig.new([], [], [], [], [])

        @rbfiles = Dir.glob("#{dir}/mrblib/**/*.rb").sort
        @objs = Dir.glob("#{dir}/src/*.{c,cpp,cxx,cc,m,asm,s,S}").map do |f|
          objfile(f.relative_path_from(@dir).to_s.pathmap("#{build_dir}/%X"))
        end

        @generate_functions = !(@rbfiles.empty? && @objs.empty?)
        @objs << objfile("#{build_dir}/gem_init") if @generate_functions

        @test_rbfiles = Dir.glob("#{dir}/test/**/*.rb")
        @test_objs = Dir.glob("#{dir}/test/*.{c,cpp,cxx,cc,m,asm,s,S}").map do |f|
          objfile(f.relative_path_from(dir).to_s.pathmap("#{build_dir}/%X"))
        end
        @custom_test_init = !@test_objs.empty?
        @test_preload = nil # 'test/assert.rb'
        @test_args = {}

        @bins = []

        @requirements = []
        @dependencies, @conflicts = [], []
        @export_include_paths = []
        @export_include_paths << "#{dir}/include" if File.directory? "#{dir}/include"

        instance_eval(&@initializer)

        if !name || !licenses || !authors
          fail "#{name || dir} required to set name, license(s) and author(s)"
        end

        build.libmruby << @objs

        instance_eval(&@build_config_initializer) if @build_config_initializer

        compilers.each do |compiler|
          compiler.define_rules build_dir, "#{dir}"
          compiler.defines << %Q[MRBGEM_#{funcname.upcase}_VERSION=#{version}]
          compiler.include_paths << "#{dir}/include" if File.directory? "#{dir}/include"
        end

        define_gem_init_builder if @generate_functions
      end

      def add_dependency(name, *requirements)
        default_gem = requirements.last.kind_of?(Hash) ? requirements.pop : nil
        requirements = ['>= 0.0.0'] if requirements.empty?
        requirements.flatten!
        @dependencies << {:gem => name, :requirements => requirements, :default => default_gem}
      end

      def add_test_dependency(*args)
        add_dependency(*args) if build.test_enabled?
      end

      def add_conflict(name, *req)
        @conflicts << {:gem => name, :requirements => req.empty? ? nil : req}
      end

      def self.bin=(bin)
        @bins = [bin].flatten
      end

      def build_dir
        "#{build.build_dir}/mrbgems/#{name}"
      end

      def test_rbireps
        "#{build_dir}/gem_test.c"
      end

      def funcname
        @funcname ||= @name.gsub('-', '_')
      end

      def compilers
        MRuby::Build::COMPILERS.map do |c|
          instance_variable_get("@#{c}")
        end
      end

      def define_gem_init_builder
        file objfile("#{build_dir}/gem_init") => [ "#{build_dir}/gem_init.c", File.join(dir, "mrbgem.rake") ]
        file "#{build_dir}/gem_init.c" => [build.mrbcfile, __FILE__] + [rbfiles].flatten do |t|
          FileUtils.mkdir_p build_dir
          generate_gem_init("#{build_dir}/gem_init.c")
        end
      end

      def generate_gem_init(fname)
        open(fname, 'w') do |f|
          print_gem_init_header f
          build.mrbc.run f, rbfiles, "gem_mrblib_irep_#{funcname}" unless rbfiles.empty?
          f.puts %Q[void mrb_#{funcname}_gem_init(mrb_state *mrb);]
          f.puts %Q[void mrb_#{funcname}_gem_final(mrb_state *mrb);]
          f.puts %Q[]
          f.puts %Q[void GENERATED_TMP_mrb_#{funcname}_gem_init(mrb_state *mrb) {]
          f.puts %Q[  int ai = mrb_gc_arena_save(mrb);]
          f.puts %Q[  mrb_#{funcname}_gem_init(mrb);] if objs != [objfile("#{build_dir}/gem_init")]
          unless rbfiles.empty?
            f.puts %Q[  mrb_load_irep(mrb, gem_mrblib_irep_#{funcname});]
            f.puts %Q[  if (mrb->exc) {]
            f.puts %Q[    mrb_print_error(mrb);]
            f.puts %Q[    exit(EXIT_FAILURE);]
            f.puts %Q[  }]
          end
          f.puts %Q[  mrb_gc_arena_restore(mrb, ai);]
          f.puts %Q[}]
          f.puts %Q[]
          f.puts %Q[void GENERATED_TMP_mrb_#{funcname}_gem_final(mrb_state *mrb) {]
          f.puts %Q[  mrb_#{funcname}_gem_final(mrb);] if objs != [objfile("#{build_dir}/gem_init")]
          f.puts %Q[}]
        end
      end # generate_gem_init

      def print_gem_comment(f)
        f.puts %Q[/*]
        f.puts %Q[ * This file is loading the irep]
        f.puts %Q[ * Ruby GEM code.]
        f.puts %Q[ *]
        f.puts %Q[ * IMPORTANT:]
        f.puts %Q[ *   This file was generated!]
        f.puts %Q[ *   All manual changes will get lost.]
        f.puts %Q[ */]
      end

      def print_gem_init_header(f)
        print_gem_comment(f)
        f.puts %Q[#include <stdlib.h>] unless rbfiles.empty?
        f.puts %Q[#include "mruby.h"]
        f.puts %Q[#include "mruby/irep.h"] unless rbfiles.empty?
      end

      def print_gem_test_header(f)
        print_gem_comment(f)
        f.puts %Q[#include <stdio.h>]
        f.puts %Q[#include <stdlib.h>]
        f.puts %Q[#include "mruby.h"]
        f.puts %Q[#include "mruby/irep.h"]
        f.puts %Q[#include "mruby/variable.h"]
        f.puts %Q[#include "mruby/hash.h"] unless test_args.empty?
      end

      def test_dependencies
        [@name]
      end

      def custom_test_init?
        @custom_test_init
      end

      def version_ok?(req_versions)
        req_versions.map do |req|
          cmp, ver = req.split
          cmp_result = Version.new(version) <=> Version.new(ver)
          case cmp
          when '=' then cmp_result == 0
          when '!=' then cmp_result != 0
          when '>' then cmp_result == 1
          when '<' then cmp_result == -1
          when '>=' then cmp_result >= 0
          when '<=' then cmp_result <= 0
          when '~>'
            Version.new(version).twiddle_wakka_ok?(Version.new(ver))
          else
            fail "Comparison not possible with '#{cmp}'"
          end
        end.all?
      end
    end
  end
end
