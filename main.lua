-- Pokedex Sprites (HGSS)
--
-- Swaps the Pokedex entry page art -- the screen reached by highlighting a
-- caught Pokemon and choosing DATA -- for HeartGold/SoulSilver-style
-- sprites. Everything else (battle, party summary, evolution, Hall of
-- Fame, trade, title, Oak's lab, credits, overworld) keeps vanilla art.
--
-- NOTE: the Gen 1 Pokedex LIST draws no sprite at all. Scrolling it will
-- never look different; src/ui/PokedexMenu.lua's only sprite reference is
-- inside Yellow's PRNT action, which renders this same entry page to a PNG.
--
-- ------- why this patches the screen instead of using the hook (0.3.0)
--
-- 0.1.0 went through `pokemon.sprite`, the public hook src/pokemon/
-- Sprites.lua raises with ctx.kind naming the calling screen. That is the
-- clean seam and it still runs first below -- but 0.2.0's diagnostic came
-- back H0 on the user's build: the hook was never raised even once, while
-- this mod's OTHER hook (ui.start_menu.items) fired fine. So the bus works
-- and Sprites.path simply was not being reached.
--
-- The engine history explains it. DexEntryMenu only started resolving its
-- pic through Sprites.path between releases v0.1.20 and v0.1.30:
--
--   v0.1.0  -> pcall(love.graphics.newImage, self.def.spriteFront)
--   v0.1.30 -> require("src.pokemon.Sprites").path(..., { kind = "dex" })
--
-- and Sprites.lua at v0.1.0, though present, raises no hook at all. On any
-- engine older than that boundary a hook-only mod is silently inert --
-- exactly H0, with nothing broken anywhere to find.
--
-- So the actual swap now happens by wrapping DexEntryMenu.new and replacing
-- the sprite it just built. That works on every engine version, because it
-- does not care HOW the vanilla pic was resolved -- only that the finished
-- screen holds one. The hook is kept as well: where it does fire it costs
-- nothing, and it also covers the PRNT printer path, which builds its own
-- image without going through DexEntryMenu.new at all.
--
-- Art: HeartGold/SoulSilver sprite rips from Bulbagarden Archives, trimmed
-- to their opaque bounds and fit to <=64x60px so they sit on the entry page
-- without crowding the stats column at x=72. Personal fan-art reskin; not
-- affiliated with or endorsed by Nintendo, Game Freak, or The Pokemon Company.

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

  -- one love Image per species, built on first view and kept: the entry page
  -- is reopened constantly and newImage on every open would thrash
  local cache = {}
  local function imageFor(species)
    local rel = ART[species]
    if not rel then return nil end
    if cache[species] ~= nil then return cache[species] or nil end
    local ok, img = pcall(love.graphics.newImage, mod.assets:path(rel))
    cache[species] = (ok and img) or false
    return cache[species] or nil
  end

  local diag = { hook = 0, new = 0, last = "NONE", hit = false }

  -- ------- the swap: wrap DexEntryMenu.new and replace the finished pic
  --
  -- Guarded behind a mod-specific field so a hot reload cannot wrap the
  -- wrapper, matching the pattern used across this author's other mods.
  local okReq, DexEntryMenu = pcall(require, "src.ui.DexEntryMenu")
  if okReq and type(DexEntryMenu) == "table" and DexEntryMenu.new then
    if not DexEntryMenu._pokedexSpritesOriginalNew then
      DexEntryMenu._pokedexSpritesOriginalNew = DexEntryMenu.new
    end
    local originalNew = DexEntryMenu._pokedexSpritesOriginalNew

    function DexEntryMenu.new(game, speciesOrOpts, onDone)
      local inst = originalNew(game, speciesOrOpts, onDone)
      diag.new = diag.new + 1
      -- never let a swap failure take the dex page down: the vanilla screen
      -- the original already built is a complete, working fallback
      pcall(function()
        -- def.id is the species id the extractor stamped, so the local
        -- resolveArgs (which cannot be reached from here) is not needed
        local species = inst and inst.def and inst.def.id
        diag.last = tostring(species)
        diag.hit = species ~= nil and ART[species] ~= nil
        local img = species and imageFor(species)
        if not img then return end
        inst.sprite = img
        -- full-colour art has to sit out the SGB shade remap, which keys on
        -- the RED channel and would return a baked red as white
        inst.spriteTrueColor = true
      end)
      return inst
    end

    -- Belt and braces for engines older than the trueColor plumbing: mark the
    -- pic's rect for the unshaded re-blit directly. On a build whose render
    -- already marked it this just appends an identical rect, which re-blits
    -- the same pixels twice and looks the same.
    if DexEntryMenu.draw then
      if not DexEntryMenu._pokedexSpritesOriginalDraw then
        DexEntryMenu._pokedexSpritesOriginalDraw = DexEntryMenu.draw
      end
      local originalDraw = DexEntryMenu._pokedexSpritesOriginalDraw
      function DexEntryMenu:draw(...)
        local result = originalDraw(self, ...)
        pcall(function()
          local img = self.sprite
          if not (img and self.spriteTrueColor) then return end
          local w, h = img:getDimensions()
          require("src.render.PaletteFX")
            .markTrueColor(8, math.max(0, 60 - h), w, h)
        end)
        return result
      end
    end
  end

  -- ------- the hook, kept for builds that do raise it
  --
  -- Also the only route that reaches Yellow's PRNT printer job, which builds
  -- its own image straight from Sprites.path without constructing the screen.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    if ctx and ctx.kind == "dex" and ctx.side == "front" then
      diag.hook = diag.hook + 1
      local rel = ART[ctx.species]
      if rel then return mod.assets:path(rel) end
    end
    return next(path, ctx)
  end)

  -- ------- diagnostic rows (removed once this is confirmed working)
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    local screens = game and game.data and game.data.screens
    local owner = (screens and screens.DexEntryMenu) and "MOD" or "ENG"
    local noop = function() end
    out = mod.ui.insertBefore(out, "SAVE",
      { label = "SPR H" .. diag.hook .. " N" .. diag.new, onSelect = noop })
    out = mod.ui.insertBefore(out, "SAVE",
      { label = "SPR " .. diag.last .. (diag.hit and " HIT" or " MISS"),
        onSelect = noop })
    return mod.ui.insertBefore(out, "SAVE",
      { label = "SPR SCR " .. owner, onSelect = noop })
  end)
end
