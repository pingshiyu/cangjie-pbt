// Path and content generators for filesystem PBT. Tests assume cwd is repo root and use tmp/ under it.
package cangjie_experiments

import std.collection.*
import std.math.*
import std.random.*
import std.fs as stdFs
import cangjie_experiments.resumptions.*
import cangjie_experiments.pbt.*

// ArrayList has no indexOf in stdlib; extend it to match Array behavior.
extend<T> ArrayList<T> where T <: Equatable<T> {
    public func indexOf(element: T): Option<Int64> {
        for (i in 0..this.size) {
            if (this[i] == element) {
                return Some(i)
            }
        }
        return None
    }
}

public func isParentOf(parent: stdFs.Path, child: stdFs.Path): Bool {
    // normalise both normalise both paths
    let parentNorm = parent.normalize()
    let childNorm = child.normalize()
    // use string check to see if parent is a parent of child
    let parentStr = parentNorm.toString()   
    let childStr = childNorm.toString()
    return childStr.startsWith(parentStr)
}

public func findAndRemove<E>(e : E, ls : ArrayList<E>): Option<E> where E <: Equatable<E> {
    let idx = ls.indexOf(e)
    if (idx.isSome()) {
        ls.remove(at: idx.getOrThrow())
        return Some(e)
    }
    return None
}

public func removeAllChildPathsOf(parent: stdFs.Path, ls : ArrayList<stdFs.Path>): Unit {
    // ensure file exists at path
    if (!stdFs.exists(parent)) {
        return
    }

    // check if the path is a directory
    // first get the file info
    let info = stdFs.FileInfo(parent)
    let isDir = info.isDirectory()
    if (!isDir) {
        return
    }

    // iterate over the list by while loop over indices, remove all children of parent
    var i : Int64 = 0
    while (i < ls.size) {
        let path = ls[i]
        if (isParentOf(parent, path)) {
            ls.remove(at: i)
            println("removing, list length is ${ls.size}")
        } else {
            i += 1
            println("not removing, list length is ${ls.size}")
        }
    }
}

public class FsContext {
    let existingFilePaths : ArrayList<stdFs.Path> = ArrayList()
    let existingFolderPaths : ArrayList<stdFs.Path> = ArrayList()
    let tmpRoot : String

    public FsContext(tmpRoot: String) {
        this.tmpRoot = tmpRoot
    }

    public func printPaths(): Unit {
        println("--------------------------------")
        println("Existing file paths:")
        for (path in existingFilePaths) {
            println("${path}")
        }
        println("Existing folder paths:")
        for (path in existingFolderPaths) {
            println("${path}")
        }
        println("--------------------------------")
    }

    public func initialiseContext(): Unit {
        // create a random folder and a random file
        let folder = createRandomFolder()
        let file = createRandomFile()
    }

    // Returns a random path under TMP_BASE with a short filename.
    public func randPath(n !: Int64 = 1): stdFs.Path {
        if (n < 0) {
            throw Exception("randPath: n must be >= 0, got " + n.toString())
        }
        // optionally add a path to an exsiting folder, if one exists
        let pathInsideFolder: Bool = randBool(0.50)
        if (pathInsideFolder && !existingFolderPaths.isEmpty()) {
            let folder = randElem(existingFolderPaths)
            return folder.join(randShortString(n:n)())
        } else {
            return stdFs.Path(tmpRoot).join(randShortString(n:n)())
        }
    }

    public func randFreshPath(): stdFs.Path {
        var path : stdFs.Path
        var loops : Int64 = 1
        do {
            // length is the (log of the number of loops) + 1
            let len = Int64(log(Float64(loops))) + 1
            path = randPath(n:len)
            loops += 1
        } while (exists(path))
        return path
    }

    public func createRandomFile(): stdFs.Path {
        let path = randFreshPath()
        fileCreate(path)
        let contentLength = randIntRange(1, 10)
        let content = randSmallBytes(n:contentLength)()
        fileWriteTo(path, content.toArray())
        return path
    }

    public func createRandomFolder(): stdFs.Path {
        let path = randFreshPath()
        directoryCreateRecursive(path)
        return path
    }

    public func randExistingFilePath(): stdFs.Path {
        // choose from existingFilePaths
        if (!existingFilePaths.isEmpty()) {
            // open a random file if exists
            randElem(existingFilePaths)
        } else {
            // create a random file and return its path
            createRandomFile()
        }
    }

    public func randExistingPath(): stdFs.Path {
        let combined = existingFilePaths.clone()
        combined.add(all:existingFolderPaths)
        if (!combined.isEmpty()) {
            randElem(combined)
        } else {
            // create a random folder or file and return its path
            let createFolder = randBool(0.50)
            if (createFolder) {
                createRandomFolder()
            } else {
                createRandomFile()
            }
        }
    }

    /* public api functions with semantics */
    private func _removePath(path: stdFs.Path): Unit {
        // print out paths before removal
        // printPaths()
        findAndRemove(path, existingFilePaths)
        findAndRemove(path, existingFolderPaths)
        removeAllChildPathsOf(path, existingFilePaths)
        removeAllChildPathsOf(path, existingFolderPaths)
        // printPaths()
    }
    
    public func exists(path: stdFs.Path): Bool {
        return stdFs.exists(path)
    }

    public func remove(path: stdFs.Path): Unit {
        _removePath(path)
        stdFs.remove(path, recursive: true)
    }

    public func removeIfExists(path: stdFs.Path): Unit {
        _removePath(path)
        stdFs.removeIfExists(path, recursive: true)
    }

    public func directoryCreateRecursive(path: stdFs.Path): Unit {
        existingFolderPaths.add(path)
        stdFs.Directory.create(path, recursive: true)
    }

    public func fileCreate(path: stdFs.Path): Unit {
        existingFilePaths.add(path)
        stdFs.File.create(path)
    }

    public func fileReadFrom(path: stdFs.Path): Array<Byte> {
        stdFs.File.readFrom(path)
    }

    public func fileWriteTo(path: stdFs.Path, content: Array<Byte>): Unit {
        stdFs.File.writeTo(path, content)
    }

    public func fileAppendTo(path: stdFs.Path, content: Array<Byte>): Unit {
        stdFs.File.appendTo(path, content)
    }

    public func cleanup(): Unit {
        // delete the tmp directory recursively
        println("Cleaning up, deleting tmp directory ${this.tmpRoot}")
        stdFs.removeIfExists(stdFs.Path(this.tmpRoot), recursive: true)
    }
}