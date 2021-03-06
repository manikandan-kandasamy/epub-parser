require 'set'
require 'addressable/uri'
require 'rchardet'
require 'epub3/constants'
require 'epub3/parser/content_document'

module EPUB3
  module Publication
    class Package
      class Manifest
        include Inspector::PublicationModel

        attr_accessor :package,
                      :id

        def initialize
          @items = {}
        end

        # @return self
        def <<(item)
          item.manifest = self
          @items[item.id] = item
          self
        end

        def each_nav
          if block_given?
            each_item do |item|
              yield item if item.nav?
            end
          else
            each_item.lazy.select(&:nav?)
          end
        end

        def navs
          items.select(&:nav?)
        end

        def nav
          navs.first
        end

        def cover_image
          items.select(&:cover_image?).first
        end

        def each_item
          if block_given?
            @items.each_value do |item|
              yield item
            end
          else
            @items.each_value
          end
        end

        def items
          @items.values
        end

        def [](item_id)
          @items[item_id]
        end

        class Item
          DUMMY_ROOT_IRI = Addressable::URI.parse('http://example.net/').freeze

          include Inspector

          # @!attribute [rw] manifest
          #   @return [Manifest] Returns the value of manifest
          # @!attribute [rw] id
          #   @return [String] Returns the value of id
          # @!attribute [rw] href
          #   @return [Addressable::URI] Returns the value of href,
          #                              which is relative IRI from rootfile(OPF file)
          # @!attribute [rw] media_type
          #   @return [String] Returns the value of media_type
          # @!attribute [rw] properties
          #   @return [Set<String>] Returns the value of properties
          # @!attribute [rw] media_overlay
          #   @return [String] Returns the value of media_overlay
          # @!attribute [rw] fallback
          #   @return [Item] Returns the value of attribute fallback
          attr_accessor :manifest,
                        :id, :media_type, :fallback, :media_overlay
          attr_reader :properties, :href

          def initialize
            @properties = Set.new
          end

          def properties=(props)
            @properties = props.kind_of?(Set) ? props : Set.new(props)
          end

          def href=(iri)
            @href = iri.kind_of?(Addressable::URI) ? iri : Addressable::URI.parse(iri)
          end

          # @todo Handle circular fallback chain
          def fallback_chain
            @fallback_chain ||= traverse_fallback_chain([])
          end

          # full path in archive
          # @return [Addressable::URI]
          def full_path
            return @full_path if @full_path
            rootfile = manifest.package.book.ocf.container.rootfile.full_path
            path = DUMMY_ROOT_IRI + rootfile + href
            path.scheme = nil
            path.host = nil
            path.path = path.path[1..-1]
            @full_path = path
          end

          # full path in archive
          # @return [String]
          def entry_name
            Addressable::URI.unencode(full_path)
          end

          def read
            raw_content = manifest.package.book.container_adapter.read(manifest.package.book.epub_file, entry_name)

            unless media_type.start_with?('text/') or
                media_type.end_with?('xml') or
                ['application/json', 'application/javascript', 'application/ecmascript', 'application/xml-dtd'].include?(media_type)
              return raw_content
            end
            # CharDet.detect doesn't raise Encoding::CompatibilityError
            # that is caused when trying compare CharDet's internal
            # ASCII-8BIT RegExp with a String with other encoding
            # because Zip::File#read returns a String with encoding ASCII-8BIT.
            # So, no need to rescue the error here.
            encoding = CharDet.detect(raw_content)['encoding']
            if encoding
              raw_content.force_encoding(encoding)
            else
              warn "No encoding detected for #{entry_name}. Set to ASCII-8BIT" if $DEBUG || $VERBOSE
              raw_content
            end
          end

          def xhtml?
            media_type == 'application/xhtml+xml'
          end

          def image?
            EPUB3::MediaType::IMAGE.include?(media_type)
          end

          def application?
            EPUB3::MediaType::APPLICATION.include?(media_type)
          end

          def text?
            EPUB3::MediaType::TEXT.include?(media_type)
          end

          def js?
            'text/javascript' == media_type
          end

          def css?
            'text/css' == media_type
          end

          def font?
            EPUB3::MediaType::FONT.include?(media_type)
          end

          alias javascript? js?
          alias stylesheet? css?

          def audio?
            EPUB3::MediaType::AUDIO.include?(media_type)
          end

          def nav?
            properties.include? 'nav'
          end

          def cover_image?
            properties.include? 'cover-image'
          end

          # @todo Handle circular fallback chain
          def use_fallback_chain(options = {})
            supported = EPUB3::MediaType::CORE
            if ad = options[:supported]
              supported = supported | (ad.respond_to?(:to_ary) ? ad : [ad])
            end
            if del = options[:unsupported]
              supported = supported - (del.respond_to?(:to_ary) ? del : [del])
            end

            return yield self if supported.include? media_type
            if (bindings = manifest.package.bindings) && (binding_media_type = bindings[media_type])
              return yield binding_media_type.handler
            end
            return fallback.use_fallback_chain(options) {|fb| yield fb} if fallback
            raise EPUB3::MediaType::UnsupportedMediaType
          end

          def content_document
            return nil unless %w[application/xhtml+xml image/svg+xml].include? media_type
            @content_document ||= Parser::ContentDocument.new(self).parse
          end

          # @return [Package::Spine::Itemref]
          # @return nil when no Itemref refers this Item
          def itemref
            manifest.package.spine.itemrefs.find {|itemref| itemref.idref == id}
          end

          # @param iri [Addressable::URI] relative iri
          # @return [Item]
          # @return [nil] when item not found
          # @raise ArgumentError when +iri+ is not relative
          # @raise ArgumentError when +iri+ starts with "/"(slash)
          # @note Algorithm stolen form Rack::Utils#clean_path_info
          def find_item_by_relative_iri(iri)
            raise ArgumentError, "Not relative: #{iri.inspect}" unless iri.relative?
            raise ArgumentError, "Start with slash: #{iri.inspect}" if iri.to_s.start_with? Addressable::URI::SLASH
            target_href = href + iri
            segments = target_href.to_s.split(Addressable::URI::SLASH)
            clean_segments = []
            segments.each do |segment|
              next if segment.empty? || segment == '.'
              segment == '..' ? clean_segments.pop : clean_segments << segment
            end
            target_iri = Addressable::URI.parse(clean_segments.join(Addressable::URI::SLASH))
            manifest.items.find { |item| item.href == target_iri}
          end

          def inspect
            "#<%{class}:%{object_id} %{manifest} %{attributes}>" % {
              :class      => self.class,
              :object_id  => inspect_object_id,
              :manifest   => "@manifest=#{@manifest.inspect_simply}",
              :attributes => inspect_instance_variables(exclude: [:@manifest])
            }
          end

          protected

          def traverse_fallback_chain(chain)
            chain << self
            return chain unless fallback
            fallback.traverse_fallback_chain(chain)
          end
        end
      end
    end
  end
end
