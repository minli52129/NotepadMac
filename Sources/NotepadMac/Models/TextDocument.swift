import AppKit
import CoreFoundation

/// 换行符类型
enum LineEnding: String, CaseIterable, Identifiable {
    case lf = "\n"
    case crlf = "\r\n"
    case cr = "\r"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lf: return "LF"
        case .crlf: return "CRLF"
        case .cr: return "CR"
        }
    }
}

/// 一个打开的文本文档（对应一个标签页）
final class TextDocument: ObservableObject, Identifiable {
    /// GB18030 编码（常见中文 Windows 文本文件）
    static let gb18030Encoding = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))

    let id = UUID()

    /// 文档内容，直接由 NSTextView 编辑
    let textStorage = NSTextStorage()

    @Published var fileURL: URL?
    @Published var isModified = false
    @Published var language: Language = .plainText
    @Published var encoding: String.Encoding = .utf8
    @Published var lineEnding: LineEnding = .lf
    @Published var cursorLine = 1
    @Published var cursorColumn = 1
    @Published var characterCount = 0

    var title: String {
        fileURL?.lastPathComponent ?? "未命名"
    }

    var displayTitle: String {
        isModified ? "\(title) ●" : title
    }

    var encodingName: String {
        switch encoding {
        case .utf8: return "UTF-8"
        case .isoLatin1: return "ISO-8859-1"
        default:
            if encoding == TextDocument.gb18030Encoding { return "GB18030" }
            return String.localizedName(of: encoding)
        }
    }

    /// 从磁盘加载文件，自动探测编码与换行符
    convenience init(url: URL) throws {
        self.init()
        let data = try Data(contentsOf: url)

        var encoding: String.Encoding = .utf8
        var string = String(data: data, encoding: .utf8)
        if string == nil {
            string = String(data: data, encoding: TextDocument.gb18030Encoding)
            encoding = TextDocument.gb18030Encoding
        }
        if string == nil {
            string = String(data: data, encoding: .isoLatin1)
            encoding = .isoLatin1
        }
        guard var text = string else {
            throw CocoaError(.coderReadCorrupt)
        }
        // 去除 UTF-8 BOM
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }

        self.encoding = encoding
        self.fileURL = url
        self.language = Language.detect(url: url)
        if text.contains("\r\n") {
            self.lineEnding = .crlf
        } else if text.contains("\r") {
            self.lineEnding = .cr
        } else {
            self.lineEnding = .lf
        }
        self.characterCount = text.count
        textStorage.setAttributedString(
            NSAttributedString(string: text, attributes: SyntaxHighlighter.baseAttributes()))
    }
}
