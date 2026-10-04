import AppKit

/// 编辑器左侧的行号栏
final class LineNumberRulerView: NSRulerView {
    private let lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)

    init(scrollView: NSScrollView, textView: NSTextView) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 40
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              textView.window != nil else { return }

        NSColor.controlBackgroundColor.setFill()
        rect.fill()

        // 右侧分隔线
        NSColor.separatorColor.setFill()
        NSRect(x: ruleThickness - 1, y: rect.minY, width: 1, height: rect.height).fill()

        let text = textView.string as NSString
        let relativePoint = convert(NSPoint.zero, from: textView)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: lineNumberFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        func drawNumber(_ number: Int, glyphRect: NSRect) {
            let string = "\(number)" as NSString
            let size = string.size(withAttributes: attributes)
            let y = glyphRect.minY + relativePoint.y + textView.textContainerInset.height
                    + (glyphRect.height - size.height) / 2
            string.draw(at: NSPoint(x: ruleThickness - size.width - 5, y: y),
                        withAttributes: attributes)
        }

        guard text.length > 0 else {
            let lineHeight = layoutManager.defaultLineHeight(
                for: textView.font ?? NSFont.systemFont(ofSize: 13))
            drawNumber(1, glyphRect: NSRect(x: 0, y: 0, width: 0, height: lineHeight))
            return
        }

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange,
                                                          actualGlyphRange: nil)

        // 统计可见区域之前的行数
        var lineNumber = 1
        var index = 0
        while index < characterRange.location {
            index = NSMaxRange(text.lineRange(for: NSRange(location: index, length: 0)))
            lineNumber += 1
        }

        // 绘制可见区域的行号
        index = characterRange.location
        while index < NSMaxRange(characterRange) {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange,
                                                          actualCharacterRange: nil)
            let lineRect = layoutManager.boundingRect(forGlyphRange: lineGlyphRange,
                                                      in: textContainer)
            drawNumber(lineNumber, glyphRect: lineRect)
            lineNumber += 1
            index = NSMaxRange(lineRange)
        }

        // 文本以换行符结尾时，为末尾空行补一个行号
        if index >= text.length {
            let lastChar = text.character(at: text.length - 1)
            if lastChar == 0x0A || lastChar == 0x0D {
                var extraRect = layoutManager.extraLineFragmentRect
                if extraRect == .zero {
                    let lineHeight = layoutManager.defaultLineHeight(
                        for: textView.font ?? NSFont.systemFont(ofSize: 13))
                    extraRect = NSRect(x: 0, y: 0, width: 0, height: lineHeight)
                }
                drawNumber(lineNumber, glyphRect: extraRect)
            }
        }
    }
}
