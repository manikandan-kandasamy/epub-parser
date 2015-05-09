{file:docs/Home.markdown} > **{file:docs/Publication.markdow}**

Publication(Information about EPUB book)
========================================

EPUB Publications is information about EPUB books.

EPUB Parser represents it as {EPUB3::Publication} module and classes under the namespace and you can access them such like `EPUB3::Parser.parse("path/to/book.epub").package`

Let

    book = EPUB3::Parser.parse("path/to/book.epub")

for continuing.

Five Models
-----------

`book.package` is a package document, a root of information tree about the book, and it has attributes to access five major models of the publication; {EPUB3::Publication::Package::Metadata Metadata}, {EPUB3::Publication::Package::Manifest Manifest}, {EPUB3::Publication::Package::Spine Spine}, {EPUB3::Publication::Package::Guide Guide} and {EPUB3::Publication::Package::Bindings Bindings}.

Each of them has information the book in the way its own.

Metadata
--------

{EPUB3::Publication::Package::Metadata Metadata} is literally metadata of the book, including identifiers, titles, languages, links and so on.

You can access them by:

    md = book.package.metadata # => EPUB3::Publication::Package::Metadata
    md.titles # => [#<EPUB3::Publication::Package::Metadata::Title...>, #<EPUB3::Publication::Package::Metadata::Title...>, ...]
    # ...

Manifest
--------

Spine
-----

Guide
-----

Bindings
--------

Package
-------

References
----------

* [EPUB Publications 3.0][publications] on IDPF site

[publications]: http://www.idpf.org/epub/30/spec/epub30-publications.html
