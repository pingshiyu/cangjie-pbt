package cangjie_experiments

import cangjie_experiments.define.*
import stdx.effect.*
import std.collection.*
import std.random.*

func asList<A>(it: Iterable<A>): List<A> {
    let o: List<A> = ArrayList<A>()
    for (e in it) {
        o.add(e)
    }
    return o
}

// perhaps then we can follow the deduction rules to get the 
// correct spec for execution?

func mapE<A, B>(f : (A) -> B, ls : List<A>): List<B> {
    println("reached mapE")
    let oElems: List<B> = ArrayList<B>()
    println("mapE: oElems prepared.")
    for (e in ls) {
        println("mapE: calling f")
        oElems.add(f(e))
        println("mapE: called f")
    }
    return oElems
}

func map2E<A, B>(f : (A) -> B, ls : List<A>): List<B> {
    println("reached map2E")
    let oElems: List<B> = ArrayList<B>()
    var i : Int64 = 0
    println("map2E: oElems prepared.")
    for (e in ls) {
        if (i % 2 != 0) {
            println("map2E: calling f")
            oElems.add(f(e))
            println("map2E: called f")
        }
        i += 1
    }
    return oElems
}

func filterE<A>(f : (A) -> Bool, ls : List<A>): List<A> {
    let oElems: List<A> = ArrayList<A>()
    for (e in ls) {
        if (f(e)) {
            oElems.add(e)
        }
    }
    return oElems
}

// import functions from the std
// need some basic generators for basic types
// we can use generators for function types: 
// - either quickcheck approach of Gen (a -> b) = a -> Gen b
// - or using our approach of resuming, if possible, a resumption

// good options: option.cj, array.cj, concurrent_hash_map.cj, middle_operation.cj,
//  end_operation.cj

// currently: experiment with f(i), filterE, mapE, map2E

// std.collections.end_collection: reduce<T>(operation: (T, T) -> T): (Iterable<T>) -> Option<T>
// std.collections.end_collection: isEmpty<T>(it: Iterable<T>): Bool
// std.collections.end_collection: count<T>(it: Iterable<T>): Int64
// std.collections.end_collection: contains<T>(element: T): (Iterable<T>) -> Bool
// std.collections.end_collection: any<T>(predicate: (T) -> Bool): (Iterable<T>) -> Bool
// std.collections.end_collection: none<T>(predicate: (T) -> Bool): (Iterable<T>) -> Bool
// std.collections.end_collection: forEach<T>(action: (T) -> Unit): (Iterable<T>) -> Unit

// f(i) :: Int -> Int

// isEmpty :: Iter A -> Bool

// count :: Iter A -> Int64

// contains :: A -> Iter A -> Bool
// containsFaked: create a function that will generate a random `x` and be `contains x` 

// reduce :: (A -> A -> A) -> Iter A -> Option A
func reduceFaked<A>(xs: List<A>): Option<A> {
    return reduce<A>(unpack(fake<(A, A), A>))(xs)
}

// any :: (A -> Bool) -> Iter A -> Bool
func anyFaked<A>(xs: List<A>): Bool {
    println("any called")
    return any(fake<A, Bool>)(xs)
}

// none :: (A -> Bool) -> Iter A -> Bool
func noneFaked<A>(xs: List<A>): Bool {
    println("none called")
    return none(fake<A, Bool>)(xs)
}

// all :: (A -> Bool) -> Iter A -> Bool
func allFaked<A>(xs: List<A>): Bool {
    println("all called")
    return all(fake<A, Bool>)(xs)
}

// forEach :: (A -> Unit) -> Iter A -> Unit
func forEachFaked<A>(xs: List<A>): Unit {
    return forEach(fake<A, Unit>)(xs)
}

// filterE :: (A -> Bool) -> [A] -> [A]
func filterEFaked<A>(xs : List<A>): List<A> {
    return filterE<A>(fake<A, Bool>, xs)
}

func filterFaked<A>(xs: List<A>): List<A> {
    asList(filter<A>(fake<A, Bool>)(xs))
}

// mapE :: (A -> B) -> [A] -> [B]
func mapEFaked<A, B>(xs : List<A>): List<B> {
    return mapE<A, B>(fake<A, B>, xs)
}

// map2E :: (A -> B) -> [A] -> [B]
func map2EFaked<A, B>(xs : List<A>): List<B> {
    return map2E<A, B>(fake<A, B>, xs)
}

func mapFaked<A, B>(xs: List<A>): List<B> {
    asList(map(fake<A, B>)(xs))
}

func filterMapFaked<A, B>(xs: List<A>): List<B> {
    asList(filterMap<A, B>(fake<A, ?B>)(xs))
}

func flatMapFaked<A, B>(xs: List<A>): List<B> {
    asList(flatMap(fake<A, Iterable<B>>)(xs))
}

//             | 0.   | 1.  | 2.  | 3.         | 4. 
@StashFromTypes([Int64, Bool, Unit, List<Int64>, Option<Int64>])

main() {
    mainHarness()

    /*
    let s : StashG_ = StashG_()
    s.fns_0_0.setStash(ArrayList<(Int64) -> Int64>([
        fint_mul(0), fint_add(1), fint_mul(2), fint_add(3) 
    ]))
    s.fns_0_1.setStash(ArrayList<(Int64) -> Bool>([
        
    ]))
    s.fns_0_2.setStash(ArrayList<(Int64) -> Unit>([

    ]))
    s.fns_3_3.setStash(ArrayList<(List<Int64>) -> List<Int64>>([
        mapEFaked<Int64, Int64>, map2EFaked<Int64, Int64>, mapFaked<Int64, Int64>, 
        filterEFaked<Int64>, filterFaked<Int64>, 
        filterMapFaked<Int64, Int64>
    ]))
    s.fns_3_1.setStash(ArrayList<(List<Int64>) -> Bool>([
        anyFaked<Int64>, noneFaked<Int64>, allFaked<Int64>, 
        isEmpty<Int64>, contains<Int64>(0), contains<Int64>(1), contains<Int64>(-1)
    ]))
    s.fns_3_4.setStash(ArrayList<(List<Int64>) -> Option<Int64>>([
        reduceFaked<Int64>, max<Int64>, min<Int64>, first<Int64>, last<Int64>
    ]))
    s.fns_3_0.setStash(ArrayList<(List<Int64>) -> Int64>([
        count<Int64>
    ]))

    let r : Random = Random()
    let output = runExtRand(r) { s.handleStash { handleUnknown {
        let input : List<Int64> = randList<Int64>(10, randInt64)()
        println("input: ${showList(", ", input)}")
        mapEFaked<Int64, Int64>(input)
    }}}

    println("output: ${output[0]}")
    */

    return 0
}
