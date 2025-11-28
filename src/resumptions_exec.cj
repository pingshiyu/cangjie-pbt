package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let a : A) {}
}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
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
    let fns: List<() -> Unit> = ArrayList<() -> Unit>([fi(1), fi(2), fi(3), fi(4)])
    runExtRand(r) {
        execute(fns)
    }
}

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