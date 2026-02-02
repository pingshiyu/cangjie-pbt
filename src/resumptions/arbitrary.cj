package cangjie_experiments.resumptions

import cangjie_experiments.pbt.*
import std.collection.*

class Arbitrary {
    func sHandle<Y>(fn: () -> Y): Y {
        try {
            fn()
        } handle(_: GenRandom<Int64>) {
            resume with randSmallInt64()
        } handle(_: GenRandom<Int8>) {
            resume with randInt8()
        } handle(_: GenRandom<Unit>) {
            resume with ()
        } handle(_: GenRandom<Bool>) {
            resume with randBool(0.50)
        } handle(_: GenRandom<ArrayList<Bool>>) {
            let vs = this.sHandle {
                randList(8, randBool_(0.50))()
            }
            resume with ArrayList(vs)
        } handle(_: GenRandom<String>) {
            resume with "not random."
        } 
    }
}