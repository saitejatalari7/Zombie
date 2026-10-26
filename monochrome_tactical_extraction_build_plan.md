# Project Specification: PROTOCOL: CRIMSON

**Engine:** Godot 4.x (Universal Render Pipeline / Forward+ or Mobile Renderer)  
**Primary Target Platform:** Android (API 33+, 60 FPS target on mid-range devices)  
**Orientation Support:** Dynamic Portrait & Landscape Switching (Player-selectable in Settings)  
**Genre:** Isometric Military Extraction & Horde Survival  
**Visual Style:** Brutalist Monochrome Architecture (Pure White/Grey Untextured Geometry) + High-Contrast Glossy Crimson Blood + Crisp Directional Shadows

---

## 1. Executive Summary & Core Vision

Build a fast-paced, 3-minute session isometric military scavenging and extraction shooter in Godot 4 for Android. The world is constructed entirely from untextured matte-white and grey architectural primitives and detailed low-poly matte-grey environmental props (wrecked cars, leafless trees, power poles with hanging wires). The only vibrant color in the world is **glossy crimson red** (persistent blood splatters, footprints, key objectives, Molotov crimson flames, and the Crimson Boss).

Instead of cutscenes or text-heavy dialogue, progression is driven by **Structured Tactical Operations**: the player first survives an initial ambush to reach and establish an **Outpost Hub**, and from there accepts escalating **Extraction Contracts** across distinct city Sectors to unlock weapon tiers, paired operative skills, and Outpost facilities.

---

## 2. Visual & Rendering Rules (Strict Art Direction)

1. **Color Palette:**
   * **World Geometry & Buildings:** Matte White (`#F5F5F7`) to Light Grey (`#D1D1D6`).
   * **Environmental Props:** Medium Slate Grey (`#8E8E93`) for wrecked cars, leafless dead trees, streetlamps, and power poles with hanging black catenary wires (`#1C1C1E`).
   * **Shadows:** Pitch Black (`#0A0A0C`) hard-edged directional shadows cast from overhead geometry, wires, and trees onto the white ground plane.
   * **Blood & High-Value Elements:** Glossy Crimson Red (`#B8000A` to `#FF0015`) with low roughness (`0.15`) so blood pools catch specular highlights.
   * **UI Theme:** Stark Swiss-Brutalist Military UI—Deep Charcoal (`#111113`), Crisp White typography (`#FFFFFF`), Tactical Amber (`#FFB800`) for contract ratings, and Crimson Red accent highlights (`#E50914`).

2. **Persistent Blood & Footprint System:**
   * Every zombie hit spawns directional blood splatter decals (`Decal` nodes or a global world-space `SubViewport` RenderTexture mask) onto floors and walls.
   * **Blood Footprints:** When the player walks through a fresh blood pool, they leave fading red boot prints for 4 seconds. Fast Runner zombies detect and track fresh blood footprints.

3. **Day & Night Lighting System:**
   * **Day Ops:** Bright directional sunlight (`DirectionalLight3D`), stark black shadows, high-visibility white corridors.
   * **Night / Blackout Ops:** Ambient light drops to near-zero (`#050507`). Visibility is restricted to flickering streetlamps (`OmniLight3D`), weapon muzzle flashes, glowing red boss eyes, and the player's sweeping conical tactical flashlight (`SpotLight3D` attached to weapon aim vector).

---

## 3. Studio-Level UI/UX & Scene Flow (Godot 4 Architecture)

### 3.1 Boot & Asynchronous Loading Screen (`LoadingScreen.tscn`)
* **Studio Splash:** Clean minimalist studio logo fade-in on pitch-black background with subtle haptic pulse.
* **Async Resource Loader:** Uses Godot’s `ResourceLoader.load_threaded_request()` to load heavy 3D scenes, shaders, and particle caches without freezing the main thread.
* **Visual Design:**
  * Matte-black screen with a razor-thin crimson progress bar (`ProgressBar`) at the bottom edge.
  * Dynamic status readout in monospace military font: `INITIALIZING NAVMESH...`, `COMPILING FLUID/DECAL SHADERS...`, `SPAWNING SECTOR GEOMETRY [78%]`.
  * Rotating 3D wireframe silhouette of the player's equipped weapon or extraction target in the center, accompanied by tactical survival tips.

### 3.2 First-Time Onboarding: Level 0 ("THE ESCAPE")
* On very first boot, the player skips the menu and drops straight into a 90-second playable **Escape Sequence** in a ruined white alleyway with a basic sidearm.
* **Objective:** Survive the initial street ambush, breach the blast doors of **Outpost Alpha**, and activate the emergency beacon.
* Reaching the Outpost unlocks the **Outpost Hub UI** and the **Tactical Contract Board**, giving immediate meaning to the entire progression loop.

