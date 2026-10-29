import Foundation

public protocol PhotoRepository: Sendable {
    func fetchPhotos(inRoomID roomID: UUID) async throws -> [PhotoItemEntity]
    func fetchPhoto(id: UUID) async throws -> PhotoItemEntity?
    func savePhoto(_ photo: PhotoItemEntity) async throws
    func deletePhoto(id: UUID) async throws
    func reorderPhotos(inRoomID roomID: UUID, orderedPhotoIDs: [UUID]) async throws
}
