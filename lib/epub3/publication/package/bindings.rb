module EPUB3
  module Publication
    class Package
      class Bindings
        include Inspector::PublicationModel
        attr_accessor :package

        def initialize
          @media_types = {}
        end

        def <<(media_type)
          @media_types[media_type.media_type] = media_type
        end

        def [](media_type)
          _, mt = @media_types.detect {|key, _| key == media_type}
          mt
        end

        def media_types
          @media_types.values
        end

        class MediaType
          attr_accessor :media_type, :handler
        end
      end
    end
  end
end
