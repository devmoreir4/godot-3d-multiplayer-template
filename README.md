# Godot 3D Multiplayer Template

This is a foundational template for a 3D multiplayer game, developed in Godot Engine 4.6. It offers a starting structure for your next multiplayer project, including essential functionalities for players to interact and communicate in real-time.

> This template is also available on the [Godot Asset Library](https://godotengine.org/asset-library/asset/3377) and [Godot Asset Store](https://store-beta.godotengine.org/asset/devmoreir4/godot-3d-multiplayer-template/).

## Key Features

This template provides everything you need to kickstart your multiplayer game development:

* **Network System:** A base for managing client-server connections, allowing multiple players to connect and interact within the same environment.
* **Player Management:** Easily add multiple players to the game, controlling their interactions and movement in a 3D space.
* **Real-Time Synchronization:** Player movement, animation states, and equipped-item appearances are synchronized for all connected players.
* **Player Name Displayed:** Each player's nickname is shown above their character for easy identification.
* **Player Skin Selection:** Players can choose from four skin options (red, green, blue, or yellow) to personalize their avatars.
* **Global Multiplayer Chat:** An integrated chat system allows players to communicate in real-time with everyone in the game.
* **Health and Respawn:** Players have 10 health points with a local health bar, synchronized damage and hurt/death animations, and an automatic respawn.
* **Server-Authoritative Combat:** The server validates attack windows, equipped weapons, targets, hit distance, and duplicate hits.
* **Multiplayer Inventory System:** Server-authoritative inventory management with a 20-slot backpack, drag-and-drop organization, item stacking, world-item collection and dropping, plus dedicated weapon and armor slots.

## How to Run the Project

Follow these simple steps to get the template up and running:

1. **Clone or Download:** Obtain the repository by cloning it via Git or downloading the ZIP file.
2. **Open in Godot Engine:** Load the project in your [Godot Engine](https://godotengine.org) installation.
3. **Execute:** Press `<kbd>`F5`</kbd>` or click `Run Project` in the Godot editor.

<br>

To test the multiplayer functionality locally:
Go to `Debug` > `Customize Run Instances`, then enable `Enable Multiple Instances` and set the number of instances you want to run simultaneously.

## Dedicated Server

To run the project as a dedicated server (headless mode), use the provided script:

```bash
./run_headless_server.sh
```

Ensure the script has execution permissions (`chmod +x run_headless_server.sh`) and that the `godot` binary is in your system `PATH`.

## Controls

* `<kbd>`W`</kbd>` `<kbd>`A`</kbd>` `<kbd>`S`</kbd>` `<kbd>`D`</kbd>` to move.
* `<kbd>`Shift`</kbd>` to run.
* `<kbd>`Space`</kbd>` to jump or double jump.
* Left mouse button to attack.
* `<kbd>`E`</kbd>` to collect a nearby item.
* `<kbd>`Esc`</kbd>` to quit.
* `<kbd>`T`</kbd>` to hide/show chat.
* `<kbd>`I`</kbd>` to toggle inventory.
* `<kbd>`F1`</kbd>` to add random test item (debug).
* `<kbd>`F2`</kbd>` to print inventory contents (debug).

<!-- ## Screenshots

<img src="./.github/img1.png" alt="Image Example" width="700px">
<img src="./.github/img4.PNG" alt="Image Example" width="700px">
<img src="./.github/img3.png" alt="Image Example" width="700px"> -->

## Contributing

If you want to contribute to this project, please refer to our [Contributing Guidelines](CONTRIBUTING.md).

## Credits

* [3D-Godot-Robot-Platformer-Character](https://github.com/AGChow/3D-Godot-Robot-Platformer-Character) (CC0)
