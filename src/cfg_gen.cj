package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.sort.*

// context free grammar expansion (randomised)
class S <: Command<Unit> {}

// implements a random sampling of a CFG
// The grammar goes:
// S -> S + S
// S -> 1
// S -> a
func expandS(buf : List<String>, verbose: Bool, fn : () -> Unit): Unit {
    try { fn() } handle (_ : S) {
        let i_rule = randIntRange(0, 3)
        if (verbose) { println("rule ${i_rule}") }
        match (i_rule) {
            case 0 => expandS(buf, verbose, {=> if (verbose) { println("expanding to S + S"); }; perform S(); perform S() })
            case 1 => { => if (verbose) { println("expanding to 1"); }; buf.add("1") }()
            case 2 => { => if (verbose) { println("expanding to a"); }; buf.add("a") }()
            case _ => throw Exception("How did we get here?!?!")
        }
        resume
    }
}

func pbtMain() : Int64 {
    // create a RandTree and print it
    let t = RandTree(None, None)
    t.addR(6); t.addR(4); t.addR(2); t.addR(100)
    let t1 = t.newScope("t1")
    t1.addR(5); t1.addR(7)
    let t1p = t1.closeScope(None)
    let t2 = t1p.newScope("t2")
    t2.addR(10); t2.addR(13); t2.addR(17)
    let t3 = t2.newScope("t3")
    t3.addR(7); t3.addR(9)
    let t2p = t2.closeScope(None)
    let t4 = t2p.newScope("t4")
    t4.addR(10); t4.addR(11); t4.addR(12)

    // clone and see how it changes
    let tMod = randTreeDeepCopy(t, None)
    tMod.addR(69)
    tMod.node.remove(0..2)

    // also alter one of the children for a laugh
    tMod.children[1].node.remove(0..1)

    println("An example RandTree looks like:")
    t.print()

    println("And modified version:")
    tMod.print()

    printSep()

    let randomness : List<RUnit> = ArrayList<RUnit>([
            Int8(0), Int8(0), Int8(0), Int8(102), Int8(-2), Int8(-6), Int8(122), Int8(90), 
            Int8(31), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(2),
            Int8(55), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0),
            Int8(23), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0)])
    let buf : List<String> = ArrayList<String>()

    runRand(randomness, {=> 
        expandS(buf, true, { => perform S()})
    })

    print("final string generated: ")
    print(showList("", buf))
    println()

    printSep()

    // another random tree, this time we run it against a real generator
    let rt = RandTree(None, None)
    let rtb = Box(rt)
    let randomness2 : List<RUnit> = ArrayList<RUnit>([
            Int8(0), Int8(0), Int8(0), Int8(102), Int8(-2), Int8(-6), Int8(122), Int8(90), 
            Int8(31), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(2),
            Int8(55), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0),
            Int8(23), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0)])
    let buf2 : List<String> = ArrayList<String>()
    runRandTracked(randomness2, rtb, {=> 
        expandS(buf2, true, { => perform S()})
    })

    println("Generated: " + showList("", buf2))
    rt.print()

    printSep()

    // try a reduction, with interestingness condition being that it should start with a `1`
    let randomness3 : List<RUnit> = ArrayList<RUnit>([
            Int8(0), Int8(0), Int8(0), Int8(102), Int8(-2), Int8(-6), Int8(122), Int8(90), 
            Int8(31), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(2),
            Int8(55), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0),
            Int8(23), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0)])

    // TODO: might need to add the rest of the tree in case it consumes _MORE_ randomness
    // OR: do we just say that is not an interesting reduction?
    // OR: do we build another strategy that will take this into account?

    /* Reduction maintains the predicate: if the (randomly) produced string starts with a "1" */
    func startsWith1(): Bool {
        let bufu : List<String> = ArrayList<String>()
        expandS(bufu, false, { => perform S()})
        return bufu[0] == "1"
    }

    let reduced : RandTree = ReduceToSimpleStrategy().makeReduction(randomness3, startsWith1)
    println("Reduced RandTree:")
    reduced.print()

    println("As a list: " + showList(", ", reduced.randList()))

    println("Result of running with reduced RandTree:")
    let buf4 = ArrayList<String>()
    runRand(reduced.randList(), { =>
        expandS(buf4, false, { => perform S() })
    })
    println(showList("", buf4))

    printSep()
    let rand5 = ArrayList<RUnit>([
        0, 0, 0, 0, 0, 1, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0])
    let rt5 = RandTree(None, None)
    let rtb5 = Box<RandTree>(rt5)
    let buf5 = ArrayList<String>()
    runRandTracked(rand5, rtb5, {=> expandS(buf5, false, { => perform S() })})
    println("Tree after reduction:")
    rt5.print()

    printSep()

    // basic algorithm: sort a list by storing it in a set and then retrieving elements from it
    // one by one, bottom first
    func crappySort(l : List<Int8>) : List<Int8> {
        let ls : Set<Int8> = HashSet<Int8>(l)
        let shortl = ArrayList<Int8>(ls)
        sort(shortl, descending: true, stable: true)
        return shortl
    }

    // generate a random list and use it to test some sorting algorithm
    // property to test
    func testCrappySort(l : List<Int8>) : Bool {
        return crappySort(l).size == l.size
    }
    // algorithm has a bug of course: elements deleted if duplicates exists

    let gtor = randList(1000, randInt8)

    // property to reveal this bug: len(list) == len(sorted(list))
    let bugTrigger : Option<RandTree> = findCounterExample(42, 100, gtor, testCrappySort)

    // check that bugTrigger triggers the bug
    let reducedTrigger: RandTree = match (bugTrigger) {
        case Some(bt) => // bug triggered
            // reduce the BugTrigger
            ReduceToSimpleStrategy().makeReduction(
                bt.randList(), 
                { => !testCrappySort(gtor()) })
        case None => throw Exception("bug should have been triggered.")
    }
    
    // show the generated smaller test case
    println("smallest bug-triggering test-case is: ")
    let smaller : List<Int8> = runRand(reducedTrigger.randList(), gtor)
    println(showList(", ", smaller))

    return 0
}