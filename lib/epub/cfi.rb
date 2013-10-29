module EPUB
  class CFI
    attr_accessor :steps

    def initialize
      @steps = []
    end

    def to_s
      steps.join
    end

    def initialize_copy(obj)
      obj.steps = self.steps.map(&:dup)
    end

    class Step
      attr_accessor :node, :offset, :reference

      def initialize(node=0, offset=nil, reference=nil, follow_reference=false)
        @node, @offset, @reference, @follow_reference = node, offset, reference, follow_reference
      end

      def follow_reference?
        !!@follow_reference
      end

      def to_s
        string = "/#{node}"
        string << ":#{offset}" if offset
        string
      end
    end

    class SearchResult < Nokogiri::XML::SAX::Document
      attr_reader :cfis

      def initialize(query)
        @query = query
        @cfis = []
      end

      def start_document
        @current_cfi = CFI.new
        @node_index = 0
      end

      def start_element(name, attrs=[])
        # This is a bug.
        @node_index
        @current_cfi.steps << Step.new((@current_cfi.steps.length + 1) * 2)
      end

      def end_element(name)
        @current_cfi.steps.pop
      end

      def characters(string)
        previous_position = -1
        while position = string.index(@query, previous_position + 1)
          previous_position = position
          cfi = @current_cfi.dup
          cfi.steps.last.offset = position
          @cfis << cfi
        end
      end
    end
  end
end
