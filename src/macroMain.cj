package cangjie_experiments

import cangjie_experiments.define.*

import std.collection.*

class UserType {}

@Stashes([Int64, UserType, Int32, ArrayList<Int64>, ArrayList<UserType>, Unit, Bool, Int8])

func macroMain(): StashG_ {
    // let x: Int64 = 3
    let y: Int64 = 2
    let s = StashG_()
    // @dprint[Int64, Int32](x)
    // @dprint[Int32, String](x + y)

    return s
}