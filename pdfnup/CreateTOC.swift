import Quartz

extension Array {
    // https://stackoverflow.com/a/38156873/3854385
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

private extension PDFDocument {
    func addPage(_ page: PDFPage) {
        insert(page, at: pageCount)
    }
}

struct CreateTOC {
    var tocEntries: [TOCEntry]
    var topMargin: Int = 50;
    var rightMargin: Int = 50;
    var bottomMargin: Int = 50;
    var leftMargin: Int = 50;
    var lineHeight: Int = 20;
    var fontSize: Int = 13;
    var pageHeight: Int = 792;
    var pageWidth: Int = 612;
    
    func run() -> PDFDocument {
        let document = PDFDocument()
        let linksPerPage = Int((pageHeight - topMargin - bottomMargin) / lineHeight) - 2
        let tocPages = tocEntries.chunked(by: linksPerPage)
        var drawTitle = true;
        for tocPage in tocPages {
            document.addPage(TOCPage(tocEntries: tocPage, topMargin: topMargin, rightMargin: rightMargin, bottomMargin: bottomMargin, leftMargin: leftMargin, lineHeight: lineHeight, fontSize: fontSize, pageHeight: pageHeight, pageWidth: pageWidth, drawTitle: drawTitle))
            drawTitle = false;
        }
        
        return document;
    }
}

private class TOCPage: PDFPage {
    let tocEntries: [TOCEntry]
    let topMargin: Int;
    let rightMargin: Int;
    let bottomMargin: Int;
    let leftMargin: Int;
    let lineHeight: Int;
    let fontSize: Int;
    let pageHeight: Int;
    let pageWidth: Int;
    let drawTitle: Bool;
    
    init(tocEntries: [TOCEntry],
    topMargin: Int,
    rightMargin: Int,
    bottomMargin: Int,
    leftMargin: Int,
    lineHeight: Int,
    fontSize: Int,
    pageHeight: Int,
    pageWidth: Int,
    drawTitle: Bool) {
        self.tocEntries = tocEntries;
        self.topMargin = topMargin;
        self.leftMargin = leftMargin;
        self.rightMargin = rightMargin;
        self.bottomMargin = bottomMargin;
        self.fontSize = fontSize;
        self.lineHeight = lineHeight;
        self.pageHeight = pageHeight;
        self.pageWidth = pageWidth;
        self.drawTitle = drawTitle;
        super.init()
        setBounds(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), for: .mediaBox)
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
        let paragraphStyleCenter = NSMutableParagraphStyle()
        paragraphStyleCenter.alignment = .center

        let attributesTitle: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle:  paragraphStyleCenter,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: CGFloat(Float(fontSize) * 1.5))
        ]
        
        let paragraphStyleRight = NSMutableParagraphStyle()
        paragraphStyleRight.alignment = .right

        let attributesRight: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle:  paragraphStyleRight,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: CGFloat(fontSize))
        ]
        

        let paragraphStyleLeft = NSMutableParagraphStyle()
        paragraphStyleLeft.alignment = .left

        let attributesLeft: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle:  paragraphStyleLeft,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: CGFloat(fontSize))
        ]

        var yPos = pageHeight - topMargin - lineHeight;
        let pageNumberWidth = 25;
        let tocWidth = pageWidth - pageNumberWidth - leftMargin - rightMargin;
        let titleX = leftMargin;
        let pageX = pageWidth - rightMargin - pageNumberWidth;
        
        if (drawTitle) {
            yPos = pageHeight - topMargin - lineHeight * 2;
            let titleString = NSAttributedString(string: "Table of Contents", attributes: attributesTitle)
            let titleRect = CGRect(x: titleX, y: yPos, width: pageWidth - leftMargin - rightMargin, height: lineHeight * 2)
            drawIn(rect: titleRect, attribString: titleString, context: context)
            yPos -= lineHeight;
        }
        
        for tocEntry in tocEntries {
            let titleString = NSAttributedString(string: tocEntry.title, attributes: attributesLeft)
            let numberString = NSAttributedString(string: String(tocEntry.startingPage), attributes: attributesRight)
            let titleRect = CGRect(x: titleX, y: yPos, width: tocWidth, height: lineHeight)
            let pageRect = CGRect(x: pageX, y: yPos, width: pageNumberWidth, height: lineHeight)
            let fullRect = CGRect(x: titleX, y: yPos, width: tocWidth + pageNumberWidth, height: lineHeight)
            drawIn(rect: titleRect, attribString: titleString, context: context)
            drawIn(rect: pageRect, attribString: numberString, context: context)
            yPos -= lineHeight
            let link = PDFAnnotation(bounds: fullRect, forType: .link, withProperties: nil)
            link.destination = PDFDestination(page: tocEntry.page, at: CGPoint(x: kPDFDestinationUnspecifiedValue, y: kPDFDestinationUnspecifiedValue))
            self.addAnnotation(link)
        }
    }

}
