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

      # @param query [String] search word
      # @param element [Nokogiri::XML::Node, nil]
      # @param steps [Array<Hash>]
      # @return [Array<Array<Hash, Integer>>]
      def search(query, element=nil, steps=[])
        unless element
          element = Nokogiri.XML(raw_document) {|config|
            config.options = Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NOCDATA
          }
        end
        result = []
        current_node = {}
        text_index = -1
        elem_index = 0
        element.children.each do |child|
          case child.type
          when Nokogiri::XML::Node::TEXT_NODE
            text_index = elem_index + 1
            pos = 0
            while pos
              pos = child.content.index(query, pos)
              if pos
                result << [steps.dup, pos]
                pos += 1
              end
            end
          when Nokogiri::XML::Node::ELEMENT_NODE
            elem_index += 2
            next_steps = steps.dup
            next_steps << {:element => child.node_name, :index => elem_index}
            result += search(query, child, next_steps)
          end
        end
        result
      end
    end
  end
end
