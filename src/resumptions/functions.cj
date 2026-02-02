package cangjie_experiments.resumptions

import std.collection.*
import cangjie_experiments.utils.*

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
// std.collections.end_collection: none<T>(predicate: (T) -> Bool): (Iterable<T>) -> Bool

// f(i) :: Int -> Int

// isEmpty :: Iter A -> Bool

// count :: Iter A -> Int64

// contains :: A -> Iter A -> Bool
// containsFaked: create a function that will generate a random `x` and be `contains x` 

// reduce :: (A -> A -> A) -> Iter A -> Option A
public func reduce_<A>(r: (A, A) -> A, xs: List<A>): Option<A> {
    return reduce<A>(r)(xs)
}

// any :: (A -> Bool) -> Iter A -> Bool
public func any_<A>(p: (A) -> Bool, xs: List<A>): Bool {
    return any(p)(xs)
}

// none :: (A -> Bool) -> Iter A -> Bool
public func none_<A>(f: (A) -> Bool, xs: List<A>): Bool {
    println("none called")
    return none(f)(xs)
}

// all :: (A -> Bool) -> Iter A -> Bool
public func all_<A>(f: (A) -> Bool, xs: List<A>): Bool {
    println("all called")
    return all(f)(xs)
}

public func filter_<A>(f: (A) -> Bool, xs: List<A>): List<A> {
    asList(filter<A>(f)(xs))
}

public func map_<A, B>(f: (A) -> B, xs: List<A>): List<B> {
    asList(map(f)(xs))
}

public func filterMap_<A, B>(f: (A) -> ?B, xs: List<A>): List<B> {
    asList(filterMap<A, B>(f)(xs))
}

public func flatMap_<A, B>(f: (A) -> Iterable<B>, xs: List<A>): List<B> {
    asList(flatMap(f)(xs))
}

public func forEach_<A>(f: (A) -> Unit, xs: List<A>): Unit {
    forEach(f)(xs)
}