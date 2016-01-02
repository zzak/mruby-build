module MRuby
  class Command::Linker < Command
    attr_accessor :flags, :library_paths, :flags_before_libraries, :libraries, :flags_after_libraries
    attr_accessor :link_options, :option_library, :option_library_path

    def initialize(build)
      super
      @command = ENV['LD'] || 'ld'
      @flags = (ENV['LDFLAGS'] || [])
      @flags_before_libraries, @flags_after_libraries = [], []
      @libraries = []
      @library_paths = []
      @option_library = '-l%s'
      @option_library_path = '-L%s'
      @link_options = "%{flags} -o %{outfile} %{objs} %{flags_before_libraries} %{libs} %{flags_after_libraries}"
    end

    def all_flags(_library_paths=[], _flags=[])
      library_path_flags = [library_paths, _library_paths].flatten.map do |f|
        if MRUBY_BUILD_HOST_IS_CYGWIN
          option_library_path % cygwin_filename(f)
        else
          option_library_path % filename(f)
        end
      end
      [flags, library_path_flags, _flags].flatten.join(' ')
    end

    def library_flags(_libraries)
      [libraries, _libraries].flatten.map{ |d| option_library % d }.join(' ')
    end

    def run(outfile, objfiles, _libraries=[], _library_paths=[], _flags=[], _flags_before_libraries=[], _flags_after_libraries=[])
      FileUtils.mkdir_p File.dirname(outfile)
      library_flags = [libraries, _libraries].flatten.map { |d| option_library % d }

      _pp "LD", outfile.relative_path
      if MRUBY_BUILD_HOST_IS_CYGWIN
        _run link_options, { :flags => all_flags(_library_paths, _flags),
                             :outfile => cygwin_filename(outfile) , :objs => cygwin_filename(objfiles).join(' '),
                             :flags_before_libraries => [flags_before_libraries, _flags_before_libraries].flatten.join(' '),
                             :flags_after_libraries => [flags_after_libraries, _flags_after_libraries].flatten.join(' '),
                             :libs => library_flags.join(' ') }
      else
        _run link_options, { :flags => all_flags(_library_paths, _flags),
                             :outfile => filename(outfile) , :objs => filename(objfiles).join(' '),
                             :flags_before_libraries => [flags_before_libraries, _flags_before_libraries].flatten.join(' '),
                             :flags_after_libraries => [flags_after_libraries, _flags_after_libraries].flatten.join(' '),
                             :libs => library_flags.join(' ') }
      end
    end
  end
end
