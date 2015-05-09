require_relative 'helper'
require 'epub3/book'
require 'epub3/publication'

class EPUB3::Publication::Package
  include EPUB3::Publication::FixedLayout
end

class TestFixedLayout < Test::Unit::TestCase
  include EPUB3::Publication

  class TestPackage < TestFixedLayout
    def test_package_dont_use_fixed_layout_by_default
      assert_false Package.new.using_fixed_layout?
    end

    def test_make_package_use_fixed_layout
      package = Package.new
      package.using_fixed_layout = true
      assert_true package.using_fixed_layout?

      package.using_fixed_layout = false
      assert_false package.using_fixed_layout?
    end
  end

  class TestMetadata < TestFixedLayout
    def setup
      @metadata = Package::Metadata.new
    end

    def test_default_layout_is_reflowable
      assert_equal 'reflowable', @metadata.rendition_layout
      assert_true @metadata.reflowable?
    end

    def test_deafult_layout_is_not_pre_paginated
      assert_false @metadata.pre_paginated?
    end

    def test_layout_is_pre_paginated_when_has_meta_with_rendition_layout
      meta = Package::Metadata::Meta.new
      meta.property = 'rendition:layout'
      meta.content = 'pre-paginated'
      @metadata.metas << meta
      assert_equal 'pre-paginated', @metadata.rendition_layout
      assert_true @metadata.pre_paginated?
    end

    def test_layout_is_reflowable_when_has_meta_with_rendition_layout
      meta = Package::Metadata::Meta.new
      meta.property = 'rendition:layout'
      meta.content = 'reflowable'
      @metadata.metas << meta
      assert_equal 'reflowable', @metadata.rendition_layout
      assert_true @metadata.reflowable?
    end

    def test_can_set_rendition_layout_by_method_of_metadata
      @metadata.pre_paginated = true
      assert_equal 'pre-paginated', @metadata.rendition_layout
      assert_false @metadata.reflowable?
      assert_true @metadata.pre_paginated?

      @metadata.reflowable = true
      assert_equal 'reflowable', @metadata.rendition_layout
      assert_true @metadata.reflowable?
      assert_false @metadata.pre_paginated?
    end

    def test_remove_meta_for_pre_paginated_when_making_reflowable
      meta = Package::Metadata::Meta.new
      meta.property = 'rendition:layout'
      meta.content = 'pre-paginated'
      @metadata.metas << meta

      @metadata.reflowable = true
      assert_false @metadata.metas.any? {|m| m.property == 'rendition:layout' && m.content == 'pre-paginated'}
    end

    def test_remove_meta_for_reflowable_when_making_pre_paginated
      meta = Package::Metadata::Meta.new
      meta.property = 'rendition:layout'
      meta.content = 'pre-paginated'
      @metadata.metas << meta
      meta = Package::Metadata::Meta.new
      meta.property = 'rendition:layout'
      meta.content = 'reflowable'
      @metadata.metas << meta

      @metadata.pre_paginated = true
      assert_false @metadata.metas.any? {|m| m.property == 'rendition:layout' && m.content == 'reflowable'}
    end

    def test_layout_setter
      @metadata.rendition_layout = 'reflowable'
      assert_equal 'reflowable', @metadata.rendition_layout

      @metadata.rendition_layout = 'pre-paginated'
      assert_equal 'pre-paginated', @metadata.rendition_layout

      assert_raise FixedLayout::UnsupportedRenditionValue do
        @metadata.rendition_layout = 'undefined'
      end
    end

    def test_utility_methods_for_rendition_layout_setter
      @metadata.make_pre_paginated
      assert_equal 'pre-paginated', @metadata.rendition_layout

      @metadata.make_reflowable
      assert_equal 'reflowable', @metadata.rendition_layout

      @metadata.pre_paginated!
      assert_equal 'pre-paginated', @metadata.rendition_layout

      @metadata.reflowable!
      assert_equal 'reflowable', @metadata.rendition_layout
    end

    def test_default_orientation_is_auto
      assert_equal 'auto', @metadata.rendition_orientation
    end
  end

  class TestItemref < TestFixedLayout
    def setup
      @itemref = Package::Spine::Itemref.new
      @package = Package.new
      @package.metadata = Package::Metadata.new
      @package.spine = Package::Spine.new
      @package.spine << @itemref
    end

    def test_inherits_metadatas_rendition_layout_by_default
      assert_equal 'reflowable', @itemref.rendition_layout

      @package.metadata.rendition_layout = 'pre-paginated'
      assert_equal 'pre-paginated', @itemref.rendition_layout
    end

    def test_overwrite_rendition_layout_of_metadata_when_set_explicitly
      @package.metadata.rendition_layout = 'pre-paginated'
      @itemref.properties << 'rendition:layout-reflowable'
      assert_equal 'reflowable', @itemref.rendition_layout
    end

    def test_can_set_explicitly
      @itemref.rendition_layout = 'pre-paginated'
      assert_equal 'pre-paginated', @itemref.rendition_layout
    end

    def test_can_unset_explicitly
      @itemref.rendition_layout = 'pre-paginated'
      @itemref.rendition_layout = nil
      assert_equal 'reflowable', @itemref.rendition_layout
      assert_not_include @itemref.properties, 'rendition:layout-reflowable'
    end

    def test_property_added_when_rendition_layout_set
      @itemref.rendition_layout = 'pre-paginated'
      assert_include @itemref.properties, 'rendition:layout-pre-paginated'
    end

    def test_opposite_property_removed_if_exists_when_rendition_layout_set
      @itemref.rendition_layout = 'reflowable'
      @itemref.rendition_layout = 'pre-paginated'
      assert_not_include @itemref.properties, 'rendition:layout-reflowable'
    end

    def test_utility_methods
      assert_true @itemref.reflowable?

      @itemref.make_pre_paginated
      assert_false @itemref.reflowable?
      assert_true @itemref.pre_paginated?
      assert_not_include @itemref.properties, 'rendition:layout-reflowbale'
      assert_include @itemref.properties, 'rendition:layout-pre-paginated'
    end

    def test_inherits_metadatas_rendition_spread_by_default
      assert_equal 'auto', @itemref.rendition_spread

      @package.metadata.rendition_spread = 'portrait'
      assert_equal 'portrait', @itemref.rendition_spread
    end

    def test_rendition_property_reader_has_alias
      assert_equal 'auto', @itemref.orientation

      @itemref.orientation = 'landscape'
      assert_equal 'landscape', @itemref.rendition_orientation
    end

    def test_page_spread_center_defined
      @itemref.properties << 'rendition:page-spread-center'
      assert_equal 'center', @itemref.page_spread
    end

    def test_can_make_page_spread_center_explicitly
      @itemref.page_spread = 'center'
      assert_include @itemref.properties, 'rendition:page-spread-center'
    end

    def test_page_spread_is_exclusive
      @itemref.page_spread = 'right'
      @itemref.page_spread = 'center'
      assert_not_include @itemref.properties, 'page-spread-right'
    end
  end

  class TestItem < TestFixedLayout
    def setup
      package = Package.new
      package.manifest = Package::Manifest.new
      @item = Package::Manifest::Item.new
      @item.id = 'item'
      package.manifest << @item
      package.spine = Package::Spine.new
      @itemref = Package::Spine::Itemref.new
      @itemref.idref = 'item'
      package.spine << @itemref
    end

    def test_can_access_rendition_attributes
      @itemref.rendition_layout = 'pre-paginated'
      assert_true @item.pre_paginated?

      @item.rendition_orientation = 'portrait'
      assert_equal 'portrait', @itemref.rendition_orientation
    end
  end

  class TestContentDocument < TestFixedLayout
    def setup
      package = Package.new
      package.manifest = Package::Manifest.new
      item = Package::Manifest::Item.new
      item.id = 'item'
      package.manifest << item
      package.spine = Package::Spine.new
      @itemref = Package::Spine::Itemref.new
      @itemref.idref = 'item'
      package.spine << @itemref
      @doc = EPUB3::ContentDocument::XHTML.new
      @doc.item = item
    end

    def test_can_access_rendition_attributes
      @itemref.rendition_layout = 'pre-paginated'
      assert_true @doc.pre_paginated?

      @doc.rendition_spread = 'none'
      assert_equal 'none', @itemref.rendition_spread
    end
  end
end
