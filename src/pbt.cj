package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.math.*

type RUnit = Int8

// outputs a number in range [-128, 127]
class Rand <: Command<RUnit> {}

// unions of all the generateable pure values
enum Value {
    | BoolV(Bool)
    | I64V(Int64)
    | I8V(Int8)
}

func showValue(v : Value) : String {
    match (v) {
        case BoolV(b) => b.toString() + " : i1"
        case I64V(i) => i.toString() + " : i64"
        case I8V(i) => i.toString() + " : i8"
    }
}

// func createValue<R>(v : R) : Option<Value> {
//     let ti = TypeInfo.of<R>()
//     if (ti == TypeInfo.of<Bool>()) {
//         return Some(BoolV(v))
//     } else if (ti == TypeInfo.of<Int64>()) {
//         return Some(I64V(Int64(v)))
//     } else if (ti == TypeInfo.of<Int8>()) {
//         return Some(I8V(Int8(v)))
//     } else {
//         return None
//     }
// }

// Enter/exit scopes of generation. Relates RUnits together.
class EnterScope <: Command<Unit> {
    public EnterScope(let label : String) {}
}
// future: can maybe add the generated value to the effect
class ExitScope <: Command<Unit> {
    public ExitScope(let gv : ?Value) {}
} 

func withScope<R>(fnName : String, fn : () -> R) : R {
    perform EnterScope(fnName)
    let rv = fn()
    // let storeVal : Option<Value> = createValue(rv)
    perform ExitScope(None)
    return rv
}


// randomness effect, allows for injection of randomness externally
func rand() : RUnit {
    perform Rand()
}

func randBool(): Bool { 
withScope("randBool()", { => 
    let i = rand()
    let v = i > 0
    return v // such that reductions towards 0 => turns this false
})}

func randInt64() : Int64 { 
withScope("randInt64()", { =>
    // Int64 consists of 8 consecutive bytes from the randomness list
    let vs : List<RUnit> = ArrayList<RUnit>()
    for (_ in 0..8) { vs.add(rand()) }
    var finalVal : Int64 = 0
    for (i in 0..8) {
        // interpret int in big-endian form
        finalVal += Int64(vs[7-i]) * 2**UInt64(8*i)
    }
    return finalVal
})}

func randNat(): List<UInt64> { 
withScope("randNat()", { =>
    // pick a random natural number
    let ns : ArrayList<UInt64> = ArrayList<UInt64>()
    var keepGoing : Bool = false
    do {
        ns.add(UInt64(perform Rand()))
        keepGoing = randBool()
    } while (keepGoing)
    
    // final value is \sum (2^(4i) * ns[i])
    return ns
})}

func randIntRange(begin : Int64, end : Int64) : Int64 { 
withScope("randIntRange(" + begin.toString() + ", " + end.toString() + ")", { => 
    // int in range [begin, end)
    let range = end - begin
    let chosenInt = abs(randInt64())
    let width = chosenInt % range
    let v = begin + width
    return v
})}

// generate a list of n numbers, with n randomly chosen.
func randIntList() : List<Int64> {
withScope("randIntList()", { =>
    let n : Int64 = abs(randInt64())
    let l : List<Int64> = ArrayList<Int64>()
    for (_ in 0..n) {
        let x : Int64 = Int64(rand())
        l.add(x)
    }
    return l
})}

func pop<T>(al : List<T>) : T {
    let rv = al[0]
    al.remove(0..1)
    return rv
}

// basic interpreter of randomness. 
// consumes a little bit of the random list
func interpRand<R>(rl : List<RUnit>, fn : () -> R) : R {
    try {
        fn ()
    } handle(_ : Rand) {
        if (rl.isEmpty()) {
            throw Exception("out of randomness!")
        }
        let x = pop(rl)
        resume with x
    }
}

// FUTURE: create type CompleteRandTree 
// to denote that the randomtree can no longer be modified (if its scope
//  has been closed)
// when interpreting randomness, also store the sequence in some structure
// this is so that we can do reductions in the future
// PRNG that is used together in a call are stored in the same node
class RandTree {
    // node -> n children
    let label : ?String
    let node : List<RUnit> 
    let children : List<RandTree>
    let parent : ?RandTree
    var genVal : ?Value
    
    public RandTree(l: ?String, p : ?RandTree) {
        label = l
        node = ArrayList<RUnit>()
        children = ArrayList<RandTree>()
        parent = p
        genVal = None
    }

    public func addR(r: RUnit): Unit {
        node.add(r)
    }

    public func newScope(l : ?String) : RandTree {
        let nt = RandTree(l, Some(this))
        this.children.add(nt)
        return nt
    }

    public func closeScope(gv : ?Value) : RandTree {
        genVal = gv
        match (this.parent) {
            case Some(p) => return p
            case None => throw Exception("already at top level scope")
        }
    }

    public func show(tabs : Int64) : List<String> {
        // ntabs(tabs) ++ toString(node) ++ "\n"
        // ++ children.show(tabs+1)
        let lines : List<String> = ArrayList<String>()
        
        // current node
        let line = showTabs(tabs) + showMaybe(label) + " : " + showList<RUnit>(", ", node) + " {"
        if (children.isEmpty()) {
            // no children: print close bracket on the same line
            lines.add(line + "}")
            return lines
        } else {
            lines.add(line)
        }

        // has children => print them each on new lines.
        for (c in children) { lines.add(all:c.show(tabs+1)) }
        lines.add(showTabs(tabs) + "}")

        // let gvPrint : String = match (genVal) {
        //     case Some(gv_) => showValue(gv_)
        //     case None => "Non-Primitive"
        // }
        // lines.add(showTabs(tabs) + "} => " + gvPrint)
        return lines
    }

    public func print() : Unit {
        println(showInterleave("\n", this.show(0)))
    }
}

func interpRandTree<R>(rl : List<RUnit>, rt : Box<RandTree>, fn : () -> R) : R {
    try {
        fn()
    } handle(_ : Rand) {
        if (rl.isEmpty()) {
            throw Exception("out of randomness!")
        }
        let r = pop(rl)
        rt.value.addR(r)
        resume with r
    }
}

func interpScope<R>(rt : Box<RandTree>, fn : () -> R) : R {
    try {
        fn ()
    } handle(e : EnterScope) {
        rt.value = rt.value.newScope(Some(e.label))
        resume
    } handle(e : ExitScope) {
        rt.value = rt.value.closeScope(e.gv)
        resume
    }
}

func ignoreScope<R>(fn : () -> R) : R {
    try {
        fn()
    } handle(_ : EnterScope) {
        resume
    } handle(_ : ExitScope) {
        resume
    }
}

// how to write properties

