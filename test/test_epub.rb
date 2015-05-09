require_relative 'helper'
require 'epub3/book'

class TestEUPB < Test::Unit::TestCase
  def setup
    @file = 'test/fixtures/book.epub'
  end

  def test_each_page_on_spine_returns_enumerator_when_block_not_given
    book = EPUB3::Parser.parse(@file)
    assert_kind_of Enumerator, book.each_page_on_spine
  end

  def test_enumerator_each_page_on_spine_returns_yields_item
    enum = EPUB3::Parser.parse(@file).each_page_on_spine
    enum.each do |entry|
      assert_kind_of EPUB3::Publication::Package::Manifest::Item, entry
    end
  end
end

