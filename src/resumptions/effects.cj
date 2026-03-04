package cangjie_experiments.resumptions

import stdx.effect.*
import std.random.*

// ================ Unit public type resumptions ================
/*
Todo:
- Turn library functions into ones that uses Switch
- Try running a library of functions
- Running functions that requires a state (part of an object) 
- make private fns public, and run them
*/

// Switch: effect that takes an A and returns a B
public class Switch <: Command<Unit> {}

public type Res = Resumption<Unit, Unit>
public type UnitFn = () -> Unit