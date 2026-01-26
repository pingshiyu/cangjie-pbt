package cangjie_experiments

import cangjie_experiments.define.*

class UserType {}

@Stashes([Int64, UserType])

func macroMain(): StashG_ {
    // let x: Int64 = 3
    let y: Int64 = 2
    let s = StashG_()
    // @dprint[Int64, Int32](x)
    // @dprint[Int32, String](x + y)

    return s
}