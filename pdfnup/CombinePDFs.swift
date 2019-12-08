import Quartz
import AVKit

struct CombinePDFs {
    var inputs: [URL]
    var output: URL
    var nup: NupMode

    func run() throws {
        let document = PDFDocument()
        let outline = PDFOutline()
        document.outlineRoot = outline

        for input in inputs {
            guard let inner = PDFDocument(url: input) else {
                throw CommandError.couldNotOpenFile(input)
            }

            var titlePage: PDFPage?
            var index = 0
            while let nextSlide = inner.page(at: index) {
                switch nup {
                case .one:
                    titlePage = titlePage ?? nextSlide
                    document.addPage(nextSlide)
                    index += 1
                case .two:
                    let newPage = TwoUpPage(
                        top: nextSlide,
                        bottom: inner.page(at: index + 1)
                    )
                    titlePage = titlePage ?? newPage
                    document.addPage(newPage)
                    index += 2
                case .six:
                    let newPage = SixUpPage(
                        one: nextSlide,
                        two: inner.page(at: index + 1),
                        three: inner.page(at: index + 2),
                        four: inner.page(at: index + 3),
                        five: inner.page(at: index + 4),
                        six: inner.page(at: index + 5)
                    )
                    titlePage = titlePage ?? newPage
                    document.addPage(newPage)
                    index += 6
                }
                
            }
            outline.addLink(named: input.deletingPathExtension().lastPathComponent, to: titlePage)
        }

        if !document.write(to: output) {
            throw CommandError.couldNotSaveFile(output)
        }
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

    func draw(with box: PDFDisplayBox, in rect: CGRect, to context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        let bounds = self.bounds(for: box)
        let target = AVMakeRect(aspectRatio: bounds.size, insideRect: rect)

        context.setStrokeColor(gray: 0, alpha: 1)
        context.stroke(target, width: 1)
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
