// Path and content generators for filesystem PBT. Tests assume cwd is repo root and use tmp/ under it.
package cangjie_experiments

import std.collection.*
import std.math.abs
import std.random.*
import std.fs.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*

// Base path for test files (tmp directory within cangjie-pbt repo; run from repo root).
public const TMP_BASE: String = "tmp"

// Short names to increase path collision and double-close likelihood.
let SHORT_NAMES: ArrayList<String> = ArrayList(["a", "b", "x", "ab", "xy"])

// Short content strings for file write/append (small arguments).
let SHORT_CONTENTS: ArrayList<String> = ArrayList(["x", "y", "1", "ab"])

// Returns a random path under TMP_BASE with a short filename.
public func randPathInTmp(): Path {
    let r = perform GetRandom()
    let n = SHORT_NAMES.size
    let idx = abs(r.nextInt64()) % Int64(n)
    let name = SHORT_NAMES[idx]
    return Path(TMP_BASE).join(name)
}

// Returns a short random string for file content (small arguments).
public func randSmallString(): String {
    let r = perform GetRandom()
    let n = SHORT_CONTENTS.size
    let idx = abs(r.nextInt64()) % Int64(n)
    return SHORT_CONTENTS[idx]
}

// Returns small content as Array<Byte> for File.writeTo/appendTo.
public func randSmallBytes(): Array<Byte> {
    return randSmallString().toArray()
}

// Ensures tmp directory exists and at least one short-named file exists so withFile(..., Read) can open it.
public func ensureTmpExists(): Unit {
    let p = Path(TMP_BASE)
    if (!exists(p)) {
        try {
            Directory.create(p, recursive: true)
        } catch (_: FSException) {
            ()
        }
    }
    let seedFile = Path(TMP_BASE).join("a")
    if (!exists(seedFile)) {
        try {
            File.writeTo(seedFile, "x".toArray())
        } catch (_: FSException) {
            ()
        }
    }
}
