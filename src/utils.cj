package cangjie_experiments

import std.collection.*
import std.core.*

func showList<T>(sep : String, l : List<T>): String where T <: ToString {
    return "[" + showInterleave(sep, l) + "]"
}

func showInterleave<T>(sep : String, l : List<T>) : String where T <: ToString {
    if (l.isEmpty()) { return "" }
    if (l.size == 1) { return l[0].toString() }

    let sb = StringBuilder()
    sb.append(l[0].toString())
    var i = 0
    for (i in 1..l.size) {
        sb.append(sep)
        sb.append(l[i].toString())
    }
    sb.toString()
}

func showTabs(n : Int64) : String {
    return "    " * n
}

func showMaybe<T>(n : Option<T>) : String where T <: ToString {
    match (n) {
        case None => "None"
        case Some(t) => t.toString()
    }
}