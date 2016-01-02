# MRuby::Build

Tool for building MRuby.

## Goals

* Extract current build system
* Written as a CRuby gem
* Interface with Rake

## Features (Roadmap)

* Build specific targets
* Improve toolchain support
* Better build time introspection
  * "Give me all gems for this build"
  * "Give me test cases for all deps"
* Pull mrbgems from source
  * mgem
  * git
* Specify path for finding gems
* Dependency lock file
  * Manifest specifies SHA/Tag/Branch (Version)
* Dependency resolver
  * Warn duplicate gems with different source
  * Support versions

## Use (TODO)

* gem install
* rake

## License

mruby-build is released under the [MIT License](http://www.opensource.org/licenses/MIT).
