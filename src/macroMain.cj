package cangjie_experiments

import cangjie_experiments.define.*

func macroMain(): Int64 {
    // let x: Int64 = 3
    let y: Int64 = 2
    @Stashes([Int64, Int32, String, Bool, Unit, ArrayList<Int64>])
    // @dprint[Int64, Int32](x)
    // @dprint[Int32, String](x + y)

    return y
}