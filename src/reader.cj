package cangjie_experiments

import stdx.effect.*

// simulate reader-like effects using an external state

public class GetDepth <: Command<Int64> {
    public func defaultImpl() : Int64 { 0 }
}

func deeper<T>(f : () -> T) : Unit {
    try {
        f()
    } handle (e : GetDepth) {
        resume with ((perform e) + 1) 
    }
}

/*
func testGetDepth() {
    let d1 = perform GetDepth()
    println("depth: ${d1}")
    deeper {
        let d2 = perform GetDepth() 
        println("depth: ${d2}")
        deeper {
            let d3 = perform GetDepth() 
            println("depth: ${d3}")
        }
        let d4 = perform GetDepth() 
        println("depth: ${d4}")
    }
    let d5 = perform GetDepth() 
    println("depth: ${d5}")
}
*/

// f :: FakeEffects -> P -> T 
// as fake reader.
class FakeEffects<R> {
    public FakeEffects(let i : R) {}

    func transform(t : (R) -> R): FakeEffects<R> {
        return FakeEffects(t(i))
    }

    func ask() : R {
        return i
    }
}

func local<R, T>(t : (R) -> R, fe : FakeEffects<R>, f : (FakeEffects<R>) -> T): T {
    return f(fe.transform(t))
}

// fakeDeeper :: r -> (r -> t) -> t
func fakeDeeper<T>(fe : FakeEffects<Int64>, f : (FakeEffects<Int64>) -> T): Unit {
    local<Int64, T>({i: Int64 => i + 1}, fe, f)
    return ()
}

/*
func fakeTestGetDepth() {
    let fe = FakeEffects(0)
    println("depth: ${fe.ask()}")
    fakeDeeper(fe, { fe => 
        println("depth: ${fe.ask()}")
        fakeDeeper(fe, { fe => 
            println("depth: ${fe.ask()}")
        })
        println("depth: ${fe.ask()}")
    })
    println("depth: ${fe.ask()}")
}

func mainReader() {
    println("Effects-based implementation:")
    testGetDepth()

    println("Fake effects-based implementation")
    fakeTestGetDepth()
}
*/