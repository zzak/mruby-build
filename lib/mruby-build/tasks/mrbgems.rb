module MRuby
  module Tasks
    class Mrbgems < Rake::TaskLib
      def initialize
        MRuby.each_target do
          if enable_gems?
            # set up all gems
            gems.each(&:setup)
            gems.check self

            # loader all gems
            self.libmruby << objfile("#{build_dir}/mrbgems/gem_init")

            file objfile("#{build_dir}/mrbgems/gem_init") => ["#{build_dir}/mrbgems/gem_init.c", "#{build_dir}/LEGAL"]
            file "#{build_dir}/mrbgems/gem_init.c" do |t|
              FileUtils.mkdir_p "#{build_dir}/mrbgems"
              open(t.name, 'w') do |f|
                gem_func_gems = gems.select { |g| g.generate_functions }
                gem_func_decls = gem_func_gems.each_with_object('') do |g, s|
                  s << "void GENERATED_TMP_mrb_#{g.funcname}_gem_init(mrb_state*);\n" \
                       "void GENERATED_TMP_mrb_#{g.funcname}_gem_final(mrb_state*);\n"
                end
                gem_init_calls = gem_func_gems.each_with_object('') do |g, s|
                  s << "  GENERATED_TMP_mrb_#{g.funcname}_gem_init(mrb);\n"
                end
                gem_final_calls = gem_func_gems.each_with_object('') do |g, s|
                  s << "  GENERATED_TMP_mrb_#{g.funcname}_gem_final(mrb);\n"
                end
                f.puts %Q[/*]
                f.puts %Q[ * This file contains a list of all]
                f.puts %Q[ * initializing methods which are]
                f.puts %Q[ * necessary to bootstrap all gems.]
                f.puts %Q[ *]
                f.puts %Q[ * IMPORTANT:]
                f.puts %Q[ *   This file was generated!]
                f.puts %Q[ *   All manual changes will get lost.]
                f.puts %Q[ */]
                f.puts %Q[]
                f.puts %Q[#include "mruby.h"]
                f.puts %Q[]
                f.write gem_func_decls
                f.puts %Q[]
                f.puts %Q[static void]
                f.puts %Q[mrb_final_mrbgems(mrb_state *mrb) {]
                f.write gem_final_calls
                f.puts %Q[}]
                f.puts %Q[]
                f.puts %Q[void]
                f.puts %Q[mrb_init_mrbgems(mrb_state *mrb) {]
                f.write gem_init_calls
                f.puts %Q[  mrb_state_atexit(mrb, mrb_final_mrbgems);] unless gem_final_calls.empty?
                f.puts %Q[}]
              end
            end

            if test_enabled?
              libmruby = libfile("#{build_dir}/lib/libmruby")
              libmruby_core = libfile("#{build_dir}/lib/libmruby_core")

              mrbtest = gems.select { |gem| gem.name == "mruby-test" }.first
              clib = "#{mrbtest.build_dir}/mrbtest.c"
              mlib = clib.ext(exts.object)
              init = "#{mrbtest.dir}/init_mrbtest.c"
              exec = exefile("#{build_dir}/bin/mrbtest")

              mrbtest_lib = libfile("#{mrbtest.build_dir}/mrbtest")
              mrbtest_objs = []

              assert_c = "#{mrbtest.build_dir}/assert.c"
              assert_rb = "#{mrbtest.dir}/lib/assert.rb"
              assert_lib = assert_c.ext(exts.object)
              mrbtest_objs << assert_lib

              file assert_lib => assert_c
              file assert_c => assert_rb do |t|
                open(t.name, 'w') do |f|
                  mrbc.run f, assert_rb, 'mrbtest_assert_irep'
                end
              end

              gem_table = gems.generate_gem_table self

              gems.each do |g|
                dep_list = gems.tsort_dependencies(g.test_dependencies, gem_table).select(&:generate_functions)
                test_rbobj = g.test_rbireps.ext(exts.object)
                g.test_objs << test_rbobj

                file test_rbobj => g.test_rbireps
                file g.test_rbireps => [g.test_rbfiles].flatten do |t|
                  FileUtils.mkdir_p File.dirname(t.name)
                  open(t.name, 'w') do |f|
                    g.print_gem_test_header(f)
                    test_preload = g.test_preload and [g.dir, MRUBY_ROOT].map {|dir|
                      File.expand_path(g.test_preload, dir)
                    }.find {|file| File.exist?(file) }

                    f.puts %Q[/*]
                    f.puts %Q[ * This file contains a test code for #{g.name} gem.]
                    f.puts %Q[ *]
                    f.puts %Q[ * IMPORTANT:]
                    f.puts %Q[ *   This file was generated!]
                    f.puts %Q[ *   All manual changes will get lost.]
                    f.puts %Q[ */]
                    if test_preload.nil?
                      f.puts %Q[extern const uint8_t mrbtest_assert_irep[];]
                    else
                      g.build.mrbc.run f, test_preload, "gem_test_irep_#{g.funcname}_preload"
                    end
                    g.test_rbfiles.flatten.each_with_index do |rbfile, i|
                      g.build.mrbc.run f, rbfile, "gem_test_irep_#{g.funcname}_#{i}"
                    end
                    f.puts %Q[void mrb_#{g.funcname}_gem_test(mrb_state *mrb);] unless g.test_objs.empty?
                    dep_list.each do |d|
                      f.puts %Q[void GENERATED_TMP_mrb_#{d.funcname}_gem_init(mrb_state *mrb);]
                      f.puts %Q[void GENERATED_TMP_mrb_#{d.funcname}_gem_final(mrb_state *mrb);]
                    end
                    f.puts %Q[void mrb_init_test_driver(mrb_state *mrb, mrb_bool verbose);]
                    f.puts %Q[void mrb_t_pass_result(mrb_state *dst, mrb_state *src);]
                    f.puts %Q[void GENERATED_TMP_mrb_#{g.funcname}_gem_test(mrb_state *mrb) {]
                    unless g.test_rbfiles.empty?
                      f.puts %Q[  mrb_state *mrb2;]
                      unless g.test_args.empty?
                        f.puts %Q[  mrb_value test_args_hash;]
                      end
                      f.puts %Q[  int ai;]
                      g.test_rbfiles.count.times do |i|
                        f.puts %Q[  ai = mrb_gc_arena_save(mrb);]
                        f.puts %Q[  mrb2 = mrb_open_core(mrb_default_allocf, NULL);]
                        f.puts %Q[  if (mrb2 == NULL) {]
                        f.puts %Q[    fprintf(stderr, "Invalid mrb_state, exiting \%s", __FUNCTION__);]
                        f.puts %Q[    exit(EXIT_FAILURE);]
                        f.puts %Q[  }]
                        dep_list.each do |d|
                          f.puts %Q[  GENERATED_TMP_mrb_#{d.funcname}_gem_init(mrb2);]
                          f.puts %Q[  mrb_state_atexit(mrb2, GENERATED_TMP_mrb_#{d.funcname}_gem_final);]
                        end
                        f.puts %Q[  mrb_init_test_driver(mrb2, mrb_test(mrb_gv_get(mrb, mrb_intern_lit(mrb, "$mrbtest_verbose"))));]
                        if test_preload.nil?
                          f.puts %Q[  mrb_load_irep(mrb2, mrbtest_assert_irep);]
                        else
                          f.puts %Q[  mrb_load_irep(mrb2, gem_test_irep_#{g.funcname}_preload);]
                        end
                        f.puts %Q[  if (mrb2->exc) {]
                        f.puts %Q[    mrb_print_error(mrb2);]
                        f.puts %Q[    exit(EXIT_FAILURE);]
                        f.puts %Q[  }]
                        f.puts %Q[  mrb_const_set(mrb2, mrb_obj_value(mrb2->object_class), mrb_intern_lit(mrb2, "GEMNAME"), mrb_str_new(mrb2, "#{g.name}", #{g.name.length}));]

                        unless g.test_args.empty?
                          f.puts %Q[  test_args_hash = mrb_hash_new_capa(mrb, #{g.test_args.length}); ]
                          g.test_args.each do |arg_name, arg_value|
                            escaped_arg_name = arg_name.gsub('\\', '\\\\\\\\').gsub('"', '\"')
                            escaped_arg_value = arg_value.gsub('\\', '\\\\\\\\').gsub('"', '\"')
                            f.puts %Q[  mrb_hash_set(mrb2, test_args_hash, mrb_str_new(mrb2, "#{escaped_arg_name.to_s}", #{escaped_arg_name.to_s.length}), mrb_str_new(mrb2, "#{escaped_arg_value.to_s}", #{escaped_arg_value.to_s.length})); ]
                          end
                          f.puts %Q[  mrb_const_set(mrb2, mrb_obj_value(mrb2->object_class), mrb_intern_lit(mrb2, "TEST_ARGS"), test_args_hash); ]
                        end

                        f.puts %Q[  mrb_#{g.funcname}_gem_test(mrb2);] if g.custom_test_init?

                        f.puts %Q[  mrb_load_irep(mrb2, gem_test_irep_#{g.funcname}_#{i});]
                        f.puts %Q[  ]

                        f.puts %Q[  mrb_t_pass_result(mrb, mrb2);]
                        f.puts %Q[  mrb_close(mrb2);]
                        f.puts %Q[  mrb_gc_arena_restore(mrb, ai);]
                      end
                    end
                    f.puts %Q[}]
                  end
                end
              end

              file mlib => clib
              file clib => init do |t|
                _pp "GEN", "*.rb", "#{clib.relative_path}"
                FileUtils.mkdir_p File.dirname(clib)
                open(clib, 'w') do |f|
                  f.puts %Q[/*]
                  f.puts %Q[ * This file contains a list of all]
                  f.puts %Q[ * test functions.]
                  f.puts %Q[ *]
                  f.puts %Q[ * IMPORTANT:]
                  f.puts %Q[ *   This file was generated!]
                  f.puts %Q[ *   All manual changes will get lost.]
                  f.puts %Q[ */]
                  f.puts %Q[]
                  f.puts IO.read(init)
                  gems.each do |g|
                    f.puts %Q[void GENERATED_TMP_mrb_#{g.funcname}_gem_test(mrb_state *mrb);]
                  end
                  f.puts %Q[void mrbgemtest_init(mrb_state* mrb) {]
                  gems.each do |g|
                    f.puts %Q[    GENERATED_TMP_mrb_#{g.funcname}_gem_test(mrb);]
                  end
                  f.puts %Q[}]
                end
              end

              gems.each do |v|
                mrbtest_objs.concat v.test_objs
              end

              file mrbtest_lib => mrbtest_objs do |t|
                archiver.run t.name, t.prerequisites
              end

              unless build_mrbtest_lib_only?
                file exec => [mlib, mrbtest_lib, libmruby, libmruby_core] do |t|
                  gem_flags = gems.map { |g| g.linker.flags }
                  gem_flags_before_libraries = gems.map { |g| g.linker.flags_before_libraries }
                  gem_flags_after_libraries = gems.map { |g| g.linker.flags_after_libraries }
                  gem_libraries = gems.map { |g| g.linker.libraries }
                  gem_library_paths = gems.map { |g| g.linker.library_paths }
                  linker.run t.name, t.prerequisites, gem_libraries, gem_library_paths, gem_flags, gem_flags_before_libraries
                end
              end
            end
          end

          # legal documents
          file "#{build_dir}/LEGAL" do |t|
            open(t.name, 'w+') do |f|
             f.puts <<LEGAL
Copyright (c) #{Time.now.year} mruby developers

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
LEGAL

              if enable_gems?
                f.puts <<GEMS_LEGAL

Additional Licenses

Due to the reason that you choosed additional mruby packages (GEMS),
please check the following additional licenses too:
GEMS_LEGAL

                gems.map do |g|
                  authors = [g.authors].flatten.sort.join(", ")
                  f.puts
                  f.puts "GEM: #{g.name}"
                  f.puts "Copyright (c) #{Time.now.year} #{authors}"
                  f.puts "License: #{g.licenses}"
                end
              end
            end
          end
        end
      end
    end
  end
end
