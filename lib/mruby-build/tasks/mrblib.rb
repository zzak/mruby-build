module MRuby
  module Tasks
    class Mrblib < Rake::TaskLib
      def initialize
        MRuby.each_target do
          self.libmruby << objfile("#{build_dir}/mrblib/mrblib")

          file objfile("#{build_dir}/mrblib/mrblib") => "#{build_dir}/mrblib/mrblib.c"
          file "#{build_dir}/mrblib/mrblib.c" => [mrbcfile] + Dir.glob("#{MRUBY_ROOT}/mrblib/*.rb").sort do |t|
            _, _, *rbfiles = t.prerequisites
            FileUtils.mkdir_p File.dirname(t.name)
            open(t.name, 'w') do |f|
              _pp "GEN", "*.rb", "#{t.name.relative_path}"
              f.puts File.read("#{MRUBY_ROOT}/mrblib/init_mrblib.c")
              mrbc.run f, rbfiles, 'mrblib_irep'
            end
          end
        end
      end
    end
  end
end
