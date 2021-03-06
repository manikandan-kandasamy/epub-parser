{file:docs/Home.markdown} > **{file:docs/UnpackedArchive.markdown}**

Unpacked Archive
================

From version 0.2.0, EPUB Parser can parse EPUB books from unpacked archive, or file system directory.

Let's parse pretty comic Page Blanche:

    % tree page-blanche
    page-blanche
    ├── EPUB
    │   ├── Content
    │   │   ├── PageBlanche_Page_000.xhtml
    │   │   ├── PageBlanche_Page_001.xhtml
    │   │   ├── PageBlanche_Page_002.xhtml
    │   │   ├── PageBlanche_Page_003.xhtml
    │   │   ├── PageBlanche_Page_004.xhtml
    │   │   ├── PageBlanche_Page_005.xhtml
    │   │   ├── PageBlanche_Page_006.xhtml
    │   │   ├── PageBlanche_Page_007.xhtml
    │   │   ├── PageBlanche_Page_008.xhtml
    │   │   └── cover.xhtml
    │   ├── Image
    │   │   ├── PageBlanche_Page_001.jpg
    │   │   ├── PageBlanche_Page_002.jpg
    │   │   ├── PageBlanche_Page_003.jpg
    │   │   ├── PageBlanche_Page_004.jpg
    │   │   ├── PageBlanche_Page_005.jpg
    │   │   ├── PageBlanche_Page_006.jpg
    │   │   ├── PageBlanche_Page_007.jpg
    │   │   ├── PageBlanche_Page_008.jpg
    │   │   └── cover.jpg
    │   ├── Navigation
    │   │   ├── nav.xhtml
    │   │   └── toc.ncx
    │   ├── Style
    │   │   └── style.css
    │   └── package.opf
    ├── META-INF
    │   └── container.xml
    └── mimetype

To load EPUB books from directory, you need specify file adapter via {EPUB3::OCF::PhysicalContainer} at first:

    require 'epub3/parser'
    
    EPUB3::OCF::PhysicalContainer.adapter = :UnpackedDirectory

And then, directory path as EPUB path:

    epub = EPUB3::Parser.parse('./page-blanche')

Now you can handle the EPUB book as always.

    epub.title # => "Page Blache"
    epub.each_page_on_spine.to_a.length # => 10
    puts epub.nav.content_document.contents.map {|content| "#{File.basename(content.href.to_s)} ... #{content.text}"}
    # PageBlanche_Page_002.xhtml ... Dédicace
    # PageBlanche_Page_005.xhtml ... Commencer la lecture
    # => nil

If set {EPUB3::OCF::PhysicalContainer.adapter}, it is used every time EPUB Parser parses books even when it's packaged EPUB file. Instead of setting adapter globally, you can also specify adapter for parsing individually by passing keyword argument `container_adapter` to `.parse` method:

    # From packaged file
    File.ftype './page-blanche.epub' # => "file"
    archived_book = EPUB3::Parser.parse('./page-blanche.epub') # => EPUB3::Book
    # From directory
    File.ftype './page-blanche' # => "directory"
    unpacked_book = EPUB3::Parser.parse('./page-blanche', container_adapter: :UnpackedDirectory) # => EPUB3::Book

Command-line tools
------------------

Command-line tools `epubinfo` and `epub-open` may also handle with directory as EPUB books.

Executing `epubinfo`:

    $ epubinfo page-blanche
    Title:              Page Blanche
    Identifiers:        code.google.com.epub-samples.page-blanche
    Titles:             Page Blanche
    Languages:          fr
    Contributors:       Vincent Gros
    Coverages:          
    Creators:           Boulet, Bagieu Pénélope
    Dates:              2012-01-18
    Descriptions:       
    Formats:            
    Publishers:         éditions Delcourt
    Relations:          
    Rights:             This work is shared with the public using the Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license.
    Sources:            
    Subjects:           
    Types:              
    Unique identifier:  code.google.com.epub-samples.page-blanche
    Epub version:       3.0

Executing `epub-open`:

    $ epub-open page-blanche
    Enter "exit" to exit IRB
    irb: warn: can't alias bindings from irb_workspaces.
    irb(main):001:0> title
    => "Page Blanche"
    irb(main):002:0> exit

Note
----

Actually loading EPUB books from unpacked directory is not recommended. The reason why is it's too complex to handle with files properly because of character encoding of file names such as Unicode normalization matters like UTF-8 NFD, NFC, NFKD, NFKC and OS X-specific custom NFD, IRI normalization like percent-encoding, case sensitivity or so on. And, you know, this is not standardized way to load EPUB books. So, at least in the near future, there's not plan to support various environment.

Of course, always pathces are welcome.
