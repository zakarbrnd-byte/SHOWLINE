# Showline

Showline is a live collection presentation app for sellers and buyers. A seller can run a session, move through a collection, spotlight products, and watch buyer interest arrive in real time. Buyers join with a short code, follow the presentation, and save the products they like.

## MVP

- Seller dashboard with session controls and live buyer activity
- Buyer join flow and presentation view
- Shared, immutable session state managed with Riverpod
- Product spotlighting and buyer interest tracking
- Responsive layouts for phone, tablet, and desktop
- Repository abstraction ready to replace the demo transport with Firestore

## Run

```bash
flutter pub get
flutter run -d chrome
```

The MVP starts in demo mode. Open the role switcher in the top-right corner to move between seller and buyer views while preserving the same session state.

## Catalog images

Catalog sheets are displayed directly as an image-only vertical feed. Add JPG files to `assets/catalog/` and register them in `lib/src/models/product.dart`. The included Desktop launcher imports the two current demo sheets from the mapped `S:` catalog drive when it is available.

## Architecture

`ShowlineSessionController` is the single source of truth. UI events become controller intents; the controller produces immutable state and sends mutations through `SessionRepository`. `DemoSessionRepository` provides deterministic latency for the MVP. A Firestore implementation can replace it without changing the UI.

See [`docs/architecture.md`](docs/architecture.md) for the state model and production path.
