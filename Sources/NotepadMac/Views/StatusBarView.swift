import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        HStack(spacing: 16) {
            if let document = store.current {
                StatusContent(document: document)
            }
        }
        .font(.system(size: 11))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.bar)
    }
}

private struct StatusContent: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        Text("行 \(document.cursorLine)，列 \(document.cursorColumn)")
        Text("\(document.characterCount) 个字符")
        Spacer()
        Menu(document.language.rawValue) {
            ForEach(Language.allCases) { language in
                Button(language.rawValue) {
                    store.setLanguage(document, language)
                }
                .disabled(language == document.language)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()

        Menu(document.encodingName) {
            Button("UTF-8") { store.reopen(document, encoding: .utf8) }
            Button("GB18030") {
                store.reopen(document, encoding: TextDocument.gb18030Encoding)
            }
            Button("ISO-8859-1") { store.reopen(document, encoding: .isoLatin1) }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(document.fileURL == nil)

        Menu(document.lineEnding.displayName) {
            ForEach(LineEnding.allCases) { lineEnding in
                Button(lineEnding.displayName) {
                    store.convertLineEndings(document, to: lineEnding)
                }
                .disabled(lineEnding == document.lineEnding)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