### 3.3 Outpost Hub & Tactical Contract Board UI (`OutpostHub.tscn`)
* **Live 3D Background Diorama:** The menu is overlaid on a live isometric 3D cutaway of your fortified white-box **Outpost**—showing parked armored vehicles, rescued VIP personnel working at terminals, weapon racks, and perimeter floodlights.
* **Top Bar (Economy & Clearance Level):**
  * **Operative Clearance Rank (Level 1–50):** XP bar earned from completing contracts; gates higher-tier skills and sectors.
  * **Survival Coins (SC):** Silver/White hexagonal icon + counter (earned from kills & extractions).
  * **Bio-Samples / Research Cores (RC):** Glowing crimson vial icon + counter (earned from Research Lab jobs & Crimson Boss kills; used to unlock Paired Skills).
  * **Settings Gear Button:** Opens modal Settings (Audio, Haptics, Portrait/Landscape Orientation Switcher).
* **Bottom/Side Navigation Dock:**
  1. **COMMAND BOARD (Missions & Sectors):** Studio-grade interactive tactical map of the city divided into Sectors. Tapping a Sector opens 3 available **Extraction Contracts** displayed as sleek military dossiers (showing Job Type icon, Threat Level, Day/Blackout status, Reward payout, and a bold crimson `[ ACCEPT CONTRACT ]` button).
  2. **ARMORY (Weapons & Attachments):** 3D weapon inspection viewport with 4-track stat upgrades.
  3. **OPERATIVE SKILLS (Paired Skill Matrix):** Grid UI where players unlock and pair active/passive combat perks as they level up.
  4. **OUTPOST UPGRADES:** Upgrade the Comms Array (better high-value contracts), Medbay (starting armor/stims), and Helipad (faster extraction timer).

---

## 4. Structured Mission System: Sectors & Extraction Job Types

To ensure 100+ levels feel purposeful and varied without needing story cutscenes, missions are generated by combining **4 Distinct Sector Biomes** with **4 Core Extraction Job Archetypes**.

### 4.1 The 4 Tactical Sectors (Progression Map)
* **Sector 1: Residential Quarantine (Clearance Lv. 1–10):** Tight white apartment courtyards, stairwells, wrecked civilian sedans, and overhead power lines.
* **Sector 2: Commercial Transit Grid (Clearance Lv. 11–25):** Wide plazas, highway overpasses, bus depots, and shatterable glass-and-steel skybridges. High Runner density.
* **Sector 3: Blackout Industrial Zone (Clearance Lv. 26–40):** **Night Ops mandatory.** Pitch-black shipping yards, chemical silos, and flickering hazard lights. Requires tactical flashlight sweeping.
* **Sector 4: The Crimson Research Complex (Clearance Lv. 41+):** High-security brutalist laboratory compounds, decontamination airlocks, and multi-Boss containment breaches.

### 4.2 The 4 Extraction Job Archetypes
Each contract on the Command Board assigns one of these structured objectives (2–3 minutes per run):

1. **ASSET EXTRACTION (High-Value Cargo):**
   * **Flow:** Locate encryption keycard $\rightarrow$ Breach locked military vault $\rightarrow$ Pick up heavy **Red Flight Recorder / Weapon Prototype Case** (carrying heavy cases slightly reduces movement speed or requires one-handed firing) $\rightarrow$ Reach Extraction Zone.
2. **PERSONNEL EXTRACTION (VIP / Survivor Rescue):**
   * **Flow:** Follow distress beacon to a barricaded room $\rightarrow$ Clear surrounding horde to free the **VIP Scientist/Medic** $\rightarrow$ Escort the VIP to the Extraction Zone. The VIP follows the player's path and must be protected from flanking Runners. Extracting VIPs permanently boosts Outpost passive income.
3. **RESEARCH LAB EXTRACTION (Bio-Sample Harvesting):**
   * **Flow:** Enter a contaminated Lab Sector $\rightarrow$ Plant 2 **Centrifuge Extractors** on glowing Crimson Biomass nodes $\rightarrow$ Defend the extractors for 20 seconds while their alarms attract swarms $\rightarrow$ Grab the refined **Research Cores** and extract.
4. **BLACKOUT PURGE & BEACON DROP (High-Risk Night Ops):**
   * **Flow:** Drop into a pitch-black sector using only your gun's hand-torch $\rightarrow$ Restore power to 2 emergency floodlight generators $\rightarrow$ Eliminate the **Crimson Boss** stalking the dark streets $\rightarrow$ Extract via emergency flare.

---

## 5. Operative Skill Progression & Paired Skill Synergy System

As players complete contracts and level up their **Operative Clearance**, they unlock **Skill Modules** in the `OPERATIVE SKILLS` tab. Players can equip **2 Paired Skills** at a time that mathematically synergize with each other:

