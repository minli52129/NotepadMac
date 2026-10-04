import AppKit

/// 单个文档的编辑器：NSTextView + 行号栏 + 语法高亮 + 查找替换
final class EditorViewController: NSViewController {
    let document: TextDocument
    weak var store: DocumentStore?

    private let layoutManager = NSLayoutManager()
    private var scrollView: NSScrollView?
    private var rulerView: LineNumberRulerView?
    private(set) var textView: NSTextView?
    private var highlightWorkItem: DispatchWorkItem?

    init(document: TextDocument, store: DocumentStore) {
        self.document = document
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        highlightWorkItem?.cancel()
        document.textStorage.removeLayoutManager(layoutManager)
    }

    override func loadView() {
        let container = NSView()

        // 手动组装 textStorage → layoutManager → textContainer → textView
        let textContainer = NSTextContainer(
            size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        document.textStorage.addLayoutManager(layoutManager)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.font = SyntaxHighlighter.baseFont
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.textContainerInset = NSSize(width: 5, height: 5)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.typingAttributes = SyntaxHighlighter.baseAttributes()
        textView.delegate = self

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let ruler = LineNumberRulerView(scrollView: scrollView, textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        self.textView = textView
        self.scrollView = scrollView
        self.rulerView = ruler
        self.view = container

        document.textStorage.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyHighlightNow()
        updateRuler()
        updateCursorInfo()
    }

    // MARK: - 语法高亮

    func applyHighlightNow() {
        highlightWorkItem?.cancel()
        SyntaxHighlighter.highlight(document.textStorage, language: document.language)
    }

    private func scheduleHighlight() {
        highlightWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            SyntaxHighlighter.highlight(self.document.textStorage,
                                        language: self.document.language)
        }
        highlightWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    // MARK: - 行号栏 / 光标信息

    private func updateRuler() {
        guard let ruler = rulerView, let textView = textView else { return }
        let lineCount = max(1, textView.string.components(separatedBy: "\n").count)
        let digits = max(2, String(lineCount).count)
        ruler.ruleThickness = CGFloat(digits) * 8 + 18
        ruler.needsDisplay = true
    }

    private func updateCursorInfo() {
        guard let textView = textView else { return }
        let text = textView.string as NSString
        let location = min(textView.selectedRange().location, text.length)
        var line = 1
        var lineStart = 0
        var index = 0
        while index < location {
            index = NSMaxRange(text.lineRange(for: NSRange(location: index, length: 0)))
            lineStart = index
            line += 1
        }
        document.cursorLine = line
        document.cursorColumn = location - lineStart + 1
    }

    func focusEditor() {
        view.window?.makeFirstResponder(textView)
    }

    // MARK: - 查找 / 替换

    func selectedText() -> String {
        guard let textView = textView else { return "" }
        let text = textView.string as NSString
        let range = textView.selectedRange()
        guard range.location != NSNotFound, range.length > 0,
              NSMaxRange(range) <= text.length else { return "" }
        return text.substring(with: range)
    }

    private var findOptions: NSString.CompareOptions {
        store?.caseSensitive == true ? [] : [.caseInsensitive]
    }

    func findNext() { find(forward: true) }
    func findPrevious() { find(forward: false) }

    private func find(forward: Bool) {
        guard let textView = textView,
              let query = store?.findQuery, !query.isEmpty else { return }
        let text = textView.string as NSString
        guard text.length > 0 else { return }

        let selection = textView.selectedRange()
        var options = findOptions
        let searchRange: NSRange
        if forward {
            let start = min(NSMaxRange(selection), text.length)
            searchRange = NSRange(location: start, length: text.length - start)
        } else {
            options.insert(.backwards)
            searchRange = NSRange(location: 0, length: min(selection.location, text.length))
        }

        var found = text.range(of: query, options: options, range: searchRange)
        if found.location == NSNotFound {
            // 回绕搜索
            found = text.range(of: query, options: options,
                               range: NSRange(location: 0, length: text.length))
        }
        if found.location != NSNotFound {
            textView.setSelectedRange(found)
            textView.scrollRangeToVisible(found)
            textView.showFindIndicator(for: found)
        } else {
            NSSound.beep()
        }
        highlightMatches()
    }

    func replaceNext() {
        guard let textView = textView, let store = store else { return }
        let selection = textView.selectedRange()
        if selection.location != NSNotFound, selection.length > 0 {
            let current = (textView.string as NSString).substring(with: selection)
            let matches = store.caseSensitive
                ? current == store.findQuery
                : current.caseInsensitiveCompare(store.findQuery) == .orderedSame
            if matches {
                if textView.shouldChangeText(in: selection,
                                             replacementString: store.replaceQuery) {
                    textView.textStorage?.replaceCharacters(in: selection,
                                                            with: store.replaceQuery)
                    textView.didChangeText()
                }
            }
        }
        findNext()
    }

    @discardableResult
    func replaceAll() -> Int {
        guard let textView = textView, let store = store, !store.findQuery.isEmpty else { return 0 }
        let mutable = NSMutableString(string: textView.string)
        let count = mutable.replaceOccurrences(of: store.findQuery,
                                               with: store.replaceQuery,
                                               options: findOptions,
                                               range: NSRange(location: 0, length: mutable.length))
        if count > 0 {
            let full = NSRange(location: 0, length: (textView.string as NSString).length)
            if textView.shouldChangeText(in: full, replacementString: mutable as String) {
                textView.textStorage?.replaceCharacters(in: full, with: mutable as String)
                textView.didChangeText()
            }
        }
        highlightMatches()
        return count
    }

    /// 高亮所有匹配项
    func highlightMatches() {
        guard let textView = textView, let layoutManager = textView.layoutManager else { return }
        let text = textView.string as NSString
        let full = NSRange(location: 0, length: text.length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)
        guard let query = store?.findQuery, !query.isEmpty, text.length > 0 else { return }

        let color = NSColor.systemYellow.withAlphaComponent(0.45)
        var searchStart = 0
        while searchStart < text.length {
            let range = text.range(of: query, options: findOptions,
                                   range: NSRange(location: searchStart,
                                                  length: text.length - searchStart))
            if range.location == NSNotFound { break }
            layoutManager.addTemporaryAttribute(.backgroundColor, value: color,
                                                forCharacterRange: range)
            searchStart = NSMaxRange(range)
        }
    }

    func clearMatchHighlights() {
        guard let textView = textView, let layoutManager = textView.layoutManager else { return }
        let full = NSRange(location: 0, length: (textView.string as NSString).length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)
    }

    // MARK: - 跳转

    func gotoLine(_ target: Int) {
        guard let textView = textView, target > 0 else { return }
        let text = textView.string as NSString
        var line = 1
        var index = 0
        while index < text.length, line < target {
            index = NSMaxRange(text.lineRange(for: NSRange(location: index, length: 0)))
            line += 1
        }
        let range = NSRange(location: index, length: 0)
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
        focusEditor()
        updateCursorInfo()
    }
}

// MARK: - NSTextStorageDelegate

extension EditorViewController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        document.isModified = true
        document.characterCount = textStorage.string.count
        scheduleHighlight()
        updateRuler()
    }
}

// MARK: - NSTextViewDelegate

extension EditorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        updateCursorInfo()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateCursorInfo()
        // 避免在高亮的关键字后继续输入时继承关键字颜色
        if let textView = notification.object as? NSTextView,
           textView.selectedRange().length == 0 {
            textView.typingAttributes = SyntaxHighlighter.baseAttributes()
        }
    }
}
