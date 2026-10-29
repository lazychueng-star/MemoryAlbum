import Foundation

/// Reference implementation for contract tests and fixtures until SwiftData persistence lands.
public actor InMemoryRoomRepository: RoomRepository, PhotoRepository {
    private var roomsByID: [UUID: RoomEntity]
    private var photosByID: [UUID: PhotoItemEntity]

    public init(
        rooms: [RoomEntity] = [],
        photos: [PhotoItemEntity] = []
    ) {
        roomsByID = Dictionary(uniqueKeysWithValues: rooms.map { ($0.id, $0) })
        photosByID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
    }

    public func fetchRooms() async throws -> [RoomEntity] {
        StableDomainOrder.rooms(Array(roomsByID.values))
    }

    public func fetchRoom(id: UUID) async throws -> RoomEntity? {
        roomsByID[id]
    }

    public func saveRoom(_ room: RoomEntity) async throws {
        roomsByID[room.id] = room
    }

    public func deleteRoom(id: UUID) async throws -> RoomDeletion {
        guard roomsByID.removeValue(forKey: id) != nil else {
            throw RepositoryError.roomNotFound(id)
        }

        let deletedPhotoIDs = photosByID.values
            .filter { $0.roomID == id }
            .map(\.id)
        for photoID in deletedPhotoIDs {
            photosByID.removeValue(forKey: photoID)
        }

        return RoomDeletion(roomID: id, photoIDs: deletedPhotoIDs)
    }

    public func fetchPhotos(inRoomID roomID: UUID) async throws -> [PhotoItemEntity] {
        guard roomsByID[roomID] != nil else {
            throw RepositoryError.roomNotFound(roomID)
        }

        return StableDomainOrder.photos(
            photosByID.values.filter { $0.roomID == roomID }
        )
    }

    public func fetchPhoto(id: UUID) async throws -> PhotoItemEntity? {
        photosByID[id]
    }

    public func savePhoto(_ photo: PhotoItemEntity) async throws {
        guard roomsByID[photo.roomID] != nil else {
            throw RepositoryError.roomNotFound(photo.roomID)
        }

        photosByID[photo.id] = photo
    }

    public func deletePhoto(id: UUID) async throws {
        guard photosByID.removeValue(forKey: id) != nil else {
            throw RepositoryError.photoNotFound(id)
        }
    }

    public func reorderPhotos(
        inRoomID roomID: UUID,
        orderedPhotoIDs: [UUID]
    ) async throws {
        guard roomsByID[roomID] != nil else {
            throw RepositoryError.roomNotFound(roomID)
        }

        let currentIDs = Set(
            photosByID.values
                .filter { $0.roomID == roomID }
                .map(\.id)
        )
        guard orderedPhotoIDs.count == currentIDs.count,
              Set(orderedPhotoIDs).count == orderedPhotoIDs.count,
              Set(orderedPhotoIDs) == currentIDs
        else {
            throw RepositoryError.invalidPhotoOrder(roomID: roomID)
        }

        for (sortIndex, photoID) in orderedPhotoIDs.enumerated() {
            guard var photo = photosByID[photoID] else {
                throw RepositoryError.photoNotFound(photoID)
            }
            photo.sortIndex = sortIndex
            photosByID[photoID] = photo
        }
    }
}
