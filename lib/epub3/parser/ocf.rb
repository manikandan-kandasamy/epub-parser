require 'epub3/constants'
require 'epub3/ocf'
require 'epub3/ocf/physical_container'
require 'zipruby'
require 'nokogiri'

module EPUB3
  class Parser
    class OCF
      include Utils

      DIRECTORY = 'META-INF'

      class << self
        def parse(container)
          new(container).parse
        end
      end

      def initialize(container)
        @container = container
        @ocf = EPUB3::OCF.new
      end

      def parse
        EPUB3::OCF::MODULES.each do |m|
          begin
            data = @container.read(File.join(DIRECTORY, "#{m}.xml"))
            @ocf.__send__ "#{m}=", __send__("parse_#{m}", data)
          rescue ::Zip::Error, ::Errno::ENOENT, OpenURI::HTTPError
          end
        end

        @ocf
      end

      def parse_container(xml)
        container = EPUB3::OCF::Container.new
        doc = Nokogiri.XML(xml)
        doc.xpath('/ocf:container/ocf:rootfiles/ocf:rootfile', EPUB3::NAMESPACES).each do |elem|
          rootfile = EPUB3::OCF::Container::Rootfile.new
          rootfile.full_path = Addressable::URI.parse(extract_attribute(elem, 'full-path'))
          rootfile.media_type = extract_attribute(elem, 'media-type')
          container.rootfiles << rootfile
        end

        container
      end

      def parse_encryption(content)
        encryption = EPUB3::OCF::Encryption.new
        encryption.content = content
        encryption
      end

      def parse_manifest(content)
        warn "Not implemented: #{self.class}##{__method__}" if $VERBOSE
      end

      def parse_metadata(content)
        warn "Not implemented: #{self.class}##{__method__}" if $VERBOSE
      end

      def parse_rights(content)
        warn "Not implemented: #{self.class}##{__method__}" if $VERBOSE
      end

      def parse_signatures(content)
        warn "Not implemented: #{self.class}##{__method__}" if $VERBOSE
      end
    end
  end
end
