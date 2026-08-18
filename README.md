# Pokedex Sprites (HGSS)

Replaces the Pokedex art in [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) with
Pokemon HeartGold/SoulSilver-style sprites, for all 151 species.

Install with **Launcher → MODS → Import mod .zip**.

## What it changes

The **Pokédex entry page** — the screen with the species name, height/weight and dex text.

**Where to actually see it:** open the Pokédex, highlight a Pokémon you've caught, and
choose **DATA**. The Pokédex *list* itself draws no sprite at all in Gen 1 — scrolling it
will never look different, because there is no picture there to change. (Yellow's **PRNT**
printer action renders the same entry page, so it picks up the new art too.)

Nothing else. Battle sprites, the party summary screen, evolution, Hall of Fame, trade,
title screen, and Professor Oak's lab all keep their original art untouched.

## How it works

`src/pokemon/Sprites.lua` is the one seam every sprite draw in the engine goes through, and
it raises a public `pokemon.sprite` hook carrying `ctx.kind` -- `"battle"`, `"dex"`,
`"summary"`, `"evolution"`, `"hof"`, `"trade"`, `"title"`, `"oak"`, `"credits"`,
`"overworld"` -- so a hook can tell which screen is asking. The two `kind = "dex"` call
sites are `src/ui/DexEntryMenu.lua` (the entry page) and `src/ui/PokedexMenu.lua`'s
Yellow-only PRNT action, which renders that same page to a PNG; every other site passes
something else. This mod answers the hook only when `ctx.kind == "dex"` and returns a path
into its own bundled `sprites/` folder; every other call falls through untouched to
`next(path, ctx)`.

**That hook alone was not enough**, which is why 0.3.0 also patches the screen directly.
`DexEntryMenu` only began resolving its picture through `Sprites.path` somewhere between
engine releases **v0.1.20 and v0.1.30**:

```
v0.1.0   pcall(love.graphics.newImage, self.def.spriteFront)   -- no hook at all
v0.1.30  require("src.pokemon.Sprites").path(..., { kind = "dex" })
```

and `Sprites.lua` at v0.1.0, though it exists, raises no hook. On any engine older than that
boundary a hook-only mod is **silently inert** — nothing is broken, the hook simply is never
raised. A diagnostic build confirmed exactly that: zero `pokemon.sprite` calls, while this
mod's other hook (`ui.start_menu.items`) fired normally.

So the swap now works by wrapping `DexEntryMenu.new` and replacing the sprite on the screen
it just built. That is version-proof: it doesn't care *how* the vanilla pic was resolved,
only that the finished screen holds one. The hook is still installed as well — where it does
fire it costs nothing, and it's the only route that reaches Yellow's PRNT printer job, which
builds its own image without constructing the screen.

Patching an engine module means this version requires the `engine_internals` permission
(0.1.0 and 0.2.0 needed none).

## Art

`sprites/<SPECIES>.png`, one per species, trimmed to their opaque pixel bounds and scaled
down (never up) to fit within 64x60px, so the biggest sprites don't crowd the stats text
that starts at x=72 on the entry page or push out the top of the visible area.

Source: HeartGold/SoulSilver sprite rips from
[Bulbagarden Archives](https://archives.bulbagarden.net). **Personal, non-commercial use
only** -- see `LICENSE`. This is an unofficial fan-art swap, not affiliated with or
endorsed by Nintendo, Creatures Inc., GAME FREAK inc., or The Pokemon Company.

## The caught marker

The Pokédex list marks every caught species with a small ball. Vanilla draws it inline in
`ListMenu:draw` as a flat black disc — a filled circle, a white band, a centre dot — with no
asset behind it and no hook over it. This mod repaints it as a proper Poké Ball: red top,
white bottom, dark band and outline, white release button.

Set **CAUGHT BALL** to `VANILLA` on the mod's page in the mod manager to keep the original
flat marker.

Wrapping the shared `ListMenu` is safe because `item.ball` is set in exactly one place in
the whole engine — `src/ui/PokedexMenu.lua`, on owned entries — so the bag, party, shops and
PC lists draw no ball and are untouched. The marker's position is recomputed the way the
original does it, with `Font.width` in glyph advances rather than a byte count, because
NIDORAN's gender signs are multi-byte and a byte count pushes their ball 16px right.

## Why the art is masked, not boxed

Full-colour art has to sit out the SGB shade pass, which keys on the **red** channel — a
baked red would otherwise come back white. `PaletteFX.markTrueColor` is the escape hatch,
but it re-blits *the rect it is given*, including every transparent pixel in it. Handed a
sprite's whole bounding box it repaints the page background behind the art in raw white
instead of BROWNMON brown, which reads as a grey slab. The dex page's mon-pic palette zone
is tiles (1,1,8,8) — pixels y 8–72 — so a tall sprite drawn at `y = max(0, 60 - h)` reached
*above* that zone and broke the brown frame across the top of the page.

Two fixes, both in 0.4.0:

- Sprites are capped at **56px tall**, the same limit vanilla Gen 1 front pics have, so the
  engine places them at `y = 4` exactly as it places vanilla art instead of jamming them to
  `y = 0`.
- Each sprite carries a **mask** — one rect per horizontal span of opaque pixels, with
  identical spans merged vertically (about 40 rects for a typical sprite). Only those spans
  are marked, so nothing transparent is ever re-blitted and the page keeps its own colour
  right up to the edge of the art. The caught-marker ball gets the same treatment with a
  seven-span disc mask, so it doesn't grow pale square corners.

For the same reason the mod deliberately does **not** set `spriteTrueColor`: on an engine
that has that plumbing, it would mark the whole bounding box and reintroduce the slab.

## Compatibility

**[Useful Dex](https://github.com/ShaneMcGovernIE/useful_dex) — either/or for the sprites,
fine for the ball.** No hard conflict is declared, and nothing breaks if both are installed;
the sprite swap just stops taking effect.

Useful Dex registers its own `DexEntryMenu` and `PokedexMenu` screens, and a registry record
beats the builtin in `Screens.resolve`.

- *The caught marker still works.* Its list is built on the engine's `PokedexMenu`, keeps the
  same `item.ball` field and still renders through `ListMenu`, which is where this mod's
  wrapper sits — so the modern ball draws in all three of its list modes.
- *The entry-page sprites do not.* Its `DexInfoScreen.new` does call the engine's
  `DexEntryMenu.new`, so the swap lands — but the next line calls `setSpecies()`, which
  re-resolves the pic through `Sprites.path(..., { kind = "battle" })` and overwrites it. That
  `"battle"` is deliberate on its side (so animation and skin mods apply). This mod answers
  only `kind == "dex"`, because answering `"battle"` would change real battle sprites, so it
  falls through to vanilla art. It also draws with its own `DexInfoScreen:draw` rather than
  the engine's, so the span-mask true-colour pass never runs either.

A shim is possible — patch `setSpecies` on its metatable and wrap its draw — but it would
reach into another mod's private tables and break on any refactor there, so it is
deliberately not done.

## Status

**1.0.0 — confirmed working in play.** The entry-page sprites were verified in game, and the
modern caught marker and tall-sprite border fix went out in 0.4.0 ahead of the promotion.

Install with **Launcher → MODS → Import mod .zip**, or through the
[keberos mod index](https://github.com/keberos/gen1recomp-index).
