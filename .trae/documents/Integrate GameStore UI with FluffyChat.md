# Plan: Integrate GameStore with Chat

## 1. Analyze and Fix Dependencies
1.  **Check `pubspec.yaml`**: Verify if `gamestore` is defined as a package. If not, I will need to refactor imports in the transplanted files.
2.  **Find Router Config**: Locate the `GoRouter` configuration (likely in `lib/config/routes.dart` or `lib/main.dart`) to understand how to change the home route.

## 2. Refactor GameStore Imports
1.  **Update Imports**: In `lib/pages/gamestore/main.dart` (and potentially other files in that directory), change `import 'package:gamestore/...'` to `import 'package:fluffychat/pages/gamestore/...'` or relative imports.

## 3. Modify GameStore Main Page
1.  **Edit `lib/pages/gamestore/main.dart`**:
    *   Remove `void main()`.
    *   Rename `MyApp` to `GameStoreApp` or similar widget to be used within FluffyChat.
    *   **Add Chat Tab**:
        *   Import `package:fluffychat/pages/chat_list/chat_list.dart`.
        *   Add a `NavigationDestination` for "Chat" (聊天) to the `NavigationBar`.
        *   Add `ChatList(...)` to the `body` widget list.
        *   **Conditional AppBar**: Logic to hide `GameStoreAppBar` when the "Chat" tab is selected (since ChatList has its own header).

## 4. Integrate into FluffyChat Navigation
1.  **Update Router**: Change the default route (`/` or `/home`) in the app's `GoRouter` configuration to point to the new `GameStoreApp` widget instead of the default `ChatList`.

## 5. Verification
1.  **Compile & Run**: Ensure no import errors remain and the app launches with the new bottom navigation bar containing the Chat tab.
