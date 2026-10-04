import AppKit

/// 全局文档管理器：负责标签页、打开/保存、查找状态
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()

    @Published private(set) var documents: [TextDocument] = []
    @Published var selectedID: TextDocument.ID?

    // 查找栏状态（菜单与查找栏共享）
    @Published var findBarVisible = false
    @Published var replaceVisible = false
    @Published var findQuery = ""
    @Published var replaceQuery = ""
    @Published var caseSensitive = false

    /// 当前活动的编辑器（由 EditorView 注册）
    weak var activeEditor: EditorViewController?

    var current: TextDocument? {
        documents.first(where: { $0.id == selectedID })
    }

    private init() {
        newDocument()
    }

    // MARK: - 标签页

    func newDocument() {
        let doc = TextDocument()
        documents.append(doc)
        selectedID = doc.id
    }

    func selectNextTab() { shiftSelection(by: 1) }
    func selectPreviousTab() { shiftSelection(by: -1) }

    private func shiftSelection(by delta: Int) {
        guard !documents.isEmpty,
              let id = selectedID,
              let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let next = (index + delta + documents.count) % documents.count
        selectedID = documents[next].id
    }

    // MARK: - 打开

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            for url in panel.urls {
                self?.openDocument(url: url)
            }
        }
    }

    func openDocument(url: URL) {
        // 已打开的文件直接切换过去
        if let existing = documents.first(where: { $0.fileURL == url }) {
            selectedID = existing.id
            return
        }
        do {
            let doc = try TextDocument(url: url)
            documents.append(doc)
            selectedID = doc.id
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    // MARK: - 保存

    func saveCurrent() {
        if let doc = current { save(doc) }
    }

    func saveCurrentAs() {
        if let doc = current { saveAs(doc) }
    }

    func save(_ doc: TextDocument) {
        guard let url = doc.fileURL else {
            saveAs(doc)
            return
        }
        write(doc, to: url)
    }

    func saveAs(_ doc: TextDocument, completion: (() -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = doc.title
        panel.begin { [weak self, weak doc] response in
            guard response == .OK, let url = panel.url, let doc = doc else { return }
            doc.fileURL = url
            doc.language = Language.detect(url: url)
            self?.write(doc, to: url)
            self?.activeEditor?.applyHighlightNow()
            completion?()
        }
    }

    private func write(_ doc: TextDocument, to url: URL) {
        let string = doc.textStorage.string
        do {
            if let data = string.data(using: doc.encoding) {
                try data.write(to: url, options: .atomic)
            } else {
                // 原编码无法表示内容时回退 UTF-8
                try string.write(to: url, atomically: true, encoding: .utf8)
                doc.encoding = .utf8
            }
            doc.isModified = false
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    // MARK: - 关闭

    func closeCurrentTab() {
        if let doc = current { close(doc) }
    }

    func close(_ doc: TextDocument) {
        if doc.isModified {
            let alert = NSAlert()
            alert.messageText = "是否存储对“\(doc.title)”的更改？"
            alert.informativeText = "如果不存储，您的更改将丢失。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "存储")
            alert.addButton(withTitle: "不存储")
            alert.addButton(withTitle: "取消")
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                if doc.fileURL != nil {
                    save(doc)
                } else {
                    // 另存为完成后再关闭；取消则中止关闭
                    saveAs(doc) { [weak self] in self?.remove(doc) }
                    return
                }
            case .alertSecondButtonReturn:
                break // 不存储，直接关闭
            default:
                return // 取消
            }
        }
        remove(doc)
    }

    private func remove(_ doc: TextDocument) {
        guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        documents.remove(at: index)
        if selectedID == doc.id {
            selectedID = documents.isEmpty ? nil : documents[min(index, documents.count - 1)].id
        }
        if documents.isEmpty {
            newDocument()
        }
    }

    // MARK: - 查找

    func showFind(replace: Bool) {
        replaceVisible = replace
        findBarVisible = true
        // 有选中文本时自动填入查找框
        if let selected = activeEditor?.selectedText(),
           !selected.isEmpty, !selected.contains("\n") {
            findQuery = selected
        }
    }

    func dismissFindBar() {
        findBarVisible = false
        replaceVisible = false
        activeEditor?.clearMatchHighlights()
        activeEditor?.focusEditor()
    }

    func gotoLine() {
        let alert = NSAlert()
        alert.messageText = "跳转到行"
        alert.addButton(withTitle: "跳转")
        alert.addButton(withTitle: "取消")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.placeholderString = "行号"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        if alert.runModal() == .alertFirstButtonReturn, let line = Int(field.stringValue) {
            activeEditor?.gotoLine(line)
        }
    }

    // MARK: - 编码 / 换行符 / 语言

    func reopen(_ doc: TextDocument, encoding: String.Encoding) {
        guard let url = doc.fileURL else { return }
        if doc.isModified {
            let alert = NSAlert()
            alert.messageText = "以新编码重新打开将丢弃未存储的更改"
            alert.informativeText = "确定要继续吗？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "继续")
            alert.addButton(withTitle: "取消")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        do {
            let data = try Data(contentsOf: url)
            guard var text = String(data: data, encoding: encoding) else {
                throw CocoaError(.coderReadCorrupt)
            }
            if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
            doc.encoding = encoding
            doc.textStorage.setAttributedString(
                NSAttributedString(string: text, attributes: SyntaxHighlighter.baseAttributes()))
            doc.isModified = false
            doc.characterCount = text.count
            activeEditor?.applyHighlightNow()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func convertLineEndings(_ doc: TextDocument, to lineEnding: LineEnding) {
        let text = doc.textStorage.string
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let converted = lineEnding == .lf
            ? normalized
            : normalized.replacingOccurrences(of: "\n", with: lineEnding.rawValue)
        doc.lineEnding = lineEnding
        if converted != text {
            doc.textStorage.setAttributedString(
                NSAttributedString(string: converted, attributes: SyntaxHighlighter.baseAttributes()))
            doc.isModified = true
            doc.characterCount = converted.count
            activeEditor?.applyHighlightNow()
        }
    }

    func setLanguage(_ doc: TextDocument, _ language: Language) {
        doc.language = language
        activeEditor?.applyHighlightNow()
    }
}
