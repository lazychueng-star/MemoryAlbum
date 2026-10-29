import Foundation

struct MissingFileFixture: Sendable {
    let photo: PhotoItemEntity
    let availability: MediaFileAvailability
}

enum DomainFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_735_689_600)

    static let oneRoom: [RoomEntity] = [
        makeRoom(id: 1, name: "Story Room", sortIndex: 0, theme: .hearthStoryRoom)
    ]

    static let fourRooms: [RoomEntity] = [
        makeRoom(id: 1, name: "Astronomy Loft", sortIndex: 0, theme: .stargazingLoft),
        makeRoom(id: 2, name: "Herbal Apothecary", sortIndex: 1, theme: .herbalApothecary),
        makeRoom(id: 3, name: "Manuscript Gallery", sortIndex: 2, theme: .manuscriptGallery),
        makeRoom(id: 4, name: "Hearth Story Room", sortIndex: 3, theme: .hearthStoryRoom)
    ]

    static let noPhotos: [PhotoItemEntity] = []

    static let photosAcrossRooms: [PhotoItemEntity] = [
        makePhoto(id: 101, roomID: 1, sortIndex: 0, path: "originals/101.heic"),
        makePhoto(id: 102, roomID: 1, sortIndex: 1, path: "originals/102.heic"),
        makePhoto(id: 103, roomID: 1, sortIndex: 2, path: "originals/103.heic"),
        makePhoto(id: 201, roomID: 2, sortIndex: 0, path: "originals/201.heic")
    ]

    static let missingFile = MissingFileFixture(
        photo: makePhoto(
            id: 901,
            roomID: 1,
            sortIndex: 0,
            path: "originals/901.heic"
        ),
        availability: .missing
    )

    static func makeRoom(
        id: Int,
        name: String,
        sortIndex: Int,
        theme: RoomTheme
    ) -> RoomEntity {
        try! RoomEntity(
            id: stableUUID(id),
            name: name,
            sortIndex: sortIndex,
            theme: theme,
            createdAt: referenceDate,
            updatedAt: referenceDate
        )
    }

    static func makePhoto(
        id: Int,
        roomID: Int,
        sortIndex: Int,
        path: String
    ) -> PhotoItemEntity {
        try! PhotoItemEntity(
            id: stableUUID(id),
            roomID: stableUUID(roomID),
            originalRelativePath: MediaRelativePath(rawValue: path)!,
            sortIndex: sortIndex,
            capturedAt: referenceDate,
            importedAt: referenceDate,
            updatedAt: referenceDate,
            displayStyle: .hearthPolaroid
        )
    }

    private static func stableUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
