package cangjie_experiments

import stdx.effect.*
import std.collection.*

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

func randNat(): Int64 {
    // pick a random natural number
    var ns : ArrayList<Int64> = ArrayList<Int64>()
    var keepGoing : Bool = false
    do {
        ns.add(Int64(perform Rand()))
        keepGoing = randBool()
    } while (keepGoing)
    
    var finalVal = 0
    for (n in ns) {
        finalVal = finalVal * 2 + n
    }

    return finalVal
}

// generate a list of n numbers, with n randomly chosen.
func randList() : List<Int64> {
    let n : Int64 = randNat()
    let l : List<Int64> = ArrayList<Int64>()
    for (i in 0..n) {
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
    } handle(e : Rand) {
        let x = pop(rl)
        resume with x
    }
}

// how to write properties
// how to do reductions

// context free grammar expansion (randomised)

// treating program as terms in a cfg
func cfgExpand() {
    
}
