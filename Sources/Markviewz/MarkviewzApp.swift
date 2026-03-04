import SwiftUI

@main
struct MarkviewzApp: App {
    @State private var initialFile: URL? = Self.fileFromArgs()

    var body: some Scene {
        WindowGroup {
            ContentView(initialFile: initialFile)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }

    private static func fileFromArgs() -> URL? {
        let args = CommandLine.arguments
        guard args.count > 1 else { return nil }
        let path = args[1]
        let url = URL(fileURLWithPath: (path as NSString).standardizingPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }
}
