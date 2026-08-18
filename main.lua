-- Pokedex Sprites (HGSS)
--
-- Swaps the Pokedex art -- the list-view preview icon and the full entry
-- page pic -- for HeartGold/SoulSilver-style sprites. Everything else
-- (battle, party summary, evolution, Hall of Fame, trade, title, Oak's
-- lab, credits, overworld) is untouched: src/pokemon/Sprites.lua's
-- pokemon.sprite hook tells every call site apart by ctx.kind, and this
-- mod only answers when ctx.kind == "dex" (src/ui/PokedexMenu.lua and
-- src/ui/DexEntryMenu.lua are the only two call sites that pass it).
--
-- Art: HeartGold/SoulSilver sprite rips from Bulbagarden Archives
-- (archives.bulbagarden.net), trimmed to their opaque bounds and fit to
-- <=64x60px so they sit on the entry page without crowding the stats
-- column at x=72. Personal fan-art reskin; not affiliated with or
-- endorsed by Nintendo, Game Freak, or The Pokemon Company.

return function(mod)
  local SPECIES = {
    "BULBASAUR", "IVYSAUR", "VENUSAUR", "CHARMANDER", "CHARMELEON", "CHARIZARD",
    "SQUIRTLE", "WARTORTLE", "BLASTOISE", "CATERPIE", "METAPOD", "BUTTERFREE",
    "WEEDLE", "KAKUNA", "BEEDRILL", "PIDGEY", "PIDGEOTTO", "PIDGEOT",
    "RATTATA", "RATICATE", "SPEAROW", "FEAROW", "EKANS", "ARBOK",
    "PIKACHU", "RAICHU", "SANDSHREW", "SANDSLASH", "NIDORAN_F", "NIDORINA",
    "NIDOQUEEN", "NIDORAN_M", "NIDORINO", "NIDOKING", "CLEFAIRY", "CLEFABLE",
    "VULPIX", "NINETALES", "JIGGLYPUFF", "WIGGLYTUFF", "ZUBAT", "GOLBAT",
    "ODDISH", "GLOOM", "VILEPLUME", "PARAS", "PARASECT", "VENONAT",
    "VENOMOTH", "DIGLETT", "DUGTRIO", "MEOWTH", "PERSIAN", "PSYDUCK",
    "GOLDUCK", "MANKEY", "PRIMEAPE", "GROWLITHE", "ARCANINE", "POLIWAG",
    "POLIWHIRL", "POLIWRATH", "ABRA", "KADABRA", "ALAKAZAM", "MACHOP",
    "MACHOKE", "MACHAMP", "BELLSPROUT", "WEEPINBELL", "VICTREEBEL", "TENTACOOL",
    "TENTACRUEL", "GEODUDE", "GRAVELER", "GOLEM", "PONYTA", "RAPIDASH",
    "SLOWPOKE", "SLOWBRO", "MAGNEMITE", "MAGNETON", "FARFETCHD", "DODUO",
    "DODRIO", "SEEL", "DEWGONG", "GRIMER", "MUK", "SHELLDER",
    "CLOYSTER", "GASTLY", "HAUNTER", "GENGAR", "ONIX", "DROWZEE",
    "HYPNO", "KRABBY", "KINGLER", "VOLTORB", "ELECTRODE", "EXEGGCUTE",
    "EXEGGUTOR", "CUBONE", "MAROWAK", "HITMONLEE", "HITMONCHAN", "LICKITUNG",
    "KOFFING", "WEEZING", "RHYHORN", "RHYDON", "CHANSEY", "TANGELA",
    "KANGASKHAN", "HORSEA", "SEADRA", "GOLDEEN", "SEAKING", "STARYU",
    "STARMIE", "MR_MIME", "SCYTHER", "JYNX", "ELECTABUZZ", "MAGMAR",
    "PINSIR", "TAUROS", "MAGIKARP", "GYARADOS", "LAPRAS", "DITTO",
    "EEVEE", "VAPOREON", "JOLTEON", "FLAREON", "PORYGON", "OMANYTE",
    "OMASTAR", "KABUTO", "KABUTOPS", "AERODACTYL", "SNORLAX", "ARTICUNO",
    "ZAPDOS", "MOLTRES", "DRATINI", "DRAGONAIR", "DRAGONITE", "MEWTWO",
    "MEW",
  }

  -- species id -> "sprites/<ID>.png", built once so a lookup miss is a
  -- nil table read rather than a string concat on every dex open
  local ART = {}
  for _, id in ipairs(SPECIES) do
    ART[id] = "sprites/" .. id .. ".png"
  end

  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    if ctx.kind == "dex" and ctx.side == "front" then
      local file = ART[ctx.species]
      if file then return mod.assets:path(file) end
    end
    return next(path, ctx)
  end)
end
