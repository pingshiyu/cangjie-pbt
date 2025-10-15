import std.effect.{Command, Resumption}

// eff is a effect of () -> Int64 ! [Eff]
class Eff <: Command<Int64> {}

main() {
    try {
        println(1)
        let x = perform Eff()
        println(x)
    } handle (e: Eff, next: Resumption<Int64>) {
        // rewrites Eff with println(2)
        println(2)
        resume next with 3 // next(3)
    }

    println("yooo wassup cangjie")

    // expected output: 1\n2\n3\n"yooo wassup cangjie"
}