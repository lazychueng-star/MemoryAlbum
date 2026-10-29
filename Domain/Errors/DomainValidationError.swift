import Foundation

public enum DomainEntityKind: String, Codable, Hashable, Sendable {
    case room
    case photo
}

public enum DomainValidationError: Error, Equatable, Sendable {
    case emptyRoomName
    case negativeSortIndex(entity: DomainEntityKind)
}
