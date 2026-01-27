package cangjie_experiments

import std.collection.*
import stdx.effect.*

class UnhandledInstance <: Exception {
    public init(msg: String) {
        super(msg)
    }

    public override func getClassName(): String {
        "UnhandledInstance"
    }
}

// UnknownFunction :: A -> B
class UnknownFunction<A, B> <: Command<B> {
    public UnknownFunction(let arg : A) {}
    public func defaultImpl() : B {
        throw UnhandledInstance("UnknownFunction")
    }
}

class BackpocketGenerator<B> <: Command<B> {
    public func defaultImpl() : B {
        throw UnhandledInstance("BackpocketGenerator")
    }
}

func fake<A, B>(a : A): B {
    return perform UnknownFunction<A, B>(a)
}

class GetRandomFn<A, B> <: Command<(A) -> B> {
    public func defaultImpl() : (A) -> B {
        throw UnhandledInstance("GetRandomFn")
    }
}

class GetRandomResumption<X, Y> <: Command<Resumption<X, Y>> {
    public func defaultImpl() : Resumption<X, Y> {
        throw UnhandledInstance("GetRandomResumption")
    }
}

class AddResumption<X, Y> <: Command<Unit> {
    AddResumption(let r: Resumption<X, Y>) {}
    public func defaultImpl() : Unit {
        throw UnhandledInstance("AddResumption")
    }
}

class HasResumption<X, Y> <: Command<Bool> {
    public func defaultImpl(): Bool {
        println("warning: defaultImpl for HasResumption used")
        return false
    }
}

class HasFn<A, B> <: Command<Bool> {
    public func defaultImpl(): Bool {
        println("warning: defaultImpl for HasFn used")
        return false
    }
}

class Arbitrary {
    func sHandle<Y>(fn: () -> Y): Y {
        try {
            fn()
        } handle(_: BackpocketGenerator<Int64>) {
            resume with randSmallInt64()
        } handle(_: BackpocketGenerator<Unit>) {
            resume with ()
        } handle(_: BackpocketGenerator<Bool>) {
            resume with randBool(0.50)
        }
    }
}

/*
// Stash typeclass
class ResStash a where
    AddResumption :: a -> r -> a
    GetRandomResumption :: a -> Gen r
    HasResumption :: a -> Bool
*/
class ResStash<X, Y> {
    let s : List<Resumption<X, Y>> = ArrayList<Resumption<X, Y>>()

    func addResumption(r: Resumption<X, Y>): Unit {
        s.add(r)
    }

    func randomResumption() : Resumption<X, Y> {
        let chosenRIx = randIntRange(0, s.size)
        s.remove(at:chosenRIx)
    }

    func hasResumption() : Bool {
        !s.isEmpty()
    }

    func sHandle<Z>(fn: () -> Z): Z {
        try {
            fn()
        } handle(_: GetRandomResumption<X, Y>) {
            resume with randomResumption()
        } handle(_: HasResumption<X, Y>) {
            resume with hasResumption()
        } handle(e: AddResumption<X, Y>) {
            resume with addResumption(e.r)
        }
    }
}

/*
class FnStash a where
    GetRandomFn :: a -> Gen f
    HasFn :: a -> Bool
*/
class FnStash<A, B> {
    let s : List<(A) -> B> = ArrayList<(A) -> B>()

    func setStash(stash: List<(A) -> B>) {
        for (s_ in stash) { s.add(s_) }
    }

    func randomFunction() : (A) -> B {
        let chosenFIx = randIntRange(0, s.size)
        s.remove(at:chosenFIx)
    }

    func hasFunction() : Bool {
        !s.isEmpty()
    }

    func sHandle<Y>(fn: () -> Y): Y {
        try {
            fn()
        } handle(_: GetRandomFn<A, B>) {
            resume with randomFunction()
        } handle(_: HasFn<A, B>) {
            resume with hasFunction()
        }
    }
}

