package cangjie_experiments

import cangjie_experiments.define.*

import stdx.effect.*
import std.collection.*
import std.random.*
import stdx.effect.*

class UserType {}

// @StashFromTypes([Int64, UserType, Float64, String, Int16, ArrayList<Int64>, ArrayList<UserType>, Unit, Bool, Int8, ArrayList<Int32>])
// @CreateTest([
//     fint_mul(1), (Int64) -> Int64,
//     mapEFaked<Int64, Int64>, (ArrayList<Int64>) -> ArrayList<Int64>, 
//     max<Int64>, (ArrayList<Int64>) -> Int64, 
//     min<Int64>, (ArrayList<Int64>) -> Int64, 
//     fint_mul(2), (Int64) -> Int64
//     ])

func macroMain(): StashG_ {
    let s = StashG_()

    testRunRandomly()

    return s
}

func testAdd(x: Int64, y: Int64): Int64 {
    return x + y
}

func testRunRandomly(): Unit {
    println("=== Testing @RunRandomly Macro ===")
    
    // Test 1: Two Int64 generators
    let randomAdder = @RunRandomly([x in randInt64, y in randInt64], testAdd)
    
    // Test 2: Mixed generator types
    let randomMultiplier = @RunRandomly([a in randInt64, b in randInt64], testAdd)
    
    let r = Random()
    
    println("Testing random adder:")
    for (i in 0..5) {
        let result = runExtRand(r, randomAdder)
        println("  ${i}: add result = ${result}")
    }
    
    println("\nTesting random multiplier:")
    for (i in 0..5) {
        let result = runExtRand(r, randomMultiplier)
        println("  ${i}: multiply result = ${result}")
    }
    
    println("\n=== Macro Test Complete ===")
}