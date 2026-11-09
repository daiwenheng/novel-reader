import XCTest
@testable import NovelReader

final class EPUBParserTests: XCTestCase {
    func testParseSampleEPUB() throws {
        let url = try XCTUnwrap(Bundle(for: EPUBParserTests.self).url(forResource: "sample", withExtension: "epub"))
        let doc = try EPUBParser.parse(fileURL: url)
        XCTAssertEqual(doc.title, "测试EPUB")
        XCTAssertEqual(doc.chapters.count, 2)
        XCTAssertTrue(doc.chapters[0].html.contains("第一章内容") || doc.chapters[0].title.contains("第一"))
    }
}
