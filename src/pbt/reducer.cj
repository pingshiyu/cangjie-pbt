package cangjie_experiments.pbt

import std.collection.*

// reduces the subtree 
public interface ReductionStrategy {
    /* Make a single reduction to `wt`.
    Return true iff the tree has been changed. */
    public func findInterestingReduction(wt: RandTree, interesting: (List<RUnit>) -> Bool): Bool

    /* Returns an iterable to all subtrees of `t`: this includes `t` itself. */
    static public func refsToSubtrees(t: RandTree): Iterable<RandTree> {
        let lt = LinkedList<RandTree>()
        func refsToSubtrees_(lt : LinkedList<RandTree>, t : RandTree): Unit {
            lt.addLast(t)
            for (c in t.children) {
                refsToSubtrees_(lt, c)
            }
        }
        refsToSubtrees_(lt, t)
        return lt
    }
}

/* Attempt a reduction at every spot, this will take time O(n^2) for n RUnits. */
public class ReduceToSimpleStrategy <: ReductionStrategy {

    /* Attempt reductions at every location, stop if an interesting reduction is found.
    Return a boolean to indicate whether an interesting reduction were found. */
    public func findInterestingReduction(wt: RandTree, interesting: (List<RUnit>) -> Bool): Bool {
        let simpleVals = HashSet<RUnit>([0, 1, -1])
        for (tp in refsToSubtrees(wt)) {
            for (i in 0..tp.node.size) {
                // keep old value, rollback if not interesting.
                let old = tp.node[i]

                // skip if value is already simple
                if (simpleVals.contains(old)) { continue }
                
                // try with "simple values", in our case it is 0, -1 or 1, with 0 being the simplest.
                for (rv in simpleVals) {
                    tp.replace(i, rv)
                    // TODO: maybe try to keep track of the tree as well, and update the tree to the reduced
                    // tree if it turns out to be interesting
                    if (!interesting(wt.randList())) {
                        tp.replace(i, old)
                    } else {
                        // is interesting. restart the process from the beginning.
                        return true
                    }
                }
            }
        }
        return false
    }
}

/* Make reductions with the default reduction strategy (of applying our reduction strategies
one by one in a loop). */
public func makeReduction(rs: List<RUnit>, hasProp: () -> Bool) : RandTree {
    // run the program once to build the initial randtree, also check that it is interesting
    // this assumes interesting is a public function that uses randomness effects
    let rt = RandTree(None, None)
    let rtb = Box<RandTree>(rt)
    let rsu = ArrayList<RUnit>(rs)
    let initiallyInteresting = runRandTracked(rs, rtb, hasProp)

    if (!initiallyInteresting) {
        throw WrongArgumentException("Input public function, along with random seed, does not contain prop to begin with.")
    }

    // run apply to get the reduced tree
    func interesting(rss: List<RUnit>) : Bool {
        let rsu = ArrayList<RUnit>(rss)
        try { // unfortunate: cannot use an effect here but rather a try/catch
            handleOutOfRandAsError { runRand(rsu, hasProp) }
        } catch(e: WrongArgumentException) {
            false
        }
    }

    let workingTree : RandTree = randTreeDeepCopy(rt, None)

    var reduced = true
    while (reduced) {
        reduced = ReduceToSimpleStrategy().findInterestingReduction(workingTree, interesting)
    }
    
    return workingTree
}