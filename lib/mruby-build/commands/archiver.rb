module MRuby
  class Command::Archiver < Command
    attr_accessor :archive_options

    def initialize(build)
      super
      @command = ENV['AR'] || 'ar'
      @archive_options = 'rs %{outfile} %{objs}'
    end

    def run(outfile, objfiles)
      FileUtils.mkdir_p File.dirname(outfile)
      _pp "AR", outfile.relative_path
      if MRUBY_BUILD_HOST_IS_CYGWIN
        _run archive_options, { :outfile => cygwin_filename(outfile), :objs => cygwin_filename(objfiles).join(' ') }
      else
        _run archive_options, { :outfile => filename(outfile), :objs => filename(objfiles).join(' ') }
      end
    end
  end
end
