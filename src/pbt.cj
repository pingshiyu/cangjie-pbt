package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.math.*

// outputs a number in range [-128, 127]
class Rand <: Command<Int8> {}

// randomness effect, allows for injection of randomness externally
func rand() : Int8 {
    perform Rand()
}

func randBool(): Bool {
    let i = perform Rand()
    return i >= 0
}

func randInt64() : Int64 {
    // Int64 consists of 8 consecutive bytes from the randomness list
    let vs : List<Int8> = ArrayList<Int8>()
    for (_ in 0..8) { vs.add(rand()) }
    var finalVal : Int64 = 0
    for (i in 0..8) {
        // interpret int in big-endian form
        finalVal += Int64(vs[7-i]) * 2**UInt64(8*i)
    }
    return finalVal
}

func randNat(): List<UInt64> {
    // pick a random natural number
    let ns : ArrayList<UInt64> = ArrayList<UInt64>()
    var keepGoing : Bool = false
    do {
        ns.add(UInt64(perform Rand()))
        keepGoing = randBool()
    } while (keepGoing)
    
    // final value is \sum (2^(4i) * ns[i])
    return ns
}

func randIntRange(begin : Int64, end : Int64) : Int64 {
    // int in range [begin, end)
    let range = end - begin
    let chosenInt = abs(randInt64())
    let width = chosenInt % range
    return begin + width
}

// generate a list of n numbers, with n randomly chosen.
func randIntList() : List<Int64> {
    let n : Int64 = abs(randInt64())
    let l : List<Int64> = ArrayList<Int64>()
    for (_ in 0..n) {
        let x : Int64 = Int64(rand())
        l.add(x)
    }
    return l
}

func pop<T>(al : List<T>) : T {
    let rv = al[0]
    al.remove(0..1)
    return rv
}

func interpRand<R>(rl : List<Int8>, fn : () -> R) : R {
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

// how to write properties
// how to do reductions

// context free grammar expansion (randomised)
class S <: Command<Unit> {}

// treating program as terms in a cfg
func expandS(buf : List<String>, fn : () -> Unit): Unit {
    try { fn() } handle (_ : S) {
        let i_rule = randIntRange(0, 3)
        println("rule ${i_rule}")
        match (i_rule) {
            case 0 => expandS(buf, {=> println("expanding to S + S"); perform S(); perform S() })
            case 1 => { => println("expanding to 1"); buf.add("1") }()
            case 2 => { => println("expanding to a"); buf.add("a") }()
            case _ => throw Exception("How did we get here?!?!")
        }
        resume
    }
}