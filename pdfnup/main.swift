import Foundation

let help = "Usage: pdfnup --output <out> --cover <file> --details <file.json>";

do {
    var arguments = CommandLine.arguments.dropFirst()
    guard let outputFlagIndex = arguments.firstIndex(where: { $0 == "-o" || $0 == "--output" }),
        let outputIndex = arguments.index(outputFlagIndex, offsetBy: 1, limitedBy: arguments.endIndex) else {
            throw CommandError.missingArgument(key: "output path")
    }
    let output = URL(fileURLWithPath: arguments[outputIndex])
    arguments.removeSubrange(outputFlagIndex ... outputIndex)
    
    var cover: URL?;
    if let coverFlagIndex = arguments.firstIndex(where: { $0 == "-c" || $0 == "--cover" }),
        let coverIndex = arguments.index(coverFlagIndex, offsetBy: 1, limitedBy: arguments.endIndex) {
        cover = URL(fileURLWithPath: arguments[coverIndex])
        arguments.removeSubrange(coverFlagIndex ... coverIndex)
    }
    
    guard let detailsFlagIndex = arguments.firstIndex(where: { $0 == "-d" || $0 == "--details" }),
        let detailsIndex = arguments.index(detailsFlagIndex, offsetBy: 1, limitedBy: arguments.endIndex) else {
            throw CommandError.missingArgument(key: "details path")
    }
    let details = URL(fileURLWithPath: arguments[detailsIndex])
    arguments.removeSubrange(detailsFlagIndex ... detailsIndex)
    
    let data = Data("""
    [
        {"title":"Introduction","file":"/Users/loren/Sites/pdfnup/01-Introduction.pdf","nup":"6"},
        {"title":"Ottergram Setup","file":"/Users/loren/Sites/pdfnup/02-Ottergram-Setup.pdf","nup":"6"},
        {"title":"Introduction","file":"/Users/loren/Sites/pdfnup/03-edit.pdf","nup":"full"},
    ]
    """.utf8)
    var fileDetails: [FileDetail]
    do {
        fileDetails = try JSONDecoder().decode([FileDetail].self, from: data)
    } catch {
        throw CommandError.couldNotDecodeFile(details)
    }
    
//    var nup = "2"
//    if let nupFlagIndex = arguments.firstIndex(where: { $0 == "-n" || $0 == "--nup" }),
//        let nupIndex = arguments.index(nupFlagIndex, offsetBy: 1, limitedBy: arguments.endIndex) {
//        nup = arguments[nupIndex]
//        arguments.removeSubrange(nupFlagIndex ... nupIndex)
//    }
//    guard let nupMode = NupMode(rawValue: nup) else {
//        throw CommandError.missingArgument(key: "nup mode can only be full, 1, 2, or 6")
//    }

//    let inputs = arguments.map(URL.init(fileURLWithPath:))
    let action = CombinePDFs(cover: cover, fileDetails: fileDetails, output: output)
    try action.run()

    exit(0)
} catch {
    fputs("error: \(error)\n\(help)\n", stderr)
    exit(1)
}
