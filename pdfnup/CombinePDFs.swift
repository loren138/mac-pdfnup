import Quartz
import AVKit

struct CombinePDFs {
    var cover: URL?
    var inputs: [URL]
    var output: URL
    var nup: NupMode

    func run() throws {
        let document = PDFDocument()
        let outline = PDFOutline()
        document.outlineRoot = outline
        var tocEntries = [TOCEntry]();

        for input in inputs {
            guard let inner = PDFDocument(url: input) else {
                throw CommandError.couldNotOpenFile(input)
            }

            var titlePage: PDFPage?
            var index = 0
            let startingPage = document.pageCount + 1
            while let nextSlide = inner.page(at: index) {
                var newPage: PDFPage?
                switch nup {
                case .full:
//                    newPage = FullPage(page: nextSlide)
                    newPage = nextSlide
                    index += 1
                case .one:
                    newPage = OneUpPage(page: nextSlide)
                    index += 1
                case .two:
                    newPage = TwoUpPage(
                        top: nextSlide,
                        bottom: inner.page(at: index + 1)
                    )
                    index += 2
                case .six:
                    newPage = SixUpPage(
                        one: nextSlide,
                        two: inner.page(at: index + 1),
                        three: inner.page(at: index + 2),
                        four: inner.page(at: index + 3),
                        five: inner.page(at: index + 4),
                        six: inner.page(at: index + 5)
                    )
                    index += 6
                }
                newPage = NumberedPage(page: newPage!, number: document.pageCount)
                titlePage = titlePage ?? newPage
                document.addPage(newPage!)
            }
            if let title = titlePage {
                tocEntries.append(TOCEntry(
                                    title: input.deletingPathExtension().lastPathComponent,
                                    page: title,
                                    startingPage: startingPage
                ))
            }
        }
        
        var frontPage = 0;
        if let coverUrl = cover {
            var index = 0
            var titlePage: PDFPage?
            
            guard let coverPdf = PDFDocument(url: coverUrl) else {
                throw CommandError.couldNotOpenFile(coverUrl)
            }
            while let nextSlide = coverPdf.page(at: index) {
                let newPage = nextSlide
                titlePage = titlePage ?? newPage
                document.insert(newPage, at: frontPage)
                index += 1
                frontPage += 1
            }
            outline.addLink(named: "Cover", to: titlePage)
        }
        
        if cover != nil {
            var index = 0
            var titlePage: PDFPage?
            
            let create = CreateTOC(tocEntries: tocEntries);
            let toc = create.run();
            while let nextSlide = toc.page(at: index) {
                titlePage = titlePage ?? nextSlide
                document.insert(nextSlide, at: frontPage)
                index += 1
                frontPage += 1
            }
            outline.addLink(named: "Table of Contents", to: titlePage)
        }
        
        for entry in tocEntries {
            outline.addLink(named: entry.title, to: entry.page)
        }

        if !document.write(to: output) {
            throw CommandError.couldNotSaveFile(output)
        }
    }

}


private class NumberedPage: PDFPage {
    
    let page: PDFPage
    let pageNumber: Int
    
    init(page: PDFPage, number: Int) {
        self.page = page;
        self.pageNumber = number
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
    }
    
    final private func drawIn(rect: CGRect, attribString: NSAttributedString, context: CGContext) {
        // https://stackoverflow.com/a/44215442/3854385
        context.saveGState()
        defer { context.restoreGState() }
        
        let framesetter = CTFramesetterCreateWithAttributedString(attribString)

        // left column form
        let leftColumnPath = CGMutablePath()
        leftColumnPath.addRect(CGRect(x:rect.origin.x,
                                      y: -rect.origin.y,
                                      width: rect.size.width,
                                      height: rect.size.height)
        )

        // left column frame
        let translateAmount = rect.size.height

        context.translateBy(x: 0, y: translateAmount)
        context.scaleBy(x: 1.0, y: -1.0)
        let leftFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), leftColumnPath, nil)
        let textTransform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        context.textMatrix = textTransform
        CTFrameDraw(leftFrame, context)
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        // Carry forward Links
        for annotation in page.annotations {
            self.addAnnotation(annotation)
        }
        // Draw original content
        page.draw(with: box, to: context)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right


        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle:  paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14)
        ]

        let attrString = NSAttributedString(string: String(pageNumber + 1),
                                       attributes: attributes)


        let rect = CGRect(x: 480, y: 730, width: 100, height: 100)
        drawIn(rect: rect, attribString: attrString, context: context)
    }

}

