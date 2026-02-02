package cangjie_experiments

import cangjie_experiments.define.*
import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.resumptions.loop.*
import cangjie_experiments.pbt.*
import cangjie_experiments.utils.*

// User code.
// example functions
func effectfulFunction(label: String): UnitFn {{ =>
    println("${label}: entry")
    perform Unk() // call ext function
    println("${label}: called Unk 1")
    perform Unk() // call ext function
    println("${label}: called Unk 2")
}}

func mainHarness(library: List<UnitFn>): Unit {
    let r = Random()
    let arb = Arbitrary()
    let ress = ArrayList<Res>()
    
    runExtRand(r) { arb.sHandle {
        try {
            executor()
        } handle(e: HasRes) {
            resume with (ress.size > 0)
        } handle(e: GetRandomRes) {
            let chosenRIx = randIntRange(0, ress.size)
            resume with ress.remove(at:chosenRIx)
        } handle(e: AddRes) {
            ress.add(e.r)
            resume with ()
        } handle(e: GetRandomUnitFn) {
            let chosenRIx = randIntRange(0, library.size)
            resume with library[chosenRIx]
        }
    }}
}

func runHarness() : Unit {
    // let lib = ArrayList<UnitFn>([ // these may produce Unk effects.
    //     effectfulFunction("one"),
    //     effectfulFunction("two"),
    //     effectfulFunction("three")
    // ])

    let lib = ArrayList<UnitFn>([
        @RunRandomly([f in randFunc<Int64, Int64>, ls in randList<Int64>(10, randInt64)], map_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList<Int64>(10, randInt64)], filter_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList<Int64>(10, randInt64)], all_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList<Int64>(10, randInt64)], none_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList<Int64>(10, randInt64)], any_),
        @RunRandomly([f in randFunc<(Int8, Int8), Int8>, ls in randList<Int8>(10, randInt8)], reduce_),
        @RunRandomly([f in randFunc<Int8, ?Bool>, ls in randList<Int8>(8, randInt8)], filterMap_),
        @RunRandomly([f in randFunc<Bool, ArrayList<Bool>>, ls in randList<Bool>(10, randBool_(0.50))], flatMap_),
        @RunRandomly([f in randFunc<Bool, Unit>, ls in randList<Bool>(10, randBool_(0.30))], forEach_)
    ])

    mainHarness(lib)
}

main() {

    runHarness()
    return 0
}
