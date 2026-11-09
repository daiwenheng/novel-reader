import SwiftUI
import WebKit

struct EPUBReaderView: View {
    @EnvironmentObject private var library: BookLibrary
    let book: Book

    @State private var document: EPUBDocument?
    @State private var chapterIndex = 0
    @State private var fontSize: Double = 18
    @State private var theme: ReaderTheme = .sepia
    @State private var loadError: String?

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView("无法打开 EPUB", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else if let document {
                EPUBWebView(
                    html: themedHTML(document.chapters[safe: chapterIndex]?.html ?? ""),
                    theme: theme
                )
            } else {
                ProgressView("解析中…")
            }
        }
        .navigationTitle(document?.chapters[safe: chapterIndex]?.title ?? book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let document, document.chapters.count > 1 {
                    Menu {
                        ForEach(Array(document.chapters.enumerated()), id: \.offset) { idx, chapter in
                            Button(chapter.title) {
                                chapterIndex = idx
                                library.updateProgress(ReadingProgress(bookID: book.id, chapterIndex: idx))
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
                Menu {
                    Stepper("字号 \(Int(fontSize))", value: $fontSize, in: 14...28, step: 1)
                    Picker("主题", selection: $theme) {
                        ForEach(ReaderTheme.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .task { await load() }
        .onChange(of: fontSize) { _, _ in }
        .onChange(of: theme) { _, _ in }
    }

    private func load() async {
        do {
            let doc = try EPUBParser.parse(fileURL: library.fileURL(for: book))
            document = doc
            if let p = library.progress[book.id] {
                chapterIndex = min(max(0, p.chapterIndex), max(0, doc.chapters.count - 1))
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func themedHTML(_ body: String) -> String {
        let bg: String
        let fg: String
        switch theme {
        case .light: bg = "#fafafa"; fg = "#111"
        case .sepia: bg = "#f5edd6"; fg = "#3b2f2f"
        case .dark: bg = "#141414"; fg = "#e8e8e8"
        }
        return """
        <html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <style>
        body { margin: 16px; font-size: \(Int(fontSize))px; line-height: 1.7; background: \(bg); color: \(fg); font-family: -apple-system, sans-serif; }
        img { max-width: 100%; height: auto; }
        a { color: inherit; }
        </style></head><body>\(body)</body></html>
        """
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct EPUBWebView: UIViewRepresentable {
    let html: String
    let theme: ReaderTheme

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
