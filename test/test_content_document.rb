# -*- coding: utf-8 -*-
require_relative 'helper'

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

  def test_search
    item = EPUB::Publication::Package::Manifest::Item.new
    stub(item).read {File.read(File.join(File.dirname(__FILE__), 'fixtures', 'book', 'OPS', 'nav.xhtml'))}
    content_doc = XHTML.new
    content_doc.item = item
    expected = [
      [
        [
          {:element => 'html', :index => 2},
          {:element => 'head', :index => 2},
          {:element => 'title', :index => 2}
        ],
        {:position => 9, :index => 1}
      ],
      [
        [
          {:element => 'html', :index => 2},
          {:element => 'body', :index => 4},
          {:element => 'div', :index => 2},
          {:element => 'nav', :index => 2},
          {:element => 'hgroup', :index => 2},
          {:element => 'h1', :index => 4}
        ],
        {:position => 9, :index => 1}
      ]
    ]

    assert_equal expected, content_doc.search('Content')
  end
end
