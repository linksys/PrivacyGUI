# Routing Specification

## 1. Overview

The application's routing is managed by the `go_router` package, orchestrated by a centralized, state-aware redirection system. This system is primarily controlled by the `RouterNotifier` class, which acts as a `refreshListenable` for the main `GoRouter` instance. All major navigation and route guarding rules are defined in this central location.

## 2. Core Components

*   **`routerProvider`**: A Riverpod `Provider` that creates and holds the singleton `GoRouter` instance for the entire app.
*   **`RouterNotifier`**: A `ChangeNotifier` that `go_router` listens to. It contains all the complex redirection logic and calls `notifyListeners()` when a state change (like authentication) requires the router to re-evaluate its current location.
*   **`redirect` function**: The global guard within the `GoRouter` configuration. It intercepts every navigation event and delegates the decision-making to methods within `RouterNotifier`.

## 3. Core Navigation Flows

The routing logic can be understood as a state machine that directs users based on their authentication status, network environment, and the state of the connected router.

### 3.1. App Launch Flow (from `/`)

When a user starts the app, the `redirect` function detects the initial `/` location and calls the `_autoConfigurationLogic` method. This is the primary entry workflow.

1.  **Connectivity Check**: It first forces an update of the network connectivity status.
2.  **PnP Determination**: If on a local network, it initiates a series of checks via `pnpProvider` to determine the router's state (e.g., is it a new device, is it configured, is it a special "Auto Parent" type?).
3.  **Branching**: Based on the result, the user is redirected to one of three main flows:
    *   **PnP Flow (`/pnp` path)**: For new or factory-reset routers that require initial setup.
    *   **Login Flow** (e.g., `/localLoginPassword`): For previously configured routers.
    *   **First-Time Login Flow (`/autoParentFirstLogin`)**: For a specific device type requiring a unique setup.

### 3.2. General Navigation & Route Guarding (`_redirectLogic`)

For most navigations after the initial launch, the `_redirectLogic` method acts as the primary guard. It enforces several crucial rules in order:

1.  **PnP Status Guard**: The first and highest-priority check. If the user is on a local network and the router has not completed its PnP setup (`userAcknowledgedAutoConfiguration == false`), it forcefully redirects the user to the `/pnp` flow, preventing any bypass.
2.  **Remote Login Guard**: If the user is logged in remotely but has not selected a network to manage, it redirects them to the `selectNetwork` page.
3.  **Session Guard**: For remote logins, it validates the session token from the URL against the stored session. If they don't match, it logs the user out to ensure security.
4.  **Authentication Guard**: If a user is not authenticated (`loginType` is null or none) but attempts to access a protected route (any path starting with `/dashboard`), it redirects them to the home/login page.

### 3.3. Data Preparation Flow (`_prepare`)

This is a critical helper method called by the redirection logic before allowing navigation to protected pages like the dashboard.

*   **Purpose**: Its sole responsibility is to load all necessary data required for the destination page to function correctly. This includes:
    *   Checking and fetching the latest device information (`checkDeviceInfo`).
    *   Loading data from the cache (`linksysCacheManagerProvider`).
    *   Initializing or updating the background data polling service (`pollingProvider`).
*   **Benefit**: This prevents pages from loading in an empty or error state. The user only sees the page once all its required data is ready.

## 4. Key Principles

*   **Centralized Logic**: All routing rules are co-located in `RouterNotifier`, providing a single source of truth for navigation policies.
*   **State-Driven**: Navigation is not imperative but *reactive*. It changes in response to state changes in providers like `authProvider` and `connectivityProvider`.
*   **Defensive Guarding**: Routes are protected by default. The `redirect` logic acts as a gatekeeper that must explicitly allow navigation to proceed, ensuring a secure and predictable user flow.
