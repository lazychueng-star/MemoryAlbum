import XCTest
@testable import MemoryAlbum

final class ScaffoldTests: XCTestCase {
    func testAppModuleLoads() {
        XCTAssertFalse(String(reflecting: MemoryAlbumApp.self).isEmpty)
    }
}
