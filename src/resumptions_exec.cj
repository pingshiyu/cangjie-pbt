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

func runBackpocket<R>(fn: () -> R) {
    try {
        fn()
    } handle(bg : BackpocketGenerator<Int64>) {
        resume with randSmallInt64()
    }
}

func handleUnknownUnit(fns: List<() -> Unit>, rs: List<Resumption<Unit, Unit>>, fn : () -> Unit): Unit {
    try {
        fn()
    } handle(f : UnknownFunction<Unit, Unit>, r : Resumption<Unit, Unit>) {
        // either resume an existing resumption, or start a function in the list
        rs.add(r)

        let path = randBool(0.50)
        if (path && !fns.isEmpty()) {
            let chosenFnIx = randIntRange(0, fns.size)
            let chosenFn = fns.remove(at:chosenFnIx)
            handleUnknownUnit(fns, rs) {
                chosenFn()
            }
        } else {
            // resume a random existing continuation
            let chosenRIx = randIntRange(0, rs.size)
            let chosenR = rs.remove(at:chosenRIx)
            handleUnknownUnit(fns, rs) {
                resume chosenR
            }
        }
    }
}

func handleUnknownSingleType<A>(fns: List<(A) -> A>, rs: List<Resumption<A, A>>, fn: (A) -> A): (A) -> A {{ a =>
    try {
        fn(a)
    } handle(f: UnknownFunction<A, A>, r: Resumption<A, A>) {
        rs.add(r)

        let path = randBool(0.50)
        if (path && !fns.isEmpty()) {
            let chosenFIx = randIntRange(0, fns.size)
            let chosenF = fns.remove(at:chosenFIx)
            handleUnknownSingleType<A>(fns, rs, chosenF)(f.arg)
        } else {
            let chosenRIx = randIntRange(0, rs.size)
            let chosenR = rs.remove(at:chosenRIx)
            let a0 = perform BackpocketGenerator<A>()
            handleUnknownSingleType<A>(fns, rs, { x: A => resume chosenR with x })(a0)
        }
    }
}}

class GetFns<A, B> <: Command<List<(A) -> B>> {}
class GetResumptions<X, Y> <: Command<List<Resumption<X, Y>>> {}
class AddResumption<X, Y> <: Command<Unit> {
    AddResumption(let r: Resumption<X, Y>) {}
}

func handleUnknown<X, A, B, Y>(fn: (X) -> Y): (X) -> Y {{ x => 
    try {
        fn(x)
    } handle(f: UnknownFunction<A, B>, r: Resumption<B, Y>) {
        // stash the current resumption
        AddResumption(r) // <B, Y>
        let hasFns = !(perform GetFns<A, B>()).isEmpty()
        let hasPreRs = !(perform GetResumptions<A, Y>()).isEmpty()
        // POST: !(perform GetResumptions<B, Y>()).isEmpty()

        let path = randBool(0.50)
        if (path && hasFns) {
            // start a new function, then use post_rs
            let chosenF = randElem<(A) -> B>(perform GetFns<A, B>())
            let chosenR = randElem<Resumption<B, Y>>(perform GetResumptions<B, Y>())
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(chosenF(f.arg))
        } else if (hasPreRs) {
            // resume directly from the function inputs
            let chosenR = randElem<Resumption<A, Y>>(perform GetResumptions<A, Y>())
            handleUnknown<A, A, B, Y>({ a : A => resume chosenR with a })(f.arg)
        } else {
            // backup: resume by generating a fresh random argument to r
            let b0 = perform BackpocketGenerator<B>()
            let chosenR = randElem<Resumption<B, Y>>(perform GetResumptions<B, Y>())
            handleUnknown<B, A, B, Y>({ b : B => resume chosenR with b })(b0)
        }
    }
}}

func executeIntInt(fns: List<(Int64) -> Int64>): Int64 {
    let r: Random = Random()
    let rs: List<Resumption<Int64, Int64>> = ArrayList<Resumption<Int64, Int64>>()
    let fn = fns[0]

    // wrap the lambda `p` around handleResumes deeply
    // func executeP(i: Int64, p: (Int64) -> Int64): (Int64) -> Int64 {
    //     if (i <= 0) {
    //         return p
    //     } else {
    //         return executeP(i-1, handleResume<Int64, Int64, Int64, Int64>(fns, rs, p))
    //     }
    // }

    // return executeP(500, fn)(0)
    runExtRand(r) {
        runBackpocket { 
            handleUnknownSingleType<Int64>(fns, rs, fn)(randSmallInt64())
        }
    } 
}

func executeUnitUnit(fns: List<() -> Unit>) {
    let rs : List<Resumption<Unit, Unit>> = ArrayList<Resumption<Unit, Unit>>()
    handleUnknownUnit(fns, rs) {
        let fn = fns.remove(at:0)
        fn()
    }
}

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
    executeIntInt(fns)
}

func fint_add(a: Int64): (Int64) -> Int64 {{ i =>
    println("fadd${a}: 1, ${i}")
    let i0 = fake<Int64, Int64>(i)
    println("fadd${a}: 2, ${i0}")
    let i1 = fake<Int64, Int64>(i0)
    println("fadd${a}: 3, ${i1}")
    let i2 = fake<Int64, Int64>(i1)
    println("fadd${a}: 4, ${i2}")
    let i3 = fake<Int64, Int64>(i2)
    println("fadd${a}: 5, ${i3}")
    let i4 = fake<Int64, Int64>(i3)
    println("fadd${a}: return ${i} + ${i4}")
    return i + i4
}}

func fint_mul(a: Int64): (Int64) -> Int64 {{ i => 
    println("fmul${a}: 1, ${i}")
    let i0 = fake<Int64, Int64>(i)
    println("fmul${a}: 2, ${i0}")
    let i1 = fake<Int64, Int64>(i0)
    println("fmul${a}: 3, ${i1}")
    let i2 = fake<Int64, Int64>(i1)
    println("fmul${a}: 4, ${i2}")
    let i3 = fake<Int64, Int64>(i2)
    println("fmul${a}: 5, ${i3}")
    let i4 = fake<Int64, Int64>(i3)
    println("fmul${a}: return ${i} * ${i4}")
    return i * i4
}}

func fi(i : Int64): () -> Unit {{ =>
    println("f${i}: 1")
    fake<Unit, Unit>(())
    println("f${i}: 2")
    fake<Unit, Unit>(())
    println("f${i}: 3")
    fake<Unit, Unit>(())
    println("f${i}: 4")
    fake<Unit, Unit>(())
    println("f${i}: 5")
    fake<Unit, Unit>(())
}}

// what to do:
// start with 2 functions
// unknowns gets replaced by effects
// continuations gets stored 
// rerun randomly

// initially we just do unit->unit continuations
// and then we try to track the types and run the correct one

// perhaps then we can follow the deduction rules to get the 
// correct spec for execution?

func mapE<A, B>(f : (A) -> B, ls : List<A>): List<B> {
    let oElems: List<B> = ArrayList<B>()
    for (e in ls) {
        oElems.add(f(e))
    }
    return oElems
}

func map2E<A, B>(f : (A) -> B, ls : List<A>): List<B> {
    let oElems: List<B> = ArrayList<B>()
    let i : Int64 = 0
    for (e in ls) {
        if (i % 2 == 0) {
            continue // introduced bug: this skips every other element
        }
        oElems.add(f(e))
    }
    return oElems
}

func filterE<A>(f : (A) -> Bool, ls : List<A>): List<A> {
    let oElems: List<A> = ArrayList<A>()
    for (e in ls) {
        if (f(e)) {
            oElems.add(e)
        }
    }
    return oElems
}