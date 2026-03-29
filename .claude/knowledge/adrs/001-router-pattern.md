# ADR-001: Centralized SDK Router Pattern

## Status
Accepted

## Context
Network SDKs on iOS typically use delegate-based callbacks. When multiple ad placements are active simultaneously, a single delegate must route callbacks to the correct ad request. The network SDK often supports only one delegate instance.

## Decision
Each network adapter uses a Router class (`GADMediation{Network}Router`) that:
- Acts as the single delegate for the network SDK
- Maintains a mapping of placement IDs to active ad request objects
- Routes SDK callbacks to the correct format-specific handler
- Manages shared SDK initialization state
- Is implemented as a singleton or shared instance

Format-specific classes (banner, interstitial, rewarded) register with the Router and receive their callbacks through it.

## Consequences
- Correctly handles concurrent ad requests across multiple placements
- Single point of SDK lifecycle management
- Format-specific classes are decoupled from direct SDK delegate registration
- Router must be thread-safe for concurrent ad operations
- Adds an indirection layer between the network SDK and format handlers
- Router state must be cleaned up when ad objects are deallocated
