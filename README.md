# Pokedex Sprites (HGSS)

Replaces the Pokedex art in [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) with
Pokemon HeartGold/SoulSilver-style sprites, for all 151 species.

Install with **Launcher → MODS → Import mod .zip**.

## What it changes

Both places the Pokedex shows a Pokemon's picture:

- The **list-view preview** (the small pic next to a highlighted entry).
- The **full entry page** (species, height/weight, dex text).

Nothing else. Battle sprites, the party summary screen, evolution, Hall of Fame, trade,
title screen, and Professor Oak's lab all keep their original art untouched.

## How it works

`src/pokemon/Sprites.lua` is the one seam every sprite draw in the engine goes through, and
it raises a public `pokemon.sprite` hook carrying `ctx.kind` -- `"battle"`, `"dex"`,
`"summary"`, `"evolution"`, `"hof"`, `"trade"`, `"title"`, `"oak"`, `"credits"`,
`"overworld"` -- so a hook can tell which screen is asking. Both Pokedex call sites
(`src/ui/PokedexMenu.lua`, `src/ui/DexEntryMenu.lua`) pass `kind = "dex"`; every other site
passes something else. This mod answers the hook only when `ctx.kind == "dex"` and returns a
path into its own bundled `sprites/` folder; every other call falls through untouched to
`next(path, ctx)`.

Because that's the entire mechanism, this mod requests **no permissions** -- it never
`require`s an internal engine module, it only uses the public `mod.hooks` and `mod.assets`
APIs every mod gets by default.

## Art

`sprites/<SPECIES>.png`, one per species, trimmed to their opaque pixel bounds and scaled
down (never up) to fit within 64x60px, so the biggest sprites don't crowd the stats text
that starts at x=72 on the entry page or push out the top of the visible area.

Source: HeartGold/SoulSilver sprite rips from
[Bulbagarden Archives](https://archives.bulbagarden.net). **Personal, non-commercial use
only** -- see `LICENSE`. This is an unofficial fan-art swap, not affiliated with or
endorsed by Nintendo, Creatures Inc., GAME FREAK inc., or The Pokemon Company.

## Status

Untested in-game (built without a local install to verify against -- see this repo owner's
usual workflow). Should be checked against: the Pokedex list scroll, opening a full entry
for a few species of different sprite sizes (e.g. a tall one like Alakazam, a wide one like
Arcanine), and that vanilla art still shows correctly in battle/summary/evolution.
