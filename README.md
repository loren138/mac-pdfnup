# Mac PDFNUp

Mac Command Line Tool for PDFNUp Multiple Pages Per Sheet

Usage: `pdfnup --cover cover.pdf --output <out> --nup full/1/2/6 <filelist>`

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

### Number Up - NUP

- Full page will preserve links, but only accepts portrait letter pages.
- 1 up will add a black border and inset the page but will make it fit.
- 2 up adds an upper and lower (intended to fit two landscape slides per page)
- 6 up adds a 2 x 3 grid (intended to fit 6 landscape slides per page)

### File List

The files to be added.