* **Skill Pair Example 1 (The Crimson Berserker):**
  * *Skill A (Blood Siphon):* Standing in fresh crimson blood pools increases fire rate by 25%.
  * *Skill B (Hemorrhage Rounds):* Zombies explode into 2x wider blood pools on death.
* **Skill Pair Example 2 (The Tactical Demolisher):**
  * *Skill A (Napalm Gel):* Molotov fire pools burn 50% longer and slow enemies by 40%.
  * *Skill B (Thermobaric Ignition):* Shooting a burning zombie triggers a localized concussive blast.
* **Skill Pair Example 3 (The Ghost Operative - Ideal for VIP & Blackout Jobs):**
  * *Skill A (Silent Treads):* Walking through blood pools no longer leaves scent footprints for Runners to track.
  * *Skill B (Strobe Torch):* In Night Ops, your flashlight beam blinds and stuns zombies inside its cone every 6 seconds.

---

## 6. Dynamic Orientation System (Portrait vs. Landscape)

Players can toggle between **Portrait** and **Landscape** anytime inside the **Settings Menu** (or Pause Menu).

### 6.1 Godot Implementation (`OrientationManager.gd` Autoload)
* Calls `DisplayServer.screen_set_orientation()` dynamically (`SCREEN_PORTRAIT` vs `SCREEN_SENSOR_LANDSCAPE`).
* Updates project viewport scaling and emits a global `orientation_changed(is_portrait: bool)` signal so all UI Control nodes smoothly re-anchor using Godot `Control` containers and `Camera3D` FOV/size adjustments.

### 6.2 Portrait Mode HUD & Controls (One-Thumb Tactical)
* **Left/Bottom-Center Virtual Joystick:** Dynamic floating movement joystick (`VirtualJoystick`).
* **Auto-Shoot Toggle Button:** Positioned easily within right-thumb reach (`[ AUTO-FIRE: ON / OFF ]`).
  * **When ON:** Player automatically aims and fires at the nearest zombie within weapon range and line-of-sight (prioritizing Runners > Bosses > Shamblers).
  * **When OFF:** Player holds fire to conserve ammo while sneaking past hordes or repositioning.
* **Top Mission Tracker Pill:** Compact studio UI banner showing current contract step (e.g., `[ 2/3 ] ESCORT VIP TO HELIPAD - 140m`) and mini directional arrow.
* **Tactical Ability Buttons:** Compact vertical stack on the lower-right edge for **Molotov Throw** and **Active Mid-Game Power-Up**.

### 6.3 Landscape Mode HUD & Controls (Twin-Stick Precision)
* **Left Thumb Zone:** Movement Virtual Joystick.
* **Right Thumb Zone:**
  * **Dedicated Fire Button / Aim-Fire Stick:** Tap or hold to fire; drag the fire button to manually sweep aim direction (crucial for sweeping the Night Ops flashlight cone and lining up Rocket Launcher shots).
  * **Radial / Arc Ability Buttons:** Dedicated buttons for **Molotov (Hold & Drag to Aim Arc)**, **Reload**, and **Active Power-Up Slot** arrayed cleanly around the main Fire button.

---

## 7. Economy, Armory & Mid-Game Power-Up Systems

### 7.1 Mission Rewards & Contract Tally UI
Every mission end-screen (Extracted or KIA) displays a sleek military after-action report:
* **Contract Completion Payout:** +250 to +800 Survival Coins (SC) + Research Cores (RC) based on job difficulty.
* **Horde Elimination Bonus:** +1 SC per Shambler, +5 SC per Runner, +100 SC per Crimson Boss.
* *Failure Penalty:* Dying forfeits the main Contract Bonus and 70% of unbanked mission loot (keeping extraction tension high). Includes an optional `[ EMERGENCY REVIVE ]` button once per mission.

### 7.2 Permanent Armory Gun Power-Ups (Spent with Survival Coins)
Each weapon (Assault Carbine, Tactical Shotgun, High-Caliber SMG) can be upgraded across 4 studio-polished stat tracks in the Armory:
1. **Overpressure Rounds (Damage & Knockback):** Increases damage and physically pushes grey zombies backward into walls, producing larger blood decals.
2. **Extended Drum & Rapid Bolt (Fire Rate & Mag Size):** Reduces reload downtime during massive horde rushes.
3. **Hollow-Point / Piercing Core (Penetration):** Bullets punch through 2 to 4 Shamblers in a straight line, painting long crimson streaks behind them.
4. **Laser Targeter (Crit & Auto-Aim Speed):** Faster target acquisition in Portrait Auto-Shoot mode and tighter spread in Landscape mode.

