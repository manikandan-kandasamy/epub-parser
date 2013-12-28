module EPUB
  class CFI
    attr_accessor :steps

    def initialize
      @steps = []
    end

    def ==(other)
      steps == other.steps
    end

    class Step
      ATTRIBUTES = [:index, :id, :character_offset, :element]
      attr_accessor *ATTRIBUTES

      def initialize(attributes={})
        unknown_keywords = attributes.keys - ATTRIBUTES
        unless unknown_keywords.empty?
          content = "unknown keyword"
          content << 's' if unknown_keywords.length > 1
          content << ": #{unknown_keywords.join(', ')}"
          raise ArgumentError, content
        end
        ATTRIBUTES.each do |attr|
          __send__ "#{attr}=", attributes[attr]
        end
      end

      def ==(other)
        ATTRIBUTES.all? {|attr|
          __send__(attr) == other.__send__(attr)
        }
      end
    end
  end
end
