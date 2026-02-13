package cangjie_experiments.pbt

import std.collection.*
import std.math.*

class ChooseFromEmptyListError <: Exception {
    public ChooseFromEmptyListError(message: String) {
        super(message)
    }
}

// p denotes the probability of being true.
public func randBool(p : Float64) : Bool {
withScope("randBool(${p})") {
    let i = rand()
    let trueLimit = 128.0 * (1.0 - p) // abs(v) above this => true
    return Float64(abs(Int16(i))) > trueLimit // such that reductions towards 0 => turns this false
}}

public func randBool_(p : Float64) : () -> Bool {{ =>
    randBool(p)
}}


public func randInt8(): Int8 { 
withScope("randInt8()") { 
    return rand()
}}

public func randSmallInt64(): Int64 {
withScope("randSmallInt64()") {
    return Int64(rand())
}}

public func randInt64() : Int64 { 
withScope("randInt64()") {
    // Int64 consists of 8 consecutive bytes from the randomness list
    var finalVal : Int64 = 0
    for (_ in 0..7) {
        let x = rand()
        finalVal = finalVal * Int64(2 ** 8) + Int64(x)
    }
    return finalVal
}}

public func randNat(): List<UInt64> { 
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

public func randIntRange(begin : Int64, end : Int64) : Int64 {
withScope("randIntRange(" + begin.toString() + ", " + end.toString() + ")") {
    // int in range [begin, end)
    let range = end - begin
    let chosenInt = abs(randInt64())
    let width = chosenInt % range
    let v = begin + width
    return v
}}

public func randElem<T>(ls : List<T>): T {
withScope("randElem<T>(ls)") {
    let n : Int64 = ls.size
    if (n == 0) {
        throw ChooseFromEmptyListError("randElem: list is empty")
    }
    let ix: Int64 = randIntRange(0, n)
    return ls[ix] 
}
}

public func randList<T>(eLen : Int64, g : () -> T) : () -> List<T> {{ =>
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
public func randIntListAlt() : List<Int64> {
withScope("randIntList()") {
    let n : Int64 = abs(randInt64())
    let l : List<Int64> = ArrayList<Int64>()
    for (_ in 0..n) {
        let x : Int64 = Int64(rand())
        l.add(x)
    }
    return l
}}

public func randOption<T>(p: Float64, g : () -> T) : () -> Option<T> {{=>
withScope("randOption(${p})") {
    let makeOpt = randBool(p)
    if (makeOpt) {
        return Some(g())
    } else {
        return None
    }
 }}}

// Generator functions that return a function
public func randInt64_(): () -> Int64 {{=>
    randInt64()
 }}

public func randIntRange_(begin: Int64, end: Int64): () -> Int64 {{=>
    randIntRange(begin, end)
 }}

// Generator for nested lists (lists of lists)
public func randNestedList<T>(eLen: Int64, g: () -> T): () -> List<List<T>> {{=>
withScope("randNestedList<T>(eLen, g)") {
    let p: Float64 = 1.0 - 1.0 / Float64(eLen)
    let outerList: List<List<T>> = ArrayList<List<T>>()
    while (randBool(p)) {
        let innerList: List<T> = randList(eLen, g)()
        outerList.add(innerList)
    }
    return outerList
}}}

 public func randAlphanumericChar(): () -> Rune {{=>
 withScope("randAlphanumericChar()") {
    // pick a random ascii character
    let c = Rune(randIntRange(0, 128))    
    if (c.isAsciiNumberOrLetter()) {
        return c
    } else {
        // try again, should generally generate an alphanumeric quickly
        return randAlphanumericChar()()
    }
 }}}

 public func randString(sLen: Int64): () -> String {{=>
 withScope("randString(sLen)") {
    // pick n random ascii characters
    var s: String = ""
    for (_ in 0..sLen) {
        s += randAlphanumericChar()().toString()
    }
    return s
 }}}

 public func randShortString(n !: Int64 = 1, alphabet !: List<String> = ArrayList(["a", "b"])): () ->  String {{=>
 withScope("randShortString(${n})") {
    // generate n random characters from the alphabet
    var s = ""
    for (_ in 0..n) {
        s += randElem(alphabet)
    }
    return s
}}}

public func randSmallBytes(n !: Int64 = 5): () -> Array<Byte> {{=>
withScope("randSmallBytes(${n})") {
    return randShortString(n:n)().toArray()
}}}