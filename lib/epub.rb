require 'method_decorators/deprecated'
require 'epub/inspector'
require 'epub/ocf'
require 'epub/publication'
require 'epub/content_document'

module EPUB
  modules = [:ocf, :package]
  attr_reader *modules
  attr_accessor :epub_file
  modules.each do |mod|
    define_method "#{mod}=" do |obj|
      instance_variable_set "@#{mod}", obj
      obj.book = self
    end
  end

  Publication::Package::CONTENT_MODELS.each do |model|
    define_method model do
      package.__send__(model)
    end
  end

  %w[ title main_title subtitle short_title collection_title edition_title extended_title description date unique_identifier ].each do |met|
    define_method met do
      metadata.__send__(met)
    end
  end

  %w[nav].each do |met|
    define_method met do
      manifest.__send__ met
    end
  end

  # @overload each_page_on_spine(&blk)
  #   iterate over items in order of spine when block given
  #   @yieldparam item [Publication::Package::Manifest::Item]
  # @overload each_page_on_spine
  #   @return [Enumerator] which iterates over {Publication::Package::Manifest::Item}s in order of spine when block not given
  def each_page_on_spine(&blk)
    enum = package.spine.items
    if block_given?
      enum.each &blk
    else
      enum
    end
  end

  def each_page_on_toc(&blk)
    raise NotImplementedError
  end

  # @overload each_content(&blk)
  #   iterate all items over when block given
  #   @yieldparam item [Publication::Package::Manifest::Item]
  # @overload each_content
  #   @return [Enumerator] which iterates over all {Publication::Package::Manifest::Item}s in EPUB package when block not given
  def each_content(&blk)
    enum = manifest.items
    if block_given?
      enum.each &blk
    else
      enum.to_enum
    end
  end

  def other_navigation
    raise NotImplementedError
  end

  # @return [Array<Publication::Package::Manifest::Item>] All {Publication::Package::Manifest::Item}s in EPUB package
  def resources
    manifest.items
  end

  # Syntax sugar
  def rootfile_path
    ocf.container.rootfile.full_path.to_s
  end

  # Syntax sugar
  def cover_image
    manifest.cover_image
  end

  def search(query)
    results = []
    each_page_on_spine.with_index do |page, index|
      begin
        html = page.read
      rescue => err
        $stderr.puts err
        next
      end
      results += search_from_html(query, html)
    end
    results
  end

  def search_from_html(query, html)
    document = CFI::SearchResult.new(query)
    parser = Nokogiri::XML::SAX::Parser.new(document)
    parser.parse(html)
    document.cfis
  end
end
