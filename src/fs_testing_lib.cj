// libFs: list of UnitFns from std.fs for PBT. Shared state (Box<Option<File>>) for close-current-file.
package cangjie_experiments

import std.collection.*
import std.fs.*
import stdx.effect.*
import cangjie_experiments.define.*
import cangjie_experiments.resumptions.loop.*
import cangjie_experiments.resumptions.*

// Wrappers for fs APIs so @RunRandomly can pass (path, ...).
func fsWriteTo(path: Path, buffer: Array<Byte>): Unit {
    File.writeTo(path, buffer)
}

func fsAppendTo(path: Path, buffer: Array<Byte>): Unit {
    File.appendTo(path, buffer)
}

func createDirRecursive(path: Path): Unit {
    Directory.create(path, recursive: true)
}

// Builds libFs: path-based std.fs UnitFns plus close-current-file. Uses tmp under repo root.
public func getLibFs(): ArrayList<UnitFn> {
    ArrayList([
        @RunRandomly([path in randPathInTmp], exists),
        @RunRandomly([path in randPathInTmp], remove),
        @RunRandomly([path in randPathInTmp], removeIfExists),
        @RunRandomly([path in randPathInTmp], createDirRecursive),
        @RunRandomly([path in randPathInTmp], File.create),
        @RunRandomly([path in randPathInTmp], File.readFrom),
        @RunRandomly([path in randPathInTmp, content in randSmallBytes], fsWriteTo),
        @RunRandomly([path in randPathInTmp, content in randSmallBytes], fsAppendTo),
    ])
}
