module MRuby
  module Gem
    class Version
      include Comparable
      include Enumerable

      def <=>(other)
        ret = 0
        own = to_enum

        other.each do |oth|
          begin
            ret = own.next <=> oth
          rescue StopIteration
            ret = 0 <=> oth
          end

          break unless ret == 0
        end

        ret
      end

      # ~> compare algorithm
      #
      # Example:
      #    ~> 2.2   means >= 2.2.0 and < 3.0.0
      #    ~> 2.2.0 means >= 2.2.0 and < 2.3.0
      def twiddle_wakka_ok?(other)
        gr_or_eql = (self <=> other) >= 0
        still_minor = (self <=> other.skip_minor) < 0
        gr_or_eql and still_minor
      end

      def skip_minor
        a = @ary.dup
        a.slice!(-1)
        a[-1] = a[-1].succ
        a
      end

      def initialize(str)
        @str = str
        @ary = @str.split('.').map(&:to_i)
      end

      def each(&block); @ary.each(&block); end
      def [](index); @ary[index]; end
      def []=(index, value)
        @ary[index] = value
        @str = @ary.join('.')
      end
      def slice!(index)
        @ary.slice!(index)
        @str = @ary.join('.')
      end
    end
  end
end
