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

// Parent is a parent of child iff child is under parent in path hierarchy (child has parent prefix followed by separator).
public func isParentOf(parent: stdFs.Path, child: stdFs.Path): Bool {
    let parentNorm = parent.normalize()
    let childNorm = child.normalize()
    let parentStr = parentNorm.toString()
    let childStr = childNorm.toString()
    if (parentStr == childStr) {
        return false
    }
    if (!childStr.startsWith(parentStr)) {
        return false
    }
    if (parentStr.size >= childStr.size) {
        return false
    }
    let sep = childStr[parentStr.size]
    return sep == b'/' || sep == b'\\'
}

public func findAndRemove<E>(e : E, ls : ArrayList<E>): Option<E> where E <: Equatable<E> {
    let idx = ls.indexOf(e)
    if (idx.isSome()) {
        ls.remove(at: idx.getOrThrow())
        return Some(e)
    }
    return None
}

// Remove from ls every path that is a child of parent (by path structure only; no filesystem calls).
public func removeAllChildPathsOf(parent: stdFs.Path, ls : ArrayList<stdFs.Path>): Unit {
    var i : Int64 = 0
    while (i < ls.size) {
        let path = ls[i]
        if (isParentOf(parent, path)) {
            ls.remove(at: i)
        } else {
            i += 1
        }
    }
}

public class FsContext {
    let existingFilePaths : ArrayList<stdFs.Path> = ArrayList()
    let existingFolderPaths : ArrayList<stdFs.Path> = ArrayList()
    let existingSymlinkPaths : ArrayList<stdFs.Path> = ArrayList()
    let tmpRoot : String
    var _absTmpRoot : Option<String> = None

    public FsContext(tmpRoot: String) {
        this.tmpRoot = tmpRoot
    }

    // Canonical form for state: paths under tmpRoot stored as relative (tmpRoot/...) so _removePath always matches.
    private func getAbsTmpRoot(): String {
        if (_absTmpRoot.isNone()) {
            _absTmpRoot = Some(stdFs.canonicalize(stdFs.Path(tmpRoot)).toString())
        }
        return _absTmpRoot.getOrThrow()
    }

    private func pathForState(path: stdFs.Path): stdFs.Path {
        let n = path.normalize()
        if (!n.isAbsolute()) {
            return n
        }
        let abs = getAbsTmpRoot()
        let s = n.toString()
        if (!s.startsWith(abs)) {
            return n
        }
        var rest = s.removePrefix(abs)
        if (rest.startsWith("/")) {
            rest = rest[1..]
        }
        return stdFs.Path(tmpRoot).join(rest).normalize()
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
        println("Existing symlink paths:")
        for (path in existingSymlinkPaths) {
            println("${path}")
        }
        println("--------------------------------")
    }

    // Recursively collect every path under root (in state form) into the three lists by type. Does not add root itself.
    private func collectAllPathsUnder(root: stdFs.Path, files: ArrayList<stdFs.Path>, dirs: ArrayList<stdFs.Path>, symlinks: ArrayList<stdFs.Path>): Unit {
        let children = stdFs.Directory.readFrom(root)
        for (info in children) {
            let statePath = pathForState(info.path)
            if (info.isDirectory()) {
                dirs.add(statePath)
                collectAllPathsUnder(info.path, files, dirs, symlinks)
            } else if (info.isSymbolicLink()) {
                symlinks.add(statePath)
            } else {
                files.add(statePath)
            }
        }
    }

