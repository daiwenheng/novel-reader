import Foundation

enum EncodingDetector {
    /// Detect common Chinese encodings and decode. Prefers UTF-8, then GB18030/GBK, then UTF-16.
    static func decode(_ data: Data) -> (text: String, encoding: String.Encoding) {
        if let text = String(data: data, encoding: .utf8), !text.contains("\u{FFFD}") {
            return (text, .utf8)
        }

        let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let text = String(data: data, encoding: gb18030) {
            return (text, gb18030)
        }

        if let text = String(data: data, encoding: .utf16) {
            return (text, .utf16)
        }
        if let text = String(data: data, encoding: .utf16LittleEndian) {
            return (text, .utf16LittleEndian)
        }
        if let text = String(data: data, encoding: .utf16BigEndian) {
            return (text, .utf16BigEndian)
        }

        let fallback = String(decoding: data, as: UTF8.self)
        return (fallback, .utf8)
    }
}
