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
