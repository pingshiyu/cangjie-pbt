// Entry point for std.net PBT. Registers all defined executors (TCP, Unix, UDP) and runs them (runInContext inlined).
package cangjie_experiments

import std.collection.*
import std.random.*
import std.math.*
import std.unittest.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*

func dummyNetTester(): Unit {
    perform Switch()
}

func dummyFunction() : Unit {
    println("dummyFunction")
}

func executeUntilDone(r : Random, lib: ArrayList<UnitFn>, maxFuel: Int64, fn: () -> Unit): Unit {
    let ress = ArrayList<Res>()
    let fuel = Box<Int64>(maxFuel)
    
    let done : Box<Bool> = Box(false)
    try {
        fn()
        done.value = true
    } handle (_ : Switch, res : Res) {
        ress.add(res)
    }
    while (!(done.value)) {
        // resume a random function or a resumption from the list
        let hasResumptions = ress.size > 0
        if (fuel.value > 0 && cjRandom<Bool>(r)) {
            fuel.value -= 1
            let chosenF = lib[randomIntInRange(r, 0, lib.size)]
            chosenF()
        } else if (hasResumptions) {
            let chosenR = ress.remove(at: randomIntInRange(r, 0, ress.size))
            resume chosenR with ()
        } else {
            println("WARNING: no resumptions, didn't choose to run a function. skipping")
        }
    }
}

// Entry: NetContext + getLibNet, run dummyNetTester under executeUntilDone (runInContext body inlined).
public func main_net_testing(): Unit {
    for (i in 0..10000) {
        let r = Random(UInt64(i))
        let netCtx = NetContext("tmp", r)
        netCtx.cleanup()
        netCtx.initialiseContext() // seems to happen when we need to clone netCtx a lot.
        let lib = getLibNet(netCtx)
        executeUntilDone(r, lib, 20, dummyNetTester)
        println("********** Net iteration ${i} completed **********")
    }
}
