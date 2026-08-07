# Showline state architecture

## Why one session state

A live presentation is a synchronized room, not a collection of unrelated screens. The MVP therefore stores the presentation status, spotlighted product, connected buyers, and buyer interest events in one immutable `ShowlineSession`. Riverpod exposes focused selectors so widgets rebuild only when the data they display changes.

## Update path

1. A seller or buyer action calls an intent on `ShowlineSessionController`.
2. The controller validates the action and performs an optimistic immutable update.
3. `SessionRepository` sends the mutation to the transport.
4. The controller confirms the update or rolls back to the prior state on failure.
5. Riverpod selectors update only the affected UI.

## Production transport

`DemoSessionRepository` simulates network latency. For a multi-device release, replace it with a Firestore repository using this shape:

- `sessions/{sessionId}`: status, active product, seller, title, join code
- `sessions/{sessionId}/participants/{buyerId}`: identity and presence heartbeat
- `sessions/{sessionId}/interests/{buyerId_productId}`: buyer/product pair and timestamp
- A document snapshot stream hydrates `ShowlineSession`.
- Transactions protect spotlight version numbers from stale seller clients.
- Presence uses heartbeats plus server timestamps; the UI derives online state.

The UI depends on the repository interface, so this transport swap does not require redesigning the seller or buyer views.
