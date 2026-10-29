import Foundation

public enum RepositoryError: Error, Equatable, Sendable {
    case roomNotFound(UUID)
    case photoNotFound(UUID)
    case invalidPhotoOrder(roomID: UUID)
    case persistenceUnavailable
}
