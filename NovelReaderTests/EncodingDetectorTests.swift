import XCTest
@testable import NovelReader

final class EncodingDetectorTests: XCTestCase {
    func testUTF8Sample() throws {
        let url = try XCTUnwrap(Bundle(for: EncodingDetectorTests.self).url(forResource: "sample_utf8", withExtension: "txt"))
        let data = try Data(contentsOf: url)
        let result = EncodingDetector.decode(data)
        XCTAssertTrue(result.text.contains("第一章"))
        XCTAssertEqual(result.encoding, .utf8)
    }

    func testGBKSample() throws {
        let url = try XCTUnwrap(Bundle(for: EncodingDetectorTests.self).url(forResource: "sample_gbk", withExtension: "txt"))
        let data = try Data(contentsOf: url)
        let result = EncodingDetector.decode(data)
        XCTAssertTrue(result.text.contains("编码测试") || result.text.contains("第一章"))
    }
}
