import Foundation

public protocol RoomRepository: Sendable {
    func fetchRooms() async throws -> [RoomEntity]
    func fetchRoom(id: UUID) async throws -> RoomEntity?
    func saveRoom(_ room: RoomEntity) async throws
    func deleteRoom(id: UUID) async throws -> RoomDeletion
}
