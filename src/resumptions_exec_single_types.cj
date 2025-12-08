package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

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
    let s: Stash<Int64> = Stash(fns)
    runExtRand(r) {
        runBackpocket {
            handleUnknownSingleType<Int64>(fns, rs, fn)(randSmallInt64())
            // handleStash<Int64, Int64>(s, { i =>
            //     handleUnknownSingleType<Int64>(fn)(i1)
            // })(randSmallInt64())
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

func main_old() {
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