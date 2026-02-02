package cangjie_experiments.misc

import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*
import cangjie_experiments.resumptions.original.*

func runBackpocket<R>(fn: () -> R) {
    try {
        fn()
    } handle(_ : GenRandom<Int64>) {
        resume with randSmallInt64()
    }
}

/* v1: runs functions of type Unit -> Unit
Issues: 
- only runs unit type functions. Only way to get interactions here is through side effects of the 
functions.
*/
func handleUnknownUnit(fns: List<() -> Unit>, rs: List<Resumption<Unit, Unit>>, fn : () -> Unit): Unit {
    try {
        fn()
    } handle(_ : UnknownFunction<Unit, Unit>, r : Resumption<Unit, Unit>) {
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

func executeUnitUnit(fns: List<() -> Unit>) {
    let rs : List<Resumption<Unit, Unit>> = ArrayList<Resumption<Unit, Unit>>()
    handleUnknownUnit(fns, rs) {
        let fn = fns.remove(at:0)
        fn()
    }
}

/* v2: generalisation to single types A -> A. Now functions can interact through passing their input/output 
arguments.
Issues:
- still limited to A -> A types. 
- also requires outside function to be type A -> A (function that wraps the unknown function)
- interpretation of effects is cumbersome: need to keep passing parameters in to the interpretation function
*/
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
            let a0 = perform GenRandom<A>()
            handleUnknownSingleType<A>(fns, rs, { x: A => resume chosenR with x })(a0)
        }
    }
}}

func executeIntInt(fns: List<(Int64) -> Int64>): Int64 {
    let r: Random = Random()
    let rs: List<Resumption<Int64, Int64>> = ArrayList<Resumption<Int64, Int64>>()

    // wrap the lambda `p` around handleResumes deeply
    // func executeP(i: Int64, p: (Int64) -> Int64): (Int64) -> Int64 {
    //     if (i <= 0) {
    //         return p
    //     } else {
    //         return executeP(i-1, handleResume<Int64, Int64, Int64, Int64>(fns, rs, p))
    //     }
    // }

    // return executeP(500, fn)(0)
    let s: Stash = Stash()
    s.intIntFns = fns
    runExtRand(r) {
        runBackpocket {
            handleUnknownSingleType<Int64>(fns, rs, fns[0])(randSmallInt64())
            // handleStash<Int64, Int64>(s, { i =>
            //     handleUnknownSingleType<Int64>(fn)(i1)
            // })(randSmallInt64())
        }
    }
}

/* v3: generalised to general outside function of type X -> Y.
Moreover, we now no longer need to pass in the state-based parameters to track the 
pending resumptions. Instead, we treat those as effects too and handle them outside
using a base-level immediate handler. 
This function only handles the deferred effect (UnknownFunction)
Issues:
- Still only executes inner library functions of type A -> A
*/
func handleUnknownSimplified<X, A, Y>(fn: (X) -> Y) : (X) -> Y {{ a =>
    try {
        fn(a)
    } handle(f: UnknownFunction<A, A>, r: Resumption<A, Y>) {
        perform AddResumption<A, Y>(r)
        let hasFns = perform HasFn<A, A>()

        let path = randBool(0.50)
        if (path && hasFns) {
            let chosenF = perform GetRandomFn<A, A>()
            let chosenR = perform GetRandomResumption<A, Y>()
            let fOut = handleUnknownSimplified<A, A, A>(chosenF)(f.arg)
            handleUnknownSimplified<A, A, Y>({ x: A => resume chosenR with x })(fOut)
        } else {
            let chosenR = perform GetRandomResumption<A, Y>()
            let a0 = perform GenRandom<A>()
            handleUnknownSimplified<A, A, Y>({ x: A => resume chosenR with x })(a0)
        }
    }
}}

/* v4: generalised to arbitrary library calls of type A -> B
Issues:
- sometimes causes seg faults
- sometimes causes internal error
*/
func handleUnknownABType<X, A, B, Y>(fn: (X) -> Y): (X) -> Y {{ x => 
    /*
    requires implementation of:
    - {Add, GetRandom}Resumption<B, Y>
    - {Has, GetRandom}Resumption<A, Y>
    - {Has, GetRandom}Fn<A, B>
    - GenRandom<B>
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
            let fOut = handleUnknownABType<A, A, B, B>(chosenF)(f.arg)
            handleUnknownABType<B, A, B, Y>({ b : B => resume chosenR with b })(fOut)
        } else if (hasPreRs) {
            // resume directly from the function inputs
            let chosenR = perform GetRandomResumption<A, Y>()
            handleUnknownABType<A, A, B, Y>({ a : A => resume chosenR with a })(f.arg)
        } else {
            // backup: resume by generating a fresh random argument to r
            let b0 = perform GenRandom<B>()
            let chosenR = perform GetRandomResumption<B, Y>()
            handleUnknownABType<B, A, B, Y>({ b : B => resume chosenR with b })(b0)
        }
    }
}}

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
func handleStash_old<Y>(s: Stash, fn: () -> Y): Y {
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
    } handle(_: GetRandomResumption<Int64, Int64>) {
        let chosenRIx = randIntRange(0, s.intIntRes.size)
        let chosenR = s.intIntRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: GetRandomResumption<Unit, Unit>) {
        let chosenRIx = randIntRange(0, s.unitUnitRes.size)
        let chosenR = s.unitUnitRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: GetRandomResumption<Int64, List<Int64>>) {
        let chosenRIx = randIntRange(0, s.intlintRes.size)
        let chosenR = s.intlintRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: GetRandomResumption<Bool, Int64>) {
        let chosenRIx = randIntRange(0, s.boolIntRes.size)
        let chosenR = s.boolIntRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: GetRandomResumption<Bool, List<Int64>>) {
        let chosenRIx = randIntRange(0, s.boolLintRes.size)
        let chosenR = s.boolLintRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: GetRandomResumption<Bool, Bool>) {
        let chosenRIx = randIntRange(0, s.boolBoolRes.size)
        let chosenR = s.boolBoolRes.remove(at:chosenRIx)
        resume with chosenR
    } handle(_: HasResumption<Unit, Unit>) {
        resume with s.unitUnitRes.isEmpty()
    } handle(_: HasResumption<Int64, Int64>) {
        resume with s.intIntRes.isEmpty()
    } handle(_: HasResumption<Int64, List<Int64>>) {
        resume with s.intlintRes.isEmpty()
    } handle(_: GetRandomFn<Int64, Int64>) {
        let chosenFIx = randIntRange(0, s.intIntFns.size)
        let chosenF = s.intIntFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(_: GetRandomFn<Unit, Unit>) {
        let chosenFIx = randIntRange(0, s.unitUnitFns.size)
        let chosenF = s.unitUnitFns.remove(at:chosenFIx)
        resume with chosenF
    } handle(_: HasFn<Int64, Int64>) {
        resume with !s.intIntFns.isEmpty()
    } handle(_: HasFn<Unit, Unit>) {
        resume with !s.unitUnitFns.isEmpty()
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


func main_run_resumptions_once() {
    let fns: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>()
    for (i in 0..50) {
        // prepare 100 random functions
        fns.add(fint_add(i))
        fns.add(fint_mul(i))
    }

    let r : Random = Random()
    let s : Stash = Stash()
    s.intIntFns = fns
    runExtRand(r) {
        handleStash_old(s) {
            handleUnknownABType<Int64, Int64, Int64, Int64>(fns[0])(randSmallInt64())
        }
    }
}

