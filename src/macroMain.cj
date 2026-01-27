package cangjie_experiments

import cangjie_experiments.define.*

import std.collection.*
import stdx.effect.*

class UserType {}

// @ModuleTest([Int64, UserType, Float64, String, ArrayList<Int64>, ArrayList<UserType>, Unit, Bool, Int8, ArrayList<Int32>])
@FuncTypes([
    fint_mul(1), (Int64) -> Int64,
    mapEFaked<Int64, Int64>, (ArrayList<Int64>) -> ArrayList<Int64>, 
    max<Int64>, (ArrayList<Int64>) -> Int64, 
    min<Int64>, (ArrayList<Int64>) -> Int64, 
    fint_mul(2), (Int64) -> Int64
    ])

func macroMain(): Unit {
    // let s = StashG_()
// 
    // s.handleStash {
    //     println("hello world... seems like my effect handlers are all working?")
    // }
    // @dprint[Int64, Int32](x)
    // @dprint[Int32, String](x + y)

    // return s
}