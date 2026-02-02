package cangjie_experiments.resumptions.original

import cangjie_experiments.define.*
import stdx.effect.*
import std.collection.*
import std.random.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*
import cangjie_experiments.utils.*

// ========================
//             | 0.   | 1.  | 2.  | 3.         | 4. 
@StashFromTypes([Int64, Bool, Unit, List<Int64>, Option<Int64>])

main() {
    let s : StashG_ = StashG_()
    s.fns_0_0.setStash(ArrayList<(Int64) -> Int64>([
        fint_mul(0), fint_add(1), fint_mul(2), fint_add(3) 
    ]))
    s.fns_0_1.setStash(ArrayList<(Int64) -> Bool>([
        
    ]))
    s.fns_0_2.setStash(ArrayList<(Int64) -> Unit>([

    ]))
    s.fns_3_3.setStash(ArrayList<(List<Int64>) -> List<Int64>>([
        mapEFaked<Int64, Int64>, map2EFaked<Int64, Int64>, mapFaked<Int64, Int64>, 
        filterEFaked<Int64>, filterFaked<Int64>, 
        filterMapFaked<Int64, Int64>
    ]))
    s.fns_3_1.setStash(ArrayList<(List<Int64>) -> Bool>([
        anyFaked<Int64>, noneFaked<Int64>, allFaked<Int64>, 
        isEmpty<Int64>, contains<Int64>(0), contains<Int64>(1), contains<Int64>(-1)
    ]))
    s.fns_3_4.setStash(ArrayList<(List<Int64>) -> Option<Int64>>([
        reduceFaked<Int64>, max<Int64>, min<Int64>, first<Int64>, last<Int64>
    ]))
    s.fns_3_0.setStash(ArrayList<(List<Int64>) -> Int64>([
        count<Int64>
    ]))

    let r : Random = Random()
    let output = runExtRand(r) { s.handleStash { handleUnknown {
        let input : List<Int64> = randList<Int64>(10, randInt64)()
        println("input: ${showList(", ", input)}")
        mapEFaked<Int64, Int64>(input)
    }}}

    println("output: ${output[0]}")

    return 0
}