class Stash_ {
    let intIntFns : FnStash<Int64, Int64> = FnStash<Int64, Int64>()
    let intBoolFns : FnStash<Int64, Bool> = FnStash<Int64, Bool>()
    let intUnitFns : FnStash<Int64, Unit> = FnStash<Int64, Unit>()
    let unitUnitFns : FnStash<Unit, Unit> = FnStash<Unit, Unit>()
    let lintBoolFns : FnStash<List<Int64>, Bool> = FnStash<List<Int64>, Bool>()
    let lintLintFns : FnStash<List<Int64>, List<Int64>> = FnStash<List<Int64>, List<Int64>>()
    let lintOintFns : FnStash<List<Int64>, Option<Int64>> = FnStash<List<Int64>, Option<Int64>>()
    let lintIntFns : FnStash<List<Int64>, Int64> = FnStash<List<Int64>, Int64>()
    let intLintFns : FnStash<Int64, List<Int64>> = FnStash<Int64, List<Int64>>()

    let intIntRes : ResStash<Int64, Int64> = ResStash<Int64, Int64>()
    let unitUnitRes : ResStash<Unit, Unit> = ResStash<Unit, Unit>()
    let intlintRes : ResStash<Int64, List<Int64>> = ResStash<Int64, List<Int64>>()
    let boolIntRes : ResStash<Bool, Int64> = ResStash<Bool, Int64>()
    let boolLintRes : ResStash<Bool, List<Int64>> = ResStash<Bool, List<Int64>>()
    let boolBoolRes : ResStash<Bool, Bool> = ResStash<Bool, Bool>()

    let arb : Arbitrary = Arbitrary()

    func handleStash<Y>(fn: () -> Y): Y {
        // generators for primitive types
        arb.sHandle {
        // functions
        intIntFns.sHandle {
        intBoolFns.sHandle {
        intUnitFns.sHandle {
        unitUnitFns.sHandle {
        lintBoolFns.sHandle {
        lintLintFns.sHandle {
        lintOintFns.sHandle {
        lintIntFns.sHandle {
        intLintFns.sHandle {
        // resumptions
        intIntRes.sHandle {
        unitUnitRes.sHandle {
        intlintRes.sHandle {
        boolIntRes.sHandle {
        boolLintRes.sHandle {
        boolBoolRes.sHandle {
            fn()
        }}}}}}}}}}}}}}}}
    }
}

/* v5: supporting functions of different types to be used in the execution
We need to fill a function A -> B, eventually resuming something that yields Y.
We do either of these things:
    - run a random library function of type A -> B, then a resumption of type B -> Y
    - run a resumption of type A -> Y
    - generate a B, then run a resumption of type B -> Y
potentially also:
    - generate a random type that we have resumptions for, and then resume that resumption
        with our random value.
*/
func fillFunction<A, B, Y>(f: UnknownFunction<A, B>, r: Resumption<B, Y>): Y {
    // stash the current resumption
    perform AddResumption<B, Y>(r) // <B, Y>
    // idea: library fns might have Unknowns too, so those will trigger recursively
    let hasFns = perform HasFn<A, B>()
    let hasPreFs = perform HasFn<A, Y>()
    let hasPreRs = perform HasResumption<A, Y>()
    // POST: !(perform GetResumptions<B, Y>()).isEmpty()

    let path = randBool(0.20)
    println("hasFns=${hasFns}, hasPreRs=${hasPreRs}, path=${path}")
    if (path && hasFns) {
        println("running a new f and resuming a resumption")
        // start a new function, then use post_rs
        let chosenF = perform GetRandomFn<A, B>()
        let chosenR = perform GetRandomResumption<B, Y>()
        let fOut = chosenF(f.arg)
        resume chosenR with fOut
    } else if (hasPreRs) {
        println("skipping handling with a resumption")
        // resume directly from the function inputs
        let chosenR = perform GetRandomResumption<A, Y>()
        resume chosenR with f.arg
    } else if (hasPreFs) {
        println("skipping handling with a function")
        let chosenF = perform GetRandomFn<A, Y>()
        chosenF(f.arg)
    } else {
        println("generating random output and resuming")
        // backup: resume by generating a fresh random argument to r
        let b0 = perform BackpocketGenerator<B>()
        let chosenR = perform GetRandomResumption<B, Y>()
        resume chosenR with b0
    }
}

func handleUnknown<Y>(fn: () -> Y): Y {
    try {
        fn()
    } handle(f: UnknownFunction<Int64, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, Int64>, r: Resumption<Int64, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Int64, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, List<Int64>>, r: Resumption<List<Int64>, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, List<Int64>, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, List<Int64>>, r: Resumption<List<Int64>, Y>) {
        handleUnknown<Y> { fillFunction<Int64, List<Int64>, Y>(f, r) }
    }
}