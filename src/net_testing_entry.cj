// Entry point for std.net PBT. Registers all defined executors (TCP, Unix, UDP) and runs them via runInContext.
package cangjie_experiments

import std.collection.*
import std.runtime.*
import std.fs.*
import std.random.*
import std.math.*
import std.unittest.*
import cangjie_experiments.define.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.resumptions.loop.*
import cangjie_experiments.pbt.*


func dummyNetTester(): Unit {
    perform Switch()
    perform Switch()
    perform Switch()
}

func executeUntilDoneFast(lib: ArrayList<UnitFn>, maxFuel: Int64, fn: () -> Unit): Unit {
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
        if (fuel.value > 0 && cjRandom<Bool>()) {
            fuel.value -= 1
            let chosenF = lib[randomIntInRange(0, lib.size)]
            chosenF()
        } else if (hasResumptions) {
            let chosenR = ress.remove(at: randomIntInRange(0, ress.size))
            resume chosenR with ()
        } else {
            println("WARNING: no resumptions, didn't choose to run a function. skipping")
        }
    }
}

// Entry: create NetContext, register all executors, initialise state, run dummyNetTester under executeUntilDone in runInContext.
// Each Switch() causes the handler to run a random UnitFn from the registered executors.
public func main_net_testing(): Unit {
    for (i in 0..100) {
        let seed: Option<UInt64> = None
        let r = match (seed) {
            case Some(s) => Random(s)
            case None => Random()
        }

        try {
            let netCtx = NetContext("tmp", r)
            let lib = getLibNet(netCtx)
            netCtx.initialiseContext()
            executeUntilDoneFast(lib, 20, dummyNetTester)
            netCtx.cleanup()
        } handle (e : GetRandom) {
            resume with r
        }
        println("********** Net iteration ${i + 1} completed **********")
    }
}
