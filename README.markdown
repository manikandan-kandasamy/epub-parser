EPUB Parser
===========
[![Build Status](https://secure.travis-ci.org/KitaitiMakoto/epub-parser.png?branch=master)](http://travis-ci.org/KitaitiMakoto/epub-parser)
[![Dependency Status](https://gemnasium.com/KitaitiMakoto/epub-parser.png)](https://gemnasium.com/KitaitiMakoto/epub-parser)
[![Gem Version](https://badge.fury.io/rb/epub-parser.svg)](http://badge.fury.io/rb/epub-parser)

INSTALLATION
-------

    gem install epub-parser

USAGE
-----

### As a library

    require 'epub3/parser'
    
    book = EPUB3::Parser.parse('book.epub')
    book.metadata.titles # => Array of EPUB3::Publication::Package::Metadata::Title. Main title, subtitle, etc...
    book.metadata.title # => Title string including all titles
    book.metadata.creators # => Creators(authors)
    book.each_page_on_spine do |page|
      page.media_type # => "application/xhtml+xml"
      page.entry_name # => "OPS/nav.xhtml" entry name in EPUB package(zip archive)
      page.read # => raw content document
      page.content_document.nokogiri # => Nokogiri::XML::Document. The same to Nokogiri.XML(page.read)
      # do something more
      #    :
    end

See document's {file:docs/Home.markdown} or [API Documentation][rubydoc] for more info.

[rubydoc]: http://rubydoc.info/gems/epub-parser

### `epubinfo` command-line tool

`epubinfo` tool extracts and shows the metadata of specified EPUB book.

    $ epubinfo ~/Documebts/Books/build_awesome_command_line_applications_in_ruby.epub
    Title:              Build Awesome Command-Line Applications in Ruby (for KITAITI MAKOTO)
    Identifiers:        978-1-934356-91-3
    Titles:             Build Awesome Command-Line Applications in Ruby (for KITAITI MAKOTO)
    Languages:          en
    Contributors:       
    Coverages:          
    Creators:           David Bryant Copeland
    Dates:              
    Descriptions:       
    Formats:            
    Publishers:         The Pragmatic Bookshelf, LLC (338304)
    Relations:          
    Rights:             Copyright © 2012 Pragmatic Programmers, LLC
    Sources:            
    Subjects:           Pragmatic Bookshelf
    Types:              
    Unique identifier:  978-1-934356-91-3
    Epub version:       2.0

See {file:docs/Epubinfo} for more info.

### `epub-open` command-line tool

`epub-open` tool provides interactive shell(IRB) which helps you research about EPUB book.

    epub-open path/to/book.epub

IRB starts. `self` becomes the EPUB book and can access to methods of `EPUB`.

    title
    => "Title of the book"
    metadata.creators
    => [Author 1, Author2, ...]
    resources.first.properties
    => #<Set: {"nav"}> # You know that first resource of this book is nav document
    nav = resources.first
    => ...
    nav.href
    => #<Addressable::URI:0x15ce350 URI:nav.xhtml>
    nav.media_type
    => "application/xhtml+xml"
    puts nav.read
    <?xml version="1.0"?>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
        :
        :
        :
    </html>
    => nil
    exit # Enter "exit" when exit the session

See {file:docs/EpubOpen} for more info.

DOCUMENTATION
-------------

Documentation is available in [homepage][].

If you installed EPUB Parser by gem command, you can also generate documentaiton by your own([rubygems-yardoc][] gem is needed):

    $ gem install epub-parser
    $ gem yardoc epub-parser
    ...
    Files:          33
    Modules:        20 (   20 undocumented)
    Classes:        45 (   44 undocumented)
    Constants:      31 (   31 undocumented)
    Methods:       292 (   88 undocumented)
    52.84% documented
    YARD documentation is generated to:
    /path/to/gempath/ruby/2.2.0/doc/epub-parser-0.2.0/yardoc

It will show you path to generated documentation(`/path/to/gempath/ruby/2.2.0/doc/epub-parser-0.2.0/yardoc` here) at the end.

Or, generating by yardoc command is possible, too:

    $ git clone https://github.com/KitaitiMakoto/epub-parser.git
    $ cd epub-parser
    $ bundle install --path=deps
    $ bundle exec rake doc:yard
    ...
    Files:          33
    Modules:        20 (   20 undocumented)
    Classes:        45 (   44 undocumented)
    Constants:      31 (   31 undocumented)
    Methods:       292 (   88 undocumented)
    52.84% documented

Then documentation will be available in `doc` directory.

[homepage]: http://www.rubydoc.info/gems/epub-parser/file/docs/Home.markdown
[rubygems-yardoc]: https://rubygems.org/gems/rubygems-yardoc

REQUIREMENTS
------------
* Ruby 2.0.0 or later
* `patch` command to install Nokogiri
* C compiler to compile Zip/Ruby and Nokogiri

Related Gems
------------
* [gepub](https://github.com/skoji/gepub) - a generic EPUB library for Ruby
* [epubinfo](https://github.com/chdorner/epubinfo) - Extracts metadata information from EPUB files. Supports EPUB2 and EPUB3 formats.
* [ReVIEW](https://github.com/kmuto/review) - ReVIEW is a easy-to-use digital publishing system for books and ebooks.
* [epzip](https://github.com/takahashim/epzip) - epzip is EPUB packing tool. It's just only doing 'zip.' :)
* [eeepub](https://github.com/jugyo/eeepub) - EeePub is a Ruby ePub generator
* [epub-maker](https://github.com/KitaitiMakoto/epub-maker) - This library supports making and editing EPUB books based on this EPUB Parser library

If you find other gems, please tell me or request a pull request.

RECENT CHANGES
--------------

### 0.2.3

* Change the name of physical container adapter for file system: :File -> :UnpackedDirectory
* Add `EPUB3::Publication::Package::Manifest::Item#full_path`
* Make #href= acceptable String

### 0.2.2

* [BUGFIX]Item#entry_name returns normalized IRI

### 0.2.1

* Remove deprecated `EPUB3::Constants::MediaType::UnsupportedError`. Use `UnsupportedMediatType` instead.
* Make it possible to use [archive-zip][] gem to extract contents from EPUB package
* Add warning about default physical container adapter change
* Make it possible to extract contents from the web via `EPUB3::OCF::PhysicalContainer::UnpackedURI` See {file:ExtractContentsFromWeb.markdown} for details.

[archive-zip]: https://github.com/javanthropus/archive-zip

### 0.2.0

* Make it possible to parse file system directory as an EPUB file. See {file:docs/UnpackedArchive.markdown} for details.

### 0.1.9

* Introduce [Nokogumbo][] for XHTML Content Documents
* Stop support for Ruby 1.9
* Remove `EPUB.included` method. Now including `EPUB` module empowers nothing of EPUB features. Include `EPUB3::Book::Features` instead.
* Add `EPUB3::Searcher::XHTML::Seamless` and make it default searcher
* Add `EPUB3::Publication::Package::Manifest#each_nav`

[nokogumbo]: https://github.com/rubys/nokogumbo/

See {file:CHANGELOG.markdown} for older changelogs and details.

TODOS
-----
* EPUB 3.0.1
* Multiple rootfiles
* Help features for `epub-open` tool
* Vocabulary Association Mechanisms
* Implementing navigation document and so on
* Media Overlays
* Content Document
* Digital Signature
* Using SAX on parsing
* Abstraction of XML parser(making it possible to use REXML, standard bundled XML library of Ruby)
* Handle with encodings other than UTF-8

DONE
----
* Simple inspect for `epub-open` tool
* Using zip library instead of `unzip` command, which has security issue
* Modify methods around fallback to see `bindings` element in the package
* Content Document(only for Navigation Documents)
* Fixed Layout
* Vocabulary Association Mechanisms(only for itemref)
* Archive library abstraction
* Extracting and organizing common behavior from some classes to modules

LICENSE
-------
This library is distribuetd under the term of the MIT License.
See MIT-LICENSE file for more info.