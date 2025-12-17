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
class HasResumption<X, Y> <: Command<Bool> {}
class HasFn<A, B> <: Command<Bool> {}
class HasFn_ <: Command<Bool> {}

class Stash {
    var intFns : List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    var unitFns : List<(Unit) -> Unit> = ArrayList<(Unit) -> Unit>()
    var lintFns : List<(List<Int64>) -> Bool> = ArrayList<(List<Int64>) -> Bool>()
    var intRes: List<Resumption<Int64, Int64>> = ArrayList<Resumption<Int64, Int64>>()
    var unitRes : List<Resumption<Unit, Unit>> = ArrayList<Resumption<Unit, Unit>>()
    var lintRes : List<Resumption<Int64, List<Int64>>> = ArrayList<Resumption<Int64, List<Int64>>>()

    init(intFns: List<(Int64) -> Int64>) {
        this.intFns = intFns
    }
}

/* This provides all of the implementation for the immediate effects used.
*/
func handleStash<Y>(s: Stash, fn: () -> Y): Y {
    try {
        fn()
    } handle(e: AddResumption<Int64, Int64>) {
        s.intRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Unit, Unit>) {
        s.unitRes.add(e.r)
        resume with ()
    } handle(e: AddResumption<Int64, List<Int64>>) {
        s.lintRes.add(e.r)
        resume with ()
    } handle(e: GetRandomResumption<Int64, Int64>) {
        let chosenRIx = randIntRange(0, s.intRes.size)
        let chosenR = s.intRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Unit, Unit>) {
        let chosenRIx = randIntRange(0, s.unitRes.size)
        let chosenR = s.unitRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: GetRandomResumption<Int64, List<Int64>>) {
        let chosenRIx = randIntRange(0, s.lintRes.size)
        let chosenR = s.lintRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(e: HasResumption<Unit, Unit>) {
        resume with s.unitRes.isEmpty()
    } handle(e: HasResumption<Int64, Int64>) {
        resume with s.intRes.isEmpty()
    } handle(e: HasResumption<Int64, List<Int64>>) {
        resume with s.lintRes.isEmpty()
    } handle(e: GetRandomFn<Int64, Int64>) {
        let chosenFIx = randIntRange(0, s.intFns.size)
        let chosenF = s.intFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: GetRandomFn<Unit, Unit>) {
        let chosenFIx = randIntRange(0, s.unitFns.size)
        let chosenF = s.unitFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(e: HasFn<Int64, Int64>) {
        resume with !s.intFns.isEmpty()
    } handle(e: HasFn<Unit, Unit>) {
        resume with !s.unitFns.isEmpty()
    } handle(e: BackpocketGenerator<Int64>) {
        resume with randSmallInt64()
    } handle(e: BackpocketGenerator<Unit>) {
        resume with ()
    }
}

/* v4: generalised to arbitrary library calls of type A -> B
Issues:
- sometimes causes seg faults
- sometimes causes internal error
*/
func handleUnknown<X, A, B, Y>(fn: (X) -> Y): (X) -> Y {{ x => 
    /*
    requires implementation of:
    - {Add, GetRandom}Resumption<B, Y>
    - {Has, GetRandom}Resumption<A, Y>
    - {Has, GetRandom}Fn<A, B>
    - BackpocketGenerator<B>
    */
    try {
        fn(x)
    } handle(f: UnknownFunction<A, B>, r: Resumption<B, Y>) {
        // stash the current resumption
        perform AddResumption<B, Y>(r) // <B, Y>
        let hasFns = perform HasFn<A, B>()
        let hasPreRs = perform HasResumption<A, Y>()
        // POST: !(perform GetResumptions<B, Y>()).isEmpty()

        let path = randBool(0.20)
        if (path && hasFns) {
            // start a new function, then use post_rs
            let chosenF = perform GetRandomFn<A, B>()
            let chosenR = perform GetRandomResumption<B, Y>()
            let fOut = handleUnknown<A, A, B, B>(chosenF)(f.arg)
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(fOut)
        } else if (hasPreRs) {
            // resume directly from the function inputs
            let chosenR = perform GetRandomResumption<A, Y>()
            handleUnknown<A, A, B, Y>({ a : A => resume chosenR with a })(f.arg)
        } else {
            // backup: resume by generating a fresh random argument to r
            let b0 = perform BackpocketGenerator<B>()
            let chosenR = perform GetRandomResumption<B, Y>()
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(b0)
        }
    }
}}

/* v5: supporting functions of different types to be used in the execution

For function A -> B ... Y.
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
    let hasPreRs = perform HasResumption<A, Y>()
    // POST: !(perform GetResumptions<B, Y>()).isEmpty()

    let path = randBool(0.20)
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
    } else {
        // backup: resume by generating a fresh random argument to r
        let b0 = perform BackpocketGenerator<B>()
        let chosenR = perform GetRandomResumption<B, Y>()
        resume chosenR with b0
    }
}

func handleUnknownGen<Y>(fn: () -> Y): Y {
    try {
        fn()
    } handle(f: UnknownFunction<Int64, Bool>, r: Resumption<Bool, Y>) {
        handleUnknownGen<Y> { fillFunction<Int64, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, Int64>, r: Resumption<Int64, Y>) {
        handleUnknownGen<Y> { fillFunction<Int64, Int64, Y>(f, r) }
    }
}

func main_run_resumptions_once() {
    let fns: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    for (i in 0..50) {
        // prepare 100 random functions
        fns.add(fint_add(i))
        fns.add(fint_mul(i))
    }

    let r : Random = Random()
    let s : Stash = Stash(fns)
    runExtRand(r) {
        handleStash(s) {
            handleUnknown<Int64, Int64, Int64, Int64>(fns[0])(randSmallInt64())
        }
    }
}