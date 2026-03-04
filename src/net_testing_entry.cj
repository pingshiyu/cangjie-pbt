// Entry point for std.net PBT. Registers all defined executors (TCP, Unix, UDP) and runs them (runInContext inlined).
package cangjie_experiments

import std.collection.*
import std.random.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*

func dummyNetTester(_ : Int64): Unit {
    perform Switch()
}

func dummyFunction() : Unit {
    println("dummyFunction")
}

// Entry: NetContext + getLibNet, run dummyNetTester under executeUntilDone (runInContext body inlined).
public func main_net_testing(): Unit {
    for (i in 0..100) {
        let netCtx = NetContext("tmp")
        netCtx.cleanup()
        netCtx.initialiseContext() // seems to happen when we need to clone netCtx a lot.
        let lib = ArrayList([
            { => netCtx.randSmallByteArray() },
        ])
        let ress = ArrayList<Res>()
        let fuel = Box<Int64>(10)
        runExtRand(Random(UInt64(i))) {
            let done : Box<Bool> = Box(false)
            try {
                dummyNetTester(0)
                done.value = true
            } handle (_ : Switch, r : Res) {
                ress.add(r)
            }
            while (!(done.value)) {
                // resume a random function or a resumption from the list
                let hasResumptions = ress.size > 0
                if (fuel.value > 0 && randBool(0.50)) {
                    fuel.value -= 1
                    let chosenF = lib[randIntRange(0, lib.size)]
                    chosenF()
                } else if (hasResumptions) {
                    let chosenR = ress.remove(at: randIntRange(0, ress.size))
                    resume chosenR with ()
                } else {
                    println("WARNING: no resumptions, didn't choose to run a function. skipping")
                }
            }
        }
        println("********** Net iteration ${i} completed **********")
    }
}
