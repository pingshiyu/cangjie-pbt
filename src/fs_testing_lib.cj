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
public func getLibFs(fg : FsContext): ArrayList<UnitFn> {
    ArrayList([
        @RunRandomly([path in fg.randPath], fg.exists),
        @RunRandomly([path in fg.randExistingPath], fg.remove),
        @RunRandomly([path in fg.randPath], fg.removeIfExists),
        @RunRandomly([path in fg.randFreshPath], fg.directoryCreateRecursive),
        @RunRandomly([path in fg.randFreshPath], fg.fileCreate), 
        @RunRandomly([path in fg.randExistingFilePath], fg.fileReadFrom),
        @RunRandomly([path in fg.randExistingFilePath, content in randSmallBytes], fg.fileWriteTo),
        @RunRandomly([path in fg.randExistingFilePath, content in randSmallBytes], fg.fileAppendTo),
    ])
}
