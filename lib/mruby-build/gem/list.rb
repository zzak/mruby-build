module MRuby
  module Gem
    class List
      include Enumerable

      def initialize
        @ary = []
      end

      def each(&b)
        @ary.each(&b)
      end

      def <<(gem)
        unless @ary.detect {|g| g.dir == gem.dir }
          @ary << gem
        else
          # GEM was already added to this list
        end
      end

      def empty?
        @ary.empty?
      end

      def generate_gem_table build
        gem_table = @ary.reduce({}) { |res,v| res[v.name] = v; res }

        default_gems = []
        each do |g|
          g.dependencies.each do |dep|
            unless gem_table.key? dep[:gem]
              if dep[:default]; default_gems << dep
              elsif File.exist? "#{MRUBY_ROOT}/mrbgems/#{dep[:gem]}" # check core
                default_gems << { :gem => dep[:gem], :default => { :core => dep[:gem] } }
              else # fallback to mgem-list
                default_gems << { :gem => dep[:gem], :default => { :mgem => dep[:gem] } }
              end
            end
          end
        end

        until default_gems.empty?
          def_gem = default_gems.pop

          spec = build.gem def_gem[:default]
          fail "Invalid gem name: #{spec.name} (Expected: #{def_gem[:gem]})" if spec.name != def_gem[:gem]
          spec.setup

          spec.dependencies.each do |dep|
            unless gem_table.key? dep[:gem]
              if dep[:default]; default_gems << dep
              else default_gems << { :gem => dep[:gem], :default => { :mgem => dep[:gem] } }
              end
            end
          end
          gem_table[spec.name] = spec
        end

        each do |g|
          g.dependencies.each do |dep|
            name = dep[:gem]
            req_versions = dep[:requirements]
            dep_g = gem_table[name]

            # check each GEM dependency against all available GEMs
            if dep_g.nil?
              fail "The GEM '#{g.name}' depends on the GEM '#{name}' but it could not be found"
            end
            unless dep_g.version_ok? req_versions
              fail "#{name} version should be #{req_versions.join(' and ')} but was '#{dep_g.version}'"
            end
          end

          cfls = g.conflicts.select { |c|
            cfl_g = gem_table[c[:gem]]
            cfl_g and cfl_g.version_ok?(c[:requirements] || ['>= 0.0.0'])
          }.map { |c| "#{c[:gem]}(#{gem_table[c[:gem]].version})" }
          fail "Conflicts of gem `#{g.name}` found: #{cfls.join ', '}" unless cfls.empty?
        end

        gem_table
      end

      def tsort_dependencies ary, table, all_dependency_listed = false
        unless all_dependency_listed
          left = ary.dup
          until left.empty?
            v = left.pop
            table[v].dependencies.each do |dep|
              left.push dep[:gem]
              ary.push dep[:gem]
            end
          end
        end

        ary.uniq!
        table.instance_variable_set :@root_gems, ary
        class << table
          include TSort
          def tsort_each_node &b
            @root_gems.each &b
          end

          def tsort_each_child(n, &b)
            fetch(n).dependencies.each do |v|
              b.call v[:gem]
            end
          end
        end

        begin
          table.tsort.map { |v| table[v] }
        rescue TSort::Cyclic => e
          fail "Circular mrbgem dependency found: #{e.message}"
        end
      end

      def check(build)
        gem_table = generate_gem_table build

        @ary = tsort_dependencies gem_table.keys, gem_table, true

        each do |g|
          import_include_paths(g)
        end
      end

      def import_include_paths(g)
        gem_table = @ary.reduce({}) { |res,v| res[v.name] = v; res }
        g.dependencies.each do |dep|
          dep_g = gem_table[dep[:gem]]
          # We can do recursive call safely
          # as circular dependency has already detected in the caller.
          import_include_paths(dep_g)

          g.compilers.each do |compiler|
            compiler.include_paths += dep_g.export_include_paths
            g.export_include_paths += dep_g.export_include_paths
          end
        end
      end
    end
  end
end
