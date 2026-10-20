# Evently

Evently is an event-ticketing application with a Flutter client and a Spring Boot REST API. Attendees can discover events, purchase tickets, and view ticket QR codes. Organizers can manage events, and staff can validate tickets by scanning a QR code or entering a ticket ID.

## Repository layout

- `frontend-mobile/`: Flutter app for Android, iOS, and web.
- `backend/`: Spring Boot API, Maven wrapper, Dockerfile, and Keycloak development Compose configuration.

## Requirements

- Flutter stable with Dart 3.3 or later.
- Java 21 for the backend.
- PostgreSQL for the backend's configured runtime database.
- Docker Compose for the optional local Keycloak service.
- A Keycloak realm and client configured for the application.

## Local setup

### 1. Start Keycloak

From `backend/`, start the included Keycloak development service:

```sh
docker compose up -d keycloak
```

Keycloak is exposed on port `9090`. The Compose file starts Keycloak in development mode; it does not import or create the `event-ticket-platform` realm, nor does it start PostgreSQL or the Spring Boot API. Configure the realm, client, and realm roles before testing authenticated flows. The development container's initial admin credentials are defined in `backend/docker-compose.yml`; replace them for any environment beyond local development.

The Flutter client uses the OIDC realm `event-ticket-platform`, client ID `evently-frontend`, and realm roles `ROLE_ATTENDEE`, `ROLE_ORGANIZER`, and `ROLE_STAFF`. The client needs Authorization Code flow enabled and these redirect URIs:

- Web: `http://localhost:62100/redirect.html`
- Android: `com.example.eventlymobile:/oauth2redirect`

### 2. Configure and run the API

The API listens on port `8080` by default and requires a PostgreSQL database. Set the datasource environment variables before starting it:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`

The JWT issuer is configured in `backend/src/main/resources/application.properties`. Set it to the issuer URL for the Keycloak realm reachable by the API, for example `http://localhost:9090/realms/event-ticket-platform` when both services run on the same machine. Ensure the issuer is also reachable from the app and that its URL matches the issuer in Keycloak-issued tokens.

From `backend/`, run the API with the Maven wrapper:

```sh
./mvnw spring-boot:run
```

On Windows PowerShell, use:

```powershell
.\mvnw.cmd spring-boot:run
```

Build and test the backend from the same directory:

```sh
./mvnw test
```

### 3. Run the Flutter client

From `frontend-mobile/`, fetch packages:

```sh
flutter pub get
```

The API base URL is controlled by the `API_BASE_URL` Dart define and defaults to `http://localhost:8080`. For an Android emulator, use the emulator host mapping:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

For Flutter Web on the same machine as the API:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

For a physical device, use LAN-accessible API and Keycloak URLs. Update the OIDC endpoint selection in `frontend-mobile/lib/core/auth/oidc_service.dart` for the target environment; the current physical-Android selection is a development-specific LAN address. Use HTTPS and production-grade credentials and configuration for deployed environments.

Run Flutter checks from `frontend-mobile/`:

```sh
flutter analyze
flutter test
```

## Mobile app features

- Event discovery, search, pagination, and event details.
- Keycloak sign-in and role-aware navigation.
- Ticket purchase, attendee ticket list, and QR display.
- Organizer event management.
- Staff QR scanning and ticket validation.

Staff QR scanning requires camera permission on the device. The checkout screen displays dummy card fields; those values are not sent to the API as payment information.
