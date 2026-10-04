import Foundation

/// 支持的语法高亮语言
enum Language: String, CaseIterable, Identifiable {
    case plainText = "纯文本"
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case java = "Java"
    case c = "C"
    case cpp = "C++"
    case go = "Go"
    case rust = "Rust"
    case ruby = "Ruby"
    case shell = "Shell"
    case json = "JSON"
    case html = "HTML"
    case css = "CSS"
    case xml = "XML"
    case yaml = "YAML"
    case markdown = "Markdown"
    case sql = "SQL"

    var id: String { rawValue }

    static func detect(url: URL) -> Language {
        switch url.pathExtension.lowercased() {
        case "swift": return .swift
        case "py", "pyw": return .python
        case "js", "jsx", "mjs": return .javascript
        case "ts", "tsx": return .typescript
        case "java": return .java
        case "c", "h": return .c
        case "cpp", "cc", "cxx", "hpp", "m", "mm": return .cpp
        case "go": return .go
        case "rs": return .rust
        case "rb": return .ruby
        case "sh", "bash", "zsh": return .shell
        case "json": return .json
        case "html", "htm": return .html
        case "css": return .css
        case "xml", "plist", "svg": return .xml
        case "yml", "yaml": return .yaml
        case "md", "markdown": return .markdown
        case "sql": return .sql
        default: return .plainText
        }
    }

    var iconName: String {
        switch self {
        case .plainText: return "doc.plaintext"
        default: return "chevron.left.forwardslash.chevron.right"
        }
    }

    /// 注释正则
    var commentPattern: String? {
        switch self {
        case .swift, .javascript, .typescript, .java, .c, .cpp, .go, .rust, .css, .json:
            return #"//[^\n]*|/\*[\s\S]*?\*/"#
        case .python, .ruby, .shell, .yaml:
            return "#[^\\n]*"
        case .html, .xml, .markdown:
            return #"<!--[\s\S]*?-->"#
        case .sql:
            return "--[^\\n]*"
        case .plainText:
            return nil
        }
    }

    /// 字符串正则
    var stringPattern: String {
        switch self {
        case .python:
            return #"'''[\s\S]*?'''|"""[\s\S]*?"""|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*""#
        case .markdown:
            return "`[^`\\n]*`"
        case .plainText:
            return "(?!)"
        default:
            return #"'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*""#
        }
    }

    static let numberPattern = #"\b0[xX][0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#

    var keywordPattern: String? {
        guard !keywords.isEmpty else { return nil }
        return "\\b(?:" + keywords.joined(separator: "|") + ")\\b"
    }

    var keywords: [String] {
        switch self {
        case .swift:
            return ["class", "struct", "enum", "protocol", "extension", "func", "var", "let",
                    "if", "else", "switch", "case", "default", "return", "for", "while",
                    "repeat", "do", "catch", "throw", "throws", "try", "await", "async",
                    "guard", "defer", "import", "public", "private", "internal", "fileprivate",
                    "open", "static", "final", "override", "init", "deinit", "self", "Self",
                    "nil", "true", "false", "typealias", "where", "in", "is", "as", "super",
                    "some", "any", "mutating", "lazy", "weak", "unowned"]
        case .python:
            return ["and", "as", "assert", "async", "await", "break", "class", "continue",
                    "def", "del", "elif", "else", "except", "finally", "for", "from",
                    "global", "if", "import", "in", "is", "lambda", "nonlocal", "not", "or",
                    "pass", "raise", "return", "try", "while", "with", "yield",
                    "True", "False", "None", "self"]
        case .javascript:
            return ["async", "await", "break", "case", "catch", "class", "const", "continue",
                    "debugger", "default", "delete", "do", "else", "export", "extends",
                    "finally", "for", "from", "function", "if", "import", "in", "instanceof",
                    "let", "new", "of", "return", "static", "super", "switch", "this", "throw",
                    "try", "typeof", "var", "void", "while", "with", "yield",
                    "true", "false", "null", "undefined"]
        case .typescript:
            return Language.javascript.keywords +
                    ["interface", "type", "implements", "namespace", "declare", "readonly",
                     "enum", "abstract", "keyof"]
        case .java:
            return ["abstract", "boolean", "break", "byte", "case", "catch", "char", "class",
                    "continue", "default", "do", "double", "else", "enum", "extends", "final",
                    "finally", "float", "for", "if", "implements", "import", "instanceof",
                    "int", "interface", "long", "new", "package", "private", "protected",
                    "public", "return", "short", "static", "super", "switch", "this", "throw",
                    "throws", "try", "void", "while", "true", "false", "null"]
        case .c:
            return ["auto", "break", "case", "char", "const", "continue", "default", "do",
                    "double", "else", "enum", "extern", "float", "for", "goto", "if", "int",
                    "long", "register", "return", "short", "signed", "sizeof", "static",
                    "struct", "switch", "typedef", "union", "unsigned", "void", "volatile",
                    "while", "include", "define", "ifdef", "ifndef", "endif"]
        case .cpp:
            return Language.c.keywords +
                    ["class", "namespace", "template", "typename", "using", "new", "delete",
                     "this", "virtual", "override", "final", "public", "private", "protected",
                     "operator", "try", "catch", "throw", "noexcept", "constexpr", "nullptr",
                     "bool", "true", "false"]
        case .go:
            return ["break", "case", "chan", "const", "continue", "default", "defer", "else",
                    "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
                    "map", "package", "range", "return", "select", "struct", "switch", "type",
                    "var", "true", "false", "nil"]
        case .rust:
            return ["as", "async", "await", "break", "const", "continue", "crate", "dyn",
                    "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in", "let",
                    "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "self",
                    "Self", "static", "struct", "super", "trait", "true", "type", "unsafe",
                    "use", "where", "while"]
        case .ruby:
            return ["alias", "and", "begin", "break", "case", "class", "def", "defined", "do",
                    "else", "elsif", "end", "ensure", "false", "for", "if", "in", "module",
                    "next", "nil", "not", "or", "redo", "rescue", "retry", "return", "self",
                    "super", "then", "true", "undef", "unless", "until", "when", "while",
                    "yield"]
        case .shell:
            return ["if", "then", "else", "elif", "fi", "case", "esac", "for", "while",
                    "until", "do", "done", "in", "function", "select", "return", "break",
                    "continue", "local", "declare", "readonly", "export", "shift", "eval",
                    "exec", "exit", "set", "unset", "trap", "source", "alias", "echo"]
        case .json:
            return ["true", "false", "null"]
        case .html:
            return ["html", "head", "body", "div", "span", "a", "p", "h1", "h2", "h3", "h4",
                    "h5", "h6", "script", "style", "link", "meta", "title", "ul", "ol", "li",
                    "table", "tr", "td", "th", "form", "input", "button", "img", "br", "hr",
                    "section", "article", "header", "footer", "nav", "main", "aside"]
        case .css:
            return ["important", "media", "supports", "keyframes", "charset", "import",
                    "namespace", "root", "hover", "active", "focus", "before", "after"]
        case .yaml:
            return ["true", "false", "null", "yes", "no", "on", "off"]
        case .sql:
            return ["select", "from", "where", "insert", "into", "values", "update", "set",
                    "delete", "create", "table", "alter", "drop", "join", "left", "right",
                    "inner", "outer", "on", "group", "by", "order", "having", "limit",
                    "offset", "union", "all", "distinct", "as", "and", "or", "not", "null",
                    "primary", "key", "foreign", "references", "index", "view"]
        case .xml, .markdown, .plainText:
            return []
        }
    }
}
