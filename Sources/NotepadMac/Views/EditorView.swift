import SwiftUI

/// 将 AppKit 编辑器包装进 SwiftUI
struct EditorView: NSViewControllerRepresentable {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var store: DocumentStore

    func makeNSViewController(context: Context) -> EditorViewController {
        let controller = EditorViewController(document: document, store: store)
        DispatchQueue.main.async { store.activeEditor = controller }
        return controller
    }

    func updateNSViewController(_ controller: EditorViewController, context: Context) {
        if store.activeEditor !== controller {
            DispatchQueue.main.async { store.activeEditor = controller }
        }
    }
}
