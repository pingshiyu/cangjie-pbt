package cangjie_experiments

import std.collection.*
import std.math.*

// p denotes the probability of being true.
func randBool(p : Float64) : Bool {
withScope("randBool(${p})") { 
    let i = rand()
    let trueLimit = 128.0 * (1.0 - p) // abs(v) above this => true
    return Float64(abs(Int16(i))) > trueLimit // such that reductions towards 0 => turns this false
}}

func randInt8(): Int8 { 
withScope("randInt8()") { 
    return rand()
}}

func randSmallInt64(): Int64 {
withScope("randSmallInt64()") {
    return Int64(rand())
}}

func randInt64() : Int64 { 
withScope("randInt64()") {
    // Int64 consists of 8 consecutive bytes from the randomness list
    let vs : List<RUnit> = ArrayList<RUnit>()
    for (_ in 0..8) { vs.add(rand()) }
    var finalVal : Int64 = 0
    for (i in 0..8) {
        // interpret int in big-endian form
        finalVal += Int64(vs[7-i]) * 2**UInt64(8*i)
    }
    return finalVal
}}

func randNat(): List<UInt64> { 
withScope("randNat()") {
    // pick a random natural number
    let ns : ArrayList<UInt64> = ArrayList<UInt64>()
    var keepGoing : Bool = false
    do {
        ns.add(UInt64(rand()))
        keepGoing = randBool(0.50)
    } while (keepGoing)
    
    // final value is \sum (2^(4i) * ns[i])
    return ns
}}

func randIntRange(begin : Int64, end : Int64) : Int64 {
withScope("randIntRange(" + begin.toString() + ", " + end.toString() + ")") {
    // int in range [begin, end)
    let range = end - begin
    let chosenInt = abs(randInt64())
    let width = chosenInt % range
    let v = begin + width
    return v
}}

func randList<T>(eLen : Int64, g : () -> T) : () -> List<T> {{ =>
withScope("randList<T>(g)") { 
    let p : Float64 = 1.0 - 1.0 / Float64(eLen)
    let l : List<T> = ArrayList<T>()
    var cont: Bool = randBool(p)
    while (cont) {
        l.add(g())
        cont = randBool(p)
    }
    return l
}}}

// generate a list of n numbers, with n randomly chosen.
func randIntListAlt() : List<Int64> {
withScope("randIntList()") {
    let n : Int64 = abs(randInt64())
    let l : List<Int64> = ArrayList<Int64>()
    for (_ in 0..n) {
        let x : Int64 = Int64(rand())
        l.add(x)
    }
    return l
}}