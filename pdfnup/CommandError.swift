import Foundation

enum CommandError: Swift.Error, CustomStringConvertible {
    case unknownCommand(String)
    case invalidArgument(key: String)
    case missingArgument(key: String)
    case couldNotOpenFile(URL, underlying: Error? = nil)
    case couldNotDecodeFile(URL, underlying: Error? = nil)
    case couldNotSaveFile(URL, underlying: Error? = nil)

    var description: String {
        switch self {
        case .unknownCommand(let command):
            return "I don't know what to do with \"\(command)\"."
        case .missingArgument(let key):
            return "Missing argument, needed \(key)"
        case .invalidArgument(let key):
            return "Invalid argument \(key)"
        case .couldNotDecodeFile(_, let underlying?):
            return String(describing: underlying)
        case .couldNotDecodeFile(let url, nil):
            return "Could not decode file at \(url.path)"
        case .couldNotOpenFile(_, let underlying?):
            return String(describing: underlying)
        case .couldNotOpenFile(let url, nil):
            return "Could not open file at \(url.path)"
        case .couldNotSaveFile(_, let underlying?):
            return String(describing: underlying)
        case .couldNotSaveFile(let url, nil):
            return "Could not write to file at \(url.path)"
        }
    }
}
