module MRuby
  class Command::Yacc < Command
    attr_accessor :compile_options

    def initialize(build)
      super
      @command = 'bison'
      @compile_options = '-o %{outfile} %{infile}'
    end

    def run(outfile, infile)
      FileUtils.mkdir_p File.dirname(outfile)
      _pp "YACC", infile.relative_path, outfile.relative_path
      _run compile_options, { :outfile => filename(outfile) , :infile => filename(infile) }
    end
  end
end
