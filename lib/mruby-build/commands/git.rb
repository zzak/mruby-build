module MRuby
  class Command::Git < Command
    attr_accessor :flags
    attr_accessor :clone_options, :pull_options, :checkout_options

    def initialize(build)
      super
      @command = 'git'
      @flags = %w[]
      @clone_options = "clone %{flags} %{url} %{dir}"
      @pull_options = "pull"
      @checkout_options = "checkout %{checksum_hash}"
    end

    def run_clone(dir, url, _flags = [])
      _pp "GIT", url, dir.relative_path
      _run clone_options, { :flags => [flags, _flags].flatten.join(' '), :url => url, :dir => filename(dir) }
    end

    def run_pull(dir, url)
      root = Dir.pwd
      Dir.chdir dir
      _pp "GIT PULL", url, dir.relative_path
      _run pull_options
      Dir.chdir root
    end

    def run_checkout(dir, checksum_hash)
      root = Dir.pwd
      Dir.chdir dir
      _pp "GIT CHECKOUT", checksum_hash
      _run checkout_options, { :checksum_hash => checksum_hash }
      Dir.chdir root
    end
  end
end
