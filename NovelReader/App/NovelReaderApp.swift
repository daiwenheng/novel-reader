import SwiftUI

@main
struct NovelReaderApp: App {
    @StateObject private var library = BookLibrary()

    var body: some Scene {
        WindowGroup {
            BookshelfView()
                .environmentObject(library)
        }
    }
}
