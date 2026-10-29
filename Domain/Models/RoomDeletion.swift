import Foundation

public struct RoomDeletion: Equatable, Sendable {
    public let roomID: UUID
    public let photoIDs: [UUID]

    public init(roomID: UUID, photoIDs: [UUID]) {
        self.roomID = roomID
        self.photoIDs = photoIDs.sorted { $0.uuidString < $1.uuidString }
    }
}
