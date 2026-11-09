import Foundation

enum ChapterSplitter {
    /// Split Chinese novel text by common chapter headings.
    static func split(_ text: String) -> [Chapter] {
        let pattern = #"(?m)^[ 　\t]*第[一二三四五六七八九十百千零〇两0-9]+[章节回卷集部篇].*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [Chapter(title: "全文", startIndex: 0, endIndex: text.utf16.count)]
        }

        let full = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: full)
        if matches.isEmpty {
            return [Chapter(title: "全文", startIndex: 0, endIndex: text.utf16.count)]
        }

        var chapters: [Chapter] = []
        if let first = matches.first, first.range.location > 0 {
            chapters.append(Chapter(title: "前言", startIndex: 0, endIndex: first.range.location))
        }

        for (idx, match) in matches.enumerated() {
            let titleRange = Range(match.range, in: text)!
            let title = String(text[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let start = match.range.location
            let end: Int
            if idx + 1 < matches.count {
                end = matches[idx + 1].range.location
            } else {
                end = text.utf16.count
            }
            chapters.append(Chapter(title: title.isEmpty ? "第\(idx + 1)章" : title, startIndex: start, endIndex: end))
        }
        return chapters
    }

    static func content(of chapter: Chapter, in text: String) -> String {
        let ns = text as NSString
        let length = ns.length
        let start = min(max(0, chapter.startIndex), length)
        let end = min(max(start, chapter.endIndex), length)
        return ns.substring(with: NSRange(location: start, length: end - start))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
