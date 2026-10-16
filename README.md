<h1 align="center">
    <br>
    <img src="assets/logo.svg" width="128px" alt="z4lab logo"/>
    <br>
	z4lab custom UI addon
</h1>

<p align="center">Custom HUD, popup menu and paint dot for <b>SurfTimer for CS2</b></p>

<hr>

A Workshop addon that contains **only generic, server-driven HUD slots** and a **clickable popup
menu**. You publish it once; after that, all content, colours and visibility are controlled from the
SurfTimer plugin (`src/ST-Player/CustomHud.cs`, `PlayerHUD.cs` and `src/ST-Player/Menu/`), with no
republish needed.

Click a section to expand it.

<details>
<summary><b>Layout</b></summary>

`custom_hud_layout` labels only support plain `text`, with no HTML, according to Valve's
`point_script.d.ts`. So every piece of text is its own label, with its own text (a dialog variable
named like the label's id) and its own style classes.

The style follows CS2's own HUD:
- values in bold Stratum2, and the changing numbers in a monospace font so they don't jitter;
- small caps grey labels and units;
- bands that fade at both ends for the top bar rows;
- dark fields with an accent edge in the bottom centre;
- killfeed-style rows for the side panels;
- the [Nord](https://www.nordtheme.com) colours, with a team accent: CT blue, T yellow.

| Slot id | Region | Structure | Plugin content |
|---|---|---|---|
| `z4_top` | top centre | grid, 4 rows × 8 segments | row 0: map, tier, stage or bonus, practice/repeat flags. Smaller rows: row 1 PB, rank, WR, or the replay being played; row 2 the map chooser (time left, vote, next map); row 3 free for addons |
| `z4_center` | bottom centre | 2 rows × 4 fields, see below | row 0: timer (double-width) and speed. Row 1: prespeed, keys and sync |
| `z4_left` | left side | grid, 7 × 4 | splits of the current map run vs PB |
| `z4_right` | right side | grid, 9 × 2 | players spectating you |
| `z4_mid` | screen centre | 3 lines: `z4_mid_0` above the crosshair, `z4_mid_1` at it, `z4_mid_2` below | line 0: the player's speed (opt-in, `!options` › HUD › Center HUD); all three: messages (later, e.g. admin messages) |

The grid slots use `z4_<slot>`, then `z4_<slot>_<row>`, then `z4_<slot>_<row>_<segment>`, with sizes
that must match `CustomHud.Grid`.

The centre slot holds the field rows `z4_fields_0..1`. Each row has fields `z4_field_R_0..3`, and
each field has a label `z4_field_R_F_lbl` and value segments `z4_field_R_F_0..5`. The plugin decides
what each field shows and which ones are `wide` (see `PlayerHud.SendCenter`).

The slots have room to spare, so more content fits without a republish. The XML is regular, so it's
generated: change sizes or add elements in `tools/generate_layout.ps1` and run it from the repo root
(`./tools/generate_layout.ps1`) instead of editing `z4lab_custom_ui.xml` by hand.

</details>

<details>
<summary><b>Popup menu</b></summary>

`z4_menu` is a popup in the screen centre, used by the plugin's pickers (`!replay`, `!spec`). While
it's open the plugin puts the player in cursor mode (`SetInputCaptureEnabled`), and every `<Button>`
reports its id to the server when clicked (`OnCustomHudClicked`).

| Id | Element | Content |
|---|---|---|
| `z4_menu_title` | Label | menu title |
| `z4_menu_close` | Button | closes the popup |
| `z4_menu_tabs` | Panel | tab row, hidden for single-tab menus |
| `z4_menu_tab_0..5` | Button, label `z4_menu_tab_N_lbl` | tabs; `on` marks the active one |
| `z4_menu_item_0..7` | Button, labels `_num`, `_text`, `_sub`, `_right` | the rows of the current page |
| `z4_menu_prev` / `z4_menu_next` | Button | paging; `off` dims them on the first/last page |
| `z4_menu_page` | Label | "Page 1 / 3" |

The counts must match `CustomHud.MenuTabCount` / `MenuItemCount`. Labels inside buttons have
`hittest="false"` so the click lands on the button.

While you spectate, the HUD shows the spectated player's data, or the replay bot's.

**Classes the server toggles per player** (all documented at the top of `z4lab_custom_ui.css`):
- **Slots:**
  - `hidden`;
  - `team-ct` / `team-t`, the accent colour (field borders, side rows, menu): the shown player's team. Also on
    `z4_mid` and `z4_menu`;
  - `shift-0` … `shift-10` for the vertical position. The step sizes are:
    - top bar: 40px from the top, plus 20px per step;
    - centre: 100px from the bottom, plus 20px per step;
    - side panels: 200px from the top, plus 40px per step.

    The plugin picks them in `CustomHud.SlotShift`, so moving a region needs only a plugin rebuild.
- **Rows:**
  - `hidden`;
  - `band`, the fading background band of a top bar row;
  - `sub`, a smaller secondary top bar row;
  - `hdr`, a header row with no background in the side panels. The plugin sets it on rows that
    contain only labels.
- **Segments:**
  - `hidden`
  - kind: `lbl` (label), `val` (value) or `unit`
  - size: `sm`, `md`, `lg` or `xl`
  - colours: `col-blue`, `col-purple`, `col-green`, `col-indigo`, `col-gold`, `col-grey`, `col-red`
  - the speed gradient: `spd-0` … `spd-8` (Nord: deep blue, frost, green, yellow, orange, red)
  - static Nord colours: `nc-snow`, `nc-frost`, `nc-teal`, `nc-blue`, `nc-deep`, `nc-red`, `nc-orange`,
    `nc-yellow`, `nc-green`, `nc-purple` (a player's speed colour, gain / loss)
  - fonts: `font-mono` (Noto Mono, shipped with CS2) or `font-digit` (Stratum2 with fixed-width
    digits; a legacy font that may fall back to regular Stratum2). The plugin picks one with
    `CustomHud.MonoFontClass`.
- **Centre:**
  - fields: `hidden`, and `wide`, which spans two fields;
  - field values: `key` (keyboard letter spacing) and `dim` (a released key).
- **Middle** (`z4_mid_0..2`): `hidden`, `msize-1` … `msize-5` (18-60px), `mpos-0` … `mpos-40` (vertical
  offset, 10px per step, `mpos-20` = at the crosshair - the plugin places line 0 / 1 / 2 at 14 / 20 / 26 plus the
  player's offset), the colours and fonts above.
- **Menu:** `hidden` on `z4_menu`, the tab row, tabs and rows; `on` on the active tab; `info` on
  rows that can't be picked (no hover); `off` on Prev/Next at the first/last page.

Everything starts hidden, so nothing shows until the plugin fills it. The HUD also hides itself
while the scoreboard or end-of-match screen is open.

With the custom HUD enabled, the plugin stops using CS2's centre print for its zone and prespeed
messages. It also removes the map's own message entities (`env_hudhint`, `game_text`), so map texts
like "Stage 7" don't cover the HUD.

A new screen region, a bigger grid, or a new colour class is the only thing that needs a republish.

</details>

<details>
<summary><b>Compile</b></summary>

`.\build.ps1` (PowerShell) does all of it: it copies `panorama/`, `materials/` and `particles/` into
`content/csgo_addons/z4lab_custom_ui/` and compiles the layout, the texture and the particle. It uses the default
Steam install; pass `-Cs2Dir` for another CS2 folder and `-Addon` for another addon name. The addon has to exist in the
Workshop Tools first.

By hand: copy `panorama/`, `materials/` and `particles/` into `content/csgo_addons/<addon>/`, then run:

```
"<CS2>\game\bin\win64\resourcecompiler.exe" -nop4 -i "<CS2>\content\csgo_addons\<addon>\panorama\layout\custom_game\z4lab_custom_ui.xml"
```

This produces `game/csgo_addons/<addon>/panorama/layout/custom_game/z4lab_custom_ui.vxml_c`, and the
CSS as `.vcss_c`. You can also compile from the Workshop Tools Asset Browser.

The paint dot (SurfTimer.Paint) is compiled the same way:

```
"<CS2>\game\bin\win64\resourcecompiler.exe" -nop4 -i "<CS2>\content\csgo_addons\<addon>\particles\z4lab\paint_dot.vpcf"
```

That also compiles its texture (`materials/z4lab/paint_dot.vtex`, a white soft round dot from `paint_dot.png`). The
particle is one sprite that lies flat along control point 0's forward axis. Its color comes from control point 1
(0-255) and its size in units from control point 2's x. Open it in the particle editor to check it.

Ignore `Leaked KeyValues blocks: …` at the end: Valve's own demo addon prints the same line.

</details>

<details>
<summary><b>Publish (once)</b></summary>

1. Upload the addon with the Workshop Tools and note the **addon ID**.
2. On the server, install **MultiAddonManager** and add the ID to `mm_client_extra_addons`, so every
   client downloads it on connect.
3. In `cfg/SurfTimer/timer_settings.json`:
   - set `"custom_hud_enabled": true`;
   - set `"custom_hud_layout": "panorama/layout/custom_game/z4lab_custom_ui.xml"`. Use the
     **source name, `.xml`**. Clients reject `.vxml` with
     `[custom_hud] Layout xml is an invalid resource name`. The plugin precaches the compiled
     `.vxml` itself.

</details>

<details>
<summary><b>Testing as a regular player</b></summary>

Your own PC has the addon locally, in `game/csgo_addons/<addon>`, because you built it. That can
hide problems other players would hit. To test like a regular player:

1. Close CS2.
2. Temporarily rename `game\csgo_addons\z4lab_custom_ui`, e.g. to `z4lab_custom_ui_off`.
3. Join the server and let MultiAddonManager download the Workshop copy. It ends up in
   `steamapps\workshop\content\730\<ID>`.
4. Check that the HUD shows, and that the client console has no `[custom_hud]` error.
5. Rename the folder back afterwards.

Even better, have a second player who has never had the addon join. Then check:

- **The HUD shows up** for them.
- **Two clients see different values**, which confirms per-player updates.
- **Texts survive another player joining.** The plugin already forces a full resend on every join.

</details>
