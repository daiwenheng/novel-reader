import Foundation

enum BookFormat: String, Codable, Hashable {
    case txt
    case epub
}

struct Book: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var format: BookFormat
    var fileName: String
    var importedAt: Date
    var lastOpenedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        format: BookFormat,
        fileName: String,
        importedAt: Date = Date(),
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.format = format
        self.fileName = fileName
        self.importedAt = importedAt
        self.lastOpenedAt = lastOpenedAt
    }
}

struct Chapter: Identifiable, Hashable {
    let id: UUID
    let title: String
    let startIndex: Int
    let endIndex: Int

    init(id: UUID = UUID(), title: String, startIndex: Int, endIndex: Int) {
        self.id = id
        self.title = title
        self.startIndex = startIndex
        self.endIndex = endIndex
    }
}

struct ReadingProgress: Codable, Hashable {
    var bookID: UUID
    var chapterIndex: Int
    var scrollOffset: Double
    var updatedAt: Date

    init(bookID: UUID, chapterIndex: Int = 0, scrollOffset: Double = 0, updatedAt: Date = Date()) {
        self.bookID = bookID
        self.chapterIndex = chapterIndex
        self.scrollOffset = scrollOffset
        self.updatedAt = updatedAt
    }
}

enum ReaderTheme: String, CaseIterable, Identifiable {
    case light
    case sepia
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "浅色"
        case .sepia: return "护眼"
        case .dark: return "深色"
        }
    }
}
