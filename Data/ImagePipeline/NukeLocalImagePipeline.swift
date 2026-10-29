import Foundation
import Nuke
import UIKit

enum LocalImageVariant: String, CaseIterable, Sendable {
    case gallery
    case thumbnail

    var maxPixelSize: Float {
        switch self {
        case .gallery: 1_000
        case .thumbnail: 320
        }
    }
}

struct LocalImageLoad: Sendable {
    private let task: ImageTask

    init(task: ImageTask) {
        self.task = task
    }

    var image: UIImage {
        get async throws {
            try await task.image
        }
    }

    var state: ImageTask.State {
        task.state
    }

    func cancel() {
        task.cancel()
    }
}

actor NukeLocalImagePipeline {
    struct MemoryCacheSnapshot: Equatable, Sendable {
        let count: Int
        let costBytes: Int
    }

    private let memoryCache: ImageCache
    private let pipeline: ImagePipeline

    init(
        memoryCostLimit: Int = 64 * 1_024 * 1_024,
        memoryCountLimit: Int = 128
    ) {
        let memoryCache = ImageCache(
            costLimit: memoryCostLimit,
            countLimit: memoryCountLimit
        )
        var configuration = ImagePipeline.Configuration()
        configuration.imageCache = memoryCache
        configuration.dataCache = nil
        configuration.isProgressiveDecodingEnabled = false

        self.memoryCache = memoryCache
        self.pipeline = ImagePipeline(configuration: configuration)
    }

    func loadFile(
        at url: URL,
        variant: LocalImageVariant
    ) -> LocalImageLoad {
        makeLoad(for: makeRequest(url: url, variant: variant))
    }

    func loadData(
        _ data: Data,
        id: String,
        variant: LocalImageVariant
    ) -> LocalImageLoad {
        let request = ImageRequest(
            id: "memory:\(variant.rawValue):\(id)",
            data: { data },
            options: [.disableDiskCache]
        )
        return makeLoad(for: makeRequest(url: nil, variant: variant, base: request))
    }

    func memoryCacheSnapshot() -> MemoryCacheSnapshot {
        MemoryCacheSnapshot(
            count: memoryCache.totalCount,
            costBytes: memoryCache.totalCost
        )
    }

    func removeAllMemoryCache() {
        memoryCache.removeAll()
    }

    private func makeLoad(for request: ImageRequest) -> LocalImageLoad {
        LocalImageLoad(task: pipeline.imageTask(with: request))
    }

    private func makeRequest(
        url: URL?,
        variant: LocalImageVariant,
        base request: ImageRequest? = nil
    ) -> ImageRequest {
        var request = request ?? ImageRequest(
            url: url,
            options: [.disableDiskCache]
        )
        request.scale = 1
        request.thumbnail = ImageRequest.ThumbnailOptions(
            maxPixelSize: variant.maxPixelSize
        )
        return request
    }
}
