macro package cangjie_experiments.define

import std.collection.*
import std.ast.*

/* Expects input to be a list of types, surrounded by [] characters.
*/
public macro Stashes(input: Tokens) : Tokens {
    println("inputs are: ${input}")

    return quote()
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
