# SurfTimer HUD addon

A Workshop addon that contains **only generic, server-driven HUD slots**. You publish it once; after
that, all HUD content, colours and visibility are controlled from the plugin
(`src/ST-Player/CustomHud.cs` and `PlayerHUD.cs`), with no republish needed.

## Layout

`custom_hud_layout` labels only support plain `text`, with no HTML, according to Valve's
`point_script.d.ts`. So every piece of text is its own label, with its own text (a dialog variable
named like the label's id) and its own style classes.

The style follows CS2's own HUD:
- values in bold Stratum2, and the changing numbers in a monospace font so they don't jitter;
- small caps grey labels and units;
- bands that fade at both ends for the top bar rows;
- dark fields with an accent edge in the bottom centre;
- killfeed-style rows for the side panels.

| Slot id | Region | Structure | Plugin content |
|---|---|---|---|
| `st_top` | top centre | grid, 2 rows × 8 segments | row 0: map, tier, stage or bonus, practice/repeat flags. Row 1 (smaller): PB, rank, WR, or the replay being played |
| `st_center` | bottom centre | 2 rows × 4 fields, see below | row 0: timer (double-width) and speed. Row 1: prespeed, keys and sync |
| `st_left` | left side | grid, 7 × 4 | splits of the current map run vs PB |
| `st_right` | right side | grid, 9 × 2 | players spectating you |

The grid slots use `st_<slot>`, then `st_<slot>_<row>`, then `st_<slot>_<row>_<segment>`, with sizes
that must match `CustomHud.Grid`.

The centre slot holds the field rows `st_fields_0..1`. Each row has fields `st_field_R_0..3`, and
each field has a label `st_field_R_F_lbl` and value segments `st_field_R_F_0..5`. The plugin decides
what each field shows and which ones are `wide` (see `PlayerHud.SendCenter`).

The slots have room to spare, so more content fits without a republish. The XML is regular:
regenerate it with a script rather than editing it by hand if you ever change the sizes.

While you spectate, the HUD shows the spectated player's data, or the replay bot's.

**Classes the server toggles per player** (all documented at the top of `surftimer_hud.css`):
- **Slots:**
  - `hidden`;
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
  - the speed gradient: `spd-0` … `spd-8`
  - fonts: `font-mono` (Noto Mono, shipped with CS2) or `font-digit` (Stratum2 with fixed-width
    digits; a legacy font that may fall back to regular Stratum2). The plugin picks one with
    `CustomHud.MonoFontClass`.
- **Centre:**
  - fields: `hidden`, and `wide`, which spans two fields;
  - field values: `key` (keyboard letter spacing) and `dim` (a released key).

Everything starts hidden, so nothing shows until the plugin fills it. The HUD also hides itself
while the scoreboard or end-of-match screen is open.

With the custom HUD enabled, the plugin stops using CS2's centre print for its zone and prespeed
messages. It also removes the map's own message entities (`env_hudhint`, `game_text`), so map texts
like "Stage 7" don't cover the HUD.

A new screen region, a bigger grid, or a new colour class is the only thing that needs a republish.

## Compile

Copy `panorama/` into `content/csgo_addons/<addon>/`, then run:

```
"<CS2>\game\bin\win64\resourcecompiler.exe" -nop4 -i "<CS2>\content\csgo_addons\<addon>\panorama\layout\custom_game\surftimer_hud.xml"
```

This produces `game/csgo_addons/<addon>/panorama/layout/custom_game/surftimer_hud.vxml_c`, and the
CSS as `.vcss_c`. You can also compile from the Workshop Tools Asset Browser.

Ignore `Leaked KeyValues blocks: …` at the end: Valve's own demo addon prints the same line.

## Publish (once)

1. Upload the addon with the Workshop Tools and note the **addon ID**.
2. On the server, install **MultiAddonManager** and add the ID to `mm_client_extra_addons`, so every
   client downloads it on connect.
3. In `cfg/SurfTimer/timer_settings.json`:
   - set `"custom_hud_enabled": true`;
   - set `"custom_hud_layout": "panorama/layout/custom_game/surftimer_hud.xml"`. Use the
     **source name, `.xml`**. Clients reject `.vxml` with
     `[custom_hud] Layout xml is an invalid resource name`. The plugin precaches the compiled
     `.vxml` itself.

## Testing as a regular player

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
