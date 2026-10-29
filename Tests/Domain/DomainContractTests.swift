import XCTest
@testable import MemoryAlbum

final class DomainContractTests: XCTestCase {
    func testFixturesAreStableAndCoverRequiredStates() {
        XCTAssertEqual(DomainFixtures.oneRoom.count, 1)
        XCTAssertEqual(DomainFixtures.fourRooms.count, 4)
        XCTAssertTrue(DomainFixtures.noPhotos.isEmpty)
        XCTAssertEqual(DomainFixtures.missingFile.availability, .missing)
        XCTAssertEqual(
            DomainFixtures.missingFile.photo.originalRelativePath.rawValue,
            "originals/901.heic"
        )
    }

    func testMediaPathRejectsAbsoluteAndParentTraversalPaths() {
        XCTAssertNil(MediaRelativePath(rawValue: "/originals/photo.heic"))
        XCTAssertNil(MediaRelativePath(rawValue: "../originals/photo.heic"))
        XCTAssertNil(MediaRelativePath(rawValue: "originals/../photo.heic"))
        XCTAssertNotNil(MediaRelativePath(rawValue: "originals/photo.heic"))
    }

    func testPhotosAreGroupedByRoomAndStablySorted() async throws {
        let repository = InMemoryRoomRepository(
            rooms: DomainFixtures.fourRooms,
            photos: DomainFixtures.photosAcrossRooms
        )

        let firstRoomPhotos = try await repository.fetchPhotos(
            inRoomID: DomainFixtures.fourRooms[0].id
        )
        let secondRoomPhotos = try await repository.fetchPhotos(
            inRoomID: DomainFixtures.fourRooms[1].id
        )

        XCTAssertEqual(firstRoomPhotos.map(\.id), photos(101...103))
        XCTAssertEqual(secondRoomPhotos.map(\.id), photos(201...201))
        XCTAssertTrue(firstRoomPhotos.allSatisfy {
            $0.roomID == DomainFixtures.fourRooms[0].id
        })
    }

    func testSortTieBreaksByUUID() {
        let laterID = DomainFixtures.makePhoto(
            id: 302,
            roomID: 1,
            sortIndex: 0,
            path: "originals/302.heic"
        )
        let earlierID = DomainFixtures.makePhoto(
            id: 301,
            roomID: 1,
            sortIndex: 0,
            path: "originals/301.heic"
        )

        XCTAssertEqual(
            StableDomainOrder.photos([laterID, earlierID]).map(\.id),
            [earlierID.id, laterID.id]
        )
    }

    func testDeleteRoomCascadesMetadataAndReturnsPhotoIDs() async throws {
        let repository = InMemoryRoomRepository(
            rooms: DomainFixtures.fourRooms,
            photos: DomainFixtures.photosAcrossRooms
        )

        let deletion = try await repository.deleteRoom(
            id: DomainFixtures.fourRooms[0].id
        )
        let deletedRoom = try await repository.fetchRoom(
            id: DomainFixtures.fourRooms[0].id
        )
        let remainingRooms = try await repository.fetchRooms()
        let remainingSecondRoomPhotos = try await repository.fetchPhotos(
            inRoomID: DomainFixtures.fourRooms[1].id
        )

        XCTAssertEqual(deletion.photoIDs, photos(101...103))
        XCTAssertNil(deletedRoom)
        XCTAssertEqual(
            remainingRooms.map(\.id),
            Array(DomainFixtures.fourRooms.dropFirst().map(\.id))
        )
        XCTAssertEqual(
            remainingSecondRoomPhotos.map(\.id),
            photos(201...201)
        )
    }

    func testReorderUpdatesOnlyRequestedRoom() async throws {
        let repository = InMemoryRoomRepository(
            rooms: DomainFixtures.fourRooms,
            photos: DomainFixtures.photosAcrossRooms
        )
        let firstRoomID = DomainFixtures.fourRooms[0].id
        let secondRoomID = DomainFixtures.fourRooms[1].id
        let reversedIDs = Array(photos(101...103).reversed())

        try await repository.reorderPhotos(
            inRoomID: firstRoomID,
            orderedPhotoIDs: reversedIDs
        )

        let reordered = try await repository.fetchPhotos(inRoomID: firstRoomID)
        let secondRoomPhotos = try await repository.fetchPhotos(inRoomID: secondRoomID)
        XCTAssertEqual(reordered.map(\.id), reversedIDs)
        XCTAssertEqual(reordered.map(\.sortIndex), [0, 1, 2])
        XCTAssertTrue(reordered.allSatisfy { $0.roomID == firstRoomID })
        XCTAssertEqual(secondRoomPhotos.map(\.sortIndex), [0])
    }

    func testReorderRejectsIncompleteOrDuplicateOrder() async throws {
        let repository = InMemoryRoomRepository(
            rooms: DomainFixtures.fourRooms,
            photos: DomainFixtures.photosAcrossRooms
        )
        let roomID = DomainFixtures.fourRooms[0].id
        let ids = photos(101...103)

        await XCTAssertThrowsRepositoryError(.invalidPhotoOrder(roomID: roomID)) {
            try await repository.reorderPhotos(
                inRoomID: roomID,
                orderedPhotoIDs: Array(ids.dropLast())
            )
        }
        await XCTAssertThrowsRepositoryError(.invalidPhotoOrder(roomID: roomID)) {
            try await repository.reorderPhotos(
                inRoomID: roomID,
                orderedPhotoIDs: [ids[0], ids[0], ids[2]]
            )
        }
    }

    private func photos(_ range: ClosedRange<Int>) -> [UUID] {
        range.map { DomainFixtures.makePhoto(
            id: $0,
            roomID: 1,
            sortIndex: 0,
            path: "originals/\($0).heic"
        ).id }
    }

    private func XCTAssertThrowsRepositoryError(
        _ expected: RepositoryError,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: @escaping () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as RepositoryError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
