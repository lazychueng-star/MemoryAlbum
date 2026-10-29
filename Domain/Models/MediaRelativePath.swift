import Foundation

public struct MediaRelativePath: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard !rawValue.isEmpty,
              rawValue == rawValue.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.hasPrefix("/"),
              !rawValue.hasPrefix("~"),
              !rawValue.contains("\\")
        else {
            return nil
        }

        let components = rawValue.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            return nil
        }

        self.rawValue = rawValue
    }

    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        guard let path = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .rawValue,
                in: container,
                debugDescription: "Expected a non-empty relative media path."
            )
        }
        self = path
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
    }
}
