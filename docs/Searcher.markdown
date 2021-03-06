{file:docs/Home.markdown} > **{file:docs/Searcher.markdown}**

Searcher
========

*Searcher is experimental now. Note that all interfaces are not stable at all.*

Example
-------

    epub = EPUB3::Parser.parse('childrens-literature-20130206.epub')
    search_word = 'INTRODUCTORY'
    results = EPUB3::Searcher.search(epub, search_word)
    # => [#<EPUB3::Searcher::Result:0x007f938ed517a8
    #   @end_steps=[#<EPUB3::Searcher::Result::Step:0x007f938ed51a50 @index=12, @info={}, @type=:character>],
    #   @parent_steps=
    #    [#<EPUB3::Searcher::Result::Step:0x007f938f1c1e78 @index=2, @info={:name=>"spine", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938f1caa78 @index=1, @info={:id=>nil}, @type=:itemref>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed521d0 @index=1, @info={:name=>"body", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed52158 @index=0, @info={:name=>"nav", :id=>"toc"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed52108 @index=1, @info={:name=>"ol", :id=>"tocList"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed52090 @index=0, @info={:name=>"li", :id=>"np-313"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed52040 @index=1, @info={:name=>"ol", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed51ff0 @index=1, @info={:name=>"li", :id=>"np-317"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed51f78 @index=0, @info={:name=>"a", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed51f28 @index=0, @info={}, @type=:text>],
    #   @start_steps=[#<EPUB3::Searcher::Result::Step:0x007f938ed51e88 @index=0, @info={}, @type=:character>]>,
    #  #<EPUB3::Searcher::Result:0x007f938ef8f5d8
    #   @end_steps=[#<EPUB3::Searcher::Result::Step:0x007f938ef8f808 @index=12, @info={}, @type=:character>],
    #   @parent_steps=
    #    [#<EPUB3::Searcher::Result::Step:0x007f938f1c1e78 @index=2, @info={:name=>"spine", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ed51730 @index=2, @info={:id=>nil}, @type=:itemref>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ef8fce0 @index=1, @info={:name=>"body", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ef8fc90 @index=0, @info={:name=>"section", :id=>"pgepubid00492"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ef8fc40 @index=3, @info={:name=>"section", :id=>"pgepubid00498"}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ef8fbf0 @index=1, @info={:name=>"h3", :id=>nil}, @type=:element>,
    #     #<EPUB3::Searcher::Result::Step:0x007f938ef8fb28 @index=0, @info={}, @type=:text>],
    #   @start_steps=[#<EPUB3::Searcher::Result::Step:0x007f938ef8fa88 @index=0, @info={}, @type=:character>]>]
    puts results.collect(&:to_cfi_s)
    # /6/4!/4/2[toc]/4[tocList]/2[np-313]/4/4[np-317]/2/1,:0,:12
    # /6/6!/4/2[pgepubid00492]/8[pgepubid00498]/4/1,:0,:12
    # => nil

Search result
-------------

Search result is an array of {EPUB3::Searcher::Result} and it may be converted to an EPUBCFI string by {EPUB3::Searcher::Result#to_cfi_s}.

Seamless XHTML Searcher
-----------------------

Now default searcher for XHTML is *seamless* searcher, which ignores tags when searching.

You can search words 'search word' from XHTML document below:

    <html>
      <head>
        <title>Sample document</title>
      </head>
      <body>
        <p><em>search</em> word</p>
      </body>
    </html>

Restricted XHTML Searcher
-------------------------

You can also use *restricted* searcher, which means that it can search from only single elements. For instance, it can find 'search word' from XHTML document below:

    <html>
      <head>
        <title>Sample document</title>
      </head>
      <body>
        <p>search word</p>
      </body>
    </html>

But cannot from document below:

    <html>
      <head>
        <title>Sample document</title>
      </head>
      <body>
        <p><em>search</em> word</p>
      </body>
    </html>

because the words 'search' and 'word' are not in the same element.

To use restricted searcher, specify `algorithm` option for `search` method:

    results = EPUB3::Searcher.search(epub, search_word, algorithm: :restricted)
