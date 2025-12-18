package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let arg : A) {}
    public func defaultImpl() : B {
        throw Exception("Unhandled instance of UnknownFunction")
    }
}

class BackpocketGenerator<B> <: Command<B> {
    public func defaultImpl() : B {
        throw Exception("Unhandled instance of BackpocketGenerator")
    }
}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
}

class GetRandomFn<A, B> <: Command<(A) -> B> {
    public func defaultImpl() : (A) -> B {
        throw Exception("Unhandled instance of GetRandomFn")
    }
}

class GetRandomResumption<X, Y> <: Command<Resumption<X, Y>> {
    public func defaultImpl() : Resumption<X, Y> {
        throw Exception("Unhandled instance of GetRandomResumption")
    }
}

class AddResumption<X, Y> <: Command<Unit> {
    AddResumption(let r: Resumption<X, Y>) {}
    public func defaultImpl() : Unit {
        throw Exception("Unhandled instance of AddResumption")
    }
}

class HasResumption<X, Y> <: Command<Bool> {
    public func defaultImpl(): Bool {
        return false
    }
}

class HasFn<A, B> <: Command<Bool> {
    public func defaultImpl(): Bool {
        return false
    }
}

class Stash {
    var intIntFns : List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    var intBoolFns : List<(Int64) -> Bool> = ArrayList<(Int64) -> Bool>()
    var unitUnitFns : List<(Unit) -> Unit> = ArrayList<(Unit) -> Unit>()
    var lintBoolFns : List<(List<Int64>) -> Bool> = ArrayList<(List<Int64>) -> Bool>()
    var lintLintFns : List<(List<Int64>) -> List<Int64>> = ArrayList<(List<Int64>) -> List<Int64>>()
    var lintOintFns : List<(List<Int64>) -> Option<Int64>> = ArrayList<(List<Int64>) -> Option<Int64>>()
    var lintIntFns : List<(List<Int64>) -> Int64> = ArrayList<(List<Int64>) -> Int64>()
    var intIntRes: List<Resumption<Int64, Int64>> = ArrayList<Resumption<Int64, Int64>>()
    var unitUnitRes : List<Resumption<Unit, Unit>> = ArrayList<Resumption<Unit, Unit>>()
    var intlintRes : List<Resumption<Int64, List<Int64>>> = ArrayList<Resumption<Int64, List<Int64>>>()
    var boolIntRes : List<Resumption<Bool, Int64>> = ArrayList<Resumption<Bool, Int64>>()
    var boolLintRes : List<Resumption<Bool, List<Int64>>> = ArrayList<Resumption<Bool, List<Int64>>>()
    var boolBoolRes : List<Resumption<Bool, Bool>> = ArrayList<Resumption<Bool, Bool>>()
}

/* This provides all of the implementation for the immediate effects used.
*/
func handleStash<Y>(s: Stash, fn: () -> Y): Y {
    try {
        fn()
    } handle(e: AddResumption<Int64, Int64>) {
        s.intIntRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Unit, Unit>) {
        s.unitUnitRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Int64, List<Int64>>) {
        s.intlintRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Bool, Int64>) {
        s.boolIntRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Bool, List<Int64>>) {
        s.boolLintRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Bool, Bool>) {
        s.boolBoolRes.add(e.r)
        resume with ()
    } handle(e: GetRandomResumption<Int64, Int64>) {
        let chosenRIx = randIntRange(0, s.intIntRes.size)
        let chosenR = s.intIntRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Unit, Unit>) {
        let chosenRIx = randIntRange(0, s.unitUnitRes.size)
        let chosenR = s.unitUnitRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Int64, List<Int64>>) {
        let chosenRIx = randIntRange(0, s.intlintRes.size)
        let chosenR = s.intlintRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Bool, Int64>) {
        let chosenRIx = randIntRange(0, s.boolIntRes.size)
        let chosenR = s.boolIntRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Bool, List<Int64>>) {
        let chosenRIx = randIntRange(0, s.boolLintRes.size)
        let chosenR = s.boolLintRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Bool, Bool>) {
        let chosenRIx = randIntRange(0, s.boolBoolRes.size)
        let chosenR = s.boolBoolRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: HasResumption<Unit, Unit>) {
        resume with s.unitUnitRes.isEmpty()
    } handle(e: HasResumption<Int64, Int64>) {
        resume with s.intIntRes.isEmpty()
    } handle(e: HasResumption<Int64, List<Int64>>) {
        resume with s.intlintRes.isEmpty()
    } handle(e: GetRandomFn<Int64, Int64>) {
        let chosenFIx = randIntRange(0, s.intIntFns.size)
        let chosenF = s.intIntFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: GetRandomFn<Unit, Unit>) {
        let chosenFIx = randIntRange(0, s.unitUnitFns.size)
        let chosenF = s.unitUnitFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: HasFn<Int64, Int64>) {
        resume with !s.intIntFns.isEmpty()
    } handle(e: HasFn<Unit, Unit>) {
        resume with !s.unitUnitFns.isEmpty()
    } handle(e: BackpocketGenerator<Int64>) {
        resume with randSmallInt64()
    } handle(e: BackpocketGenerator<Unit>) {
        resume with ()
    } handle(e: BackpocketGenerator<Bool>) {
        resume with randBool(0.50)
    }
}

/* v5: supporting functions of different types to be used in the execution
We need to fill a function A -> B, eventually resuming something that yields Y.
We do either of these things:
    - run a random library function of type A -> B, then a resumption of type B -> Y
    - run a resumption of type A -> Y
    - generate a B, then run a resumption of type B -> Y
potentially also:
    - generate a random type that we have resumptions for, and then resume that resumption
        with our random value
*/
func fillFunction<A, B, Y>(f: UnknownFunction<A, B>, r: Resumption<B, Y>): Y {
    // stash the current resumption
    perform AddResumption<B, Y>(r) // <B, Y>
    // idea: library fns might have Unknowns too, so those will trigger recursively
    let hasFns = perform HasFn<A, B>()
    let hasPreFs = perform HasFn<A, Y>()
    let hasPreRs = perform HasResumption<A, Y>()
    // POST: !(perform GetResumptions<B, Y>()).isEmpty()

    let path = randBool(0.20)
    println("hasFns=${hasFns}, hasPreRs=${hasPreRs}, path=${path}")
    if (path && hasFns) {
        // start a new function, then use post_rs
        let chosenF = perform GetRandomFn<A, B>()
        let chosenR = perform GetRandomResumption<B, Y>()
        let fOut = chosenF(f.arg)
        resume chosenR with fOut
    } else if (hasPreRs) {
        // resume directly from the function inputs
        let chosenR = perform GetRandomResumption<A, Y>()
        resume chosenR with f.arg
    } else if (hasPreFs) {
        let chosenF = perform GetRandomFn<A, Y>()
        chosenF(f.arg)
    } else {
        // backup: resume by generating a fresh random argument to r
        let b0 = perform BackpocketGenerator<B>()
        let chosenR = perform GetRandomResumption<B, Y>()
        resume chosenR with b0
    }
}

func handleUnknown<Y>(fn: () -> Y): Y {
    try {
        fn()
    } handle(f: UnknownFunction<Int64, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, Int64>, r: Resumption<Int64, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Int64, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, List<Int64>>, r: Resumption<List<Int64>, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, List<Int64>, Y>(f, r) }
    }
}