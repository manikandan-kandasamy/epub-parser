require 'epub/cfi'

module EPUB
  module ContentDocument
    class XHTML
      TEXT_LEVEL_SEMANTICS = %w[a em strong small s cite q dfn abbr data time code var samp kbd sub sup i b u mark ruby rt rp bdi bdo span br wbr]
      STEPPING_OVER_ELEMENTS = TEXT_LEVEL_SEMANTICS - %w[rt rp br]

      attr_accessor :item

      # @return [String] Returns the content string.
      def read
        item.read
      end
      alias raw_document read

      # @return [true|false] Whether referenced directly from spine or not.
      def top_level?
        !! item.itemref
      end

      # @return [String] Returns the value of title element.
      #                  If none, returns empty string
      def title
        title_elem = Nokogiri.XML(read).search('title').first
        if title_elem
          title_elem.text
        else
          warn 'title element not found'
          ''
        end
      end

      # @return [REXML::Document] content as REXML::Document object
      def rexml
        require 'rexml/document'
        @rexml ||= REXML::Document.new(raw_document)
      end

      # @return [Nokogiri::XML::Document] content as Nokogiri::XML::Document object
      def nokogiri
        @nokogiri ||= Nokogiri.XML(raw_document)
      end

      def search(query)
        doc = Nokogiri.XML(raw_document) {|config|
          config.options = Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NOCDATA
        }
        Searcher.search(query, doc)
      end

      class Searcher
        ROOT_ELEMENT = 'html'

        class << self
          def search(query, doc)
            element = doc.respond_to?(:root) ? doc.root : doc
            new(query).search(element, 2)
          end
        end

        def initialize(query)
          @query = query
        end

        def search(element, element_index)
          results = []
          text_index = -1
          elem_index = 0
          element.children.each do |node|
            case node.type
            when Nokogiri::XML::Node::TEXT_NODE
              text_index = elem_index + 1

              pos = 0
              content = node.content
              while pos
                pos = content.index(@query, pos)
                if pos
                  result_steps = [CFI::Step.new(element: element.node_name, index: element_index, id: element['id']), CFI::Step.new(index: text_index, character_offset: pos)]
                  results << result_steps
                  pos += 1
                end
              end

              @stepping_over_offset = get_stepping_over_offset(content)
            when Nokogiri::XML::Node::ELEMENT_NODE
              elem_index += 2

              if node.node_name == 'img' and node['alt'].index(@query)
                result_steps = [CFI::Step.new(element: element.node_name, index: element_index, id: element['id']), CFI::Step.new(element: node.node_name, index: elem_index, id: node['id'])]
                results << result_steps
                @stepping_over_offset = nil
              end

              results.concat search(node, elem_index).map {|result|
                if element.name == ROOT_ELEMENT
                  result
                else
                  result.unshift(CFI::Step.new(element: element.name, index: element_index, id: element['id']))
                end
              }
            end
          end
          results
        end

        def get_stepping_over_offset(content)
          return @query.length > 1
          content_length = content.length
          (@query.length - 1).downto 1 do |sublength|
            subquery = @query[0, sublength] # TODO: Cache it
            offset = content_length - sublength
            subcontent = content[offset..-1]
            if subquery == subcontent
              return offset
            end
          end
        end
      end
    end
  end
end
