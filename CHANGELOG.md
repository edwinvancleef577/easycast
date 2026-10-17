# Changelog

## 0.7.38-alpha

- Integrated native two-button running into normal world casting, including when hovering a selected enemy.
- Movement takes priority over casting. Both press orders and both release orders are handled.
- Preserved native release bindings through target changes, modifier changes and addon deactivation until the mouse buttons are released.
- Prevented mouse-status polling from removing a pending native release binding prematurely.
- Retained native WoW raid-target marker bindings on function keys.
- Added movement-route details to the optional mouse diagnostics.
- Kept existing unit-frame casting, profiles, tooltip styling, cooldown indicators and language support.

The release passed automated Lua API regression checks and in-client testing of the movement integration. Diagnostics remain available for further compatibility testing.
