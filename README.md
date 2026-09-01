# Godot 3D Multiplayer Template

This is a foundational template for a 3D multiplayer game, developed in Godot Engine 4.6. It offers a starting structure for your next multiplayer project, including essential functionalities for players to interact and communicate in real-time.

> This template is also available on the [Godot Asset Library](https://godotengine.org/asset-library/asset/3377) and [Godot Asset Store](https://store.godotengine.org/asset/devmoreir4/godot-3d-multiplayer-template/).

## Key Features

This template provides everything you need to kickstart multiplayer game development:

- **Host, Join, and Dedicated Server Modes:** Start a local host, connect to an address, test multiple editor instances, or run the project as a headless dedicated server.
- **Third-Person Character Controller:** Camera-relative movement, sprinting, jumping, double jumping, falling recovery, and synchronized movement animations.
- **Player Management:** Multiplayer spawning and removal, synchronized player information, disconnect handling, and support for up to 10 players.
- **Player Customization:** Choose between blue, yellow, green, and red Godot Robot palettes before joining a session.
- **Synchronized Player Identity:** Sanitized nicknames are displayed above characters and automatically move above equipped hats.
- **Online Player List:** Hold <kbd>Tab</kbd> to display a responsive list of connected players, including the player count, peer IDs, and a marker for the local player.
- **Global Multiplayer Chat:** Send sanitized messages to every connected player and hide or show the chat without leaving the game.
- **Server-Authoritative Inventory:** Inventory mutations, equipment changes, and collection requests are validated by the server before the resulting state is synchronized.
- **Inventory and Equipment UI:** 16 base inventory slots, 4 additional slots from an equipped backpack, drag-and-drop organization, context actions, item tooltips, stacking, and dedicated hat, weapon, and backpack slots.
- **Visible Equipment Synchronization:** Equipped hats, weapons, and backpacks are displayed on every connected player's character.
- **Physical World Items:** Drop, push, and collect physics-based items. Collection only succeeds for a valid item in front of a grounded player during the pickup animation window.
- **Multiplayer Request Protection:** Server-side validation and request limits protect animation and pickup requests from client spam.
- **Pause and Input Management:** Pause, inventory, chat, and player-list interfaces coordinate mouse capture and block gameplay input when appropriate.
- **Debug Inventory Shortcuts:** Add random items and print the local inventory while testing.

## Project Structure

- `assets/`: Imported models, textures, icons, fonts, and third-party asset attribution files.
- `scenes/items/`: World-drop scenes organized into backpacks, hats, miscellaneous items, and weapons.
- `scenes/level/`: Main level, arena, and multiplayer player scenes.
- `scenes/ui/`: Inventory, menus, chat, and online-player-list scenes.
- `scripts/autoload/`: Global `Network` and `ItemDatabase` singletons.
- `scripts/inventory/`: Item data, inventory slots, and player inventory state.
- `scripts/items/`: World-item behavior.
- `scripts/level/`: Level and multiplayer session coordination.
- `scripts/player/`: Player controller, character model, and camera support.
- `scripts/ui/`: User-interface behavior.

## How to Run the Project

Follow these simple steps to get the template up and running:

1. **Clone or Download:** Obtain the repository by cloning it via Git or downloading the ZIP file.
2. **Open in Godot Engine:** Load the project in [Godot Engine 4.6](https://godotengine.org).
3. **Execute:** Press <kbd>F5</kbd> or click `Run Project` in the Godot editor.

For local multiplayer testing, open `Debug > Customize Run Instances`, enable `Enable Multiple Instances`, choose the desired number of instances, and run the project.

## Dedicated Server

To run the project as a dedicated server (headless mode), use the provided script:

```bash
./run_headless_server.sh
```

Ensure the script has execution permissions (`chmod +x run_headless_server.sh`) and that the `godot` binary is in your system `PATH`. If Godot is installed under another command or path, set `GODOT_BIN` when starting the server:

```bash
GODOT_BIN=/path/to/godot ./run_headless_server.sh
```

Press <kbd>Ctrl</kbd>+<kbd>C</kbd> to stop the server.

## Controls

- <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> to move.
- <kbd>Shift</kbd> to run.
- <kbd>Space</kbd> to jump or double jump.
- Left mouse button to play the attack animation (visual only, without damage).
- <kbd>E</kbd> to collect a nearby item.
- <kbd>Esc</kbd> to open or close the pause menu.
- <kbd>T</kbd> to hide/show chat.
- <kbd>I</kbd> to toggle inventory.
- Hold <kbd>Tab</kbd> to show the online player list.
- <kbd>F1</kbd> to add a random test item (debug builds, host only).
- <kbd>F2</kbd> to print the local inventory (debug).

## Contributing

If you want to contribute to this project, please refer to our [Contributing Guidelines](CONTRIBUTING.md).

## Credits

- [3D Godot Robot Platformer Character](https://github.com/AGChow/3D-Godot-Robot-Platformer-Character), by AGChow, licensed under CC0. See [`assets/characters/player/ATTRIBUTIONS.md`](assets/characters/player/ATTRIBUTIONS.md).
- Item models and icons by Poly by Google and Quaternius. See [`assets/items/ATTRIBUTIONS.md`](assets/items/ATTRIBUTIONS.md).
- Prototype environment textures by Kenney, licensed under CC0. See [`assets/environment/ATTRIBUTIONS.md`](assets/environment/ATTRIBUTIONS.md).

## License

The project source code is available under the [MIT License](LICENSE). Third-party assets are excluded from that license and remain available under the terms documented in their respective attribution files.
