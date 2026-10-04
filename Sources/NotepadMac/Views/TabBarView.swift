import SwiftUI
import AppKit

struct TabBarView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(store.documents) { document in
                    TabItemView(document: document,
                                isSelected: document.id == store.selectedID)
                        .onTapGesture { store.selectedID = document.id }
                }
                Button { store.newDocument() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("新建标签页")
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 34)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItemView: View {
    @ObservedObject var document: TextDocument
    let isSelected: Bool
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: document.language.iconName)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(document.displayTitle)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: 160)
            Button { store.close(document) } label: {
                Image(systemName: document.isModified ? "circle.fill" : "xmark")
                    .font(.system(size: 8))
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isSelected
                    ? Color(nsColor: .controlBackgroundColor)
                    : Color.clear)
        .cornerRadius(6)
        .contextMenu {
            Button("关闭") { store.close(document) }
            Button("关闭其他标签页") { closeOthers() }
            Divider()
            if document.fileURL != nil {
                Button("在访达中显示") {
                    if let url = document.fileURL {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }
        }
    }

    private func closeOthers() {
        for other in store.documents where other.id != document.id && !other.isModified {
            store.close(other)
        }
        store.selectedID = document.id
    }
}
