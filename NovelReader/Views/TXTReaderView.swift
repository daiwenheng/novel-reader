import SwiftUI

struct TXTReaderView: View {
    @EnvironmentObject private var library: BookLibrary
    let book: Book

    @State private var text: String = ""
    @State private var chapters: [Chapter] = []
    @State private var chapterIndex: Int = 0
    @State private var isEditing = false
    @State private var editDraft = ""
    @State private var fontSize: Double = 18
    @State private var theme: ReaderTheme = .sepia
    @State private var loadError: String?
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView("无法打开", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else if isEditing {
                TextEditor(text: $editDraft)
                    .font(.system(size: fontSize))
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .foregroundStyle(foregroundColor)
                    .onChange(of: editDraft) { _, newValue in
                        scheduleAutosave(newValue)
                    }
            } else {
                ScrollView {
                    Text(currentChapterText)
                        .font(.system(size: fontSize))
                        .lineSpacing(8)
                        .foregroundStyle(foregroundColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(backgroundColor)
            }
        }
        .navigationTitle(currentTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !chapters.isEmpty && !isEditing {
                    Menu {
                        ForEach(Array(chapters.enumerated()), id: \.element.id) { idx, chapter in
                            Button(chapter.title) {
                                chapterIndex = idx
                                persistProgress()
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
                Button {
                    if isEditing {
                        commitEdit()
                    } else {
                        editDraft = text
                        isEditing = true
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                }
                .accessibilityLabel(isEditing ? "完成编辑" : "编辑正文")
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
        .onDisappear {
            saveTask?.cancel()
            if isEditing { commitEdit() }
        }
    }

    private var currentTitle: String {
        guard chapters.indices.contains(chapterIndex) else { return book.title }
        return chapters[chapterIndex].title
    }

    private var currentChapterText: String {
        guard chapters.indices.contains(chapterIndex) else { return text }
        return ChapterSplitter.content(of: chapters[chapterIndex], in: text)
    }

    private var backgroundColor: Color {
        switch theme {
        case .light: return Color(white: 0.98)
        case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.84)
        case .dark: return Color(white: 0.08)
        }
    }

    private var foregroundColor: Color {
        theme == .dark ? Color(white: 0.9) : Color.primary
    }

    private func load() async {
        do {
            let loaded = try library.loadTXT(for: book)
            text = loaded
            chapters = ChapterSplitter.split(loaded)
            if let p = library.progress[book.id] {
                chapterIndex = min(max(0, p.chapterIndex), max(0, chapters.count - 1))
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func scheduleAutosave(_ newValue: String) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            text = newValue
            try? library.saveTXT(newValue, for: book)
            chapters = ChapterSplitter.split(newValue)
        }
    }

    private func commitEdit() {
        saveTask?.cancel()
        text = editDraft
        try? library.saveTXT(editDraft, for: book)
        chapters = ChapterSplitter.split(editDraft)
        isEditing = false
        if chapterIndex >= chapters.count {
            chapterIndex = max(0, chapters.count - 1)
        }
        persistProgress()
    }

    private func persistProgress() {
        library.updateProgress(ReadingProgress(bookID: book.id, chapterIndex: chapterIndex))
    }
}
