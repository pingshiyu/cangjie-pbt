// withFile and entry point for filesystem PBT. Run from repo root so tmp/ is available.
package cangjie_experiments

import std.collection.*
import std.random.*
import std.fs.*
import cangjie_experiments.define.*
import cangjie_experiments.resumptions.*
import cangjie_experiments.resumptions.loop.*
import cangjie_experiments.pbt.*

// withFile(path, k): opens file at path, stores in currentFile box, runs k(file), then closes in finally.
// Double-close occurs if k performs Switch() and the handler runs the close-current-file UnitFn.
func withFile(path: Path, k: (File) -> Unit): Unit {
    let f = File(path, OpenMode.Read)
    try {
        k(f)
    } finally {
        f.close()
    }
}

// Entry: build libFs with shared box, ensure tmp exists, run withFile under executeUntilDone in runInContext.
public func main_fs_testing(): Unit {
    ensureTmpExists()
    func withFileBound(path: Path, k: (File) -> Unit): Unit {
        withFile(path, k)
    }
    let seed: Option<UInt64> = Some(Random().nextUInt64())
    runInContext(seed, getLibFs(), 20) {
        executeUntilDone(@RunRandomly([path in randPathInTmp, k in randFunc<File, Unit>], withFileBound))
    }
}
