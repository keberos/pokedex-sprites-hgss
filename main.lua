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
    -- LOVE's default filter is linear, which softens pixel art the moment the
    -- 160x144 canvas is scaled to the real screen. Nearest keeps the edges hard.
    if ok and img then pcall(img.setFilter, img, "nearest", "nearest") end
    cache[species] = (ok and img) or false
    return cache[species] or nil
  end

  -- ------- why the true-colour mark has to follow the SPRITE, not its box
  --
  -- markTrueColor re-blits the rect it is given without the SGB shade pass.
  -- Handed the sprite's whole bounding box that also re-blits every
  -- TRANSPARENT pixel in it, which paints the page background behind them in
  -- raw white instead of the BROWNMON brown -- a grey slab around the art.
  -- The dex page's mon-pic zone is tiles (1,1,8,8), i.e. y 8..72, so a tall
  -- sprite drawn at y = max(0, 60 - h) reached ABOVE that zone and broke the
  -- brown frame at the top of the page.
  --
  -- So each sprite carries a mask instead: one rect per horizontal span of
  -- opaque pixels, with vertically identical spans merged into a single
  -- taller rect. Nothing transparent is ever marked, so the page keeps its
  -- own colour right up to the edge of the art. Built once per species from
  -- the ImageData and cached, because it is pure pixel work.
  -- ------- 1.1.0: why SPANS alone was not enough
  --
  -- The row-exact mask emits a rect per horizontal run, and a jagged
  -- silhouette makes most of those ONE PIXEL TALL (about 40 rects for a
  -- typical sprite, 53 at worst). A 1px zone is the first thing to be lost
  -- when the 160x144 UI canvas is scaled to a real screen at a non-integer
  -- factor, and engine v0.2.13 rerouted the UI zone blit through a new
  -- clipToView(). Symptom: the art swaps in but only part of it keeps its
  -- colour, worst on the most jagged sprites -- "some monotone, some missing
  -- most of the colour".
  --
  -- BANDS is the fix: take the union of the row spans over each 8px band, so
  -- a 56px sprite yields at most 7 rects and every one is 8px tall. Chunky
  -- enough to survive any scale, still hugging the silhouette per band rather
  -- than boxing the whole sprite -- a band only exists where art exists, so
  -- the brown border above a tall sprite stays intact.
  local rowCache = {}
  local function rowSpans(species)
    if rowCache[species] ~= nil then return rowCache[species] or nil end
    local rel = ART[species]
    -- `rel and pcall(...)` would truncate to ONE value, leaving data always
    -- nil -- which is exactly what shipped in 0.4.0 through 1.1.0: the mask
    -- bailed for every species, nothing was ever marked, and the art fell
    -- through to the shade pass. The engine hit the identical bug in this
    -- very screen (DexEntryMenu.lua, #307: "the guard has to be a statement
    -- for pcall's second return to survive"). Keep it a statement.
    local ok, data = false, nil
    if rel then ok, data = pcall(love.image.newImageData, mod.assets:path(rel)) end
    if not ok or not data then rowCache[species] = false return nil end
    local w, h = data:getDimensions()
    local rows = { h = h, w = w }
    for y = 0, h - 1 do
      local minx, maxx
      for x = 0, w - 1 do
        local _, _, _, a = data:getPixel(x, y)
        if a > 0 then
          if not minx then minx = x end
          maxx = x
        end
      end
      rows[y] = minx and { minx, maxx } or false
    end
    rowCache[species] = rows
    return rows
  end

  local BAND = 8
  local maskCache = { spans = {}, bands = {}, box = {} }

  local function buildSpans(rows)
    local rects, open = {}, nil
    for y = 0, rows.h - 1 do
      local s = rows[y]
      if s then
        local rw = s[2] - s[1] + 1
        if open and open.x == s[1] and open.w == rw and open.y + open.h == y then
          open.h = open.h + 1
        else
          open = { x = s[1], y = y, w = rw, h = 1 }
          rects[#rects + 1] = open
        end
      else
        open = nil -- a fully blank row breaks the run
      end
    end
    return rects
  end

  local function buildBands(rows)
    local rects = {}
    for top = 0, rows.h - 1, BAND do
      local minx, maxx
      local bottom = math.min(top + BAND, rows.h) - 1
      for y = top, bottom do
        local s = rows[y]
        if s then
          if not minx or s[1] < minx then minx = s[1] end
          if not maxx or s[2] > maxx then maxx = s[2] end
        end
      end
      if minx then
        -- Overlap each band 1px into the next. Abutting rects are re-blitted
        -- as separate scissored regions, and at a non-integer display scale
        -- the join between two of them can fall on a half pixel that neither
        -- covers -- which showed up as a hairline through the art every 8px.
        -- Re-blitting a row twice is idempotent (same pixels, no shader), so
        -- an overlap costs nothing and closes the seam.
        local h = bottom - top + 1
        if bottom < rows.h - 1 then h = h + 1 end
        rects[#rects + 1] = { x = minx, y = top, w = maxx - minx + 1, h = h }
      end
    end
    return rects
  end

  local function maskFor(species, style)
    local bucket = maskCache[style]
    if not bucket then return nil end
    if bucket[species] ~= nil then return bucket[species] or nil end
    local rows = rowSpans(species)
    if not rows then bucket[species] = false return nil end
    local rects
    if style == "spans" then rects = buildSpans(rows)
    elseif style == "box" then rects = { { x = 0, y = 0, w = rows.w, h = rows.h } }
    else rects = buildBands(rows) end
    bucket[species] = rects
    return rects
  end

  mod.options:define({
    { key = "ball", label = "CAUGHT BALL", type = "choice", default = "modern",
      choices = { { "MODERN", "modern" }, { "VANILLA", "vanilla" } } },
    -- BANDS is the default and the one to keep; the others are here so a bad
    -- result can be A/B'd in game instead of guessed at from source.
    { key = "mask", label = "DEX COLOR", type = "choice", default = "bands",
      choices = { { "BANDS", "bands" }, { "EXACT", "spans" },
                  { "BOX", "box" }, { "DEBUG", "debug" }, { "OFF", "off" } } },
  })

  -- Temporary, for this round of diagnosis only -- see the SPR rows below.
  local diag = { rects = 0, species = "NONE", style = "?", stage = "NEVER" }

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
      -- never let a swap failure take the dex page down: the vanilla screen
      -- the original already built is a complete, working fallback
      pcall(function()
        -- def.id is the species id the extractor stamped, so the local
        -- resolveArgs (which cannot be reached from here) is not needed
        local species = inst and inst.def and inst.def.id
        local img = species and imageFor(species)
        if not img then return end
        inst.sprite = img
        -- deliberately NOT setting inst.spriteTrueColor: on an engine that
        -- has that plumbing it would mark the sprite's whole bounding box,
        -- which is the grey-slab bug described above. The draw wrapper below
        -- marks the art's real silhouette instead, identically on every
        -- engine version.
        inst._pokedexSpritesSpecies = species
      end)
      return inst
    end

    -- Mark the swapped-in art for the unshaded re-blit, span by span, so the
    -- colour survives the SGB pass without repainting the page around it.
    if DexEntryMenu.draw then
      if not DexEntryMenu._pokedexSpritesOriginalDraw then
        DexEntryMenu._pokedexSpritesOriginalDraw = DexEntryMenu.draw
      end
      local originalDraw = DexEntryMenu._pokedexSpritesOriginalDraw
      -- ------- 1.2.0: draw the pic ourselves so the mark cannot drift
      --
      -- Up to 1.1.2 this marked at (8, max(0, 60 - h)) because that is what
      -- src/ui/DexEntryMenu.lua's render() does. The DEBUG build proved that
      -- assumption wrong on the real device: the outlines landed to the LEFT
      -- of the art, and by MORE for narrower sprites -- the signature of the
      -- pic being centred somewhere this mod does not control, while the mask
      -- was pinned to a fixed left edge. (The engine's own source still reads
      -- x = 8 at v0.2.14, so whatever places it is not that call.)
      --
      -- Chasing the right formula would be another guess. Instead: hide the
      -- sprite from the original draw, then blit it here and mark the same
      -- rects in the same breath. Origin is now a fact this code owns rather
      -- than a claim about someone else's draw call, so the mask and the art
      -- cannot disagree no matter who else moves the pic.
      function DexEntryMenu:draw(...)
        local species = self._pokedexSpritesSpecies
        local img = species and self.sprite
        local style = "bands"
        local okOpt, chosen = pcall(function() return mod.options:get("mask") end)
        if okOpt and chosen then style = tostring(chosen) end
        diag.style = style

        if not img or style == "off" then
          diag.stage = img and "OFF" or (species and "NOIMG" or "NOSPECIES")
          return originalDraw(self, ...)
        end

        -- the original renders the page without a pic; ours goes on after
        self.sprite = nil
        local okDraw, result = pcall(originalDraw, self, ...)
        self.sprite = img
        if not okDraw then diag.stage = "DRAWERR" return nil end

        pcall(function()
          local mask = maskFor(species, style == "debug" and "bands" or style)
          if not mask then diag.stage = "NOMASK" return end
          local w, h = img:getDimensions()
          -- Centred in the mon-pic palette zone, which is tiles (1,1,8,8) --
          -- x 8..71, so 64px wide. 1.2.0 drew flush at x = 8 and narrow
          -- sprites visibly hugged the left edge; the DEBUG screenshots had
          -- already measured the real offset (Charmander, 34 wide, sat about
          -- 15px right of 8, and 8 + (64-34)/2 = 23). Vertical stays
          -- bottom-aligned on y = 60, which is vanilla's own baseline.
          -- Marks below use this same origin, so art and mask stay locked
          -- together whatever the arithmetic says.
          local ox = 8 + math.max(0, math.floor((64 - w) / 2))
          local oy = math.max(0, 60 - h)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(img, ox, oy)
          local PaletteFX = require("src.render.PaletteFX")
          for _, r in ipairs(mask) do
            PaletteFX.markTrueColor(ox + r.x, oy + r.y, r.w, r.h)
          end
          if style == "debug" then
            -- drawn INSIDE each marked band, so the outline itself lands in a
            -- true-colour region and shows its real magenta rather than being
            -- shade-remapped like everything else on the page
            love.graphics.setColor(1, 0, 1, 1)
            for _, r in ipairs(mask) do
              love.graphics.rectangle("line", ox + r.x + 0.5, oy + r.y + 0.5,
                                      math.max(1, r.w - 1), math.max(1, r.h - 1))
            end
            love.graphics.setColor(1, 1, 1, 1)
          end
          diag.rects, diag.species, diag.stage = #mask, species, "OK"
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
      local rel = ART[ctx.species]
      if rel then return mod.assets:path(rel) end
    end
    return next(path, ctx)
  end)

  -- ------- the caught marker on the dex list
  --
  -- ListMenu:draw paints it inline as a flat black disc: a filled circle, a
  -- white band across the middle, and a small filled centre dot. There is no
  -- asset behind it and no hook over it, so the only way in is to wrap the
  -- draw and repaint the marker on top of the one the original just made.
  --
  -- Safe to wrap the SHARED list menu because `item.ball` is set in exactly
  -- one place in the engine -- src/ui/PokedexMenu.lua, on owned entries -- so
  -- every other list (bag, party, shops, PC) draws no ball and is untouched.
  --
  -- Geometry is recomputed the same way the original does it rather than
  -- guessed: the ball sits one blank glyph past the label, measured with
  -- Font.width in glyph advances, because NIDORAN's gender signs are
  -- multi-byte and a byte count pushes their ball 16px right (engine #285).
  --
  -- Colour survives because the dex list runs under the SGB "BROWNMON"
  -- palette, whose shade pass keys on the RED channel -- a baked red would
  -- come back white. markTrueColor exempts the marker's rect from that pass,
  -- the same escape hatch the entry-page sprite uses above.
  local okList, ListMenu = pcall(require, "src.ui.ListMenu")
  local okFont, Font = pcall(require, "src.render.Font")
  if okList and okFont and type(ListMenu) == "table" and ListMenu.draw then
    if not ListMenu._pokedexSpritesOriginalDraw then
      ListMenu._pokedexSpritesOriginalDraw = ListMenu.draw
    end
    local originalListDraw = ListMenu._pokedexSpritesOriginalDraw

    local R = 4          -- outer radius; the vanilla disc is 3.5, so this covers it
    local INK   = { 0.09, 0.09, 0.09 }
    local RED   = { 0.85, 0.16, 0.16 }
    local WHITE = { 0.97, 0.97, 0.97 }

    local function setColor(c) love.graphics.setColor(c[1], c[2], c[3], 1) end

    -- The marker gets the same treatment as the entry-page sprite: mark the
    -- DISC, not the square around it, or the four corners of the box re-blit
    -- the brown list background as raw white and every caught row grows a
    -- pale square. Seven merged spans cover a radius-4 circle exactly.
    local DISC = {}
    do
      local open
      for dy = -R, R do
        local half = math.floor(math.sqrt(R * R - dy * dy))
        local x, w = -half, half * 2 + 1
        if open and open.x == x and open.w == w and open.y + open.h == dy then
          open.h = open.h + 1
        else
          open = { x = x, y = dy, w = w, h = 1 }
          DISC[#DISC + 1] = open
        end
      end
    end

    local function drawBall(bx, by)
      -- body: ink disc, white underneath, red poured over the top half.
      -- The top half is angles pi..2pi because LOVE's y axis points down,
      -- so sin is negative -- that arc is the half above the centre line.
      setColor(INK)
      love.graphics.circle("fill", bx, by, R)
      setColor(WHITE)
      love.graphics.circle("fill", bx, by, R - 1)
      setColor(RED)
      love.graphics.arc("fill", "pie", bx, by, R - 1, math.pi, math.pi * 2)
      -- the band, then the release button sitting on top of it
      setColor(INK)
      love.graphics.rectangle("fill", bx - R, by - 0.7, R * 2, 1.4)
      love.graphics.circle("fill", bx, by, 1.9)
      setColor(WHITE)
      love.graphics.circle("fill", bx, by, 1.1)
    end

    function ListMenu:draw(...)
      local result = originalListDraw(self, ...)
      if mod.options:get("ball") == "vanilla" then return result end
      pcall(function()
        local PaletteFX = require("src.render.PaletteFX")
        for row = 1, (self.rows or 0) do
          local item = self.items and self.items[(self.scroll or 0) + row]
          if not item then break end
          if item.ball then
            local bx = 16 + Font.width(item.label) + 8 + 3
            local by = 8 + row * 16 + 3
            drawBall(bx, by)
            for _, d in ipairs(DISC) do
              PaletteFX.markTrueColor(bx + d.x, by + d.y, d.w, d.h)
            end
          end
        end
      end)
      -- the original left the pen black for the rows it draws after this
      love.graphics.setColor(0, 0, 0, 1)
      return result
    end
  end

  -- ------- temporary diagnostic rows (out again once the cause is settled)
  --
  -- Engine v0.2.13 added PaletteFX.honorsTrueColor(), and Renderer's
  -- withTrueColor() now DISCARDS every marked rect unless it returns true --
  -- for Gen 1 that means the COLORS mode is ADVANCED (`redpp`). These rows
  -- report that answer directly rather than having it inferred from how the
  -- screen looks, plus how many rects the current mask style actually emits.
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    local noop = function() end
    local okP, PaletteFX = pcall(require, "src.render.PaletteFX")
    local mode, honors = "?", "?"
    if okP and PaletteFX then
      mode = tostring(PaletteFX.mode)
      if type(PaletteFX.honorsTrueColor) == "function" then
        local ok, v = pcall(PaletteFX.honorsTrueColor)
        honors = ok and (v and "Y" or "N") or "ERR"
      else
        honors = "OLD" -- pre-0.2.13: true colour was unconditional
      end
    end
    out = mod.ui.insertBefore(out, "SAVE",
      { label = "TC " .. mode .. " " .. honors, onSelect = noop })
    return mod.ui.insertBefore(out, "SAVE",
      { label = "TC " .. diag.style .. " R" .. diag.rects .. " " .. diag.stage, onSelect = noop })
  end)
end
