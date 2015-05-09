module EPUB3
  class OCF
    MODULES = %w[container encryption manifest metadata rights signatures]
    MODULES.each {|m| require "epub3/ocf/#{m}"}

    attr_accessor :book, *MODULES
  end
end
