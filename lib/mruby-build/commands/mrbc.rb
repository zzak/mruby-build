module MRuby
  class Command::Mrbc < Command
    attr_accessor :compile_options

    def initialize(build)
      super
      @command = nil
      @compile_options = "-B%{funcname} -o-"
    end

    def run(out, infiles, funcname)
      @command ||= @build.mrbcfile
      infiles = [infiles].flatten
      infiles.each do |f|
        _pp "MRBC", f.relative_path, nil, :indent => 2
      end
      IO.popen("#{filename @command} #{@compile_options % {:funcname => funcname}} #{filename(infiles).join(' ')}", 'r+') do |io|
        out.puts io.read
      end
      # if mrbc execution fail, drop the file
      if $?.exitstatus != 0
        File.delete(out.path)
        exit(-1)
      end
    end
  end
end
