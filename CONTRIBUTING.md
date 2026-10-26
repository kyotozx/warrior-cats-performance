# Contributing

Pull requests for fixes, features, documentation and compatibility are welcome.

Keep menus in English and usable with both keyboard and controller. Reuse the game's UI assets at runtime; do not add extracted game files to the repository. Preserve user presets and the preview/rollback behavior when changing graphics controls.

Run `scripts/Test.ps1` with Lua 5.4. Include relevant tests for changes to persistence, migration and navigation. Describe what changed and how you checked it. Keep unrelated changes out of the same PR.

For performance reports, include the mod and game versions, CPU, GPU, RAM, resolution, graphics preset and frame cap. Say whether the issue happens before opening the menu and whether it persists with Performance disabled after restarting. Comparisons in the same area are especially useful.

Do not attach save files or personal preferences unless you have reviewed their contents. Contributions are licensed under MIT.
