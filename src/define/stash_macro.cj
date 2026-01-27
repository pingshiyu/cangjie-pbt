macro package cangjie_experiments.define

import std.collection.*
import std.ast.*

/* Get types from the input tokens
Expects input to be a list of types, surrounded by [] characters.
*/
func parseAsTypes(input: Tokens): List<TypeNode> {
    let tys = ArrayList<TypeNode>()
    // assume the first character is a '['
    var i : Int64 = 1
    while (i < input.size - 1) {
        let parseRes : (TypeNode, Int64) = parseTypeFragment(input, startFrom: i)
        tys.add(parseRes[0])
        i = parseRes[1] + 1
    }
    return tys
}

func genStashes(tys: List<TypeNode>): Tokens {
    // form the Stash class
    var result = quote(
        class StashG_ {
            let arb : Arbitrary = Arbitrary()
    )

    for (i1 in 0..tys.size) {
        for (i2 in 0..tys.size) {
            let fns_vn = Token(TokenKind.IDENTIFIER, "fns_${i1}_${i2}")
            let res_vn = Token(TokenKind.IDENTIFIER, "res_${i1}_${i2}")
            result += quote(
                let $(fns_vn) = FnStash<$(tys[i1]), $(tys[i2])>()
                let $(res_vn) = ResStash<$(tys[i1]), $(tys[i2])>()
            )
        }
    }

    result += quote(func handleStash<Y>(fn: () -> Y): Y {
        arb.sHandle { )
    for (i1 in 0..tys.size) {
        for (i2 in 0..tys.size) {
            let fns_vn = Token(TokenKind.IDENTIFIER, "fns_${i1}_${i2}")
            let res_vn = Token(TokenKind.IDENTIFIER, "res_${i1}_${i2}")
            result += quote(
                $(fns_vn).sHandle {
                $(res_vn).sHandle {
            )
        }
    }
    result += quote(fn())

    for (_ in 0..tys.size) {
        for (_ in 0..tys.size) {
            result += quote(}}) // closes fns_i.handle{; res_i.handle{
        }
    }
    result += quote(}) // closes arb.handle {
    result += quote(}}) // closes func.handleStash<..>(..) {; class StashG_ {

    return result
}

/*
func handleUnknown<Y>(fn: () -> Y): Y {
    try {
        fn()
    } handle(f: UnknownFunction<Int64, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, Int64>, r: Resumption<Int64, Y>) {
        handleUnknown<Y> { fillFunction<Int64, Int64, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, Bool>, r: Resumption<Bool, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, Bool, Y>(f, r) }
    } handle(f: UnknownFunction<List<Int64>, List<Int64>>, r: Resumption<List<Int64>, Y>) {
        handleUnknown<Y> { fillFunction<List<Int64>, List<Int64>, Y>(f, r) }
    } handle(f: UnknownFunction<Int64, List<Int64>>, r: Resumption<List<Int64>, Y>) {
        handleUnknown<Y> { fillFunction<Int64, List<Int64>, Y>(f, r) }
    }
}
*/
func genUnknownHandlers(tys: List<TypeNode>): Tokens {
    var res = quote(
        func handleUnknownG<Y>(fn: () -> Y) : Y {
            try {
                fn()
            }
    )

    for (i1 in 0..tys.size) {
        for (i2 in 0..tys.size) {
            res += quote(
                handle(f : UnknownFunction<$(tys[i1]), $(tys[i2])>, r : Resumption<$(tys[i2]), Y>) {
                    handleUnknownG<Y> { fillFunction<$(tys[i1]), $(tys[i2]), Y>(f, r) }
                })
        }
    }

    res += quote(}) // func handleUnknown<Y>(...) : Y {
    return res
}

public macro ModuleTest(input: Tokens): Tokens {
    println("inputs are: ${input}")
    var res = genStashes(parseAsTypes(input))
    res += genUnknownHandlers(parseAsTypes(input))
    return res
}