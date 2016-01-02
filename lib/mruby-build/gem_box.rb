module MRuby
  GemBox = Object.new
  class << GemBox
    attr_accessor :path

    def new(&block); block.call(self); end
    def config=(obj); @config = obj; end
    def gem(gemdir, &block); @config.gem(gemdir, &block); end
  end
end
