import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // 通过 `swift run` 直接启动二进制时，确保应用以前台应用方式运行
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // 支持从访达「打开方式」/ 拖拽到 Dock 图标打开文件
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        DocumentStore.shared.openDocument(url: URL(fileURLWithPath: filename))
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for filename in filenames {
            DocumentStore.shared.openDocument(url: URL(fileURLWithPath: filename))
        }
        sender.reply(toOpenOrPrint: .success)
    }
}
