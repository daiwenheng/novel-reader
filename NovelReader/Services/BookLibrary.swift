import Foundation
import Combine

@MainActor
final class BookLibrary: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published var progress: [UUID: ReadingProgress] = [:]

    private let fm = FileManager.default
    private var booksDir: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Books", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var catalogURL: URL { booksDir.appendingPathComponent("catalog.json") }
    private var progressURL: URL { booksDir.appendingPathComponent("progress.json") }

    init() {
        load()
    }

    func fileURL(for book: Book) -> URL {
        booksDir.appendingPathComponent(book.fileName)
    }

    func importFile(from url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        guard ext == "txt" || ext == "epub" else {
            throw NSError(domain: "NovelReader", code: 1, userInfo: [NSLocalizedDescriptionKey: "只支持 TXT 和 EPUB"])
        }

        let data = try Data(contentsOf: url)
        let format: BookFormat = ext == "txt" ? .txt : .epub
        let storedName = "\(UUID().uuidString).\(ext)"
        let dest = booksDir.appendingPathComponent(storedName)
        try data.write(to: dest, options: .atomic)

        var title = url.deletingPathExtension().lastPathComponent
        if format == .epub, let doc = try? EPUBParser.parse(fileURL: dest) {
            title = doc.title
        }

        let book = Book(title: title, format: format, fileName: storedName)
        books.insert(book, at: 0)
        saveCatalog()
    }

    func delete(_ book: Book) {
        try? fm.removeItem(at: fileURL(for: book))
        books.removeAll { $0.id == book.id }
        progress.removeValue(forKey: book.id)
        saveCatalog()
        saveProgress()
    }

    func markOpened(_ book: Book) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[idx].lastOpenedAt = Date()
        saveCatalog()
    }

    func loadTXT(for book: Book) throws -> String {
        let data = try Data(contentsOf: fileURL(for: book))
        return EncodingDetector.decode(data).text
    }

    func saveTXT(_ text: String, for book: Book) throws {
        guard let data = text.data(using: .utf8) else { return }
        try data.write(to: fileURL(for: book), options: .atomic)
    }

    func updateProgress(_ value: ReadingProgress) {
        progress[value.bookID] = value
        saveProgress()
    }

    private func load() {
        if let data = try? Data(contentsOf: catalogURL),
           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
            books = decoded
        }
        if let data = try? Data(contentsOf: progressURL),
           let decoded = try? JSONDecoder().decode([UUID: ReadingProgress].self, from: data) {
            progress = decoded
        }
    }

    private func saveCatalog() {
        guard let data = try? JSONEncoder().encode(books) else { return }
        try? data.write(to: catalogURL, options: .atomic)
    }

    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        try? data.write(to: progressURL, options: .atomic)
    }
}
