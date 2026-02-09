import effects.*

class BuggyException <: Command<Unit> {}

interface ReductionInterface {
    func makeReduction(hasProp: () -> Bool) : Bool {
        try_ {
            perform(BuggyException())
            true
        } .handle { e: BuggyException =>
            false
        } .then_finally {}
    }

    static func someMember(): Unit {}
}