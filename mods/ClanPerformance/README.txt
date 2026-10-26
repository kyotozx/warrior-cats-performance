PERFORMANCE
Optional graphics configuration mod for Warrior Cats: Clans of the Forest.
Credits: kyotozx. MIT licensed. Contributions and pull requests are welcome.

INSTALL
Requires Clan Loader 0.3.0-rc5 or newer and its supported UE4SS installation.
Supported game: Windows Steam build 24847281. ClanTools is not required.
Save and close the game. Import the Performance ZIP with Add mod package in Clan Loader.
Start the game, open its original pause, main or settings menu, then select
Performance. Keyboard shortcut: F9. Controller shortcut: L3 (left stick click).
Navigate with arrows / D-pad / left stick. Right enters the settings area;
Left moves back toward the tabs. Up / Down selects a row, Left / Right chooses
its minus or plus button, and Enter / A (Cross) activates it. Selecting a tab
also moves focus into its settings. Backspace / B (Circle) closes the panel.
Switch tabs with 1 / 2 or LB / RB (L1 / R1).
No mouse is required. All mod UI is English.

PRESETS
Balanced: 83% internal resolution, reduced effects and shadows, Lumen retained,
60 FPS cap. Preserves more of the game's lighting.
Low: 67% internal resolution, low world/effects/shadows, medium textures and AA,
Lumen off, 30 FPS cap. Suggested first comparison for integrated graphics.
Ultra Low: 50% internal resolution, minimum quality groups, 30 FPS cap.
The first install makes no graphics changes until you choose a preset.

CUSTOMIZE
Render scale, anti-aliasing, global illumination, reflections, textures,
post-processing, view distance, shadows, effects, foliage, shading and frame cap
are individually adjustable. Lower render scale reduces 3D clarity; native UI
resolution is preserved. Low GI removes Lumen and can darken interiors. Foliage
scaling only affects assets authored to support it; it does not delete plants.
Frame rate: Unlimited, 30, 40, 45, 60, 75, 90, 120, 144, 165, 240 and 360 FPS.
Custom frame limits: 15 to 1000 FPS. F8 also opens Performance from game menus.
VSync and display mode stay under the original game settings.

SAVED PRESETS
Open Saved presets and choose Save current settings. Enter a name with your
keyboard, or use the on-screen keyboard with a controller. You can keep up to
24 presets. Each preset captures the graphics values currently in use, including
supported values changed in the original game options. Unapplied edits in the
Performance panel are not captured: preview and keep them first.
Select a saved preset to preview it, then Keep changes to apply it permanently.
Deleting a preset asks for confirmation and does not alter your current graphics.
Presets persist in preferences.json and are kept when updating this mod.

PREVIEW AND RECOVERY
Changes first enter a 20-second preview. Keep changes commits the selection;
Revert, leaving the panel or timeout restores the previous values. Graphics
changes can briefly stall while the engine rebuilds rendering resources.
A baseline is saved before applying the first change. Restore original settings
returns to that baseline, not factory defaults. Original solo saves are untouched.
An interrupted preview is recovered when this mod next loads.
Confirmed settings are saved through the engine and can remain after disabling
or uninstalling the mod. Restore original settings and confirm BEFORE removal.
If the original game's options replace values, the mod reports the difference;
it does not continuously fight the game's settings. Preview a preset to reapply.
Recovery files: ue4ss/Mods/ClanPerformance/preferences.json and
preferences.json.previous. Keep these files private; they are not package code.

CAMERA & COMFORT
View & motion: motion blur, exploration FOV, camera shake and sprint effects.
Camera controls: smoothing and separate horizontal/vertical turn sensitivity.
Reduced Camera Motion disables blur, exploration shakes, sprint FOV/pullback and
camera lag; it sets FOV to 90 degrees and both sensitivities to 75 percent.
Preview and keep changes. Restore camera defaults returns native behavior.
Camera adjustments yield outside free exploration. Motion blur is global.
Saved presets include these settings. Graphics presets keep your camera choices.

MEASURE
Performance monitor offers an optional top-right FPS overlay and a 30-second
test. The overlay hides while gameplay is paused. Start the test, close menus
and follow the same route for each comparison.
The average uses frame-counter deltas over sampled time. The displayed range
is a range of sampling windows, NOT per-frame 1% lows or a CPU/GPU profiler.
Paused gameplay and gaps over two seconds are excluded; world changes cancel
the test. Test with the same frame cap and VSync, or remove limits to compare
rendering throughput. A cap can hide improvements above that cap.

LIMITS
This mod exposes engine quality settings with presets and recovery. It does not
rewrite the renderer, add upscaler technology, remove shader compilation stalls
or guarantee a particular FPS on unsupported/weak hardware. No per-hardware
speedup is advertised without a measurement on that hardware.
No enemies, collisions, quests, gameplay audio or story logic are removed.
No registry tweaks, process priorities, RAM cleaners or texture-streaming hacks.
No telemetry uploads. Assets/fonts are loaded from the user's installed game;
no proprietary game assets are included in this package.

DEVELOPMENT
Source: https://github.com/kyotozx/warrior-cats-performance. Separate optional
package through the existing loader, not a dependency on the offline admin suite.
From the repository root, run tests with Lua 5.4:
  lua mods/ClanPerformance/tests/controller.test.lua
  lua mods/ClanPerformance/tests/backend.test.lua
  lua mods/ClanPerformance/tests/meter.test.lua
  lua mods/ClanPerformance/tests/store.test.lua
  lua mods/ClanPerformance/tests/navigation.test.lua
  lua mods/ClanPerformance/tests/native_panel.test.lua
Build with PowerShell: ./mods/ClanPerformance/Build-Package.ps1
Before upgrading, update Clan Tools to rc5 or newer to remove its old FPS runtime.
Existing Performance preferences take priority. Otherwise the old Clan Tools FPS
counter and custom-limit behavior are imported without modifying its files.
json.lua retains its included rxi MIT license notice.
