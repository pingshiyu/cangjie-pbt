package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let a : A) {}
}

class BackpocketGenerator<B> <: Command<B> {}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
}

func handleResumeSingleType<A>(fns: List<(A) -> A>, rs: List<Resumption<A, A>>, fn: (A) -> A, a_0: A): (A) -> A {{ a =>
    try {
        fn(a)
    } handle(f: UnknownFunction<A, A>, r: Resumption<A, A>) {
        rs.add(r)
        let chosenRIx = randIntRange(0, rs.size)
        let chosenR = rs.remove(at:chosenRIx)

        let path = randBool(0.25)
        if (path) {
            let chosenFIx = randIntRange(0, fns.size)
            let chosenF = fns[chosenFIx]
            handleResumeSingleType(fns, rs, { x=> resume chosenR with x }, a_0)(chosenF(f.a))
        } else {
            // let b = perform BackpocketGenerator<A>()
            handleResumeSingleType(fns, rs, { x=> resume chosenR with x }, a_0)(a_0)
        }
    }
}}

func handleResume<X, A, B, Y>(fns: List<(A) -> B>, rs: List<Resumption<B, Y>>, fn: (X) -> Y): (X) -> Y {{ x => 
    try {
        fn(x)
    } handle(f: UnknownFunction<A, B>, r: Resumption<B, Y>) {
        // save the resumption r into the list of possible calls
        rs.add(r)
        let chosenRIx = randIntRange(0, rs.size)
        let chosenR = rs.remove(at:chosenRIx)

        // our job: resume a resumption of type B -> Y.
        // For this we need to obtain a value of type B:
        // - either call one of fns and use the return value there, or
        // - generate a value of type B and use that.
        let path = randBool(0.10)
        if (path) {
            let chosenFIx = randIntRange(0, fns.size)
            let chosenF = fns[chosenFIx]
            resume chosenR with chosenF(f.a)
        } else {
            let b = perform BackpocketGenerator<B>()
            // may emit more UnknownFunctions, which will be captured by higher-level
            // handlers
            resume chosenR with b
        }
    } handle(b: BackpocketGenerator<Int64>) {
        let chosenInt = randSmallInt64()
        resume with chosenInt
    }
}}

func executeIntInt(fns: List<(Int64) -> Int64>): Int64 {
    let rs: List<Resumption<Int64, Int64>> = ArrayList<Resumption<Int64, Int64>>()
    let fn = fns[0]

    // wrap the lambda `p` around handleResumes deeply
    func executeP(i: Int64, p: (Int64) -> Int64): (Int64) -> Int64 {
        if (i <= 0) {
            return p
        } else {
            return executeP(i-1, handleResume<Int64, Int64, Int64, Int64>(fns, rs, p))
        }
    }

    // return executeP(500, fn)(0)\
    return handleResumeSingleType<Int64>(fns, rs, fn, 1)(0)
}

func handleResume(fns: List<() -> Unit>, rs: List<Resumption<Unit, Unit>>, fn : () -> Unit): Unit {
    try {
        fn()
    } handle(f : UnknownFunction<Unit, Unit>, r : Resumption<Unit, Unit>) {
        // either resume an existing resumption, or start a function in the list
        rs.add(r)

        let path = randBool(0.50)
        if (path && !fns.isEmpty()) {
            let chosenFnIx = randIntRange(0, fns.size)
            // println("chosen fn ${chosenFnIx}, total size ${fns.size}")
            let chosenFn = fns.remove(at:chosenFnIx)
            handleResume(fns, rs) {
                chosenFn()
            }
        } else {
            // resume a random existing continuation
            let chosenRIx = randIntRange(0, rs.size)
            // println("chosen rs ${chosenRIx}, total size ${rs.size}")
            let chosenR = rs.remove(at:chosenRIx)
            handleResume(fns, rs) {
                resume chosenR
            }
        }
    }
}

func execute(fns: List<() -> Unit>) {
    let rs : List<Resumption<Unit, Unit>> = ArrayList<Resumption<Unit, Unit>>()
    handleResume(fns, rs) {
        let fn = fns.remove(at:0)
        fn()
    }
}

main() {
    let r: Random = Random()
    // let fns: List<() -> Unit> = ArrayList<() -> Unit>([fi(1), fi(2), fi(3), fi(4)])
    // runExtRand(r) {
    //     execute(fns)
    // }

    let fns: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>(
        [fint_add(1), fint_mul(2), fint_add(3), fint_mul(4), fint_add(5), fint_mul(6)])
    runExtRand(r) {
        executeIntInt(fns)
    }
}

func fint_add(a: Int64): (Int64) -> Int64 {{ i =>
    println("fadd${a}: 1, ${i}")
    let i0 = perform UnknownFunction<Int64, Int64>(i)
    println("fadd${a}: 2, ${i0}")
    let i1 = perform UnknownFunction<Int64, Int64>(i0)
    println("fadd${a}: 3, ${i1}")
    let i2 = perform UnknownFunction<Int64, Int64>(i1)
    println("fadd${a}: 4, ${i2}")
    let i3 = perform UnknownFunction<Int64, Int64>(i2)
    println("fadd${a}: 5, ${i3}")
    let i4 = perform UnknownFunction<Int64, Int64>(i3)
    return i + i4
}}

func fint_mul(a: Int64): (Int64) -> Int64 {{ i => 
    println("fmul${a}: 1, ${i}")
    let i0 = perform UnknownFunction<Int64, Int64>(i)
    println("fmul${a}: 2, ${i0}")
    let i1 = perform UnknownFunction<Int64, Int64>(i0)
    println("fmul${a}: 3, ${i1}")
    let i2 = perform UnknownFunction<Int64, Int64>(i1)
    println("fmul${a}: 4, ${i2}")
    let i3 = perform UnknownFunction<Int64, Int64>(i2)
    println("fmul${a}: 5, ${i3}")
    let i4 = perform UnknownFunction<Int64, Int64>(i3)
    return i * i4
}}

func fi(i : Int64): () -> Unit {{ =>
    println("f${i}: 1")
    perform UnknownFunction<Unit, Unit>(())
    println("f${i}: 2")
    perform UnknownFunction<Unit, Unit>(())
    println("f${i}: 3")
    perform UnknownFunction<Unit, Unit>(())
    println("f${i}: 4")
    perform UnknownFunction<Unit, Unit>(())
    println("f${i}: 5")
    perform UnknownFunction<Unit, Unit>(())
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