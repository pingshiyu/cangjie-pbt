# Testing Using Resumptions

## Initial Implementation
In place of a function of type `Unit -> Unit`, we use an effect `e` of type `Unit -> Unit`.

This effect is interpreted as:
- Save existing resumption to the function call
- Resume a random resumption, or start a new function call

Note that throughout the execution process, the number:
- `#pending_function_calls + #pending_resumptions`
stays constant.

## Generalising to Arbitrary Types
However, the above only executes functions of type `Unit -> Unit`.

The issue is that behaviours of functions cannot be tested effectively - they execute 
independently apart from global side effects of the functions. 

We need to pass parameters into functions in a random way as well. This would tie the 
execution of one function into another. 

When functions return a value, we would also look for a resumptions that could take it,
and launch that resumption. 

If none could take it, we would need a fallback. We can use a random value generator 
as a backup. I.e. throw away the value generated, and relaunch a resumption using what 
we have.