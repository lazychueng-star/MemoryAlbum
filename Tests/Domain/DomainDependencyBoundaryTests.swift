import Foundation
import XCTest

final class DomainDependencyBoundaryTests: XCTestCase {
    func testDomainDoesNotDependOnUIStorageRealityKitOrFileManager() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let domainRoot = projectRoot.appendingPathComponent("Domain")
        let files = try XCTUnwrap(
            FileManager.default.enumerator(
                at: domainRoot,
                includingPropertiesForKeys: [.isRegularFileKey]
            )
        )
        let forbiddenDependencies = ["SwiftUI", "SwiftData", "RealityKit"]

        for case let fileURL as URL in files where fileURL.pathExtension == "swift" {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            for dependency in forbiddenDependencies {
                XCTAssertFalse(
                    source.contains("import \(dependency)"),
                    "\(fileURL.lastPathComponent) must not import \(dependency)"
                )
            }
            XCTAssertFalse(
                source.contains("FileManager"),
                "\(fileURL.lastPathComponent) must not depend on FileManager"
            )
        }
    }
}
