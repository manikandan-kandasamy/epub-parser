# -*- coding: utf-8 -*-
require_relative 'helper'
require 'epub/searcher'

class TestSearcher < Test::Unit::TestCase
  class TestXHTML < self
    def search(query)
      doc = Nokogiri.XML(open(File.join(File.dirname(__FILE__), 'fixtures', 'book', 'OPS', 'search.xhtml'))) {|config|
        config.options = Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NOCDATA
      }
      EPUB::Searcher::XHTML.search(query, doc)
    end

    def test_search_simple
      expected = [
        [
          EPUB::CFI::Step.new(element: 'head', index: 2, id: nil),
          EPUB::CFI::Step.new(element: 'title', index: 2, id: nil),
          EPUB::CFI::Step.new(character_offset: 20, index: 1)
        ],
        [
          EPUB::CFI::Step.new(element: 'body', index: 4, id: nil),
          EPUB::CFI::Step.new(element: 'h1', index: 2, id: nil),
          EPUB::CFI::Step.new(element: 'em', index: 2, id: nil),
          EPUB::CFI::Step.new(character_offset: 0, index: 1)
        ]
      ]

      assert_equal expected, search('search')
    end

    def test_text_after_child_element
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(character_offset: 6, index: 3),
      ]

      assert_equal expected, search('paragraph').first
    end

    def test_stepping_over_start_tag
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(character_offset: 8, index: 1)
      ]

      assert_equal expected, search('an em').first
    end

    def test_stepping_over_end_tag
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(element: 'em', index: 2),
        EPUB::CFI::Step.new(character_offset: 1, index: 1)
      ]

      assert_equal expected, search('m in').first
    end

    def test_stepping_over_start_and_end_tag
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(character_offset: 8, index: 1)
      ]

      assert_equal expected, search('an em in').first
    end

    def test_not_stepping_over_tag
      assert_empty search("仮名がな")
    end

    # def test_pause_stepping_over_tag
    #   # <ruby>abc<rp>(</rp><rt>def</rt><rp>)</rp></ruby>ghi</ruby> should matches "abcghi"
    #   expectd = [
    #     EPUB::CFI::Step.new(element: 'html', index: 2),
    #   ]
    # end

    # <p>search sea<em>rch search search sear</em>ch</p>

    # search "cdefg" from <p>abc<span>def</span>ghi</p>

    def test_img
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 6),
        EPUB::CFI::Step.new(element: 'img', index: 2)
      ]

      assert_equal expected, search('image').first
    end
  end
end
