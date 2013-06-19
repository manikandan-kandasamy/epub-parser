require_relative 'helper'
require 'epub/publication'

class TestPublication < Test::Unit::TestCase
  include EPUB::Publication
  def setup
    @package = EPUB::Publication::Package.new
  end

  def test_package_clear_package_attribute_of_submodules_when_attribute_writer_called
    metadata = EPUB::Publication::Package::Metadata.new
    another_metadata = EPUB::Publication::Package::Metadata.new

    @package.metadata = metadata
    assert_equal metadata.package, @package

    @package.metadata = another_metadata
    assert_nil metadata.package
  end

  class TestMetadata < TestPublication
    def test_meta_refines_setter_connect_refinee_to_the_meta
      refiner = Package::Metadata::Meta.new
      refinee = Package::Metadata::Meta.new
      refiner.refines = refinee
      assert_same refinee.refiners.first, refiner 
    end

    def test_link_refines_setter_connect_refinee_to_the_link
      refiner = Package::Metadata::Link.new
      refinee = Package::Metadata::Meta.new
      refiner.refines = refinee
      assert_same refinee.refiners.first, refiner 
    end

    def test_title_returns_extended_title_when_it_exists
      extended_title = Package::Metadata::Title.new
      extended_title.id = 'extended-title'
      extended_title.content = 'Extended Title'
      extended_refiner = Package::Metadata::Meta.new
      extended_refiner.property = 'title-type'
      extended_refiner.content = 'extended'
      extended_refiner.refines = extended_title
      extended_order = Package::Metadata::Meta.new
      extended_order.property = 'display-seq'
      extended_order.content = 2
      extended_order.refines = extended_title

      main_title = Package::Metadata::Title.new
      main_title.id = 'main-title'
      main_title.content = 'Main Title'
      main_refiner = Package::Metadata::Meta.new
      main_refiner.property = 'title-type'
      main_refiner.content = 'main'
      main_refiner.refines = main_title
      main_order = Package::Metadata::Meta.new
      main_order.property = 'display-seq'
      main_order.content = 1
      main_order.refines = main_title

      package = Package::Metadata.new
      package.titles << main_title
      package.titles << extended_title

      assert_equal 'Extended Title', package.title
    end

    def test_title_returns_compositted_title_when_it_is_not_empty
      main_title = Package::Metadata::Title.new
      main_title.id = 'main-title'
      main_title.content = 'main title'
      main_refiner = Package::Metadata::Meta.new
      main_refiner.property = 'title-type'
      main_refiner.content = 'main'
      main_refiner.refines = main_title
      main_order = Package::Metadata::Meta.new
      main_order.property = 'display-seq'
      main_order.content = 1
      main_order.refines = main_title

      subtitle = Package::Metadata::Title.new
      subtitle.id = 'subtitle'
      subtitle.content = 'subtitle'
      sub_refiner = Package::Metadata::Meta.new
      sub_refiner.property = 'title-type'
      sub_refiner.content = 'subtitle'
      sub_refiner.refines = subtitle
      sub_order = Package::Metadata::Meta.new
      sub_order.property = 'display-seq'
      sub_order.content = 2
      sub_order.refines = subtitle

      package = Package::Metadata.new
      package.titles << main_title << subtitle

      assert_equal "main title\nsubtitle", package.title
    end

    def test_title_returns_main_title_when_no_title_has_order
      main_title = Package::Metadata::Title.new
      main_title.id = 'main-title'
      main_title.content = 'main title'
      main_refiner = Package::Metadata::Meta.new
      main_refiner.property = 'title-type'
      main_refiner.content = 'main'
      main_refiner.refines = main_title

      subtitle = Package::Metadata::Title.new
      subtitle.id = 'subtitle'
      subtitle.content = 'subtitle'
      sub_refiner = Package::Metadata::Meta.new
      sub_refiner.property = 'title-type'
      sub_refiner.content = 'subtitle'
      sub_refiner.refines = subtitle

      package = Package::Metadata.new
      package.titles << subtitle << main_title

      assert_equal "main title", package.title
    end

    def test_meta_refining_publication_is_primary_expression
      meta = Package::Metadata::Meta.new
      meta.property = 'dcterms:modified'

      assert_true meta.primary_expression?
    end

    def test_meta_refining_other_element_is_subexpression
      title = Package::Metadata::Title.new
      title.id = 'title'
      meta = Package::Metadata::Meta.new
      meta.refines = title

      assert_true meta.subexpression?
    end

    def test_dcmes_inspect_includes_class_name
      meta = Package::Metadata::Title.new

      assert_match /Package::Metadata::Title/, meta.inspect
    end

    def test_dcmes_inspect_includes_instance_variables
      meta = Package::Metadata::DCMES.new
      meta.lang = 'en-US'
      meta.dir = 'rtl'

      assert_match /@lang/, meta.inspect
      assert_match /en\-US/, meta.inspect
      assert_match /@dir/, meta.inspect
      assert_match /rtl/, meta.inspect
    end

    def test_meta_inspect_includes_class_name
      meta = Package::Metadata::Meta.new

      assert_match /Package::Metadata::Meta/, meta.inspect
    end

    def test_meta_inspect_includes_instance_variables
      meta = Package::Metadata::Meta.new
      meta.id = 'meta-id'
      meta.content = 'meta content'

      assert_match /@id/, meta.inspect
      assert_match /meta\-id/, meta.inspect
      assert_match /@content/, meta.inspect
      assert_match /meta content/, meta.inspect
    end
  end

  class TestManifest < TestPublication
    include EPUB::Publication

    class TestItem < TestManifest
      def test_content_document_returns_nil_when_not_xhtml_nor_svg
        item = EPUB::Publication::Package::Manifest::Item.new
        item.media_type = 'some/media'
        assert_nil item.content_document
      end

      def test_content_document_returns_navigation_document_when_nav
        item = EPUB::Publication::Package::Manifest::Item.new
        item.media_type = 'application/xhtml+xml'
        item.properties = %w[nav]
        stub(item).read {File.read(File.expand_path('../fixtures/book/OPS/nav.xhtml', __FILE__))}
        stub(item).manifest.stub!.items {[]}

        assert_instance_of EPUB::ContentDocument::Navigation, item.content_document
      end

      def test_can_refer_itemref_which_refers_self
        itemref = stub!
        stub(itemref).idref {'item'}
        item = Package::Manifest::Item.new
        item.id = 'item'
        stub(item).manifest.stub!.package.stub!.spine.stub!.itemrefs {[itemref]}

        assert_same itemref, item.itemref
      end

      def test_xhtml_returns_true_when_xhtml
        item = Package::Manifest::Item.new
        item.media_type = 'application/xhtml+xml'

        assert_true item.xhtml?
      end

      def test_xhtml_returns_false_when_not_xhtml
        item = Package::Manifest::Item.new
        item.media_type = 'text/css'

        assert_false item.xhtml?
      end
    end
  end

  class TestSpine < TestPublication
    class TestItemref < TestSpine
      def setup
        super
        @itemref = Package::Spine::Itemref.new
      end

      def test_default_page_spread_is_nil
        assert_nil @itemref.page_spread
      end

      def test_can_set_page_spread
        @itemref.page_spread = 'left'

        assert_equal 'left', @itemref.page_spread
        assert_include @itemref.properties, 'page-spread-left'
      end

      def test_page_spread_is_exclusive
        @itemref.page_spread = 'left'
        @itemref.page_spread = 'right'

        assert_not_include @itemref.properties, 'page-spread-left'
      end

      def test_can_set_item
        package = Package.new
        item = Package::Manifest::Item.new
        item.id = 'item'
        manifest = Package::Manifest.new
        spine = Package::Spine.new
        manifest << item
        spine << @itemref
        package.manifest = manifest
        package.spine = spine

        @itemref.item = item

        assert_equal 'item', @itemref.idref
        assert_include spine.items, item
        assert_same item, @itemref.item
      end

      def test_itemref_equals_itemref_with_same_attributes
        base = Package::Spine::Itemref.new
        another = Package::Spine::Itemref.new
        [base, another].each do |itemref|
          [:spine, :idref, :id].each do |attr|
            itemref.__send__ "#{attr}=", attr.to_s
          end
          itemref.linear = false
        end
        base.properties = ['property1', 'property2']
        another.properties = ['property2', 'property1']

        assert_true base == another

        base.linear = true
        another.linear = 'yes'

        assert_true base == another
      end

      def test_itemref_doesnt_equal_itemref_with_different_attributes
        base = Package::Spine::Itemref.new
        another = Package::Spine::Itemref.new
        [base, another].each do |itemref|
          [:spine, :idref, :id].each do |attr|
            itemref.__send__ "#{attr}=", attr.to_s
          end
          itemref.linear = false
        end
        base.properties = ['property1', 'property2']
        another.properties = ['property1', 'property2', 'property3']

        assert_false base == another
      end
    end
  end
end
