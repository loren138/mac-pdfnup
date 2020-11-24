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

    var fileDetails: [FileDetail]
    do {
        let data = try Data(contentsOf: details, options: .mappedIfSafe)
        fileDetails = try JSONDecoder().decode([FileDetail].self, from: data)
    } catch {
        throw CommandError.couldNotDecodeFile(details)
    }

    let action = CombinePDFs(cover: cover, fileDetails: fileDetails, output: output)
    try action.run()

    exit(0)
} catch {
    fputs("error: \(error)\n\(help)\n", stderr)
    exit(1)
}
