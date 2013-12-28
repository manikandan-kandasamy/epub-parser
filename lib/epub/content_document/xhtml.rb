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

      # @param query [String] search word
      # @param element [Nokogiri::XML::Node, nil]
      # @param steps [Array<Hash>]
      # @return [Array<Array<CFI::Step>>] start points of found search word
      def search(query, element=nil, steps=[])
        unless element
          element = Nokogiri.XML(raw_document) {|config|
            config.options = Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NOCDATA
          }
        end
        result = []
        text_index = -1
        elem_index = 0
        stepping_over_subquery = nil
        stepping_over_offset = nil
        element.children.each do |child|
          case child.type
          when Nokogiri::XML::Node::TEXT_NODE
            text_index = elem_index + 1
            pos = 0
            content = child.content
            while pos
              pos = content.index(query, pos)
              if pos
                result_steps = steps.map {|step_info| CFI::Step.new(step_info)}
                result_steps << CFI::Step.new(index: text_index, character_offset: pos)
                result << result_steps
                pos += 1
              end
            end

            sublength = query.length - 1
            until (subquery = query[0, sublength]).to_s.empty?
              subcontent = content[-sublength..-1]
              if subquery == subcontent
                stepping_over_subquery = query[sublength..-1]
                stepping_over_offset = content.length - sublength
                break
              end
              sublength -= 1
            end
          when Nokogiri::XML::Node::ELEMENT_NODE
            elem_index += 2
            if child.node_name == 'img' and child['alt'].index(query)
              result_steps = steps.map {|step_info| CFI::Step.new(step_info)}
              result_steps << CFI::Step.new(element: 'img', index: elem_index, id: child['id'])
              result << result_steps
            end

            if stepping_over_subquery
              child_result = search(stepping_over_subquery, child, [])
              unless child_result.empty?
                result_steps = steps.map {|step_info| CFI::Step.new(step_info)}
                result_steps << CFI::Step.new(character_offset: stepping_over_offset, index: text_index)
                result << result_steps
              end
            else
              next_steps = steps.dup
              next_steps << {:element => child.node_name, :index => elem_index, :id => child['id']}
              result.concat search(query, child, next_steps)
            end
            stepping_over_subquery = nil
            stepping_over_offset = nil
          end
        end
        result
      end
    end
  end
end
