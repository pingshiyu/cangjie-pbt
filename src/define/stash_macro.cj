macro package cangjie_experiments.define

import std.collection.*
import std.ast.*

/* Expects input to be a list of types, surrounded by [] characters.
*/
public macro Stashes(input: Tokens) : Tokens {
    println("inputs are: ${input}")

    let tys = ArrayList<TypeNode>()
    // assume the first character is a '['
    var i : Int64 = 1
    while (i < input.size - 1) {
        let parseRes : (TypeNode, Int64) = parseTypeFragment(input, startFrom: i)
        tys.add(parseRes[0])
        i = parseRes[1] + 1
    }

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

public macro dprint(attrs: Tokens, input: Tokens): Tokens {
    println("attrs are: ${attrs}")
    // let tys = parseType(attrs)
    for (attr in attrs) {
        attr.dump()
    }

    let inputStr = input.toString()
    let result = quote(
        print($(inputStr) + " = ")
         println($(input))
        )
    return result
}

public macro Memoize(attrib: Tokens, input: Tokens) {
    if (attrib.size != 1 || attrib[0].kind != TokenKind.BOOL_LITERAL) {
        diagReport(DiagReportLevel.ERROR, attrib,
                   "Attribute must be a boolean literal (true or false)",
                   "Expected boolean literal (true or false) here")
    }

    let memoized = (attrib[0].value == "true")
    if (!memoized) {
        return input
    }

    let fd = FuncDecl(input)
    if (fd.funcParams.size != 1) {
        diagReport(DiagReportLevel.ERROR, fd.lParen + fd.funcParams.toTokens() + fd.rParen,
                   "Input function to memoize should take exactly one argument",
                   "Expect only one argument here")
    }

    let memoMap = Token(TokenKind.IDENTIFIER, "_memoize_" + fd.identifier.value + "_map")
    let arg1 = fd.funcParams[0]

    return quote(
        var $(memoMap) = HashMap<$(arg1.paramType), $(fd.declType)>()

        func $(fd.identifier)($(arg1)): $(fd.declType) {
            if ($(memoMap).contains($(arg1.identifier))) {
                return $(memoMap).get($(arg1.identifier)).getOrThrow()
            }

            let memoizeEvalResult = { => $(fd.block.nodes) }()
            $(memoMap).add($(arg1.identifier), memoizeEvalResult)
            return memoizeEvalResult
        }
    )
}
