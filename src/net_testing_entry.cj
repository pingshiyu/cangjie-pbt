// Entry point for std.net PBT. Registers all defined executors (TCP, Unix, UDP) and runs them via runInContext.
package cangjie_experiments

import std.collection.*
import cangjie_experiments.define.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.resumptions.loop.*
import cangjie_experiments.pbt.*

func dummyNetTester(i : Int64): Unit {
    perform Switch()
    perform Switch()
    perform Switch()
}

// Entry: create NetContext, register all executors, initialise state, run dummyNetTester under executeUntilDone in runInContext.
// Each Switch() causes the handler to run a random UnitFn from the registered executors.
public func main_net_testing(): Unit {
    for (i in 0..10) {
        let netCtx = NetContext("tmp")
        netCtx.cleanup()
        let seed: Option<UInt64> = None
        let lib = getLibNet(netCtx)
        runInContext(seed, lib, 25) {
            netCtx.initialiseContext()
            executeUntilDone(@RunRandomly([i in cjRandom<Int64>], dummyNetTester))
        }
        netCtx.cleanup()
        println("********** Net iteration ${i + 1} completed **********")
    }
}
