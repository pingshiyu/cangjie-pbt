package cangjie_experiments

import stdx.effect.*

class BuggyException <: Command<Unit> {}

interface ReductionInterface {
    func apply(interesting : () -> Bool) : Unit

    func makeReduction(hasProp: () -> Bool) : Unit {
        func interesting() : Bool {
            try {
                perform BuggyException()
                true
            } handle(e: BuggyException) {
                false
            }
        }
        apply(interesting)
    }

    static func someMember(): Unit {}
}