    /**
     * Validates that (1) every path in FsContext exists on disk with the correct type, and
     * (2) every file/directory/symlink under tmpRoot on disk is recorded in FsContext.
     * Throws an exception with details if any check fails.
     */
    public func validateStateMatchesFilesystem(): Unit {
        var errors = ArrayList<String>()
        for (path in existingFilePaths) {
            if (!stdFs.exists(path)) {
                errors.add("Path ${path} in existingFilePaths does not exist on disk.")
            } else {
                let info = stdFs.FileInfo(path)
                if (!info.isRegular()) {
                    errors.add("Path ${path} in existingFilePaths is not a regular file on disk (isDirectory=${info.isDirectory()}, isSymbolicLink=${info.isSymbolicLink()}).")
                }
            }
        }
        for (path in existingFolderPaths) {
            if (!stdFs.exists(path)) {
                errors.add("Path ${path} in existingFolderPaths does not exist on disk.")
            } else {
                let info = stdFs.FileInfo(path)
                if (!info.isDirectory()) {
                    errors.add("Path ${path} in existingFolderPaths is not a directory on disk (isRegular=${info.isRegular()}, isSymbolicLink=${info.isSymbolicLink()}).")
                }
            }
        }
        for (path in existingSymlinkPaths) {
            if (!stdFs.exists(path)) {
                errors.add("Path ${path} in existingSymlinkPaths does not exist on disk.")
            } else {
                let info = stdFs.FileInfo(path)
                if (!info.isSymbolicLink()) {
                    errors.add("Path ${path} in existingSymlinkPaths is not a symbolic link on disk (isRegular=${info.isRegular()}, isDirectory=${info.isDirectory()}).")
                }
            }
        }
        // Each filesystem path under tmpRoot must be accounted for in FsContext (except tmpRoot itself, which we do not track).
        if (stdFs.exists(stdFs.Path(tmpRoot))) {
            let diskFiles = ArrayList<stdFs.Path>()
            let diskDirs = ArrayList<stdFs.Path>()
            let diskSymlinks = ArrayList<stdFs.Path>()
            collectAllPathsUnder(stdFs.Path(tmpRoot), diskFiles, diskDirs, diskSymlinks)
            for (path in diskFiles) {
                if (existingFilePaths.indexOf(path).isNone()) {
                    errors.add("Path ${path} exists on disk as a file but is not in existingFilePaths.")
                }
            }
            for (path in diskDirs) {
                if (existingFolderPaths.indexOf(path).isNone()) {
                    errors.add("Path ${path} exists on disk as a directory but is not in existingFolderPaths.")
                }
            }
            for (path in diskSymlinks) {
                if (existingSymlinkPaths.indexOf(path).isNone()) {
                    errors.add("Path ${path} exists on disk as a symbolic link but is not in existingSymlinkPaths.")
                }
            }
        }
        if (!errors.isEmpty()) {
            let msg = String.join(errors.toArray(), delimiter: "\n")
            throw Exception("FsContext state desync with filesystem:\n" + msg)
        }
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

    // Like randExistingFilePath but for directories: choose from existingFolderPaths or create one.
    public func randExistingDirPath(): stdFs.Path {
        if (!existingFolderPaths.isEmpty()) {
            randElem(existingFolderPaths)
        } else {
            createRandomFolder()
        }
    }

    // Path that does not exist and whose parent is in existingFolderPaths (for Directory.create(..., recursive: false)).
    public func randFreshPathWithExistingParent(): stdFs.Path {
        var path : stdFs.Path
        var loops : Int64 = 1
        do {
            let len = Int64(log(Float64(loops))) + 1
            if (!existingFolderPaths.isEmpty()) {
                let parent = randElem(existingFolderPaths)
                path = parent.join(randShortString(n:len)())
            } else {
                path = randPath(n:len)
            }
            loops += 1
        } while (exists(path))
        return path
    }

    // Fresh path under tmpRoot that is not equal to and not under prefix (for safe copy/rename when source is directory).
    public func randFreshPathNotUnder(prefix: stdFs.Path): stdFs.Path {
        var path : stdFs.Path
        var loops : Int64 = 1
        let prefixStr = prefix.normalize().toString()
        do {
            path = randFreshPath()
            loops += 1
        } while (path.normalize().toString().startsWith(prefixStr) || path.normalize() == prefix.normalize())
        return path
    }

    // Choose from existingSymlinkPaths; when empty returns a dummy path (runner must no-op when empty).
    public func randExistingSymlinkPath(): stdFs.Path {
        if (!existingSymlinkPaths.isEmpty()) {
            randElem(existingSymlinkPaths)
        } else {
            randPath()
        }
    }

    /* public api functions with semantics. Use normalized path so list membership matches. */
    private func _removePath(path: stdFs.Path): Unit {
        let n = path.normalize()
        findAndRemove(n, existingFilePaths)
        findAndRemove(n, existingFolderPaths)
        findAndRemove(n, existingSymlinkPaths)
        removeAllChildPathsOf(n, existingFilePaths)
        removeAllChildPathsOf(n, existingFolderPaths)
        removeAllChildPathsOf(n, existingSymlinkPaths)
    }
    
    public func exists(path: stdFs.Path): Bool {
        let result = stdFs.exists(path)
        validateStateMatchesFilesystem()
        return result
    }

    public func remove(path: stdFs.Path): Unit {
        _removePath(path)
        stdFs.remove(path, recursive: true)
        validateStateMatchesFilesystem()
    }

    public func removeIfExists(path: stdFs.Path): Unit {
        _removePath(path)
        stdFs.removeIfExists(path, recursive: true)
        validateStateMatchesFilesystem()
    }

    public func directoryCreateRecursive(path: stdFs.Path): Unit {
        existingFolderPaths.add(path.normalize())
        stdFs.Directory.create(path, recursive: true)
        validateStateMatchesFilesystem()
    }

    public func fileCreate(path: stdFs.Path): Unit {
        existingFilePaths.add(path.normalize())
        stdFs.File.create(path)
        validateStateMatchesFilesystem()
    }

    public func fileReadFrom(path: stdFs.Path): Array<Byte> {
        let result = stdFs.File.readFrom(path)
        validateStateMatchesFilesystem()
        return result
    }

    public func fileWriteTo(path: stdFs.Path, content: Array<Byte>): Unit {
        stdFs.File.writeTo(path, content)
        validateStateMatchesFilesystem()
    }

    public func fileAppendTo(path: stdFs.Path, content: Array<Byte>): Unit {
        stdFs.File.appendTo(path, content)
        validateStateMatchesFilesystem()
    }

    public func canonicalize(path: stdFs.Path): Unit {
        stdFs.canonicalize(path)
        validateStateMatchesFilesystem()
    }

    // Copy with overwrite. No-op if sourcePath == to or (when source is dir) to is under sourcePath.
    public func copyWithOverwrite(sourcePath: stdFs.Path, to: stdFs.Path): Unit {
        if (sourcePath.normalize() == to.normalize()) {
            return
        }
        if (existingFolderPaths.indexOf(sourcePath).isSome() && isParentOf(sourcePath, to)) {
            return
        }
        let wasFile = existingFilePaths.indexOf(sourcePath).isSome()
        let wasDir = existingFolderPaths.indexOf(sourcePath).isSome()
        let wasSym = existingSymlinkPaths.indexOf(sourcePath).isSome()
        stdFs.copy(sourcePath, to: to, overwrite: true)
        _removePath(to)
        let toN = to.normalize()
        if (wasFile) {
            existingFilePaths.add(toN)
        }
        if (wasDir) {
            existingFolderPaths.add(toN)
        }
        if (wasSym) {
            existingSymlinkPaths.add(toN)
        }
        validateStateMatchesFilesystem()
    }

    // TODO: copyWithoutOverwrite(sourcePath, to) – leave as TODO, not registered in getLibFs.
    // public func copyWithoutOverwrite(sourcePath: stdFs.Path, to: stdFs.Path): Unit { ... }

    // Rename with overwrite. No-op if sourcePath == to or (when source is dir) to is under sourcePath.
    public func renameWithOverwrite(sourcePath: stdFs.Path, to: stdFs.Path): Unit {
        if (sourcePath.normalize() == to.normalize()) {
            return
        }
        if (existingFolderPaths.indexOf(sourcePath).isSome() && isParentOf(sourcePath, to)) {
            return
        }
        let wasFile = existingFilePaths.indexOf(sourcePath).isSome()
        let wasDir = existingFolderPaths.indexOf(sourcePath).isSome()
        let wasSym = existingSymlinkPaths.indexOf(sourcePath).isSome()
        stdFs.rename(sourcePath, to: to, overwrite: true)
        _removePath(sourcePath)
        _removePath(to)
        let toN = to.normalize()
        if (wasFile) {
            existingFilePaths.add(toN)
        }
        if (wasDir) {
            existingFolderPaths.add(toN)
        }
        if (wasSym) {
            existingSymlinkPaths.add(toN)
        }
        validateStateMatchesFilesystem()
    }

    // TODO: renameWithoutOverwrite(sourcePath, to) - leave as TODO, not registered in getLibFs.

    public func directoryCreateNonRecursive(path: stdFs.Path): Unit {
        stdFs.Directory.create(path, recursive: false)
        existingFolderPaths.add(path.normalize())
        validateStateMatchesFilesystem()
    }

    public func directoryCreateTemp(directoryPath: stdFs.Path): Unit {
        let p = stdFs.Directory.createTemp(directoryPath)
        existingFolderPaths.add(pathForState(p))
        validateStateMatchesFilesystem()
    }

    public func directoryIsEmpty(path: stdFs.Path): Unit {
        try {
            stdFs.Directory.isEmpty(path)
        } catch (_) {
            _removePath(path)
        }
        validateStateMatchesFilesystem()
    }

    public func directoryReadFrom(path: stdFs.Path): Unit {
        try {
            stdFs.Directory.readFrom(path)
        } catch (_) {
            _removePath(path)
        }
        validateStateMatchesFilesystem()
    }

    public func directoryWalk(path: stdFs.Path): Unit {
        try {
            stdFs.Directory.walk(path) { _ => true }
        } catch (_) {
            _removePath(path)
        }
        validateStateMatchesFilesystem()
    }

    public func fileCreateTemp(directoryPath: stdFs.Path): Unit {
        let f = stdFs.File.createTemp(directoryPath)
        try {
            let p = f.info.path
            existingFilePaths.add(pathForState(p))
        } finally {
            f.close()
        }
        validateStateMatchesFilesystem()
    }

    public func symbolicLinkCreate(link: stdFs.Path, to: stdFs.Path): Unit {
        if (stdFs.exists(link)) {
            return
        }
        stdFs.SymbolicLink.create(link, to: to)
        existingSymlinkPaths.add(link.normalize())
        validateStateMatchesFilesystem()
    }

    public func symbolicLinkReadFrom(path: stdFs.Path): Unit {
        if (existingSymlinkPaths.isEmpty()) {
            return
        }
        stdFs.SymbolicLink.readFrom(path)
        validateStateMatchesFilesystem()
    }

    public func hardLinkCreate(link: stdFs.Path, to: stdFs.Path): Unit {
        if (link.normalize() == to.normalize()) {
            return
        }
        stdFs.HardLink.create(link, to: to)
        existingFilePaths.add(link.normalize())
        validateStateMatchesFilesystem()
    }

    public func cleanup(): Unit {
        // delete the tmp directory recursively
        println("Cleaning up, deleting tmp directory ${this.tmpRoot}")
        stdFs.removeIfExists(stdFs.Path(this.tmpRoot), recursive: true)
    }
}