import Foundation

extension NSString {
    var byteCount: ByteCount {
        ByteCount(length * 2)
    }

    func getAllBytes(withEncoding encoding: String.Encoding, usedLength: inout Int) -> UnsafePointer<Int8>? {
        let range = NSRange(location: 0, length: length)
        return getBytes(in: range, encoding: encoding, usedLength: &usedLength)
    }

    func getBytes(in range: NSRange, encoding: String.Encoding, usedLength: inout Int) -> UnsafePointer<Int8>? {
        let byteRange = ByteRange(utf16Range: range)
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: byteRange.length.value)
        let didGetBytes = getBytes(
            buffer,
            maxLength: byteRange.length.value,
            usedLength: &usedLength,
            encoding: encoding.rawValue,
            options: [],
            range: range,
            remaining: nil)
        if didGetBytes {
            return UnsafePointer<Int8>(buffer)
        } else {
            return nil
        }
    }

    /// A wrapper around `rangeOfComposedCharacterSequences(for:)` that considers CRLF line endings as composed character sequences.
    func customRangeOfComposedCharacterSequence(at location: Int) -> NSRange {
        let range = NSRange(location: location, length: 0)
        return customRangeOfComposedCharacterSequences(for: range)
    }

    /// A wrapper around `rangeOfComposedCharacterSequences(for:)` that considers CRLF line endings as composed character sequences.
    func customRangeOfComposedCharacterSequences(for range: NSRange) -> NSRange {
        let clampedRange = clampedRangeForComposedCharacterSequences(range)
        // Guard against out-of-bounds ranges that can raise NSInvalidArgumentException.
        guard length > 0, clampedRange.location < length else {
            return clampedRange
        }
        let defaultRange: NSRange
        if clampedRange.length == 0 {
            defaultRange = rangeOfComposedCharacterSequence(at: clampedRange.location)
        } else {
            defaultRange = rangeOfComposedCharacterSequences(for: clampedRange)
        }
        let candidateCRLFRange = NSRange(location: defaultRange.location - 1, length: 2)
        if candidateCRLFRange.location >= 0 && candidateCRLFRange.upperBound <= length && isCRLFLineEnding(in: candidateCRLFRange) {
            return NSRange(location: defaultRange.location - 1, length: defaultRange.length + 1)
        } else {
            return defaultRange
        }
    }
}

private extension NSString {
    func clampedRangeForComposedCharacterSequences(_ range: NSRange) -> NSRange {
        let safeLocation = min(max(range.location, 0), length)
        let maxLength = length - safeLocation
        let safeLength = min(max(range.length, 0), maxLength)
        return NSRange(location: safeLocation, length: safeLength)
    }

    private func isCRLFLineEnding(in range: NSRange) -> Bool {
        substring(with: range) == Symbol.carriageReturnLineFeed
    }
}
