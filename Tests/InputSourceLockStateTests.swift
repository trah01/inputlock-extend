import Foundation

@main
struct InputSourceLockStateTests {
    static func main() {
        var state = InputSourceLockState()

        assert(!state.isLocked)
        assert(!state.matchesLockedInputSourceID("com.apple.keylayout.ABC"))

        state.lock(inputSourceID: "com.apple.keylayout.ABC")
        assert(state.isLocked)
        assert(state.matchesLockedInputSourceID("com.apple.keylayout.ABC"))
        assert(!state.matchesLockedInputSourceID("com.apple.inputmethod.SCIM.ITABC"))

        state.unlock()
        assert(!state.isLocked)
        assert(!state.matchesLockedInputSourceID("com.apple.keylayout.ABC"))
    }
}
