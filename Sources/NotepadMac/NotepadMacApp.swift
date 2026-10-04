import SwiftUI
import AppKit

@main
struct NotepadMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DocumentStore.shared

    var body: some Scene {
        Window("NotepadMac", id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 640, minHeight: 400)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建") { store.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("打开…") { store.openDocument() }
                    .keyboardShortcut("o", modifiers: .command)
                Divider()
                Button("关闭标签页") { store.closeCurrentTab() }
                    .keyboardShortcut("w", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("存储") { store.saveCurrent() }
                    .keyboardShortcut("s", modifiers: .command)
                Button("另存为…") { store.saveCurrentAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandMenu("查找") {
                Button("查找…") { store.showFind(replace: false) }
                    .keyboardShortcut("f", modifiers: .command)
                Button("替换…") { store.showFind(replace: true) }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                Divider()
                Button("查找下一个") { store.activeEditor?.findNext() }
                    .keyboardShortcut("g", modifiers: .command)
                Button("查找上一个") { store.activeEditor?.findPrevious() }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                Divider()
                Button("跳转到行…") { store.gotoLine() }
                    .keyboardShortcut("l", modifiers: .command)
            }
            CommandMenu("标签页") {
                Button("下一个标签页") { store.selectNextTab() }
                    .keyboardShortcut(.tab, modifiers: [.control])
                Button("上一个标签页") { store.selectPreviousTab() }
                    .keyboardShortcut(.tab, modifiers: [.control, .shift])
            }
        }
    }
}
