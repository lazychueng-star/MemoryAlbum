import Foundation

public enum RoomTheme: String, CaseIterable, Codable, Hashable, Sendable {
    case stargazingLoft
    case herbalApothecary
    case manuscriptGallery
    case hearthStoryRoom
}

public struct RoomEntity: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var sortIndex: Int
    public var theme: RoomTheme
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        name: String,
        sortIndex: Int,
        theme: RoomTheme,
        createdAt: Date,
        updatedAt: Date
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw DomainValidationError.emptyRoomName
        }
        guard sortIndex >= 0 else {
            throw DomainValidationError.negativeSortIndex(entity: .room)
        }

        self.id = id
        self.name = trimmedName
        self.sortIndex = sortIndex
        self.theme = theme
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
