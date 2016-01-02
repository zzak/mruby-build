module MRuby
  class Command::Compiler < Command
    attr_accessor :flags, :include_paths, :defines, :source_exts
    attr_accessor :compile_options, :option_define, :option_include_path, :out_ext

    def initialize(build, source_exts=[])
      super(build)
      @command = ENV['CC'] || 'cc'
      @flags = [ENV['CFLAGS'] || []]
      @source_exts = source_exts
      @include_paths = ["#{MRUBY_ROOT}/include"]
      @defines = %w()
      @option_include_path = '-I%s'
      @option_define = '-D%s'
      @compile_options = '%{flags} -o %{outfile} -c %{infile}'
    end

    alias header_search_paths include_paths
    def search_header_path(name)
      header_search_paths.find do |v|
        File.exist? build.filename("#{v}/#{name}").sub(/^"(.*)"$/, '\1')
      end
    end

    def search_header(name)
      path = search_header_path name
      path && build.filename("#{path}/#{name}").sub(/^"(.*)"$/, '\1')
    end

    def all_flags(_defineds=[], _include_paths=[], _flags=[])
      define_flags = [defines, _defineds].flatten.map{ |d| option_define % d }
      include_path_flags = [include_paths, _include_paths].flatten.map do |f|
        if MRUBY_BUILD_HOST_IS_CYGWIN
          option_include_path % cygwin_filename(f)
        else
          option_include_path % filename(f)
        end
      end
      [flags, define_flags, include_path_flags, _flags].flatten.join(' ')
    end

    def run(outfile, infile, _defineds=[], _include_paths=[], _flags=[])
      FileUtils.mkdir_p File.dirname(outfile)
      _pp "CC", infile.relative_path, outfile.relative_path
      if MRUBY_BUILD_HOST_IS_CYGWIN
        _run compile_options, { :flags => all_flags(_defineds, _include_paths, _flags),
                                :infile => cygwin_filename(infile), :outfile => cygwin_filename(outfile) }
      else
        _run compile_options, { :flags => all_flags(_defineds, _include_paths, _flags),
                                :infile => filename(infile), :outfile => filename(outfile) }
      end
    end

    def define_rules(build_dir, source_dir='')
      @out_ext = build.exts.object
      gemrake = File.join(source_dir, "mrbgem.rake")
      rakedep = File.exist?(gemrake) ? [ gemrake ] : []

      if build_dir.include? "mrbgems/"
        generated_file_matcher = Regexp.new("^#{Regexp.escape build_dir}/(.*)#{Regexp.escape out_ext}$")
      else
        generated_file_matcher = Regexp.new("^#{Regexp.escape build_dir}/(?!mrbgems/.+/)(.*)#{Regexp.escape out_ext}$")
      end
      source_exts.each do |ext, compile|
        rule generated_file_matcher => [
          proc { |file|
            file.sub(generated_file_matcher, "#{source_dir}/\\1#{ext}")
          },
          proc { |file|
            get_dependencies(file) + rakedep
          }
        ] do |t|
          run t.name, t.prerequisites.first
        end

        rule generated_file_matcher => [
          proc { |file|
            file.sub(generated_file_matcher, "#{build_dir}/\\1#{ext}")
          },
          proc { |file|
            get_dependencies(file) + rakedep
          }
        ] do |t|
          run t.name, t.prerequisites.first
        end
      end
    end

    private
    def get_dependencies(file)
      file = file.ext('d') unless File.extname(file) == '.d'
      if File.exist?(file)
        File.read(file).gsub("\\\n ", "").scan(/^\S+:\s+(.+)$/).flatten.map {|s| s.split(' ') }.flatten
      else
        []
      end + [ MRUBY_CONFIG ]
    end
  end
end
