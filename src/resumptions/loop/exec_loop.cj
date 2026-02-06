package cangjie_experiments.resumptions.loop

import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.pbt.*
import cangjie_experiments.resumptions.*

class IsDone <: Command<Bool> {}
class SetDone <: Command<Unit> {
    public SetDone(public let s : Bool) {}
}
class StoreV<R> <: Command<Unit> {
    public StoreV(public let s : R) {}
}
class GetV<R> <: Command<R> {}

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

func execute(): Unit {
    handleSwitch {
        let runFunction = randBool(0.50)
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

// ensure we complete the entry function 
public func executeUntilDone<R>(f : () -> R) : R {
    handleSwitch { withMarkers { f() } }
    while (!(perform IsDone())) {
        execute()
    }
    perform GetV<R>()
}

public func executeRandomly(n : Int64) : Unit {
    // a list of callables
    // to turn a function of A -> B into a callable,
    // supply all primitive types A with a generator `GenRandom<A>`
    // supply all function types X -> Y with `replacement<X, Y>`
    // at the end of the function, ignore the return type.
    /* For example:
    f : (X -> Y) -> A -> B
    turns into
    f' () = {
        f(replacement<X, Y>, perform GenRandom<A>)
        return ()
    }
    */
    for (i in 0..n) {
        execute()
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