private class OneUpPage: PDFPage {

    let page: PDFPage

    init(page: PDFPage) {
        self.page = page
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        let rect = bounds(for: box).insetBy(dx: 36, dy: 27)
        page.draw(with: .cropBox, in: rect, to: context)
    }

}

private class FullPage: PDFPage {

    let page: PDFPage

    init(page: PDFPage) {
        self.page = page
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        let rect = bounds(for: box)
        page.draw(with: .cropBox, in: rect, to: context, drawOutline: false)
    }

}

private class TwoUpPage: PDFPage {

    let topPage: PDFPage
    let bottomPage: PDFPage?

    init(top topPage: PDFPage, bottom bottomPage: PDFPage?) {
        self.topPage = topPage
        self.bottomPage = bottomPage
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        let rect = bounds(for: box).insetBy(dx: 36, dy: 27)
        let (bottomRect, topRect) = rect.divided(atDistance: rect.height / 2, from: .minYEdge)
        topPage.draw(with: .cropBox, in: topRect, to: context)
        bottomPage?.draw(with: .cropBox, in: bottomRect, to: context)
    }

}

private class SixUpPage: PDFPage {

    let pageOne: PDFPage
    let pageTwo: PDFPage?
    let pageThree: PDFPage?
    let pageFour: PDFPage?
    let pageFive: PDFPage?
    let pageSix: PDFPage?

    init(one: PDFPage, two: PDFPage?, three: PDFPage?, four: PDFPage?, five: PDFPage?, six: PDFPage?) {
        self.pageOne = one
        self.pageTwo = two
        self.pageThree = three
        self.pageFour = four
        self.pageFive = five
        self.pageSix = six
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        let rect = bounds(for: box).insetBy(dx: 36, dy: 27)
        let (col1, col2) = rect.divided(atDistance: rect.width / 2, from: .minXEdge)
        let (rect1, rem1) = col1.divided(atDistance: rect.height / 3, from: .maxYEdge)
        let (rect3, rect5) = rem1.divided(atDistance: rect.height / 3, from: .maxYEdge)
        let (rect2, rem2) = col2.divided(atDistance: rect.height / 3, from: .maxYEdge)
        let (rect4, rect6) = rem2.divided(atDistance: rect.height / 3, from: .maxYEdge)
        pageOne.draw(with: .cropBox, in: rect1.insetBy(dx: 10, dy: 10), to: context)
        pageTwo?.draw(with: .cropBox, in: rect2.insetBy(dx: 10, dy: 10), to: context)
        pageThree?.draw(with: .cropBox, in: rect3.insetBy(dx: 10, dy: 10), to: context)
        pageFour?.draw(with: .cropBox, in: rect4.insetBy(dx: 10, dy: 10), to: context)
        pageFive?.draw(with: .cropBox, in: rect5.insetBy(dx: 10, dy: 10), to: context)
        pageSix?.draw(with: .cropBox, in: rect6.insetBy(dx: 10, dy: 10), to: context)
    }

}

private extension PDFDocument {
    func addPage(_ page: PDFPage) {
        insert(page, at: pageCount)
    }
}

private extension PDFPage {

    func draw(with box: PDFDisplayBox, in rect: CGRect, to context: CGContext, drawOutline: Bool = true) {
        context.saveGState()
        defer { context.restoreGState() }

        let bounds = self.bounds(for: box)
        let target = AVMakeRect(aspectRatio: bounds.size, insideRect: rect)

        if (drawOutline) {
            context.setStrokeColor(gray: 0, alpha: 1)
            context.stroke(target, width: 1)
        }
        context.translateBy(x: target.minX, y: target.minY)
        context.scaleBy(x: target.width / bounds.width, y: target.height / bounds.height)
        draw(with: box, to: context)
    }

}

private extension PDFOutline {

    func addLink(named label: String, to page: PDFPage?) {
        guard let page = page else { return }
        let child = PDFOutline()
        child.label = label
        child.destination = PDFDestination(page: page, at: CGPoint(x: kPDFDestinationUnspecifiedValue, y: kPDFDestinationUnspecifiedValue))
        insertChild(child, at: numberOfChildren)
    }

}
