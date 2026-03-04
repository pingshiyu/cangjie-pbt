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

public func randOption<T>(p: Float64, g : () -> T) : () -> Option<T> {{=>
withScope("randOption(${p})") {
    let makeOpt = randBool(p)
    if (makeOpt) {
        return Some(g())
    } else {
        return None
    }
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