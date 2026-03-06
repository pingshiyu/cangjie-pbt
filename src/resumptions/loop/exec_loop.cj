package cangjie_experiments.resumptions.loop

import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.pbt.*
import cangjie_experiments.resumptions.*

/** Runs the property-based test body `f` within a randomized execution context.
 *
 * Parameters:
 *   - seed: Random seed for reproducibility. `Some(n)` uses a fixed seed for deterministic,
 *     replayable runs (useful for debugging or reproducing failures). `None` uses a fresh
 *     random seed each run for broader exploration.
 *   - lib: Library of executable units (effectful functions) that the PBT framework can
 *     inject when the tested code performs external effects (e.g. Switch, GetRandomUnitFn).
 *     Each element is a function the framework may randomly choose to run—e.g. net operations,
 *     fs operations, or abstract "unknown" functions in differential testing.
 *   - f0: Initial fuel count. Fuel limits how many external calls (GetRandomUnitFn,
 *     RunFunction) can be made before the run is forced to stop. Each such operation
 *     consumes one unit of fuel. When fuel reaches zero, no new external calls are started.
 *     This bounds exploration depth to prevent infinite loops during random testing.
 */
func runInContext(seed: Option<UInt64>, lib: List<UnitFn>, f0: Int64, f : () -> Unit) : Unit {
    let r = match (seed) {
        case Some(s) => Random(s)
        case None => Random()
    }
    let arb = ArbitraryGen()
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
        } handle(e: GetRandom) {
            resume with r
        }
    }}}}
}

public func withMarkers<R>(f : () -> R): Unit {
    perform SetDone(false)
    let retVal = f()
    perform SetDone(true)
    perform StoreV<R>(retVal)
}

public func handleStateV<R>(r0 : R, f : () -> R): R {
    let s : Box<R> = Box(r0)
    let done : Box<Bool> = Box(false)
    try {
        f()
    } handle(e: GetV<R>) {
        resume with s.value
    } handle(e: StoreV<R>) {
        s.value = e.s
        resume with ()
    } handle(e: SetDone) {
        done.value = e.s
        resume with ()
    } handle(e: IsDone) {
        resume with done.value
    }
}

public func handleFuel<R>(f0 : Int64, f : () -> R): R {
    let fuel = Box<Int64>(f0)
    try {
        f()
    } handle(e: SetFuel) {
        fuel.value = e.f
        resume with ()
    } handle(e: HasFuel) {
        resume with fuel.value > 0
    } handle(e: ConsumeFuel) {
        fuel.value -= 1
        resume with ()
    } handle(e: RunFunction) {
        if (fuel.value > 0) {
            resume with randBool(e.p)
        } else {
            resume with false
        }
    }
}

func execute(p : Float64): Unit {
    handleSwitch {
        let runFunction = perform RunFunction(p)
        let hasResumptions = perform HasRes()
        if (runFunction) {
            // println("starting a new function")
            let chosenF = perform GetRandomUnitFn()
            chosenF()
        } else if (hasResumptions) {
            // println("resuming a resumption")
            let chosenR = perform GetRandomRes()
            resume chosenR with ()
        } else {
            println("WARNING: no resumptions, didn't choose to run a function. skipping")
        }
    }
}

/*
Ensures that the entry function `f` is executed until it terminates.
Input `n` controls the maximum number of parallel function calls created.
Larger `n` means longer execution time.
*/
public func executeUntilDone<R>(f : () -> R) : R {
    handleSwitch { withMarkers { f() } }
    while (!(perform IsDone())) {
        execute(0.50)
    }
    perform GetV<R>()
}

public func executeRandomly(iters : Int64) : Unit {
    for (i in 0..iters) {
        execute(0.50)
    }
}

// given 2 functions f, g :: (A -> B) -> C
// check for equivalence, i.e. for all functions p,
// f(p) = g(p)
// need to ensure that the p :: (A -> B) used is always the same.
// firstly, if p is not called in the same order then we wouldn't assume
// them to be the same. So we need to guarantee:
// for the ith call of p, the output is the same.
// that is, the random choices made within the framework is the same.
// need to: 
// - track random choices made during each function call
// - replay the random choices made
// - (optional) ignore the random choices made by the function itself
// but first, see if we just get the same results by fixing the random seed
// this should work for determinisitic functions?

// the randomness should be consumed by the context

/*
Differential testing
 Randomly executing test suite
 \- need to record down the choices made (or maybe just use the random seed?)
Execution of a class's functions that's marked by @LibMember, or change the semantics of @Test based
 on the overall tag on the class.
*/

public func differntialTest<R>(seed: Int64, f: () -> R, g: () -> R): Bool where R <: Equal<R> {
    // execute both functions within the same context
    return true
}

// in place of any f : A -> B, we can use this as randFunc()
public func randFunc<A, B>(): (A) -> B {{ a => 
    perform Switch()
    return perform GenRandom<B>()
}}

public func handleSwitch(f : UnitFn) : Unit {
    try {
        f()
    } handle (e : Switch, r : Res) {
        perform AddRes(r)
    }
}

public func ignoreOutput<B>(f : () -> B): () -> Unit {{ =>
    let b = f()
    return ()
}}