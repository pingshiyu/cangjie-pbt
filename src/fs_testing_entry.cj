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

func dummyTester(path: Path, k: (File) -> Unit) : Unit {
    perform Switch()
    perform Switch()
    perform Switch()
}

// Entry: build libFs with shared box, ensure tmp exists, run withFile under executeUntilDone in runInContext.
public func main_fs_testing(): Unit {
    for (i in 0..1000) {
        let fg = FsContext("tmp")
        let seed: Option<UInt64> = None
        runInContext(seed, getLibFs(fg), 50) {
            fg.initialiseContext()
            executeUntilDone(@RunRandomly([path in fg.randExistingFilePath, k in randFunc<File, Unit>], dummyTester))
        }
        fg.cleanup()
        println("********** Iteration ${i} completed **********")
    }
}
