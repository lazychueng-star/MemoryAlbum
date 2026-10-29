public enum StableDomainOrder {
    public static func rooms(_ rooms: [RoomEntity]) -> [RoomEntity] {
        rooms.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    public static func photos(_ photos: [PhotoItemEntity]) -> [PhotoItemEntity] {
        photos.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
