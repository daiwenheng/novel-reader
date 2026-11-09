import SwiftUI
import UniformTypeIdentifiers

struct BookshelfView: View {
    @EnvironmentObject private var library: BookLibrary
    @State private var showImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Group {
                if library.books.isEmpty {
                    ContentUnavailableView(
                        "还没有书",
                        systemImage: "books.vertical",
                        description: Text("点右上角导入 TXT 或 EPUB")
                    )
                } else {
                    List {
                        ForEach(library.books) { book in
                            NavigationLink {
                                BookDetailRouter(book: book)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: book.format == .txt ? "doc.text" : "book")
                                        .foregroundStyle(.tint)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title)
                                            .font(.headline)
                                        Text(book.format == .txt ? "TXT" : "EPUB")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                library.delete(library.books[i])
                            }
                        }
                    }
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("导入书籍")
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [
                    UTType(filenameExtension: "txt") ?? .plainText,
                    UTType(filenameExtension: "epub") ?? .data
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        try library.importFile(from: url)
                    } catch {
                        importError = error.localizedDescription
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
            .alert("导入失败", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("好", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }
}

struct BookDetailRouter: View {
    @EnvironmentObject private var library: BookLibrary
    let book: Book

    var body: some View {
        Group {
            switch book.format {
            case .txt:
                TXTReaderView(book: book)
            case .epub:
                EPUBReaderView(book: book)
            }
        }
        .onAppear { library.markOpened(book) }
    }
}
