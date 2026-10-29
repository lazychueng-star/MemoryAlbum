import Foundation

public enum PhotoDisplayStyle: String, Codable, Hashable, Sendable {
    case hearthPolaroid
    case brassFrame
    case apothecaryCard
    case openFolio
}

public struct PhotoItemEntity: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let roomID: UUID
    public var originalRelativePath: MediaRelativePath
    public var displayRelativePath: MediaRelativePath?
    public var thumbnailRelativePath: MediaRelativePath?
    public var sortIndex: Int
    public var capturedAt: Date?
    public let importedAt: Date
    public var updatedAt: Date
    public var displayStyle: PhotoDisplayStyle
    public var note: String?

    public init(
        id: UUID,
        roomID: UUID,
        originalRelativePath: MediaRelativePath,
        displayRelativePath: MediaRelativePath? = nil,
        thumbnailRelativePath: MediaRelativePath? = nil,
        sortIndex: Int,
        capturedAt: Date? = nil,
        importedAt: Date,
        updatedAt: Date,
        displayStyle: PhotoDisplayStyle,
        note: String? = nil
    ) throws {
        guard sortIndex >= 0 else {
            throw DomainValidationError.negativeSortIndex(entity: .photo)
        }

        self.id = id
        self.roomID = roomID
        self.originalRelativePath = originalRelativePath
        self.displayRelativePath = displayRelativePath
        self.thumbnailRelativePath = thumbnailRelativePath
        self.sortIndex = sortIndex
        self.capturedAt = capturedAt
        self.importedAt = importedAt
        self.updatedAt = updatedAt
        self.displayStyle = displayStyle
        self.note = note
    }
}
