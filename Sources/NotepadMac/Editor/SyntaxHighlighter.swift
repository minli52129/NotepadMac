import AppKit

/// 基于正则的轻量语法高亮器
enum SyntaxHighlighter {
    static let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static func baseAttributes() -> [NSAttributedString.Key: Any] {
        return [.font: baseFont, .foregroundColor: NSColor.textColor]
    }

    static func highlight(_ storage: NSTextStorage, language: Language) {
        let text = storage.string
        let full = NSRange(location: 0, length: (text as NSString).length)

        storage.beginEditing()
        storage.setAttributes(baseAttributes(), range: full)

        if language != .plainText, full.length > 0 {
            // 顺序：注释 → 字符串 → 数字 → 关键字（后者仅在未着色区域生效）
            if let comments = language.commentPattern {
                apply(comments, color: .systemGreen, to: storage, in: text, range: full)
            }
            apply(language.stringPattern, color: .systemOrange, to: storage, in: text, range: full)
            apply(Language.numberPattern, color: .systemBlue, to: storage, in: text, range: full, skipColored: true)
            if let keywords = language.keywordPattern {
                apply(keywords, color: .systemPurple, to: storage, in: text, range: full, skipColored: true)
            }
        }

        storage.endEditing()
    }

    private static func apply(_ pattern: String,
                              color: NSColor,
                              to storage: NSTextStorage,
                              in text: String,
                              range: NSRange,
                              skipColored: Bool = false) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let matchRange = match?.range, matchRange.length > 0 else { return }
            if skipColored,
               let existing = storage.attribute(.foregroundColor, at: matchRange.location, effectiveRange: nil) as? NSColor,
               !existing.isEqual(to: NSColor.textColor) {
                return
            }
            storage.addAttribute(.foregroundColor, value: color, range: matchRange)
        }
    }
}
