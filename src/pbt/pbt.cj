package cangjie_experiments.pbt

import stdx.effect.*
import std.random.*

class WrongArgumentException <: Exception {
    public WrongArgumentException(_: String) {}
}

type RUnit = Int8

// outputs a number in range [-128, 127]
class Rand <: Command<RUnit> {}

// randomness effect, allows for injection of randomness externally
public func rand() : RUnit {
    perform Rand()
}

// indicate we ran out of randomness:
// gives option to either error or do something else
// like undo the last change during reduction
// OutOfRand :: (() -> R) -> m R
class OutOfRand <: Command<Unit> {
    public OutOfRand() {}
}

public func handleOutOfRandAsError<R>(fn: () -> R) : R {
    try { fn() } handle(_ : OutOfRand) {
        throw WrongArgumentException("Out of random bits!")
    }
}

// unions of all the generateable pure values
public enum Value {
    | BoolV(Bool)
    | I64V(Int64)
    | I8V(Int8)
}

public func showValue(v : Value) : String {
    match (v) {
        case BoolV(b) => b.toString() + " : i1"
        case I64V(i) => i.toString() + " : i64"
        case I8V(i) => i.toString() + " : i8"
    }
}

public func createValue(v : Bool) : Option<Value> {
    return BoolV(v)
}

public func createValue(v : Int64) : Option<Value> {
    return I64V(v)
}

public func createValue(v : Int8) : Option<Value> {
    return I8V(v)
}

public func createValue<R>(_ : R) : Option<Value> {
    return None
}


// Enter/exit scopes of generation. Relates RUnits together.
class EnterScope <: Command<Unit> {
    public EnterScope(let label : String) {}
}
// future: can maybe add the generated value to the effect
class ExitScope <: Command<Unit> {
    public ExitScope(let gv : ?Value) {}
} 

public func withScope<R>(fnName : String, fn : () -> R) : R {
    perform EnterScope(fnName)
    let rv = fn()
    let storeVal : Option<Value> = createValue(rv)
    perform ExitScope(storeVal)
    return rv
}

public func interpExtRand<R>(rs: Random, fn : () -> R) : R {
    try {
        fn()
    } handle(_ : Rand) {
        resume with rs.nextInt8()
    }
}

public func ignoreScope<R>(fn : () -> R) : R {
    try {
        fn()
    } handle(_ : EnterScope) {
        resume
    } handle(_ : ExitScope) {
        resume
    }
}

public func runExtRand<R>(r: Random, fn : () -> R) : R {
    ignoreScope { interpExtRand(r, fn) }
}