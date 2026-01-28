package cangjie_experiments

import stdx.effect.*
import std.collection.*

// Unk: effect that takes an A and returns a B
class Unk <: Command<Unit> {}

// GenRandom<X>
class GenRandom<X> <: Command<X> {}

type Res = Resumption<Unit, Unit>

// in place of any f : A -> B, we can use this as replacement<A, B>
func replacement<A, B>(a : A) : B {
    perform Unk()
    return perform GenRandom<B>()
}

class AddRes <: Command<Unit> {
    public AddRes(let r : Res) {}
}
class GetRandomRes <: Command<Res> {}
class HasRes <: Command<Bool> {}

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
    let fns : ArrayList<() -> Unit> = ArrayList<() -> Unit>() // these may produce Unk effects.
    for (i in 0..100) {
        let runFunction = randBool(0.50)
        let hasFunctions = fns.size > 0
        if (runFunction && hasFunctions) {
            let chosenF = randElem(fns)
            chosenF() 
        } else {
            let hasRes = perform HasRes()
            if (!hasRes) {
                continue
            }
            let chosenR = perform GetRandomRes()
            resume chosenR with ()
        }
    }
}

func handleUnk(f : () -> Unit) : Unit {
    try {
        f()
    } handle (e : Unk, r : Res) {
        perform AddResumption(r)
        // resume which resumption to continue execution?
        // we have to resume _something_
        // if we don't... the code will never get past this point :c
    }
}

func mainHarness(): Unit {
    let ress = ArrayList<Res>()
    try {
        handleUnk {
            executor()
        }
    } handle(e: HasRes) {
        resume with (ress.size > 0)
    } handle(e: GetRandomRes) {
        let chosenR = randElem(ress)
        resume with chosenR
    } handle(e: AddRes) {
        ress.add(e.r)
        resume with ()
    }
}