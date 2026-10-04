import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            TabBarView()
            Divider()
            if store.findBarVisible {
                FindBarView()
                Divider()
            }
            if let document = store.current {
                EditorView(document: document)
                    .id(document.id)
            } else {
                Text("没有打开的文件")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            StatusBarView()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            DocumentStore.shared.openDocument(url: url)
                        }
                    }
                }
            }
            return true
        }
    }
}
