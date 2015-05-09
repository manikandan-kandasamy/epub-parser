if RUBY_VERSION < "2.0.0"
  warn "Ruby version under the 2.0.0 is deprecated."
end

require 'epub3/inspector'
require 'epub3/ocf'
require 'epub3/publication'
require 'epub3/content_document'
require 'epub3/book/features'

module EPUB3
  class << self
    def included(base)
      warn 'Including EPUB module is deprecated. Include EPUB3::Book::Features instead.'
      base.__send__ :include, EPUB3::Book::Features
    end
  end
end
