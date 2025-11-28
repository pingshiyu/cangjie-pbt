package cangjie_experiments

import stdx.effect.*
import std.collection.*

// Assume UnknownUnitFunction :: Unit -> Unit
class UnknownUnitFunction <: Command<Unit> {}

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let a : A) {}
}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
}

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

// what to do:
// start with 2 functions
// unknowns gets replaced by effects
// continuations gets stored 
// rerun randomly

// initially we just do unit->unit continuations
// and then we try to track the types and run the correct one

// perhaps then we can follow the deduction rules to get the 
// correct spec for execution?