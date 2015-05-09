require 'epub3'
require 'epub3/constants'
require 'zipruby'
require 'nokogiri'

module EPUB3
  class Parser
    class << self
      # Parse an EPUB file
      # 
      # @example
      #   EPUB3::Parser.parse('path/to/book.epub') # => EPUB3::Book object
      # 
      # @example
      #   class MyBook
      #     include EPUB
      #   end
      #   book = MyBook.new
      #   parsed_book = EPUB3::Parser.parse('path/to/book.epub', :book => book) # => #<MyBook:0x000000019760e8 @epub_file=..>
      #   parsed_book.equal? book # => true
      # 
      # @example
      #   book = EPUB3::Parser.parse('path/to/book.epub', :class => MyBook) # => #<MyBook:0x000000019b0568 @epub_file=...>
      #   book.instance_of? MyBook # => true
      # 
      # @param [String] filepath
      # @param [Hash] options the type of return is specified by this argument.
      #   If no options, returns {EPUB3::Book} object.
      #   For details of options, see below.
      # @option options [EPUB] :book instance of class which includes {EPUB} module
      # @option options [Class] :class class which includes {EPUB} module
      # @return [EPUB] object which is an instance of class including {EPUB} module.
      #   When option :book passed, returns the same object whose attributes about EPUB are set.
      #   When option :class passed, returns the instance of the class.
      #   Otherwise returns {EPUB3::Book} object.
      def parse(filepath, options = {})
        new(filepath, options).parse
      end
    end

    def initialize(filepath, options = {})
      raise "File #{filepath} not readable" unless File.readable_real? filepath

      @filepath = File.realpath filepath
      @book = create_book options
      @book.epub_file = @filepath
    end

    def parse
      Zip::Archive.open @filepath do |zip|
        @book.ocf = OCF.parse(zip)
        @book.package = Publication.parse(zip, @book.ocf.container.rootfile.full_path.to_s)
      end

      @book
    end

    private

    def create_book(params)
      case
      when params[:book]
        params[:book]
      when params[:class]
        params[:class].new
      else
        require 'epub3/book'
        Book.new
      end
    end
  end
end

require 'epub3/parser/version'
require 'epub3/parser/utils'
require 'epub3/parser/ocf'
require 'epub3/parser/publication'
require 'epub3/parser/content_document'
