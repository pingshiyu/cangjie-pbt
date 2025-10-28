package cangjie_experiments

import std.unittest.*
import std.collection.*
import std.unittest.testmacro.*

@Test
class AddTests {

    let randomness : List<Int8> = ArrayList<Int8>([
            Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(3), 
            Int8(31), Int8(-103), Int8(20), Int8(31), 
            Int8(85), Int8(84), Int8(93)])

    @TestCase
    func createListLength3Controlled() {
        // a random list of length 3.
        let l : List<Int64> = ignoreScope {interpRand<List<Int64>>(randomness, { => 
            randIntListAlt() 
        })}
        let expected : List<Int64> = ArrayList<Int64>([31, -103, 20])

        @Expect(l.size, expected.size)
        for (i in 0..3) {
            @Expect(l[i], expected[i])
        }
    }

    @TestCase
    func randomCfgGeneration() {
        let randomness0 : List<Int8> = ArrayList<Int8>([
            Int8(0), Int8(0), Int8(0), Int8(102), Int8(-2), Int8(-6), Int8(122), Int8(90), 
            Int8(31), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(2),
            Int8(55), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0),
            Int8(23), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(3),
            Int8(11), Int8(-103), Int8(20), Int8(31), Int8(85), Int8(84), Int8(93), Int8(0)])
        let buf : List<String> = ArrayList<String>()
        ignoreScope {interpRand(randomness0, {=> 
            expandS(buf, false, { => perform S()})
        })}

        let expected = "1aa"
        let actual : ?String = buf.iterator().reduce({s, e => s + e})
        match (actual) {
            case Some(act) => for (i in 0..3) { @Expect(expected[i], act[i]) }
            case _ => failExpect("Output should be a string.")
        }
    }
}

// prog that handles One with true
/* THE FOLLOWING CODE RETURNS BROKEN LLVM IR. !!!! */
/* 
import stdx.effect.*

class One <: Command<Unit> {}

func one() {
    perform One()
}

func handleOneAsFalse(fn : () -> Unit): Bool {
    let res = try { fn(); true } handle(e: One) {
        false
    }
    res
}

let res = handleOneAsFalse(one)
*/