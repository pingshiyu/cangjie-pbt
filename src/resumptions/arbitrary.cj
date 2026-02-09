package cangjie_experiments.resumptions

import cangjie_experiments.pbt.*
import std.collection.*
import effects.*

public class ArbitraryGen {
    public func sHandle<Y>(fn: () -> Y): Y {
        try_ {
            fn()
        } .handle { _: GenRandom<Int64> =>
            randSmallInt64()
        } .handle { _: GenRandom<Int8> =>
            randInt8()
        } .handle { _: GenRandom<Unit> =>
            ()
        } .handle { _: GenRandom<Bool> =>
            randBool(0.50)
        } .handle { _: GenRandom<ArrayList<Bool>> =>
            let vs = randList(8, randBool_(0.50))()
            ArrayList(vs)
        } .handle { _: GenRandom<String> =>
            "not random."
        } .handle { _: GenRandom<Option<Bool>> =>
            randOption(0.90, randBool_(0.50))()
        } .then_finally {}
    }
}