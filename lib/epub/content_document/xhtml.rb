require 'epub/cfi'

module EPUB
  module ContentDocument
    class XHTML
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
        TEXT_LEVEL_SEMANTICS = %w[a em strong small s cite q dfn abbr data time code var samp kbd sub sup i b u mark ruby rt rp bdi bdo span br wbr]
        STEPPING_OVER_ELEMENTS = TEXT_LEVEL_SEMANTICS - %w[rt rp br]
        ROOT_ELEMENT = 'html'

        class << self
          def search(query, doc)
            element = doc.respond_to?(:root) ? doc.root : doc
            new(query).search(element, 2)
          end
        end

        def initialize(query)
          @query = query
          @stepping_over_length = @stepping_over_offset = @stepping_over_index = nil
        end

        def search(element, element_index) # TODO: Define appropriate variable name for second argument
          results = []
          text_index = -1
          elem_index = 0
          element.children.each_with_index do |node, node_index|
            case node.type
            when Nokogiri::XML::Node::TEXT_NODE
              text_index = elem_index + 1

              content = node.content
              results.concat find_from_content(content).map {|pos|
                [
                  CFI::Step.new(element: element.node_name, index: element_index, id: element['id']),
                  CFI::Step.new(index: text_index, character_offset: pos)
                ]
              }

              if @stepping_over_length && node_index == 0 && STEPPING_OVER_ELEMENTS.include?(element.node_name) or
                  @stepping_over_length && STEPPING_OVER_ELEMENTS.include?(@stepping_over_end_tag)
                subquery = @query[@stepping_over_length..-1]
                subcontent = content[0, subquery.length]
                if subquery == subcontent
                  result = [CFI::Step.new(character_offset: @stepping_over_offset, index: @stepping_over_index)]
                  if @stepping_over_end_tag
                    result = [
                      CFI::Step.new(element: element.node_name, index: element_index, id: element['id']),
                      CFI::Step.new(element: @stepping_over_end_tag, index: @stepping_over_end_tag_index, id: @stepping_over_end_tag_id)
                    ] + result
                  end
                  results << result
                end
              end

              @stepping_over_length, @stepping_over_offset = detect_stepping_over(content)
              @stepping_over_index = text_index if @stepping_over_length
            when Nokogiri::XML::Node::ELEMENT_NODE
              elem_index += 2

              if node.node_name == 'img' and node['alt'].index(@query)
                results << [
                  CFI::Step.new(element: element.node_name, index: element_index, id: element['id']),
                  CFI::Step.new(element: node.node_name, index: elem_index, id: node['id'])
                ]
                @stepping_over_length = @stepping_over_offset = @stepping_over_index = nil
              end

              child_results = search(node, elem_index)
              results.concat child_results.map {|result|
                if element.name == ROOT_ELEMENT
                  result
                else
                  result.unshift(CFI::Step.new(element: element.name, index: element_index, id: element['id']))
                end
              }
              # TODO: what's happening if the child's last node is img, br or hr and so on?
              if @stepping_over_length
                @stepping_over_end_tag = node.node_name
                @stepping_over_end_tag_index = elem_index
                @stepping_over_end_tag_id = node['id']
              else
                @stepping_over_end_tag = @stepping_over_end_tag_index = @stepping_over_end_tag_id = nil
              end
            end
          end
          results
        end

        private

        def find_from_content(content)
          results = []
          pos = 0
          while pos
            pos = content.index(@query, pos)
            if pos
              results << pos
              pos += 1
            end
          end
          results
        end

        def detect_stepping_over(content)
          return unless @query.length > 1
          content_length = content.length
          (@query.length - 1).downto 1 do |sublength|
            subquery = @query[0, sublength] # TODO: Cache it
            offset = content_length - sublength
            subcontent = content[offset..-1]
            if subquery == subcontent
              return sublength, offset
            end
          end
          nil
        end
      end
    end
  end
end
