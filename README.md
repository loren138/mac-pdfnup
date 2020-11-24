# Mac PDFNUp

Mac Command Line Tool for PDFNUp Multiple Pages Per Sheet

Usage: `pdfnup --cover cover.pdf --output combined.pdf --details details.json`

The cover is optional.

Page numbers will be added in the upper right of each page.

Contributions are welcome to add additional functionality and options!

Downloadable binary available under releases: https://github.com/loren138/mac-pdfnup/releases

## Options

### Output

The file name to output to (ie `combined.pdf`)

### Cover

Optional, a file to append to the front as a cover.

This file will be appneded in `full` mode so it most be portrait letter.

If you include a cover, a table of contents will also be generated.

### Details

A JSON file giving the details of the combine action.

It should look like:

```json
[
    {"title":"1. Introduction","file":"/Users/other/Documents/01-Introduction.pdf","nup":"6"},
    {"title":"2. Setup","file":"/Users/other/Documents/02-Ottergram-Setup.pdf","nup":"6"},
    {"title":"3.1. Edit Stuff","file":"/Users/other/Documents/03-edit.pdf","nup":"full"}
]
```

- Title - the title for the Table of Contents (if you supply a cover) and the PDF outline
    (viewable in the sidebar of many pdf viewers)
- File - the full path to the PDF file for that chapter
- nup - Number Up
  - Full page will preserve links, but only accepts portrait letter pages.
  - 1 up will add a black border and inset the page but will make it fit.
  - 2 up adds an upper and lower (intended to fit two landscape slides per page)
  - 6 up adds a 2 x 3 grid (intended to fit 6 landscape slides per page)