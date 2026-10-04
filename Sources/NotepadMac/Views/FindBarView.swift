import SwiftUI

struct FindBarView: View {
    @EnvironmentObject var store: DocumentStore
    @FocusState private var focusedField: Field?

    private enum Field {
        case find, replace
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("查找", text: $store.findQuery)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200, maxWidth: 320)
                    .focused($focusedField, equals: .find)
                    .onSubmit { store.activeEditor?.findNext() }
                Toggle("区分大小写", isOn: $store.caseSensitive)
                    .toggleStyle(.checkbox)
                Button { store.activeEditor?.findPrevious() } label: {
                    Image(systemName: "chevron.up")
                }
                .help("查找上一个")
                Button { store.activeEditor?.findNext() } label: {
                    Image(systemName: "chevron.down")
                }
                .help("查找下一个")
                Button {
                    store.replaceVisible.toggle()
                } label: {
                    Image(systemName: store.replaceVisible
                          ? "chevron.up.square" : "chevron.down.square")
                }
                .help("替换")
                Spacer()
                Button("完成") { store.dismissFindBar() }
                    .keyboardShortcut(.escape, modifiers: [])
            }

            if store.replaceVisible {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                    TextField("替换为", text: $store.replaceQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 200, maxWidth: 320)
                        .focused($focusedField, equals: .replace)
                        .onSubmit { store.activeEditor?.replaceNext() }
                    Button("替换") { store.activeEditor?.replaceNext() }
                    Button("全部替换") { store.activeEditor?.replaceAll() }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.bar)
        .onAppear { focusedField = .find }
        .onChange(of: store.findQuery) { _ in
            store.activeEditor?.highlightMatches()
        }
        .onChange(of: store.caseSensitive) { _ in
            store.activeEditor?.highlightMatches()
        }
    }
}
