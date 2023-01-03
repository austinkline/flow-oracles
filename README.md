# flow-oracles

Oracles are an important piece of infrastructure for any blockchain. 
They allow for things like price feeds for defi exchanges, random number generation
from outside sources, or gather custom api info from external sources to be used on-chain.

## How it works

There are two types of oracles highlighted here that can be hooked into:
- RandomNumberGenerator
- HTTP (with multiple flavors for GET and POST)

When an oracle is called, it is picked up to be executed in a separate transaction with whatever
request has been given to it. That could be the request for a random number or for an HTTP endpoint payload.
The oracle will deduct a small amount of FLOW tokens in order to pay for the infrastructure needed to support itself,
or perhaps a native token in the future should there be desire/need for it in the community.

The main resource in play is the Executor interface

```cadence
pub resource interface Executor {
    pub fun Callback(): AnyStruct?
}
```