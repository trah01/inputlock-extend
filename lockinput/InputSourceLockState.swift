import Foundation

struct InputSourceLockState {
    private(set) var lockedInputSourceID: String?

    var isLocked: Bool {
        lockedInputSourceID != nil
    }

    mutating func lock(inputSourceID: String) {
        lockedInputSourceID = inputSourceID
    }

    mutating func unlock() {
        lockedInputSourceID = nil
    }

    func matchesLockedInputSourceID(_ inputSourceID: String?) -> Bool {
        guard let lockedInputSourceID, let inputSourceID else { return false }
        return lockedInputSourceID == inputSourceID
    }
}
