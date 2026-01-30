package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.define.*

/*
Todo:
- Turn library functions into ones that uses Unk
- Try running a library of functions
- Running functions that requires a state (part of an object) 
- make private fns public, and run them
*/

// Unk: effect that takes an A and returns a B
class Unk <: Command<Unit> {}

type Res = Resumption<Unit, Unit>
type UnitFn = () -> Unit

class AddRes <: Command<Unit> {
    public AddRes(let r : Res) {}
}
class GetRandomRes <: Command<Res> {}
class HasRes <: Command<Bool> {}
class GetRandomUnitFn <: Command<() -> Unit> {}

func executor() : Unit {
    // a list of callables
    // to turn a function of A -> B into a callable,
    // supply all primitive types A with a generator `GenRandom<A>`
    // supply all function types X -> Y with `replacement<X, Y>`
    // at the end of the function, ignore the return type.
    /*
        For example:
        f : (X -> Y) -> A -> B
        turns into
        f' () = {
            f(replacement<X, Y>, perform GenRandom<A>)
            return ()
        }
    */
    for (i in 0..100) {
        handleUnk {
            let runFunction = randBool(0.50)
            let hasResumptions = perform HasRes()
            if (runFunction) {
                // println("running a function")
                let chosenF = perform GetRandomUnitFn()
                chosenF()
            } else if (hasResumptions) {
                // println("running a resumption")
                let chosenR = perform GetRandomRes()
                resume chosenR with ()
            } else {
                println("WARNING: no resumptions, didn't choose to run a function. skipping")
            }
        }
    }
}

// in place of any f : A -> B, we can use this as randFunc()
func randFunc<A, B>(): (A) -> B {{ a => 
    perform Unk()
    return perform GenRandom<B>()
}}

func handleUnk(f : UnitFn) : Unit {
    try {
        f()
    } handle (e : Unk, r : Res) {
        perform AddRes(r)
    }
}

func ignoreOutput<B>(f : () -> B): () -> Unit {{ =>
    perform Unk()
    let b = f()
    return ()
}}

func mainHarness(library: List<UnitFn>): Unit {
    let r = Random()
    let arb = Arbitrary()
    let ress = ArrayList<Res>()
    
    runExtRand(r) { arb.sHandle {
        try {
            executor()
        } handle(e: HasRes) {
            resume with (ress.size > 0)
        } handle(e: GetRandomRes) {
            let chosenRIx = randIntRange(0, ress.size)
            resume with ress.remove(at:chosenRIx)
        } handle(e: AddRes) {
            ress.add(e.r)
            resume with ()
        } handle(e: GetRandomUnitFn) {
            let chosenRIx = randIntRange(0, library.size)
            resume with library[chosenRIx]
        }
    }}
}