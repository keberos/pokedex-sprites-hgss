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

## Diagnostic rows

This build still adds three temporary rows to the START menu, kept until the swap is
confirmed working in play:

| Row | Meaning |
| --- | --- |
| `SPR H<n> N<n>` | `pokemon.sprite` calls, and `DexEntryMenu.new` calls |
| `SPR <ID> HIT/MISS` | last dex species built, and whether the art table had it |
| `SPR SCR ENG/MOD` | whether the engine or another mod owns the `DexEntryMenu` screen |

`N` rising while `H` stays at 0 is the expected shape on an older engine, and means the
screen patch is carrying the swap on its own. `SCR MOD` would mean a different mod has
replaced the dex entry screen wholesale, in which case neither route can reach it.

## Status

Not yet confirmed working in play. 0.1.0's hook-only approach was verified inert by a
diagnostic build; 0.3.0's screen patch addresses that cause but has not been seen rendering
yet. Worth checking: a few entries at different sprite sizes (a tall one like Alakazam, a
wide one like Arcanine), that the colours look right rather than washed out, and that
battle/summary art is still vanilla.
