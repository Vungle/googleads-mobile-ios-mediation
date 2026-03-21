# ADR-003: Separate Bidding Implementation Classes

## Status
Accepted

## Context
Google Mobile Ads SDK supports both waterfall mediation and programmatic bidding (Open Bidding). These two paths have different initialization flows, ad request parameters, and callback handling. Combining both in a single class increases complexity.

## Decision
Bidding and waterfall implementations are separated into distinct classes:
- **Waterfall classes**: Handle traditional mediation with server parameters and waterfall ordering
- **Bidding classes**: Handle Open Bidding with bid tokens, signal collection, and auction-based ad loading

The main adapter class (`GADMediationAdapter{Network}`) determines which path to use and delegates to the appropriate implementation class. Both paths share the Router for SDK lifecycle management.

## Consequences
- Clean separation of concerns between bidding and waterfall logic
- Each class is simpler and easier to test independently
- Shared infrastructure (Router, Utils) is reused across both paths
- More files per adapter (bidding + waterfall variants per format)
- Adding a new ad format requires classes for both paths
- Publishers can use either or both monetization strategies
