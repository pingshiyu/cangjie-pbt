package cangjie_experiments.misc

import effects.*
import std.collection.*
import cangjie_experiments.utils.*
import cangjie_experiments.pbt.*

class Eff <: Command<Int64> {}

class One <: Command<Unit> {}
class Two <: Command<Unit> {}

class Erroring <: Command<Unit> {
    public Erroring(let msg: String) {}
}

class HasDefault <: Command<Unit> {
    public func defaultImpl() {
        println("ran default impl here")
    }
}

class ThirdCharacter <: Command<Unit> {
    public ThirdCharacter(let name: String) {}
}

class Yield <: Command<Unit> {
    public Yield(let res: () -> Unit) {}
}
class Fork <: Command<Unit> {}

class Fib <: Command<Int64> & Hashable & Equatable<Fib> & ToString {
    public Fib(let n : Int64) {}

    public func defaultImpl(): Int64 {
        if (n <= 1) { return n }
        let n1 : Int64 = perform(Fib(n-1))
        let n2 : Int64 = perform(Fib(n-2))
        return n1 + n2
    }

    public func hashCode() : Int64 {
        return n
    }

    public operator func ==(rhs: Fib): Bool {
        return rhs.n == n
    }

    public func toString() : String {
        return "Fib(${n})"
    }
}


func main2(): Int64 {
    try_ {
        println(1)
        let x = perform(Eff())
        println(x)
    } .handle { _ : Eff =>
        println(2) // return value is 3. resume = rest of code after effect is called.
        3
    } .then_finally {}
    // expected 1 \n 2 \n 3

    printSep()

    try_ {
        try_ { 
            perform(One())
            perform(Two())
        } .handle { _: One =>
            println("handled One into this, inner")
        } .handle { _: Two =>
            println("handling Two now, inner")
        } .then_finally {}
        perform(One())
    } .handle { _: One =>
        println("and now this is the outer handler.")
    } .then_finally {}
    // expected "handled One..." \n "handling Two now..." \n "and now this is the..."

    printSep()

    try_ {
        println("normal execution")
        perform(Erroring("big mistake"))
        println("well let's get back to work anyways")
    } .handle { _: Erroring =>
        println("recovered woop woop")
        // don't resume
    } .then_finally {}
    // expected: "well let's get back to work anyways" is NOT printed.
    
    printSep()

    println("not gonna handle the one below me")
    perform(HasDefault())
    // expected "not gonna..." \n "ran default impl..."

    printSep()

    func functionThatUseEffects() {
        println("spongebob")
        println("patrick")
        perform(ThirdCharacter("squidward"))
        println("having fun under the sea")
    }

    try_ {
        functionThatUseEffects()
    } .handle { e : ThirdCharacter =>
        println(e.name.toAsciiUpper())
    } .then_finally {}
    // expected: spongebob \n patrick \n SQUIDWARD \n having fun...

    try_ {
        functionThatUseEffects()
    } .handle { e : ThirdCharacter =>
        println(e.name.replace("squid", "shark"))
    } .then_finally {}
    // expected: spongebob \n patrick \n sharkward \n having fun...

    printSep()

    // currently, the resumptions cannot be treated as "objects"
    // i.e. they cannot be treated as a lambda, thus disallowing them 
    // from being used outside the handler's scope.
    // however, this prevents e.g. schedulers from being implemented
    // using effects. 

    // this is because, the current restrictions mean that the resumption
    // must be ran from within the handler's scope (or not ran at all).
    // thus, implementing such a scheduler is impossible, as it requires
    // the resumption to be delayed until later, outside of the handler 
    // scope.

    // we can get past this by doing a CPS transform, which provides
    // us with the resumption as an explicit lambda object.

    func conc1(): Unit {
        println("t1: atomic op1")
        perform(Yield({ =>
            println("t1: atomic op2")
            perform(Yield({=>}))
        }))
    }

    func conc2(): Unit {
        println("t2: atomic op1")
        perform(Yield({ =>
            println("t2: atomic op2")
            perform(Yield({=>}))
        }))
    }

    func interleave(t1: () -> Unit, t2: () -> Unit): Unit {
        try_ {
            t1()
        } .handle { y: Yield =>
            interleave(t2, y.res)
        } .then_finally {}
    }

    interleave(conc1, conc2)
    // expected: "t1:..." \n "t2:..." \n "t1:..." \n "t2:..."

    printSep()

    // stateful handler that counts the number of occurences inside fn?
    func severalEffs(): Unit {
        perform(One())
        perform(One())
        println("hehe")
        perform(One())
    }

    // R ! Effs -> R ! Effs
    func countEffs<Cmd, Res, R>(_: Res, rInit: R, fn: () -> R): R where Cmd <: Command<Res> {
        let count : Box<Int> = Box(0)
        let rv : Box<R> = Box(rInit);
        try_ {
            rv.value = fn()
            println("counted ${count.value} of One effects.")
        } .handle { e: Cmd =>
            count.value = count.value + 1
            // reperform the effect
            let o = perform(e)
            // let o2: Res = countEffs<Cmd, Res, Res>(def, { => e.defaultImpl() })
            o
        } .then_finally {}
        return rv.value
    }

    // R ! (One : Effs) -> R ! Effs
    func interpOne<R>(fn: () -> R) {
        try_ {
            fn()
        } .handle { _ : One =>
        } .then_finally {}
    }

    interpOne { 
        countEffs<One, Unit, Unit>((), (), { => severalEffs() })
    }
    // expected: counted 3 of One effects

    printSep()

    // handler that will capture Cmd effects, and memoise their input/outputs
    func memoise<Cmd, Res, R>(m: HashMap<Cmd, Res>, fn : () -> R): R 
        where Cmd <: Command<Res> & Hashable & Equatable<Cmd> & ToString, 
              Res <: ToString {
        try_ {
            // every time Cmd is observed inside fn, handle it using handler below:
            fn()
        } .handle { e : Cmd =>
            // check on the map first to see if an entry exists
            let res : Res
            if (m.contains(e)) {
                // use stored entry if exists, else use default implementation
                res = m[e]
            } else {
                res = memoise<Cmd, Res, Res>(m, { => e.defaultImpl() })
                m.add(e, res)
            }
            res
        } .then_finally {}
    }

    let cache = HashMap<Fib, Int64>()
    let n : Int64 = 60
    let k : Int64 = memoise<Fib, Int64, Int64>(cache, { => perform(Fib(n)) })
    println("${n}th fibonacci number is ${k}")
    // expected: 60th fibonacci number is 1548008755920

    printSep()

    pbtMain()

    return 0
}