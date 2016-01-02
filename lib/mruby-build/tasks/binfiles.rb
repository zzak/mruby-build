module MRuby
  module Tasks
    class Binfiles < Rake::TaskLib
      def initialize
        bin_path = ENV['INSTALL_DIR'] || "#{MRUBY_ROOT}/bin"

=begin
        FileUtils.mkdir_p bin_path, { :verbose => $verbose }

        #MRuby.targets['host'].bins.map do |bin|
        #  install_path = MRuby.targets['host'].exefile("#{bin_path}/#{bin}")
        #  source_path = MRuby.targets['host'].exefile("#{MRuby.targets['host'].build_dir}/bin/#{bin}")

        #  file install_path => source_path do |t|
        #    FileUtils.rm_f t.name, { :verbose => $verbose }
        #    FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
        #  end
        #end

        MRuby.each_target do |target|
          target.bins.map do |bin|
            install_path = target.exefile("#{bin_path}/#{bin}")
            source_path = target.exefile("#{target.build_dir}/bin/#{bin}")

            file install_path => source_path do |t|
              FileUtils.rm_f t.name, { :verbose => $verbose }
              FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
            end
          end
        end

        MRuby.each_target do |target|
          gems.map do |gem|
            gem.bins.each do |bin|
              exec = target.exefile("#{target.build_dir}/bin/#{bin}")
              objs = Dir.glob("#{gem.dir}/tools/#{bin}/*.{c,cpp,cxx,cc}").map do |f|
                objfile(f.pathmap("#{gem.build_dir}/tools/#{bin}/%n"))
              end

              file exec => objs do |t|
                gem_flags = gems.map { |g| g.linker.flags }
                gem_flags_before_libraries = gems.map { |g| g.linker.flags_before_libraries }
                gem_flags_after_libraries = gems.map { |g| g.linker.flags_after_libraries }
                gem_libraries = gems.map { |g| g.linker.libraries }
                gem_library_paths = gems.map { |g| g.linker.library_paths }
                linker.run t.name, t.prerequisites, gem_libraries, gem_library_paths, gem_flags, gem_flags_before_libraries, gem_flags_after_libraries
              end

              install_path = target.exefile("#{bin_path}/#{bin}")

              file install_path => exec do |t|
                FileUtils.rm_f t.name, { :verbose => $verbose }
                FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
              end
            end
          end
        end

        binfiles = MRuby.targets.reject { |n, t| n == 'host' }.map do |n, t|
          t.bins.map { |bin| t.exefile("#{t.build_dir}/bin/#{bin}") }
        end.flatten
=end
FileUtils.mkdir_p bin_path, { :verbose => $verbose }

binfiles = MRuby.targets['host'].bins.map do |bin|
  install_path = MRuby.targets['host'].exefile("#{bin_path}/#{bin}")
  source_path = MRuby.targets['host'].exefile("#{MRuby.targets['host'].build_dir}/bin/#{bin}")

  file install_path => source_path do |t|
    FileUtils.rm_f t.name, { :verbose => $verbose }
    FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
  end

  install_path
end

MRuby.each_target do |target|
  gems.map do |gem|
    gem.bins.each do |bin|
      exec = exefile("#{target.build_dir}/bin/#{bin}")
      objs = Dir.glob("#{gem.dir}/tools/#{bin}/*.{c,cpp,cxx,cc}").map do |f|
        objfile(f.pathmap("#{gem.build_dir}/tools/#{bin}/%n"))
      end

      file exec => objs + [libfile("#{build_dir}/lib/libmruby")] do |t|
        gem_flags = gems.map { |g| g.linker.flags }
        gem_flags_before_libraries = gems.map { |g| g.linker.flags_before_libraries }
        gem_flags_after_libraries = gems.map { |g| g.linker.flags_after_libraries }
        gem_libraries = gems.map { |g| g.linker.libraries }
        gem_library_paths = gems.map { |g| g.linker.library_paths }
        linker.run t.name, t.prerequisites, gem_libraries, gem_library_paths, gem_flags, gem_flags_before_libraries, gem_flags_after_libraries
      end

      if target == MRuby.targets['host']
        install_path = MRuby.targets['host'].exefile("#{bin_path}/#{bin}")

        file install_path => exec do |t|
          FileUtils.rm_f t.name, { :verbose => $verbose }
          FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
        end
        binfiles += [ install_path ]
      elsif target == MRuby.targets['host-debug']
        unless MRuby.targets['host'].gems.map {|g| g.bins}.include?([bin])
          install_path = MRuby.targets['host-debug'].exefile("#{bin_path}/#{bin}")

          file install_path => exec do |t|
            FileUtils.rm_f t.name, { :verbose => $verbose }
            FileUtils.cp t.prerequisites.first, t.name, { :verbose => $verbose }
          end
          binfiles += [ install_path ]
        end
      else
        binfiles += [ exec ]
      end
    end
  end
end

binfiles += MRuby.targets.map { |n, t|
  [t.libfile("#{t.build_dir}/lib/libmruby")]
}.flatten

binfiles += MRuby.targets.reject { |n, t| n == 'host' }.map { |n, t|
  t.bins.map { |bin| t.exefile("#{t.build_dir}/bin/#{bin}") }
}.flatten



        task :binfiles => binfiles
      end
    end
  end
end
