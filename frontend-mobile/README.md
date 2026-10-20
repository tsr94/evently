# Evently Flutter starter

A premium dark/purple Flutter client for the existing Spring Boot event-ticket platform. The first slice implements published-event discovery, search, pagination, and event details.

## Requirements

- Flutter stable with Dart 3.3+
- Existing Spring Boot API running
- Published-event endpoints reachable from the device

## Run

1. Create the native platform folders if needed:

   ```bash
   flutter create . --platforms=android,ios,web
   ```

   If Flutter warns that the project already exists, keep the `lib/` and `pubspec.yaml` files in this starter.

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run on an Android emulator (default API URL is `http://10.0.2.2:8080`):

   ```bash
   flutter run
   ```

4. Run on web or a local desktop where the backend is available at localhost:

   ```bash
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
   ```

5. Run on a physical Android phone. Put the phone and computer on the same network, then use the computer's LAN IP:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
   ```

   Replace the example IP with your computer's actual LAN IP. The backend must listen on an interface reachable from the phone. Android cleartext HTTP may be blocked by app policy; use HTTPS for production and configure development networking deliberately.

## Implemented endpoints

- `GET /api/v1/published-events?q=&page=0&size=20`
- `GET /api/v1/published-events/{eventId}`

Models match the OpenAPI fields: event `id`, `name`, `start`, `end`, `venue`, and `ticketTypes`.

## Current limitations

- Keycloak login/token refresh is not yet wired. This initial slice assumes published-event GET endpoints are public, as intended by the existing Spring Security rules. If you get 401/403, check the backend's actual authorization configuration.
- Purchase is intentionally not enabled in the UI yet. Confirm the purchase endpoint's request contract and payment behavior first.
- Organizer and staff screens will be added after authentication and role claims are verified.
- Event artwork is a placeholder gradient because the current API schema does not expose image URLs.

## Suggested next steps

1. Verify the API base URL from the target device.
2. Confirm Keycloak mobile client settings and role mapping (`ORGANIZER`, `STAFF`, attendee role/permissions).
3. Add OIDC Authorization Code + PKCE and secure token storage.
4. Add attendee tickets, checkout, organizer event management, and staff QR scanning.
