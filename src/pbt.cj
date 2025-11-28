package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

class WrongArgumentException <: Exception {
    public WrongArgumentException(msg: String) {}
}

type RUnit = Int8

// outputs a number in range [-128, 127]
class Rand <: Command<RUnit> {}

// randomness effect, allows for injection of randomness externally
func rand() : RUnit {
    perform Rand()
}

// indicate we ran out of randomness:
// gives option to either error or do something else
// like undo the last change during reduction
// OutOfRand :: (() -> R) -> m R
class OutOfRand <: Command<Unit> {
    public OutOfRand() {}
}

func handleOutOfRandAsError<R>(fn: () -> R) : R {
    try { fn() } handle(_ : OutOfRand) {
        throw WrongArgumentException("Out of random bits!")
    }
}

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

func createValue(v : Bool) : Option<Value> {
    return BoolV(v)
}

func createValue(v : Int64) : Option<Value> {
    return I64V(v)
}

func createValue(v : Int8) : Option<Value> {
    return I8V(v)
}

func createValue<R>(_ : R) : Option<Value> {
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

func withScope<R>(fnName : String, fn : () -> R) : R {
    perform EnterScope(fnName)
    let rv = fn()
    let storeVal : Option<Value> = createValue(rv)
    perform ExitScope(storeVal)
    return rv
}

// basic interpreter of randomness. 
// consumes a little bit of the random list
func interpRand<R>(rl : List<RUnit>, fn : () -> R) : R {
    try {
        fn ()
    } handle(_ : Rand) {
        // println("interpRand: rl=" + showList(", ", rl))
        if (rl.isEmpty()) {
            perform OutOfRand() // throw Exception("out of randomness!")
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

    public init(l: ?String, n: List<RUnit>, c: List<RandTree>, p: ?RandTree, gv: ?Value) {
        this.label = l
        this.node = n
        // below needs a deep copy, we define it outside as 
        // init does not like recursion of any kind
        this.children = c
        this.parent = p
        this.genVal = gv
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
        // let gvPrint : String = match (genVal) {
        //     case Some(gv_) => showValue(gv_)
        //     case None => "Non-Primitive"
        // }

        if (children.isEmpty()) {
            // no children: print close bracket on the same line
            lines.add(line + "}") // + " => " + gvPrint)
            return lines
        } else {
            lines.add(line)
        }

        // has children => print them each on new lines.
        for (c in children) { lines.add(all:c.show(tabs+1)) }
        lines.add(showTabs(tabs) + "}") // + " => " + gvPrint)

        return lines
    }

    public func print() : Unit {
        println(showInterleave("\n", this.show(0)))
    }

    public func modify(begin: Int, len: Int, repl: Collection<RUnit>) {
        this.node.remove(begin..(begin+len-1))
        this.node.add(all: repl, at: begin)
    }

    public func modify(range: Range<Int64>, repl: Collection<RUnit>) {
        this.node.remove(range)
        this.node.add(all: repl, at: range.start)
    }

    public func replace(loc: Int64, repl: RUnit) {
        this.modify(loc, 2, [repl])
    }

    public func randList() : List<RUnit> {
        func collect(t: RandTree, l: List<RUnit>): Unit {
            l.add(all: t.node)
            for (c in t.children) {
                collect(c, l)
            }
        }
        let rl : List<RUnit> = ArrayList<RUnit>()
        collect(this, rl)
        return rl
    }
}

func randTreeDeepCopy(rt : RandTree, p: ?RandTree) : RandTree {
    let newRt : RandTree = RandTree(
        rt.label,
        ArrayList<RUnit>(rt.node),
        ArrayList<RandTree>(),
        p,
        rt.genVal
    )
    for (c in rt.children) {
        let newC = randTreeDeepCopy(c, Some(newRt))
        newRt.children.add(newC)
    }
    return newRt
}

func interpRandTree<R>(rl : List<RUnit>, rt : Box<RandTree>, fn : () -> R) : R {
    try {
        fn()
    } handle(_ : Rand) {
        if (rl.isEmpty()) {
            perform OutOfRand() // throw Exception("out of randomness!")
        }
        let r = pop(rl)
        rt.value.addR(r)
        resume with r
    }
}

func interpExtRandTree<R>(rs: Random, rt: Box<RandTree>, fn: () -> R) : R {
    try {
        fn()
    } handle(_ : Rand) {
        let i = rs.nextInt8()
        rt.value.addR(i)
        resume with i
    }
}

func interpExtRand<R>(rs: Random, fn : () -> R) : R {
    try {
        fn()
    } handle(_ : Rand) {
        resume with rs.nextInt8()
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

func runRand<R>(rl : List<RUnit>, fn : () -> R) : R {
    ignoreScope { interpRand(rl, fn) }
}

func runExtRand<R>(r: Random, fn : () -> R) : R {
    ignoreScope { interpExtRand(r, fn) }
}

func runRandTracked<R>(rl: List<RUnit>, rt: Box<RandTree>, fn : () -> R): R {
    interpScope(rt) {
        interpRandTree(rl, rt, fn)
    }
}

func runExtRandTracked<R>(r: Random, rt: Box<RandTree>, fn : () -> R) : R {
    interpScope(rt) {
        interpExtRandTree(r, rt, fn)
    }
}

// returns Some(rt) if a bug was found, None otherwise.
func findCounterExampleTree<R>(seed: UInt64, iters: Int, g : () -> R, fn: (R) -> Bool): Option<RandTree> {
    // try to find a counterexample, then return evidence of bug being triggered
    let r : Random = Random(seed)
    for (_ in 0..iters) {
        let rt : RandTree = RandTree(None, None)
        let rtb : Box<RandTree> = Box(rt)
        let gv: R = runExtRandTracked(r, rtb, g)
        if (!fn(gv)) {
            return Some(rt)
        }
    }
    return None
}

func findCounterExample<R>(seed: UInt64, iters: Int, g: () -> R, fn: (R) -> Bool): Option<R> {
    let bugTrigger : Option<RandTree> = findCounterExampleTree(seed, iters, g, fn)
    match (bugTrigger) {
        case Some(bt) => Some(runRand(bt.randList(), g))
        case None => None
    }
}

func findSmallCounterExample<R>(seed: UInt64, iters: Int, g: () -> R, fn: (R) -> Bool): Option<R> {
    // property to reveal this bug: len(list) == len(sorted(list))
    let bugTrigger : Option<RandTree> = findCounterExampleTree(seed, iters, g, fn)

    // check that bugTrigger triggers the bug
    match (bugTrigger) {
        case Some(bt) => // bug triggered
            // reduce the BugTrigger
            // println("bug found, the bug-trigger input is:");
            // println(showList(", ", runRand(bt.randList(), gtor)));

            // default strategy for reducing triggers
            let reducedTrigger = makeReduction(bt.randList(), { => !fn(g()) })
            let smaller : R = runRand(reducedTrigger.randList(), g)
            return Some(smaller)
        case None => 
            return None
    }
}