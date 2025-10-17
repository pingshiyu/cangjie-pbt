package cangjie_experiments

import std.unittest.*
import std.collection.*
import std.unittest.testmacro.*

@Test
class AddTests {
    @TestCase
    func createListLength3Controlled() {
        // a random list of length 3.
        let randomness : List<Int8> = ArrayList<Int8>([
            Int8(3), Int8(-1), Int8(100), Int8(102), 
            Int8(-1), Int8(-6), Int8(122), Int8(92), 
            Int8(31), Int8(-103), Int8(20), Int8(31), 
            Int8(85), Int8(84), Int8(93)])
        let l : List<Int64> = interpRand<List<Int64>>(randomness, { =>
            randList()
        })
        let expected : List<Int64> = ArrayList<Int64>([100, 102, -1])

        @Expect(l.size, expected.size)
        for (i in 0..3) {
            @Expect(l[i], expected[i])
        }
    }
}