### 7.3 Mid-Mission Tactical Drops (Temporary In-Game Power-Ups)
During a run, killing Elite Runners, Crimson Bosses, or cracking Red Military Crates drops glowing **Tactical Supply Beacons** on the white floor:
* **HYPER-BURST OVERDRIVE (15 Seconds):** Converts the player's primary gun into a zero-recoil, triple-shot hyper-burst mode with increased muzzle flash intensity and crimson tracer rounds.
* **HEAVY ROCKET LAUNCHER (3 Rounds Override):** Temporarily equips a shoulder-fired anti-materiel rocket launcher. Firing launches a high-velocity warhead with a smoke trail that detonates on impact—sending 20+ grey zombie ragdolls flying through the air and stamping a massive 6-meter glossy crimson blood crater onto the white architecture.
* **CRYO-SHOCK / STIMS:** Temporary movement speed boost + instant reload to escape corner traps.

### 7.4 Improved Molotov Mechanics (Physics & Crowd Control)
* **Aiming & Trajectory:**
  * In **Landscape:** Hold and drag the Molotov button to preview a crisp red parabola arc and landing blast circle on the isometric floor.
  * In **Portrait:** Tapping throws the Molotov automatically at the highest-density cluster of approaching zombies (or drag-to-aim if held).
* **Shatter & Ignited Fluid Pool:** On impact, the glass bottle shatters with high-contrast sparks and creates a spreading **Crimson/Orange Fire Pool** (`GPUParticles3D` + animated floor shader) that burns for 8 seconds.
* **Chain Ignitions & Panic AI:** Zombies walking through the fire pool catch fire, take rapid damage-over-time (DoT), and leave charred black-and-red trails. Burning zombies that touch other packed zombies in a narrow alleyway **spread the fire across the horde**, making Molotovs the ultimate chokepoint weapon.

---

## 8. Horde Hierarchy & Enemy AI

| Enemy Class | Speed | Visual Style | Behavior & Drops |
| :--- | :--- | :--- | :--- |
| **Shambler** | Slow | Standard height, Matte Light Grey (`#B0B0B8`). | Spawns in swarms of 30–80. Blocks streets and corners careless players. |
| **Runner** | Fast | Leaner silhouette, Dark Charcoal (`#3A3A3C`). | Sprints along player's red blood footprints; targets escorted VIPs first. |
| **Crimson Boss** | Medium-Heavy | 1.6x height, Pure Glossy Crimson Red (`#C8000A`) wrapped in dark shadow aura particles. | High HP, smashes through light cover, guards Lab Extractors & Keys, drops **Rocket Launcher** or Research Cores. |

---

## 9. Step-by-Step Build Order for Coding Agent (Godot 4)

* **Milestone 1: Core Project, Autoloads, Audio/Haptics & Async Loading Screen**
  * Set up Godot 4 Android export settings, `GameManager.gd` (encrypted save/load of Coins, Research Cores, Clearance Level, and Unlocked Skills), `OrientationManager.gd` (Portrait/Landscape switcher), `AudioManager.gd` (gunshots + `Input.vibrate_handheld()`), and `LoadingScreen.tscn`.
* **Milestone 2: Outpost Hub UI, Command Contract Board, Armory & Paired Skills UI**
  * Build responsive `Control` layouts that adapt cleanly to both Portrait (`1080x1920`) and Landscape (`1920x1080`). Implement the **Command Board UI** (Sector map + 3 selectable Contract dossiers), **Armory Upgrade UI**, and **Paired Skill Matrix UI**.
* **Milestone 3: Grey-Box City Sectors, Props, Day/Night Blackout Lighting & Player Controller**
  * Construct modular white/grey city templates with untextured grey props (wrecked cars, leafless trees, power poles with catenary wires casting crisp top-layer shadows) and Day/Blackout lighting toggle (including the player's sweeping `SpotLight3D` hand-torch). Build the Player controller supporting both **Portrait (Joystick + Auto-Shoot Toggle)** and **Landscape (Twin-Stick / Manual Fire Button)**.
* **Milestone 4: Combat, Persistent Blood Decals, Molotov & Mid-Game Power-Ups**
  * Implement raycast/projectile shooting, persistent crimson blood splatters & footprints, the **Burst Mode** and **Rocket Launcher** mid-game pickups, and the **Improved Molotov** arc-throw + spreading fire DoT mechanics.
* **Milestone 5: 3-Tier Zombie Horde AI & The 4 Extraction Job Loops**
  * Implement `NavigationRegion3D` horde pathfinding (Shamblers, Footprint-tracking Runners, Crimson Boss) and the modular `MissionManager.gd` state machine supporting **Level 0 Outpost Escape**, **Asset Extraction**, **VIP Escort**, **Research Lab Defense**, and **Blackout Boss Purge**.