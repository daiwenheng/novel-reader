import XCTest
@testable import NovelReader

final class ChapterSplitterTests: XCTestCase {
    func testSplitsChineseHeadings() throws {
        let url = try XCTUnwrap(Bundle(for: ChapterSplitterTests.self).url(forResource: "sample_utf8", withExtension: "txt"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let chapters = ChapterSplitter.split(text)
        XCTAssertGreaterThanOrEqual(chapters.count, 2)
        XCTAssertTrue(chapters.contains(where: { $0.title.contains("第一章") }))
        XCTAssertTrue(chapters.contains(where: { $0.title.contains("第二章") }))
        let firstBody = ChapterSplitter.content(of: chapters.first(where: { $0.title.contains("第一章") })!, in: text)
        XCTAssertTrue(firstBody.contains("推开门"))
    }

    func testNoHeadingBecomesSingleChapter() {
        let chapters = ChapterSplitter.split("一段没有章节标题的文字。")
        XCTAssertEqual(chapters.count, 1)
        XCTAssertEqual(chapters[0].title, "全文")
    }
}
