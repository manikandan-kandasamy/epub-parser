require 'epub3/searcher/result'
require 'epub3/searcher/publication'
require 'epub3/searcher/xhtml'

module EPUB3
  module Searcher
    class << self
      def search(epub, word, **options)
        Publication.search(epub.package, word, options)
      end
    end
  end
end
