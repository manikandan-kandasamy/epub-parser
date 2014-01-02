# -*- coding: utf-8 -*-
require_relative 'helper'
require 'epub/cfi'

class TestContentDocument < Test::Unit::TestCase
  include EPUB::ContentDocument

  def test_top_level?
    manifest = EPUB::Publication::Package::Manifest.new
    spine = EPUB::Publication::Package::Spine.new

    item1 = EPUB::Publication::Package::Manifest::Item.new
    item1.id = 'item1'
    item2 = EPUB::Publication::Package::Manifest::Item.new
    item2.id = 'item2'
    manifest << item1 << item2

    itemref = EPUB::Publication::Package::Spine::Itemref.new
    itemref.idref = 'item1'
    spine << itemref

    package = EPUB::Publication::Package.new
    package.manifest = manifest
    package.spine = spine

    doc = XHTML.new
    doc.item = item1
    assert_true doc.top_level?

    doc = XHTML.new
    doc.item = item2
    assert_false doc.top_level?
  end

  def test_read_returns_content_document_as_string
    item = stub
    stub(item).read {'content'}
    content_doc = XHTML.new
    content_doc.item = item
    assert_equal 'content', content_doc.read
  end

  def test_title_returns_value_of_title_element
    content_doc = XHTML.new
    stub(content_doc).read {File.read(File.join(File.dirname(__FILE__), 'fixtures', 'book', 'OPS', '日本語.xhtml'))}
    assert_equal '日本語', content_doc.title
  end

  def test_title_returns_empty_string_when_title_element_not_exist
    content_doc = XHTML.new
    stub(content_doc).read {'content'}
    assert_equal '', content_doc.title
  end

  class TestSearch < self
    def setup
      super
      item = EPUB::Publication::Package::Manifest::Item.new
      stub(item).read {File.read(File.join(File.dirname(__FILE__), 'fixtures', 'book', 'OPS', 'search.xhtml'))}
      @content_doc = XHTML.new
      @content_doc.item = item
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

      assert_equal expected, @content_doc.search('search')
    end

    def test_text_after_child_element
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(character_offset: 6, index: 3),
      ]

      assert_equal expected, @content_doc.search('paragraph').first
    end

    def test_stepping_over_start_tag
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 4),
        EPUB::CFI::Step.new(character_offset: 8, index: 1)
      ]

      assert_equal expected, @content_doc.search('an em').first
    end

    def test_not_stepping_over_tag
      assert_empty @content_doc.search("仮名がな")
    end

    def test_img
      expected = [
        EPUB::CFI::Step.new(element: 'body', index: 4),
        EPUB::CFI::Step.new(element: 'p', index: 6),
        EPUB::CFI::Step.new(element: 'img', index: 2)
      ]

      assert_equal expected, @content_doc.search('image').first
    end
  end
end
