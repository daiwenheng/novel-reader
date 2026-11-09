import Foundation
import ZIPFoundation

struct EPUBDocument {
    let title: String
    let chapters: [(title: String, html: String)]
}

enum EPUBParserError: Error {
    case invalidArchive
    case missingContainer
    case missingOPF
    case missingSpine
}

enum EPUBParser {
    static func parse(fileURL: URL) throws -> EPUBDocument {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("epub-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }

        guard let archive = Archive(url: fileURL, accessMode: .read) else {
            throw EPUBParserError.invalidArchive
        }
        for entry in archive {
            let dest = temp.appendingPathComponent(entry.path)
            let parent = dest.deletingLastPathComponent()
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
            _ = try archive.extract(entry, to: dest)
        }

        let containerURL = temp.appendingPathComponent("META-INF/container.xml")
        guard let containerXML = try? String(contentsOf: containerURL, encoding: .utf8) else {
            throw EPUBParserError.missingContainer
        }
        guard let opfRel = firstMatch(in: containerXML, pattern: #"full-path=\"([^\"]+)\""#) else {
            throw EPUBParserError.missingContainer
        }
        let opfURL = temp.appendingPathComponent(opfRel)
        let opfDir = opfURL.deletingLastPathComponent()
        guard let opf = try? String(contentsOf: opfURL, encoding: .utf8) else {
            throw EPUBParserError.missingOPF
        }

        let title = firstMatch(in: opf, pattern: #"<dc:title[^>]*>([^<]+)</dc:title>"#)
            ?? fileURL.deletingPathExtension().lastPathComponent

        var idToHref: [String: String] = [:]
        let itemRegex = try NSRegularExpression(pattern: #"<item\b[^>]*>"#, options: [.caseInsensitive])
        let itemMatches = itemRegex.matches(in: opf, range: NSRange(opf.startIndex..., in: opf))
        for m in itemMatches {
            let tag = (opf as NSString).substring(with: m.range)
            guard let id = attr(tag, "id"), let href = attr(tag, "href") else { continue }
            idToHref[id] = href
        }

        let spineRegex = try NSRegularExpression(pattern: #"<itemref\b[^>]*idref=\"([^\"]+)\""#, options: [.caseInsensitive])
        let spineMatches = spineRegex.matches(in: opf, range: NSRange(opf.startIndex..., in: opf))
        if spineMatches.isEmpty { throw EPUBParserError.missingSpine }

        var chapters: [(title: String, html: String)] = []
        for (idx, m) in spineMatches.enumerated() {
            let idref = (opf as NSString).substring(with: m.range(at: 1))
            guard let href = idToHref[idref] else { continue }
            let chapterURL = opfDir.appendingPathComponent(href)
            let html = (try? String(contentsOf: chapterURL, encoding: .utf8)) ?? ""
            let chapterTitle = firstMatch(in: html, pattern: #"<title[^>]*>([^<]+)</title>"#)
                ?? "第\(idx + 1)章"
            chapters.append((chapterTitle, html))
        }

        return EPUBDocument(title: title, chapters: chapters)
    }

    private static func attr(_ tag: String, _ name: String) -> String? {
        firstMatch(in: tag, pattern: #"\#(name)=\"([^\"]+)\""#)
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        guard let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }
}
