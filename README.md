<p align="center"><img src="docs/images/icon.png" width="96" alt="Performance emblem"></p>

# Performance

Graphics presets, camera comfort settings and FPS controls for **Warrior Cats: Clans of the Forest**, with menus that use the game's own fonts, buttons and backgrounds.

[Download Performance](https://github.com/kyotozx/warrior-cats-performance/releases/latest) · [Get Clan Loader](https://github.com/kyotozx/warrior-cats-clan-tools/releases) · [Report a bug](https://github.com/kyotozx/warrior-cats-performance/issues)

![Performance presets](docs/images/presets.jpg)

## Features

- **Balanced, Low and Ultra Low presets**, with a preview before you commit.
- **Individual quality controls** for render scale, lighting, shadows, reflections, textures, anti-aliasing, effects, foliage, view distance and shading.
- **Custom or unlimited FPS**, including presets up to 360 FPS and custom values from 15 to 1000.
- **Optional FPS counter** and a 30-second measurement to compare your settings.
- **Camera & Comfort** with motion blur, FOV, smoothing, shake, sprint effects and separate sensitivity controls. Includes a Reduced Camera Motion preset.
- **Up to 24 named presets** that capture your current graphics and camera configuration.
- **20-second confirmation timer**, automatic preview recovery and a button to restore your original settings.
- **Keyboard and controller navigation** throughout, including the preset naming screen.

| Image quality | World and effects |
| --- | --- |
| ![Image quality settings](docs/images/image-quality.jpg) | ![World and effects settings](docs/images/world-effects.jpg) |

| Frame rate | Saved presets |
| --- | --- |
| ![Frame rate controls](docs/images/frame-rate.jpg) | ![Saved presets](docs/images/saved-presets.jpg) |

<details>
<summary>Performance monitor</summary>

![Performance monitor](docs/images/monitor.jpg)

</details>

## Install

Requires the Windows Steam game, build **24847281**, and **Clan Loader 0.3.0-rc5 or newer**. Clan Tools is optional.

1. Save and close the game.
2. Install or update [Clan Loader](https://github.com/kyotozx/warrior-cats-clan-tools/releases) using its release ZIP and **Install / update suite**. If you only want Performance, disable Clan Tools in the manager afterward.
3. Download the named `Performance` ZIP from [Releases](https://github.com/kyotozx/warrior-cats-performance/releases/latest). Keep this ZIP intact.
4. In Clan Loader, choose **Add mod package**, select the Performance ZIP and leave Performance enabled.
5. Start the game. Open **Performance** from the original main, pause or settings menu with **F9 / L3**.

The GitHub source archives are for development. Install the named Performance ZIP through the manager.

If Clan Loader cannot load `ThemeAssets.dll` and shows error `0x80131515`, Windows may have blocked the downloaded files. Close the loader, right-click its release ZIP, select **Properties > Unblock > Apply**, then extract it again into a new folder. See the [loader troubleshooting guide](https://github.com/kyotozx/warrior-cats-clan-tools#troubleshooting) if Unblock is not shown.

No graphics preset is applied on a fresh install. When upgrading from Clan Tools, your existing FPS counter preference and custom frame-limit behavior are imported if Performance has no preferences yet. Existing Performance preferences take priority. Update Clan Tools to rc5 or newer to remove its previous FPS controls and counter.

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Open from game menus | F9 (F8 also works) | L3 / left stick click |
| Navigate | Arrow keys | D-pad / left stick |
| Select | Enter | A / Cross |
| Back | Backspace | B / Circle |
| Switch tabs | 1 / 2 | LB / RB |

Select a tab or press Right to enter its controls. Left returns toward the sidebar. All interface text is in English; a mouse is not required.

## Choosing settings

| Preset | Render scale | Frame limit | Lighting |
| --- | --- | --- | --- |
| Balanced | 83% | 60 FPS | Lumen retained |
| Low | 67% | 30 FPS | Lumen disabled |
| Ultra Low | 50% | 30 FPS | Lumen disabled |

Low is a starting point for integrated graphics. Lower render scale reduces 3D clarity while keeping menus sharp. Disabling Lumen can make interiors darker. VSync remains in the original game options and can limit FPS even when Unlimited is selected.

Choose **Saved presets > Save current settings** to keep your own setup. This captures the values currently in use, including supported changes from the game's options. Preview and keep pending edits before saving them as a preset.

Settings are stored in `ue4ss/Mods/ClanPerformance/preferences.json`. Updates preserve this file. The internal folder name stays `ClanPerformance` for compatibility with earlier versions.

## Camera & Comfort

Open **Camera & Comfort** in Performance. It uses the same game menus, fonts and controller navigation as the other pages.

| View & motion | Camera controls |
| --- | --- |
| ![Motion blur, exploration FOV, camera shake and sprint effects](docs/images/camera-comfort.jpg) | ![Camera smoothing and separate horizontal and vertical sensitivity](docs/images/camera-controls.jpg) |

| Setting | Options |
| --- | --- |
| Motion blur | Game default or Off, independent of other post processing |
| Exploration FOV | Game default or 60 to 110 degrees |
| Camera shake | Game default or Off during exploration |
| Sprint camera effects | Keep or disable the sprint FOV increase, camera pullback and extra blur |
| Camera smoothing | Game default, Reduced or Off |
| Horizontal / vertical sensitivity | Separate 25% to 200% controls for keyboard and controller |

**Reduced Camera Motion** turns off blur, exploration shakes, sprint camera effects and camera lag, sets the exploration FOV to 90 degrees, and sets both turn speeds to 75%. You can adjust every option afterward. It changes no graphics quality or frame limit settings.

Choose **Preview camera settings**, then keep or revert the changes. **Restore camera defaults** returns these controls to the game's behavior. Camera adjustments run during free exploration and yield to menus, conversations, combat, photo mode and scripted camera paths. Motion blur is a global rendering setting. Your existing inverted-axis settings remain in effect.

Saved presets include Camera & Comfort. Selecting Balanced, Low or Ultra Low preserves your current camera preferences. Older preferences load with the game's camera defaults. These options are personal comfort controls; they do not guarantee that everyone will find the movement comfortable.

## Recovery and limits

Use **Restore original settings** and confirm before uninstalling if you want to return to the settings captured before your first change. Confirmed engine settings can remain after removing the mod. Interrupted previews are recovered on the next launch with Performance enabled.

Performance adjusts engine graphics settings. It does not guarantee a particular FPS or fix every source of stuttering. Compare the same location and route with the same frame cap. The monitor reports sampled FPS, not per-frame 1% lows.

The mod does not edit story saves, enemies or quests. Game art and fonts are loaded from your installation and are not bundled. This is an unofficial community mod.

## Development

Lua 5.4 and Windows PowerShell are enough to run the tests and build the package:

```powershell
./scripts/Test.ps1 -LuaPath lua
./mods/ClanPerformance/Build-Package.ps1
```

Source is in `mods/ClanPerformance/Scripts`; regression tests are in `mods/ClanPerformance/tests`. The package uses Clan Loader API 1. The game runtime is UE4SS, supplied by Clan Loader.

**Pull requests are welcome.** See [CONTRIBUTING.md](CONTRIBUTING.md). Original code and the emblem are [MIT licensed](LICENSE); `json.lua` retains its included rxi MIT notice.

Credits: kyotozx
