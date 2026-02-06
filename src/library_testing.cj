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
    perform Switch() // call ext function
    println("${label}: called Switch 1")
    perform Switch() // call ext function
    println("${label}: called Switch 2")
}}

func runInContext(seed: Option<UInt64>, lib: List<UnitFn>, f0: Int64, f : () -> Unit) : Unit {
    let r = match (seed) {
        case Some(s) => Random(s)
        case None => Random()
    }
    let arb = Arbitrary()
    let ress = ArrayList<Res>()
    
    runExtRand(r) { arb.sHandle { handleStateV(()) { handleFuel(f0) {   
        try {
            f()
        } handle(e: HasRes) {
            resume with (ress.size > 0)
        } handle(e: GetRandomRes) {
            let chosenRIx = randIntRange(0, ress.size)
            resume with ress.remove(at:chosenRIx)
        } handle(e: AddRes) {
            ress.add(e.r)
            resume with ()
        } handle(e: GetRandomUnitFn) {
            let chosenRIx = randIntRange(0, lib.size)
            perform ConsumeFuel()
            resume with lib[chosenRIx]
        } handle(e: RunFunction) {
            if (perform HasFuel()) {
                perform ConsumeFuel()
                resume with randBool(e.p)
            } else {
                resume with false
            }
        }
    }}}}
}

func randObject<T>() : T {
    perform GenRandom<T>()
}

class ExampleClass {
    public ExampleClass() {}
    public func f1() {}
    public func f2(i : Int64) : String { "f2 called" }
    private func p1() {}
    private func p2(s : String) : Int64 { -1 }
}

func getContext() : ArrayList<UnitFn> {
    // let lib = ArrayList<UnitFn>([ // these may produce Switch effects.
    //     effectfulFunction("one"),
    //     effectfulFunction("two"),
    //     effectfulFunction("three"),
    // ])
    let o1_ExampleClass = ExampleClass()
    let o1_fns = ArrayList([
        @RunRandomly([], o1_ExampleClass.f1),
        @RunRandomly([x in randInt64], o1_ExampleClass.f2)
    ])

    let o2_ExampleClass = ExampleClass()
    let o2_fns = ArrayList([
        @RunRandomly([], o2_ExampleClass.f1),
        @RunRandomly([x in randInt64], o2_ExampleClass.f2)
    ])

    let lib = ArrayList([
        // these functions are higher order
        // @RunRandomly([f in randFunc<Int64, Int64>, ls in randList(5, randInt64)], map_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], map_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], filter_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], all_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], none_),
        @RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], any_),
        @RunRandomly([f in randFunc<(Int8, Int8), Int8>, ls in randList(5, randInt8)], reduce_),
        @RunRandomly([f in randFunc<Int8, ?Bool>, ls in randList(6, randInt8)], filterMap_),
        @RunRandomly([f in randFunc<Bool, ArrayList<Bool>>, ls in randList(5, randBool_(0.50))], flatMap_),
        @RunRandomly([f in randFunc<Bool, Unit>, ls in randList(5, randBool_(0.30))], forEach_),
        @RunRandomly([f in randFunc<(Int64, Bool), Int64>, e in randInt64, ls in randList(10, randBool_(0.30))], fold_),
        @RunRandomly([f in randFunc<Int64, Unit>, ls in randList(5, randInt64)], inspect_),
        
        // End operations from end_operation.cj
        @RunRandomly([ls in randList(10, randInt64)], isEmpty),
        @RunRandomly([ls in randList(10, randInt64)], count),
        @RunRandomly([element in randInt64_(), ls in randList(10, randInt64)], contains_),
        @RunRandomly([ls in randList(10, randInt64)], max),
        @RunRandomly([ls in randList(10, randInt64)], min),
        @RunRandomly([ls in randList(10, randInt64)], first),
        @RunRandomly([ls in randList(10, randInt64)], last),
        @RunRandomly([n in randIntRange_(0, 10), ls in randList(10, randInt64)], at_),
        
        // Middle operations from middle_operation.cj
        @RunRandomly([ls in randList(10, randInt64)], enumerate_),
        @RunRandomly([ls in randNestedList(5, randInt64)], flatten_),
        @RunRandomly([other in randList(8, randInt64), ls in randList(5, randInt64)], zip_),
        @RunRandomly([other in randList(5, randInt64), ls in randList(5, randInt64)], concat_),
        @RunRandomly([count in randIntRange_(0, 10), ls in randList(5, randInt64)], skip_),
        @RunRandomly([count in randIntRange_(0, 10), ls in randList(5, randInt64)], take_),
        @RunRandomly([count in randIntRange_(1, 5), ls in randList(5, randInt64)], step_),
        // @RunMembers(ExampleClass, randObject<ExampleClass>)
    ])
    let overallLib = lib
    overallLib.add(all:o1_fns)
    overallLib.add(all:o2_fns)

    return overallLib
}

main() {
    let lib = getContext()
    // runInContext(None, lib, 100) {
    //     executeRandomly(100)
    // }

    // expectation: two runs should result in the same sequence of functions called: the 
    // calls to the unknown functions `f` are controlled.
    println("comparing two runs of functions:")
    let seed : Option<UInt64> = Some(Random().nextUInt64()) // None // Some(55)
    runInContext(seed, lib, 10) {
        executeUntilDone(@RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], map_))
    }
    println("================================================")
    runInContext(seed, lib, 10) {
        executeUntilDone(@RunRandomly([f in randFunc<Int64, Bool>, ls in randList(5, randInt64)], filter_))
    }
    return 0
}