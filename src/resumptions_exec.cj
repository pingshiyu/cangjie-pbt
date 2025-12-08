package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let arg : A) {}
}

class BackpocketGenerator<B> <: Command<B> {}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
}

class GetRandomFn<A, B> <: Command<(A) -> B> {}
class GetRandomResumption<X, Y> <: Command<Resumption<X, Y>> {}
class AddResumption<X, Y> <: Command<Unit> {
    AddResumption(let r: Resumption<X, Y>) {}
}
class HasResumptions<X, Y> <: Command<Bool> {}
class HasFns<A, B> <: Command<Bool> {}

class Stash<Y> {
    var intFns: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    var unitFns: List<(Unit) -> Unit> = ArrayList<(Unit) -> Unit>()
    var intRes: List<Resumption<Int64, Y>> = ArrayList<Resumption<Int64, Y>>()
    var unitRes : List<Resumption<Unit, Y>> = ArrayList<Resumption<Unit, Y>>()

    init(intFns: List<(Int64) -> Int64>) {
        this.intFns = intFns
    }
}

func handleStash<Y>(s: Stash<Y>, fn: () -> Y): Y {
    try {
        fn()
    } handle(e: GetRandomResumption<Int64, Y>) {
        let chosenRIx = randIntRange(0, s.intRes.size)
        let chosenR = s.intRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Unit, Y>) {
        let chosenRIx = randIntRange(0, s.unitRes.size)
        let chosenR = s.unitRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomFn<Int64, Int64>) {
        let chosenFIx = randIntRange(0, s.intFns.size)
        let chosenF = s.intFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: GetRandomFn<Unit, Unit>) {
        let chosenFIx = randIntRange(0, s.unitFns.size)
        let chosenF = s.unitFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: HasFns<Int64, Int64>) {
        resume with !s.intFns.isEmpty()
    } handle(e: HasFns<Unit, Unit>) {
        resume with !s.unitFns.isEmpty()
    } handle(e: AddResumption<Int64, Y>) {
        s.intRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Unit, Y>) {
        s.unitRes.add(e.r)
        resume with ()
    } handle(e: BackpocketGenerator<Int64>) {
        resume with randSmallInt64()
    } handle(e: BackpocketGenerator<Unit>) {
        resume with ()
    }
}

func handleUnknownSimplified<X, A, Y>(fn: (X) -> Y) : (X) -> Y {{ a =>
    try {
        fn(a)
    } handle(f: UnknownFunction<A, A>, r: Resumption<A, Y>) {
        perform AddResumption<A, Y>(r)
        let hasFns = perform HasFns<A, A>()

        let path = randBool(0.50)
        if (path && hasFns) {
            let chosenF = perform GetRandomFn<A, A>()
            let chosenR = perform GetRandomResumption<A, Y>()
            handleUnknownSimplified<A, A, Y>({ x: A => resume chosenR with x })(chosenF(f.arg))
        } else {
            let chosenR = perform GetRandomResumption<A, Y>()
            let a0 = perform BackpocketGenerator<A>()
            handleUnknownSimplified<A, A, Y>({ x: A => resume chosenR with x })(a0)
        }
    }
}}

func handleUnknown<X, A, B, Y>(fn: (X) -> Y): (X) -> Y {{ x => 
    /*
    requires implementation of:
    - GetResumptions<B, Y>
    - GetResumptions<A, Y>
    - GetFns<A, B>
    - BackpocketGenerator<B>
    */
    try {
        fn(x)
    } handle(f: UnknownFunction<A, B>, r: Resumption<B, Y>) {
        // stash the current resumption
        perform AddResumption(r) // <B, Y>
        let hasFns = !(perform HasFns<A, B>())
        let hasPreRs = !(perform HasResumptions<A, Y>())
        // POST: !(perform GetResumptions<B, Y>()).isEmpty()

        let path = randBool(0.50)
        if (path && hasFns) {
            println("got here, starting a random function")
            // start a new function, then use post_rs
            let chosenF = perform GetRandomFn<A, B>()
            let chosenR = perform GetRandomResumption<B, Y>()
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(chosenF(f.arg))
        } else if (hasPreRs) {
            println("got here, resume random resumption")
            // resume directly from the function inputs
            let chosenR = perform GetRandomResumption<A, Y>()
            handleUnknown<A, A, B, Y>({ a : A => resume chosenR with a })(f.arg)
        } else {
            // backup: resume by generating a fresh random argument to r
            println("got here, generate random arg")
            let b0 = perform BackpocketGenerator<B>()
            let chosenR = perform GetRandomResumption<B, Y>()
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(b0)
        }
    } catch (e : UnhandledCommandException) {
        println("exception caught: ${e}")
        throw e
    }
}}

main() {
    // only unit types:
    // let fns: List<() -> Unit> = ArrayList<() -> Unit>([fi(1), fi(2), fi(3), fi(4)])
    // runExtRand(r) {
    //     executeUnitUnit(fns)
    // }

    let fns: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    for (i in 0..50) {
        // prepare 100 random functions
        fns.add(fint_add(i))
        fns.add(fint_mul(i))
    }

    let r : Random = Random()
    let s : Stash<Int64> = Stash<Int64>(fns)
    runExtRand(r) {
        handleStash(s) {
            handleUnknownSimplified<Int64, Int64, Int64>(fns[0])(randSmallInt64())
        }
    } 
}