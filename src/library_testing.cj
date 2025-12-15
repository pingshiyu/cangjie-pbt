package cangjie_experiments

import stdx.effect.*
import std.collection.*
import std.random.*

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
// filterE :: (A -> Bool) -> [A] -> [A]
// mapE :: (A -> B) -> [A] -> [B]
// map2E :: (A -> B) -> [A] -> [B]

// reduce :: (A -> A -> A) -> Iter A -> Option A
// isEmpty :: Iter A -> Bool
// count :: Iter A -> Int64
// contains :: A -> Iter A -> Bool
// any :: (A -> Bool) -> Iter A -> Bool
// none :: (A -> Bool) -> Iter A -> Bool
// forEach :: (A -> Unit) -> Iter A -> Unit

func filterEFaked<A>(xs : List<A>): List<A> {
    return filterE<A>(fake<A, Bool>, xs)
}

func mapEFaked<A, B>(xs : List<A>): List<B> {
    return mapE<A, B>(fake<A, B>, xs)
} 

func map2EFaked<A, B>(xs : List<A>): List<B> {
    return map2E<A, B>(fake<A, B>, xs)
}

main() {
    let fns_intint: List<(Int64) -> Int64> = ArrayList<(Int64) -> Int64>([
        fint_add(1),
        fint_mul(2),
        fint_mul(3),
        fint_add(4)
    ])

    // doing this for mapE and map2E
    let r : Random = Random()
    let s : Stash = Stash(fns_intint)
    let output : List<Int64> = runExtRand(r) {
        handleStash(s) {
            let input : List<Int64> = randList<Int64>(10, randInt64)()
            println("input: ${showList(", ", input)}")
            handleUnknown<List<Int64>, Int64, Int64, List<Int64>>(mapEFaked<Int64, Int64>)(randList<Int64>(10, randInt64)())
        }
    }

    println("output: ${showList(", ", output)}")

    return 0
}
