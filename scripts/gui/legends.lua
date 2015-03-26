-- legends.lua
-- A replacement for legends mode.
-- version 0.1
-- author: BenLubar

local gui     = require 'gui'
local widgets = require 'gui.widgets'
local utils   = require 'utils'

local number_names = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen"}

local entity_type_name = {
    [df.historical_entity_type.Civilization]   = ' civilization',
    [df.historical_entity_type.SiteGovernment] = ' site government',
    [df.historical_entity_type.VesselCrew]     = ' vessel crew',
    [df.historical_entity_type.MigratingGroup] = ' migrating group',
    [df.historical_entity_type.NomadicGroup]   = ' nomadic group',
    [df.historical_entity_type.Religion]       = ' religion',
    [df.historical_entity_type.MilitaryUnit]   = ' military unit',
    [df.historical_entity_type.Outcast]        = ' band of outcasts'
}

local layer_type_name = {
    [df.world_underground_region.T_type.Cavern]     = "a cavern",
    [df.world_underground_region.T_type.MagmaSea]   = "a magma sea",
    [df.world_underground_region.T_type.Underworld] = "the underworld"
}

local function translate_name(name)
    local t = dfhack.TranslateName(name)
    local e = dfhack.TranslateName(name, 1)
    if e ~= t then
        t = t..', "'..e..'"'
    end
    return t
end

local function profession_name(fig, prof)
    prof = prof or fig.profession
    if prof >= 0 and prof ~= df.profession.STANDARD then
        local profession = df.profession.attrs[prof].caption
        if fig and fig.race >= 0 then
            local race = df.global.world.raws.creatures.all[fig.race]
            if race.profession_name.singular[prof] ~= '' then
                profession = race.profession_name.singular[prof]
            end
            if fig.caste >= 0 then
                local caste = race.caste[fig.caste]
                if caste.caste_profession_name.singular[prof] ~= '' then
                    profession = caste.caste_profession_name.singular[prof]
                end
            end
        end
        return string.lower(profession)
    end
end

local function figure_link(fig)
    if type(fig) == 'number' then
        fig = utils.binsearch(df.global.world.history.figures, fig, 'id')
    end
    if fig then
        local text = dfhack.TranslateName(fig.name)
        local name = dfhack.TranslateName(fig.name, 1)
        if fig.race >= 0 then
            local race = df.global.world.raws.creatures.all[fig.race]
            local race_name = race.name[0]
            if fig.caste >= 0 then
                local caste = race.caste[fig.caste]
                if caste.caste_name[0] ~= '' then
                    race_name = caste.caste_name[0]
                end
            end
            if #text == 0 then
                text = 'a '..race_name
            end
            if #name > 0 then
                name = name..', '
            end
            name = name..race_name
        end
        if fig.flags.force then
            name = name..' (force)'
        end
        if fig.flags.deity then
            name = name..' (deity)'
        end
        if fig.flags.ghost then
            name = name..' (ghost)'
        end
        return {
            text = text,
            target = function()
                return Figure{ref = fig}
            end,
            target_figure = fig,
            description = 'Figure: '..name
        }
    end
end

local function site_link(site)
    if type(site) == 'number' then
        site = utils.binsearch(df.global.world.world_data.sites, site, 'id')
    end
    if site then
        local name = dfhack.TranslateName(site.name, 1)
        if site.type == df.world_site_type.PlayerFortress then
            name = name..', fortress'
        elseif site.type == df.world_site_type.DarkFortress then
            name = name..', dark fortress'
        elseif site.type == df.world_site_type.Cave then
            name = name..', cave'
        elseif site.type == df.world_site_type.MountainHalls then
            name = name..', mountain halls'
        elseif site.type == df.world_site_type.ForestRetreat then
            name = name..', forest retreat'
        elseif site.type == df.world_site_type.Town then
            if site.flags.Town then
                name = name..', town'
            else
                name = name..', hamlet'
            end
        elseif site.type == df.world_site_type.ImportantLocation then
            name = name..', important location'
        elseif site.type == df.world_site_type.LairShrine then
            if site.subtype_info and site.subtype_info.lair_type == 2 then
                name = name..', monument'
            elseif site.subtype_info and site.subtype_info.lair_type == 3 then
                name = name..', shrine'
            else
                name = name..', lair'
            end
        elseif site.type == df.world_site_type.Fortress then
            if site.subtype_info and site.subtype_info.is_tower == 1 then
                name = name..', tower'
            else
                name = name..', fortress'
            end
        elseif site.type == df.world_site_type.Camp then
            name = name..', camp'
        elseif site.type == df.world_site_type.Monument then
            if site.subtype_info and site.subtype_info.is_monument == 1 then
                name = name..', monument'
            else
                name = name..', tomb'
            end
        end
        return {
            text = dfhack.TranslateName(site.name),
            target = function()
                return Site{ref = site}
            end,
            target_site = site,
            description = 'Site: '..name
        }
    end
end

local function entity_link(ent)
    if type(ent) == 'number' then
        ent = utils.binsearch(df.global.world.entities.all, ent, 'id')
    end
    if ent then
        local name = dfhack.TranslateName(ent.name, 1)
        if ent.race >= 0 then
            local race = df.global.world.raws.creatures.all[ent.race]
            if #name > 0 then
                name = name..', '
            end
            name = name..race.name[2]
            name = name..entity_type_name[ent.type]
        else
            name = name..','..entity_type_name[ent.type]
        end
        return {
            text = dfhack.TranslateName(ent.name),
            target = function()
                return Entity{ref = ent}
            end,
            target_entity = ent,
            description = 'Entity: '..name
        }
    end
end

local function region_link(region)
    if type(region) == 'number' then
        if region >= 0 and region < #df.global.world.world_data.regions then
            region = df.global.world.world_data.regions[region]
        else
            region = nil
        end
    end
    if region then
        return {
            text = dfhack.TranslateName(region.name),
            target = function()
                return Region{ref = region}
            end,
            target_region = region,
            description = 'Region: '..dfhack.TranslateName(region.name, 1)..', '..string.lower(df.world_region_type[region.type])
        }
    end
end

local function layer_link(layer)
    if type(layer) == 'number' then
        if layer >= 0 and layer < #df.global.world.world_data.underground_regions then
            layer = df.global.world.world_data.underground_regions[layer]
        else
            layer = nil
        end
    end
    if layer then
        local name = dfhack.TranslateName(layer.name)
        local description = layer_type_name[layer.type]
        if #name == 0 then
            name = description
        else
            description = dfhack.TranslateName(layer.name, 1)..', '..description
        end

        return {
            text = name,
            target = function()
                return Layer{ref = layer}
            end,
            target_layer = layer,
            description = 'Underground: '..description
        }
    end
end

local function timestamp(year, seconds)
    if year > 0 and seconds >= 0 then
        local month = ({[0] = "Granite", "Slate", "Felsite", "Hematite", "Malachite", "Galena", "Limestone", "Sandstone", "Timber", "Moonstone", "Opal", "Obsidian"})[math.floor(seconds / 28 / 1200)]
        local day = math.floor(seconds / 1200) % 28 + 1
        if day >= 11 and day <= 13 then
            day = day..'th'
        elseif day % 10 == 1 then
            day = day..'st'
        elseif day % 10 == 2 then
            day = day..'nd'
        elseif day % 10 == 3 then
            day = day..'rd'
        else
            day = day..'th'
        end
        return ' on '..day..' '..month..', '..year
    elseif year > 0 then
        return ' in '..year
    end
end

local function duration(year, seconds)
    while seconds < 0 do
        seconds = seconds + 12 * 28 * 1200
        year = year - 1
    end
    while seconds >= 12 * 28 * 1200 do
        seconds = seconds - 12 * 28 * 1200
        year = year + 1
    end
    local hours = math.floor(seconds / 50) -- technically 72nds of seconds, but whatever.
    local days = math.floor(hours / 24)
    local weeks = math.floor(days / 7)
    local months = math.floor(weeks / 4)
    if year > 1 then
        return year..' years'
    elseif year == 1 then
        return '1 year'
    elseif year == 0 and months > 1 then
        return months..' months'
    elseif year == 0 and months == 1 then
        return '1 month'
    elseif year == 0 and weeks > 1 then
        return weeks..' weeks'
    elseif year == 0 and weeks == 1 then
        return '1 week'
    elseif year == 0 and days > 1 then
        return days..' days'
    elseif year == 0 and days == 1 then
        return '1 day'
    elseif year == 0 and hours > 1 then
        return hours..' hours'
    elseif year == 0 and hours == 1 then
        return '1 hour'
    end
end

local function do_test_list(viewer, f, list, done)
    viewer:show()
    local next, t, i = ipairs(list)
    local function cb()
        dfhack.timeout(1, 'frames', function()
            i = next(t, i)
            if i then
                f(t[i], cb)
            else
                viewer:dismiss()
                done()
            end
        end)
    end
    cb()
end

Legends = defclass(Legends, gui.FramedScreen)
Legends.focus_path = 'legends'
Legends.ATTRS = {
    frame_style = gui.BOUNDARY_FRAME,
    frame_inset = 1
}

function Legends:init(args)
    self.frame_title = translate_name(df.global.world.world_data.name)
    local choices = {}
    local targets = {}
    table.insert(choices, 'Historical Figures:                     '..#df.global.world.history.figures)
    table.insert(targets, FigureList)
    table.insert(choices, 'Sites:                                  '..#df.global.world.world_data.sites)
    table.insert(targets, SiteList)
    table.insert(choices, 'Civilizations and other Entities:       '..#df.global.world.entities.all)
    table.insert(targets, EntityList)
    table.insert(choices, 'Regions:                                '..#df.global.world.world_data.regions)
    table.insert(targets, RegionList)
    self:addviews{widgets.List{
        frame      = {yalign = 0},
        choices    = choices,
        on_submit  = function(index, choice)
            targets[index]{}:show()
        end,
        text_pen   = COLOR_GREY,
        cursor_pen = COLOR_WHITE
    }}
end

function Legends:do_test(callback)
    do_test_list(self, function(v, cb)
        v{}:do_test(cb)
    end, {FigureList, SiteList, EntityList, RegionList}, function()
        callback()
    end)
end

function Legends:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    else
        self:inputToSubviews(keys)
    end
end

List = defclass(List, gui.FramedScreen)
List.ATTRS = {
    frame_style = gui.BOUNDARY_FRAME,
    frame_inset = 1,
    frame_title = 'List'
}

function List:init(args)
end

function List:init_list(list, view)
    local choices = {}
    for _, v in ipairs(list) do
        if not df.historical_figure:is_instance(v) or v.id > -100 then -- ignore dfhack config
            table.insert(choices, {
                icon = self:icon(v),
                text = self:name(v),
                search_key = string.lower(self:search_key(v)),
                ref = v
            })
        end
    end
    self:addviews{widgets.FilteredList{
        frame      = {yalign = 0},
        choices    = choices,
        edit_below = true,
        on_submit  = function(index, choice)
            view{ref = choice.ref}:show()
        end,
        text_pen   = COLOR_GREY,
        cursor_pen = COLOR_WHITE,
        edit_pen   = COLOR_LIGHTCYAN
    }}

    self.view = view
    self.choices = choices
end

function List:do_test(callback)
    do_test_list(self, function(v, cb)
        self.view{ref = v.ref}:do_test(cb)
    end, self.choices, function()
        callback()
    end)
end

function List:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    else
        self:inputToSubviews(keys)
    end
end

function List:icon(v)
    return nil
end

function List:name(v)
    return tostring(v)
end

function List:search_key(v)
    return self:name(v)
end

FigureList = defclass(FigureList, List)
FigureList.focus_path = 'legends/figure/list'
FigureList.ATTRS = {
    frame_title = 'Historical Figures'
}

function FigureList:init(args)
    if args.title then
        self.frame_title = args.title
    end
    local figures = df.global.world.history.figures
    if args.list then
        figures = args.list
    end
    self:init_list(figures, Figure)
end

function FigureList:icon(fig)
    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        local ch = race.creature_tile
        local fg = race.color[0] + race.color[2] * 8
        local bg = race.color[1]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            if caste.flags.CASTE_TILE then
                ch = caste.caste_tile
            end
            if caste.flags.CASTE_COLOR then
                fg = caste.caste_color[0] + caste.caste_color[2] * 8
                bg = caste.caste_color[1]
            end
        end
        if fig.profession >= 0 then
            if df.profession.attrs[fig.profession].color >= 0 then
                fg = df.profession.attrs[fig.profession].color
            end
            if df.profession.attrs[fig.profession].military then
                if race.creature_soldier_tile ~= 0 then
                    ch = race.creature_soldier_tile
                end
                if fig.caste >= 0 then
                    local caste = race.caste[fig.caste]
                    if caste.flags.CASTE_TILE and caste.caste_soldier_tile ~= 0 then
                        ch = caste.caste_soldier_tile
                    end
                end
            end
        end
        return dfhack.pen.parse{ch = ch, fg = fg, bg = bg}
    end
end

function FigureList:name(fig)
    local name = dfhack.TranslateName(fig.name)
    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        local race_name = race.name[0]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            if caste.caste_name[0] ~= '' and (#race.caste == 1 or race.caste[0].caste_name[0] ~= race.caste[1].caste_name[0]) then
                race_name = caste.caste_name[0]
            elseif fig.sex == 0 then
                race_name = 'female '..race_name
            elseif fig.sex == 1 then
                race_name = 'male '..race_name
            end
        end
        local profession = profession_name(fig)
        if profession then
            race_name = race_name..' '..profession
        end
        if #name > 0 then
            name = name..', '
        end
        name = name..race_name
    end
    if fig.flags.deity then
        name = name..' (deity)'
    end
    if fig.flags.force then
        name = name..' (force)'
    end
    if fig.flags.ghost then
        name = name..' (ghost)'
    end
    return name
end

function FigureList:search_key(fig)
    local key = dfhack.TranslateName(fig.name)..' '..dfhack.TranslateName(fig.name, 1)
    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        key = key..' '..race.name[0]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            if caste.caste_name[0] ~= '' then
                key = key..' '..caste.caste_name[0]
            end
        end
    end
    if fig.sex == 0 then
        key = key..' female she'
    elseif fig.sex == 1 then
        key = key..' male he'
    else
        key = key..' genderless it'
    end
    if fig.flags.deity then
        key = key..' deity'
    end
    if fig.flags.force then
        key = key..' force'
    end
    if fig.flags.ghost then
        key = key..' ghost'
    end
    if fig.profession >= 0 then
        key = key..' '..df.profession.attrs[fig.profession].caption
        if fig.race >= 0 then
            local race = df.global.world.raws.creatures.all[fig.race]
            if race.profession_name.singular[fig.profession] ~= '' then
                key = key..' '..race.profession_name.singular[fig.profession]
            end
            if fig.caste >= 0 then
                local caste = race.caste[fig.caste]
                if caste.caste_profession_name.singular[fig.profession] ~= '' then
                    key = key..' '..caste.caste_profession_name.singular[fig.profession]
                end
            end
        end
    end
    return key
end

SiteList = defclass(SiteList, List)
SiteList.focus_path = 'legends/site/list'
SiteList.ATTRS = {
    frame_title = 'Sites'
}

function SiteList:init(args)
    if args.title then
        self.frame_title = args.title
    end
    local sites = df.global.world.world_data.sites
    if args.list then
        sites = args.list
    end
    self:init_list(sites, Site)
end

function SiteList:name(site)
    local name = dfhack.TranslateName(site.name)
    if site.type == df.world_site_type.PlayerFortress then
        name = name..', fortress'
    elseif site.type == df.world_site_type.DarkFortress then
        name = name..', dark fortress'
    elseif site.type == df.world_site_type.Cave then
        name = name..', cave'
    elseif site.type == df.world_site_type.MountainHalls then
        name = name..', mountain halls'
    elseif site.type == df.world_site_type.ForestRetreat then
        name = name..', forest retreat'
    elseif site.type == df.world_site_type.Town then
        if site.flags.Town then
            name = name..', town'
        else
            name = name..', hamlet'
        end
    elseif site.type == df.world_site_type.ImportantLocation then
        name = name..', important location'
    elseif site.type == df.world_site_type.LairShrine then
        if site.subtype_info and site.subtype_info.lair_type == 2 then
            name = name..', monument'
        elseif site.subtype_info and site.subtype_info.lair_type == 3 then
            name = name..', shrine'
        else
            name = name..', lair'
        end
    elseif site.type == df.world_site_type.Fortress then
        if site.subtype_info and site.subtype_info.is_tower == 1 then
            name = name..', tower'
        else
            name = name..', fortress'
        end
    elseif site.type == df.world_site_type.Camp then
        name = name..', camp'
    elseif site.type == df.world_site_type.Monument then
        if site.subtype_info and site.subtype_info.is_monument == 1 then
            name = name..', monument'
        else
            name = name..', tomb'
        end
    end
    return name
end

function SiteList:search_key(site)
    local key = dfhack.TranslateName(site.name)
    key = key..' '..dfhack.TranslateName(site.name, 1)
    if site.type == df.world_site_type.PlayerFortress then
        key = key..' fortress'
    elseif site.type == df.world_site_type.DarkFortress then
        key = key..' dark fortress'
    elseif site.type == df.world_site_type.Cave then
        key = key..' cave'
    elseif site.type == df.world_site_type.MountainHalls then
        key = key..' mountain halls'
    elseif site.type == df.world_site_type.ForestRetreat then
        key = key..' forest retreat'
    elseif site.type == df.world_site_type.Town then
        if site.flags.Town then
            key = key..' town'
        else
            key = key..' hamlet'
        end
    elseif site.type == df.world_site_type.ImportantLocation then
        key = key..' important location'
    elseif site.type == df.world_site_type.LairShrine then
        if site.subtype_info and site.subtype_info.lair_type == 2 then
            key = key..' monument'
        elseif site.subtype_info and site.subtype_info.lair_type == 3 then
            key = key..' shrine'
        else
            key = key..' lair'
        end
    elseif site.type == df.world_site_type.Fortress then
        if site.subtype_info and site.subtype_info.is_tower == 1 then
            key = key..' tower'
        else
            key = key..' fortress'
        end
    elseif site.type == df.world_site_type.Camp then
        key = key..' camp'
    elseif site.type == df.world_site_type.Monument then
        if site.subtype_info and site.subtype_info.is_monument == 1 then
            key = key..' monument'
        else
            key = key..' tomb'
        end
    end
    return key
end

EntityList = defclass(EntityList, List)
EntityList.focus_path = 'legends/entity/list'
EntityList.ATTRS = {
    frame_title = 'Entities'
}

function EntityList:init(args)
    if args.title then
        self.frame_title = args.title
    end
    local entities = df.global.world.entities.all
    if args.list then
        entities = args.list
    end
    self:init_list(entities, Entity)
end

function EntityList:name(ent)
    local name = dfhack.TranslateName(ent.name)
    if #name > 0 then
        name = name..', '
    end
    name = name..df.global.world.raws.creatures.all[ent.race].name[2]
    name = name..entity_type_name[ent.type]
    return name
end

function EntityList:search_key(ent)
    local key = dfhack.TranslateName(ent.name)
    key = key..' '..dfhack.TranslateName(ent.name, 1)
    key = key..' '..df.global.world.raws.creatures.all[ent.race].name[0]
    key = key..' '..df.global.world.raws.creatures.all[ent.race].name[1]
    key = key..' '..df.global.world.raws.creatures.all[ent.race].name[2]
    key = key..entity_type_name[ent.type]
    return key
end

RegionList = defclass(RegionList, List)
RegionList.focus_path = 'legends/region/list'
RegionList.ATTRS = {
    frame_title = 'Regions'
}

function RegionList:init(args)
    if args.title then
        self.frame_title = args.title
    end
    local regions = df.global.world.world_data.regions
    if args.list then
        regions = args.list
    end
    self:init_list(regions, Region)
end

function RegionList:name(region)
    local name = dfhack.TranslateName(region.name)
    name = name..', '..string.lower(df.world_region_type[region.type])
    return name
end

function RegionList:search_key(region)
    local key = dfhack.TranslateName(region.name)
    key = key..' '..dfhack.TranslateName(region.name, 1)
    key = key..' '..df.world_region_type[region.type]
    return key
end

Viewer = defclass(Viewer, gui.FramedScreen)
Viewer.ATTRS = {
    frame_style = gui.BOUNDARY_FRAME,
    frame_inset = 1
}

function Viewer:init(args)
    self.links = {}
    self.text = {}
    self.new_sentence = true
end

function Viewer:insert_text(text)
    if text == nil then
        return
    end
    table.insert(self.text, text)
    self.new_sentence = text == '.  ' or text == NEWLINE
end

function Viewer:insert_link(link)
    if self.target_figure and link.target_figure == self.target_figure then
        if #dfhack.TranslateName(link.target_figure.name) == 0 then
            if link.target_figure.sex == 0 then
                if self.new_sentence then
                    self:insert_text('She')
                else
                    self:insert_text('her')
                end
            elseif link.target_figure.sex == 1 then
                if self.new_sentence then
                    self:insert_text('He')
                else
                    self:insert_text('him')
                end
            else
                if self.new_sentence then
                    self:insert_text('It')
                else
                    self:insert_text('it')
                end
            end
        else
            self:insert_text(string.gsub(link.text, ' .*', ''))
        end
    elseif self.target_site and link.target_site == self.target_site then
        self:insert_text(link.text)
    elseif self.target_entity and link.target_entity == self.target_entity then
        self:insert_text(link.text)
    elseif self.target_region and link.target_region == self.target_region then
        self:insert_text(link.text)
    elseif self.target_layer and link.target_layer == self.target_layer then
        self:insert_text(link.text)
    else
        table.insert(self.links, link)
        self:insert_text(link)
    end
end

function Viewer:insert_list_of_links(links, first)
    first = first or false

    for i, link in ipairs(links) do
        if first then
            first = false
        else
            self:insert_text(' ')
        end
        self:insert_link(link)
        if i < #links and #links ~= 2 then
            self:insert_text(',')
        end
        if i == #links - 1 then
            self:insert_text(' and')
        end
    end
end

function Viewer:init_text()
    local width, height = dfhack.screen.getWindowSize()
    width, height = width - 4, height - 4 -- 1 unit border + 1 unit padding

    local out = {}

    local x = 1
    for _, t in ipairs(self.text) do
        if type(t) == 'table' then
            -- don't split tables
            x = x + #t.text
            if x > width then
                table.insert(out, NEWLINE)
                x = #t.text
            end
            table.insert(out, t)
        elseif t == NEWLINE then
            table.insert(out, t)
            x = 1
        else
            x = x - 1
            for i, s in ipairs(utils.split_string(t, ' ')) do
                x = x + #s + 1
                if x > width then
                    table.insert(out, NEWLINE)
                    x = #s
                    table.insert(out, s)
                elseif i ~= 1 and x ~= #s + 1 then
                    table.insert(out, ' ')
                    table.insert(out, s)
                else
                    table.insert(out, s)
                end
            end
        end
    end

    local page = {}
    local pages = {page}

    local y = 1
    for _, t in ipairs(out) do
        table.insert(page, t)
        if t == NEWLINE then
            y = y + 1
            if y >= height then
                y = 1
                page = {}
                table.insert(pages, page)
            end
        end
    end

    for i, p in ipairs(pages) do
        pages[i] = widgets.Label{frame = {yalign = 0}, text = p, text_pen = COLOR_GREY}
    end
    self.pages = widgets.Pages{frame = {yalign = 0}, subviews = pages}

    self:init_links()
    self:addviews{self.pages}
end

function Viewer:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    elseif keys.STANDARDSCROLL_UP then
        self:scroll(-1)
    elseif keys.STANDARDSCROLL_DOWN then
        self:scroll(1)
    elseif keys.STANDARDSCROLL_PAGEUP then
        self:page_scroll(-1)
    elseif keys.STANDARDSCROLL_PAGEDOWN then
        self:page_scroll(1)
    elseif keys.SELECT then
        self:goto_link()
    else
        self:inputToSubviews(keys)
    end
end

function Viewer:init_links()
    self.current_link = 0
    for i, l in ipairs(self.links) do
        if i == 1 then
            self.current_link = 1
            l.pen = COLOR_LIGHTCYAN
        else
            l.pen = COLOR_CYAN
        end

        for j, p in ipairs(self.pages.subviews) do
            for _, t in ipairs(p.text) do
                if t == l then
                    l.page = j
                    break
                end
            end
            if l.page then
                break
            end
        end
    end
end

function Viewer:insert_history(filter)
    local last_year = nil
    for _, event in ipairs(df.global.world.history.events) do
        if filter(event) then
            if event.year ~= last_year then
                self:insert_text(NEWLINE)
                self:insert_text(NEWLINE)
                last_year = event.year
            end

            self:insert_event(event)
            self:insert_text(timestamp(event.year, event.seconds))
            self:insert_text('.  ')
        end
    end
end

function Viewer:insert_event(event)
    if df.history_event_hist_figure_diedst:is_instance(event) then
        self:insert_link(figure_link(event.victim_hf))
        self:insert_text(' ')
        local special = false
        if event.death_cause == df.death_type.OLD_AGE then
            self:insert_text('died of old age')
            special = true
        elseif event.death_cause == df.death_type.HUNGER then
            self:insert_text('starved to death')
            special = true
        elseif event.death_cause == df.death_type.THIRST then
            self:insert_text('died of dehydration')
            special = true
        elseif event.death_cause == df.death_type.SHOT then
            self:insert_text('was shot and killed')
        elseif event.death_cause == df.death_type.BLEED then
            self:insert_text('bled to death')
            special = true
        elseif event.death_cause == df.death_type.DROWN then
            self:insert_text('drowned')
            special = true
        elseif event.death_cause == df.death_type.SUFFOCATE then
            self:insert_text('suffocated')
            special = true
        elseif event.death_cause == df.death_type.STRUCK_DOWN then
            self:insert_text('was struck down')
        else
            self:insert_text(df.death_type[event.death_cause])
        end

        local slayer = figure_link(event.slayer_hf)
        if slayer then
            if special then
                self:insert_text(', killed')
            end
            self:insert_text(' by ')
            self:insert_link(slayer)
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.subregion)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.feature_layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end

        if not slayer and (event.slayer_race ~= -1 or event.slayer_caste ~= -1) then
            print('slayer_race: '..event.slayer_race)
            print('slayer_caste: '..event.slayer_caste)
        end
        for _, v in pairs(event.weapon) do
            if v ~= -1 then
                printall(event.weapon)
                break
            end
        end
    elseif df.history_event_add_hf_entity_linkst:is_instance(event) then
        local fig_link = figure_link(event.histfig)
        local civ_link = entity_link(event.civ)
        self:insert_link(fig_link)
        self:insert_text(' became ')
        if event.link_type == df.histfig_entity_link_type.MEMBER then
            self:insert_text('a member')
        elseif event.link_type == df.histfig_entity_link_type.ENEMY then
            self:insert_text('an enemy')
        elseif event.link_type == df.histfig_entity_link_type.PRISONER then
            self:insert_text('a prisoner')
        elseif event.link_type == df.histfig_entity_link_type.POSITION then
            local pos = utils.binsearch(civ_link.target_entity.positions.own, event.position_id, 'id')
            if fig_link.target_figure.sex == 0 and #pos.name_female[0] > 0 then
                self:insert_text(pos.name_female[0])
            elseif fig_link.target_figure.sex == 1 and #pos.name_male[0] > 0 then
                self:insert_text(pos.name_male[0])
            else
                self:insert_text(pos.name[0])
            end
        else
            self:insert_text(df.histfig_entity_link_type[event.link_type]) -- TODO
            self:insert_text(' ')
            self:insert_text(event.position_id) -- TODO
            print('link_type: '..df.histfig_entity_link_type[event.link_type])
            print('position_id: '..event.position_id)
        end
        self:insert_text(' of ')
        self:insert_link(civ_link)
    elseif df.history_event_remove_hf_entity_linkst:is_instance(event) then
        self:insert_link(figure_link(event.histfig))
        self:insert_text(' stopped being ')
        self:insert_text(df.histfig_entity_link_type[event.link_type]) -- TODO
        self:insert_text(' ')
        self:insert_text(event.position_id) -- TODO
        self:insert_text(' of ')
        self:insert_link(entity_link(event.civ))
        print('link_type: '..df.histfig_entity_link_type[event.link_type])
        print('position_id: '..event.position_id)
    elseif df.history_event_add_hf_hf_linkst:is_instance(event) then
        if event.type == df.histfig_hf_link_type.PRISONER then
            self:insert_link(figure_link(event.hf))
            self:insert_text(' took ')
            self:insert_link(figure_link(event.hf_target))
            self:insert_text(' prisoner')
        elseif event.type == df.histfig_hf_link_type.SPOUSE then
            self:insert_link(figure_link(event.hf_target))
            self:insert_text(' married ')
            self:insert_link(figure_link(event.hf))
        elseif event.type == df.histfig_hf_link_type.DEITY then
            self:insert_link(figure_link(event.hf))
            self:insert_text(' started worshiping ')
            self:insert_link(figure_link(event.hf_target))
        else
            self:insert_link(figure_link(event.hf_target))
            self:insert_text(' became ')
            self:insert_text(df.histfig_hf_link_type[event.type]) -- TODO
            self:insert_text(' of ')
            self:insert_link(figure_link(event.hf))
            print('type: '..df.histfig_hf_link_type[event.type])
        end
    elseif df.history_event_remove_hf_hf_linkst:is_instance(event) then
        self:insert_link(figure_link(event.hf_target))
        self:insert_text(' stopped being ')
        self:insert_text(df.histfig_hf_link_type[event.type]) -- TODO
        self:insert_text(' of ')
        self:insert_link(figure_link(event.hf))
        print('type: '..df.histfig_hf_link_type[event.type])
    elseif df.history_event_hist_figure_abductedst:is_instance(event) then
        self:insert_link(figure_link(event.target))
        self:insert_text(' was abducted')

        local site_word = ' from '

        local site = site_link(event.site)
        if site then
            self:insert_text(site_word)
            self:insert_link(site)
            site_word = ' in '
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(site_word)
            self:insert_link(region)
        end

        local snatcher = figure_link(event.snatcher)
        if snatcher then
            self:insert_text(' by ')
            self:insert_link(snatcher)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    elseif df.history_event_change_creature_typest:is_instance(event) then
        self:insert_link(figure_link(event.changee))

        self:insert_text(' was transformed from a ')
        local old_race = df.global.world.raws.creatures.all[event.old_race]
        local old_caste = old_race.caste[event.old_caste]
        if old_race.name[0] == old_caste.caste_name[0] then
            if old_caste.gender == 0 then
                self:insert_text('female ')
            elseif old_caste.gender == 1 then
                self:insert_text('male ')
            end
        end
        self:insert_text(old_caste.caste_name[0])

        self:insert_text(' into a ')
        local new_race = df.global.world.raws.creatures.all[event.new_race]
        local new_caste = new_race.caste[event.new_caste]
        if new_race.name[0] == new_caste.caste_name[0] then
            if new_caste.gender == 0 then
                self:insert_text('female ')
            elseif new_caste.gender == 1 then
                self:insert_text('male ')
            end
        end
        self:insert_text(new_caste.caste_name[0])

        self:insert_text(' by ')
        self:insert_link(figure_link(event.changer))
    elseif df.history_event_hist_figure_simple_battle_eventst:is_instance(event) then
        local attackers = {}
        for _, id in ipairs(event.group1) do
            table.insert(attackers, figure_link(id))
        end
        self:insert_list_of_links(attackers, true)

        if event.subtype == df.history_event_simple_battle_subtype.SCUFFLE then
            self:insert_text(' had a scuffle with')
        elseif event.subtype == df.history_event_simple_battle_subtype.ATTACK then
            self:insert_text(' attacked')
        elseif event.subtype == df.history_event_simple_battle_subtype.SURPRISE then
            self:insert_text(' surprised')
        elseif event.subtype == df.history_event_simple_battle_subtype.AMBUSH then
            self:insert_text(' ambushed')
        elseif event.subtype == df.history_event_simple_battle_subtype.HAPPEN_UPON then
            self:insert_text(' happened upon')
        elseif event.subtype == df.history_event_simple_battle_subtype.CORNER then
            self:insert_text(' cornered')
        elseif event.subtype == df.history_event_simple_battle_subtype.CONFRONT then
            self:insert_text(' confronted')
        elseif event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_RECEIVE_WOUND then
            self:insert_text(' attacked')
        elseif event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_INFLICT_WOUND then
            self:insert_text(' wounded')
        elseif event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_EXCHANGE_WOUND then
            self:insert_text(' exchanged wounds with')
        else
            self:insert_text(' '..df.history_event_simple_battle_subtype[event.subtype])
            print('subtype: '..df.history_event_simple_battle_subtype[event.subtype])
        end

        local defenders = {}
        for _, id in ipairs(event.group2) do
            table.insert(defenders, figure_link(id))
        end
        self:insert_list_of_links(defenders)

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end

        if event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_RECEIVE_WOUND then
            self:insert_text(', but was wounded by')
            self:insert_list_of_links(defenders)
            self:insert_text(', who then escaped')
        elseif event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_INFLICT_WOUND then
            self:insert_text(', who then escaped')
        elseif event.subtype == df.history_event_simple_battle_subtype.LOSE_AFTER_EXCHANGE_WOUND then
            self:insert_text(', but both parties escaped with their lives')
        end
    elseif df.history_event_add_hf_site_linkst:is_instance(event) then
        self:insert_link(figure_link(event.histfig))
        self:insert_text(' ')
        if event.type == df.histfig_site_link_type.HOME_SITE_REALIZATION_BUILDING then
            self:insert_text('took up residence')
        elseif event.type == df.histfig_site_link_type.HANGOUT then
            self:insert_text('lived')
        else
            self:insert_text(df.histfig_site_link_type[event.type]) -- TODO
            print('type: '..df.histfig_site_link_type[event.type])
        end
        local site = site_link(event.site)

        local building = utils.binsearch(site.target_site.buildings, event.structure, 'id')
        if building then
            -- TODO: building links
            local name = translate_name(building:getName())
            self:insert_text(' in ')
            self:insert_text(name)
        end
        self:insert_text(' in ')
        self:insert_link(site)

        local civ = entity_link(event.civ)
        if civ then
            self:insert_text(' of ')
            self:insert_link(civ)
        end
    elseif df.history_event_change_hf_statest:is_instance(event) then
        self:insert_link(figure_link(event.hfid))
        local site_word = ' in '
        if event.state == 0 and event.substate == -1 then
            self:insert_text(' began wandering')
            site_word = ' '
        elseif event.state == 1 and event.substate == -1 then
            self:insert_text(' settled')
        elseif event.state == 1 and event.substate == 0 then
            self:insert_text(' fled')
            site_word = ' to '
        elseif event.state == 2 and event.substate == -1 then
            self:insert_text(' became a refugee')
        else
            self:insert_text(event.state..':'..event.substate)
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(site_word)
            self:insert_link(site)
            site_word = ' in '
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(site_word)
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end

        -- TODO:
        -- <compound name='region_pos' type-name='coord2d'/>
    elseif df.history_event_change_hf_jobst:is_instance(event) then
        local link = figure_link(event.hfid)
        self:insert_link(link)

        if event.old_job ~= df.profession.STANDARD then
            self:insert_text(' gave up being a ')
            self:insert_text(profession_name(fig, event.old_job))
        end
        if event.new_job ~= df.profession.STANDARD then
            if event.old_job ~= df.profession.STANDARD then
                self:insert_text(' and')
            end
            self:insert_text(' became a ')
            self:insert_text(profession_name(fig, event.new_job))
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    elseif df.history_event_hist_figure_reunionst:is_instance(event) then
        local missing = {}
        for _, id in ipairs(event.missing) do
            table.insert(missing, figure_link(id))
        end
        local reunited_with = {}
        for _, id in ipairs(event.reunited_with) do
            table.insert(reunited_with, figure_link(id))
        end

        local assistant = figure_link(event.assistant)
        if assistant then
            self:insert_link(assistant)
            self:insert_text(' reunited')
            self:insert_list_of_links(missing)
            self:insert_text(' with')
            self:insert_list_of_links(reunited_with)
        else
            self:insert_list_of_links(missing, true)
            if #missing == 1 then
                self:insert_text(' was')
            else
                self:insert_text(' were')
            end
            self:insert_text(' reunited with')
            self:insert_list_of_links(reunited_with)
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    elseif df.history_event_creature_devouredst:is_instance(event) then
        self:insert_link(figure_link(event.eater))
        self:insert_text(' devoured ')
        local victim = figure_link(event.victim)
        if victim then
            self:insert_link(victim)
        elseif event.race >= 0 then
            local race = df.global.world.raws.creatures.all[event.race]
            local race_name = race.name[0]
            if event.caste >= 0 then
                local caste = race.caste[event.caste]
                if caste.caste_name[0] ~= '' then
                    race_name = caste.caste_name[0]
                end
            end
            self:insert_text('a ')
            self:insert_text(race_name)
        end

        local ent = entity_link(event.entity)
        if ent then
            self:insert_text(' from ')
            self:insert_link(ent)
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    elseif df.history_event_hf_does_interactionst:is_instance(event) then
        self:insert_link(figure_link(event.doer))
        local interaction = utils.binsearch(df.global.world.raws.interactions, event.interaction, 'id')

        self:insert_text(interaction.sources[event.anon_1].hist_string_1) -- DFHack.Next: anon_1 -> source
        self:insert_link(figure_link(event.target))
        self:insert_text(interaction.sources[event.anon_1].hist_string_2) -- DFHack.Next: anon_1 -> source

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    elseif df.history_event_hist_figure_woundedst:is_instance(event) then
        self:insert_link(figure_link(event.wounder))
        if event.part_lost == 0 then
            self:insert_text(({
                [0] = ' smashed ',
                [1] = ' slashed ',
                [2] = ' stabbed ',
                [3] = ' ripped ',
                [4] = ' burned '
            })[event.injury_type])
        elseif event.part_lost == 1 then
            self:insert_text(({
                [0] = ' broke away ',
                [1] = ' slashed off ',
                [2] = ' ripped off ',
                [3] = ' tore off ',
                [4] = ' burned away '
            })[event.injury_type])
        else
            self:insert_text(' wounded ')
        end
        local woundee = figure_link(event.woundee)
        local race = nil
        local caste = nil
        if woundee then
            if woundee.target_figure.race >= 0 then
                race = df.global.world.raws.creatures.all[woundee.target_figure.race]
                if woundee.target_figure.caste >= 0 then
                    caste = race.caste[woundee.target_figure.caste]
                end
            end
            self:insert_link(woundee)
        elseif event.woundee_race >= 0 then
            race = df.global.world.raws.creatures.all[event.woundee_race]
            local race_name = race.name[0]
            if event.woundee_caste >= 0 then
                caste = race.caste[event.woundee_caste]
                if caste.caste_name[0] ~= '' then
                    race_name = caste.caste_name[0]
                end
            end
            self:insert_text('a ')
            self:insert_text(race_name)
        end
        if caste ~= nil and event.body_part >= 0 then
            local part = caste.body_info.body_parts[event.body_part]
            self:insert_text('\'s ')
            self:insert_text(part.name_singular[0].value)
        end

        local site = site_link(event.site)
        if site then
            self:insert_text(' in ')
            self:insert_link(site)
        end

        local region = region_link(event.region)
        if region then
            self:insert_text(' in ')
            self:insert_link(region)
        end

        local layer = layer_link(event.layer)
        if layer then
            self:insert_text(' in ')
            self:insert_link(layer)
        end
    else
        self:insert_text(tostring(event))
        print(event)
        printall(event)
    end
end

function Viewer:insert_art_image(chunk, subid, skip)
    skip = skip or {}

    local ii = df.itemimprovement_art_imagest:new()
    ii.image = {id = chunk, subid = subid, civ_id = -1, site_id = -1}
    local art = ii:getImage(0)
    df.delete(ii)

    --print(art)
    if not skip.name then
        self:insert_text(translate_name(art.name))
        --self:insert_text(df.item_quality[art.quality])
        self:insert_text(', an image')
    end
    if not skip.event and art.event ~= -1 then
        local event = utils.binsearch(df.global.world.history.events, art.event, 'id')
        if event then
            self:insert_text(' related to the event')
            self:insert_text(timestamp(event.year, event.seconds))
            self:insert_text(' when ')
            self:insert_event(event)
        end
    end
    --printall(art)
    for i, symbol in ipairs(art.elements) do
        if i == 0 then
            self:insert_text(' of')
        else
            self:insert_text(' and')
        end

        local plural = true
        if symbol.count == -1 then
            self:insert_text(' some ')
        elseif symbol.count == 1 then
            -- more complex, could be "a", "an", "the", or nothing in the case of a name.
            plural = false
            self:insert_text(' ')
        elseif symbol.count <= #number_names then
            self:insert_text(' '..number_names[symbol.count]..' ')
        else
            self:insert_text(' '..symbol.count..' ')
        end

        if df.art_image_element_itemst:is_instance(symbol) then
            local article = 'a '
            local adjective = ''
            local name = 'item'
            local name_plural = 'items'
            if symbol.item_type == df.item_type.BAR then
                if symbol.item_subtype == -1 then
                    name = 'bar'
                    name_plural = 'bars'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SMALLGEM then
                if symbol.item_subtype == -1 then
                    adjective = 'cut'
                    name = 'gem'
                    name_plural = 'gems'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BLOCKS then
                if symbol.item_subtype == -1 then
                    name = 'block'
                    name_plural = 'blocks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ROUGH then
                if symbol.item_subtype == -1 then
                    adjective = 'rough'
                    name = 'gem'
                    name_plural = 'gems'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BOULDER then
                if symbol.item_subtype == -1 then
                    name = 'boulder'
                    name_plural = 'boulders'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.WOOD then
                if symbol.item_subtype == -1 then
                    name = 'log'
                    name_plural = 'logs'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.DOOR then
                if symbol.item_subtype == -1 then
                    name = 'door'
                    name_plural = 'doors'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FLOODGATE then
                if symbol.item_subtype == -1 then
                    name = 'floodgate'
                    name_plural = 'floodgates'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BED then
                if symbol.item_subtype == -1 then
                    name = 'bed'
                    name_plural = 'beds'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CHAIR then
                if symbol.item_subtype == -1 then
                    name = 'chair'
                    name_plural = 'chairs'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CHAIN then
                if symbol.item_subtype == -1 then
                    name = 'chain'
                    name_plural = 'chains'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FLASK then
                if symbol.item_subtype == -1 then
                    name = 'flask'
                    name_plural = 'flasks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.GOBLET then
                if symbol.item_subtype == -1 then
                    name = 'goblet'
                    name_plural = 'goblets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.INSTRUMENT then
                if symbol.item_subtype == -1 then
                    name = 'instrument'
                    name_plural = 'instruments'
                else
                    local def = df.global.world.raws.itemdefs.instruments[symbol.item_subtype]
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.TOY then
                if symbol.item_subtype == -1 then
                    name = 'toy'
                    name_plural = 'toys'
                else
                    local def = df.global.world.raws.itemdefs.toys[symbol.item_subtype]
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.WINDOW then
                if symbol.item_subtype == -1 then
                    name = 'window'
                    name_plural = 'windows'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CAGE then
                if symbol.item_subtype == -1 then
                    name = 'cage'
                    name_plural = 'cages'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BARREL then
                if symbol.item_subtype == -1 then
                    name = 'barrel'
                    name_plural = 'barrels'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BUCKET then
                if symbol.item_subtype == -1 then
                    name = 'bucket'
                    name_plural = 'buckets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ANIMALTRAP then
                if symbol.item_subtype == -1 then
                    name = 'animal trap'
                    name_plural = 'animal traps'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TABLE then
                if symbol.item_subtype == -1 then
                    name = 'table'
                    name_plural = 'tables'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.COFFIN then
                if symbol.item_subtype == -1 then
                    name = 'coffin'
                    name_plural = 'coffins'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.STATUE then
                if symbol.item_subtype == -1 then
                    name = 'statue'
                    name_plural = 'statues'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CORPSE then
                if symbol.item_subtype == -1 then
                    name = 'corpse'
                    name_plural = 'corpses'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.WEAPON then
                if symbol.item_subtype == -1 then
                    name = 'weapon'
                    name_plural = 'weapons'
                else
                    local def = df.global.world.raws.itemdefs.weapons[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.ARMOR then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'bodywear'
                    name_plural = 'bodywear'
                else
                    local def = df.global.world.raws.itemdefs.armor[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.SHOES then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'footwear'
                    name_plural = 'footwear'
                else
                    local def = df.global.world.raws.itemdefs.shoes[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.SHIELD then
                if symbol.item_subtype == -1 then
                    name = 'shield'
                    name_plural = 'shields'
                else
                    local def = df.global.world.raws.itemdefs.shields[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.HELM then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'headwear'
                    name_plural = 'headwear'
                else
                    local def = df.global.world.raws.itemdefs.helms[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.GLOVES then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'handwear'
                    name_plural = 'handwear'
                else
                    local def = df.global.world.raws.itemdefs.gloves[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.BOX then
                if symbol.item_subtype == -1 then
                    name = 'box'
                    name_plural = 'boxes'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BIN then
                if symbol.item_subtype == -1 then
                    name = 'bin'
                    name_plural = 'bins'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ARMORSTAND then
                if symbol.item_subtype == -1 then
                    name = 'armor stand'
                    name_plural = 'armor stands'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.WEAPONRACK then
                if symbol.item_subtype == -1 then
                    name = 'weapon rack'
                    name_plural = 'weapon racks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CABINET then
                if symbol.item_subtype == -1 then
                    name = 'cabinet'
                    name_plural = 'cabinets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FIGURINE then
                if symbol.item_subtype == -1 then
                    name = 'figurine'
                    name_plural = 'figurines'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.AMULET then
                if symbol.item_subtype == -1 then
                    name = 'amulet'
                    name_plural = 'amulets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SCEPTER then
                if symbol.item_subtype == -1 then
                    name = 'scepter'
                    name_plural = 'scepters'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.AMMO then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'ammunition'
                    name_plural = 'ammunition'
                else
                    local def = df.global.world.raws.itemdefs.ammo[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.CROWN then
                if symbol.item_subtype == -1 then
                    name = 'crown'
                    name_plural = 'crowns'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.RING then
                if symbol.item_subtype == -1 then
                    name = 'ring'
                    name_plural = 'rings'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.EARRING then
                if symbol.item_subtype == -1 then
                    name = 'earring'
                    name_plural = 'earrings'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BRACELET then
                if symbol.item_subtype == -1 then
                    name = 'bracelet'
                    name_plural = 'bracelets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.GEM then
                if symbol.item_subtype == -1 then
                    adjective = 'large'
                    name = 'gem'
                    name_plural = 'gems'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ANVIL then
                if symbol.item_subtype == -1 then
                    name = 'anvil'
                    name_plural = 'anvils'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CORPSEPIECE then
                if symbol.item_subtype == -1 then
                    name = 'body part'
                    name_plural = 'body parts'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.REMAINS then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'remains'
                    name_plural = 'remains'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FISH then
                if symbol.item_subtype == -1 then
                    adjective = 'prepared'
                    name = 'fish'
                    name_plural = 'fish'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FISH_RAW then
                if symbol.item_subtype == -1 then
                    adjective = 'raw'
                    name = 'fish'
                    name_plural = 'fish'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.VERMIN then
                if symbol.item_subtype == -1 then
                    name = 'vermin'
                    name_plural = 'vermin'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.PET then
                if symbol.item_subtype == -1 then
                    name = 'pet'
                    name_plural = 'pets'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SEEDS then
                if symbol.item_subtype == -1 then
                    name = 'seed'
                    name_plural = 'seeds'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.PLANT then
                if symbol.item_subtype == -1 then
                    name = 'plant'
                    name_plural = 'plants'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SKIN_TANNED then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'leather'
                    name_plural = 'leather'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.PLANT_GROWTH then
                if symbol.item_subtype == -1 then
                    name = 'fruit'
                    name_plural = 'fruit'
                    -- TODO: should it say leaf?
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.THREAD then
                if symbol.item_subtype == -1 then
                    name = 'thread'
                    name_plural = 'threads'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CLOTH then
                if symbol.item_subtype == -1 then
                    name = 'cloth'
                    name_plural = 'cloths'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TOTEM then
                if symbol.item_subtype == -1 then
                    name = 'totem'
                    name_plural = 'totems'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.PANTS then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'legwear'
                    name_plural = 'legwear'
                else
                    local def = df.global.world.raws.itemdefs.pants[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.BACKPACK then
                if symbol.item_subtype == -1 then
                    name = 'backpack'
                    name_plural = 'backpacks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.QUIVER then
                if symbol.item_subtype == -1 then
                    name = 'quiver'
                    name_plural = 'quivers'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CATAPULTPARTS then
                if symbol.item_subtype == -1 then
                    name = 'catapult part'
                    name_plural = 'catapult parts'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BALLISTAPARTS then
                if symbol.item_subtype == -1 then
                    name = 'ballista part'
                    name_plural = 'ballista parts'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SIEGEAMMO then
                if symbol.item_subtype == -1 then
                    article = ''
                    name = 'siege ammunition'
                    name_plural = 'siege ammunition'
                else
                    local def = df.global.world.raws.itemdefs.siege_ammo[symbol.item_subtype]
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.BALLISTAARROWHEAD then
                if symbol.item_subtype == -1 then
                    name = 'ballista arrow head'
                    name_plural = 'ballista arrow heads'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TRAPPARTS then
                if symbol.item_subtype == -1 then
                    name = 'mechanism'
                    name_plural = 'mechanisms'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TRAPCOMP then
                if symbol.item_subtype == -1 then
                    name = 'trap component'
                    name_plural = 'trap components'
                else
                    local def = df.global.world.raws.itemdefs.trapcomps[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.DRINK then
                if symbol.item_subtype == -1 then
                    name = 'drink'
                    name_plural = 'drinks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.POWDER_MISC then
                if symbol.item_subtype == -1 then
                    name = 'powder'
                    name_plural = 'powders'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CHEESE then
                if symbol.item_subtype == -1 then
                    name = 'cheese'
                    name_plural = 'cheeses'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.FOOD then
                if symbol.item_subtype == -1 then
                    name = 'meal'
                    name_plural = 'meals'
                else
                    local def = df.global.world.raws.itemdefs.food[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name..'s' -- XXX
                end
            elseif symbol.item_type == df.item_type.LIQUID_MISC then
                if symbol.item_subtype == -1 then
                    name = 'liquid'
                    name_plural = 'liquids'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.COIN then
                if symbol.item_subtype == -1 then
                    name = 'coin'
                    name_plural = 'coins'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.GLOB then
                if symbol.item_subtype == -1 then
                    name = 'glob'
                    name_plural = 'globs'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ROCK then
                if symbol.item_subtype == -1 then
                    adjective = 'small'
                    name = 'rock'
                    name_plural = 'rocks'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.PIPE_SECTION then
                if symbol.item_subtype == -1 then
                    name = 'pipe section'
                    name_plural = 'pipe sections'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.HATCH_COVER then
                if symbol.item_subtype == -1 then
                    name = 'hatch cover'
                    name_plural = 'hatch covers'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.GRATE then
                if symbol.item_subtype == -1 then
                    name = 'grate'
                    name_plural = 'grates'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.QUERN then
                if symbol.item_subtype == -1 then
                    name = 'quern'
                    name_plural = 'querns'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.MILLSTONE then
                if symbol.item_subtype == -1 then
                    name = 'millstone'
                    name_plural = 'millstones'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.SPLINT then
                if symbol.item_subtype == -1 then
                    name = 'splint'
                    name_plural = 'splints'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.CRUTCH then
                if symbol.item_subtype == -1 then
                    name = 'crutch'
                    name_plural = 'crutches'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TRACTION_BENCH then
                if symbol.item_subtype == -1 then
                    name = 'traction bench'
                    name_plural = 'traction benches'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.ORTHOPEDIC_CAST then
                if symbol.item_subtype == -1 then
                    name = 'orthopedic cast'
                    name_plural = 'orthopedic casts'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.TOOL then
                if symbol.item_subtype == -1 then
                    name = 'tool'
                    name_plural = 'tools'
                else
                    local def = df.global.world.raws.itemdefs.tools[symbol.item_subtype]
                    adjective = def.adjective
                    name = def.name
                    name_plural = def.name_plural
                end
            elseif symbol.item_type == df.item_type.SLAB then
                if symbol.item_subtype == -1 then
                    name = 'slab'
                    name_plural = 'slabs'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.EGG then
                if symbol.item_subtype == -1 then
                    name = 'egg'
                    name_plural = 'eggs'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            elseif symbol.item_type == df.item_type.BOOK then
                if symbol.item_subtype == -1 then
                    name = 'book'
                    name_plural = 'books'
                else
                    print('item_type: '..df.item_type[symbol.item_type])
                    print('item_subtype: '..symbol.item_subtype)
                end
            else
                print('item_type: '..df.item_type[symbol.item_type])
                print('item_subtype: '..symbol.item_subtype)
                name = df.item_type.attrs[symbol.item_type].caption
                name_plural = name..'s' -- XXX
            end

            if symbol.mat_index ~= -1 or symbol.mat_type ~= -1 then
                print('mat_type: '..symbol.mat_type)
                print('mat_index: '..symbol.mat_index)
            end
            local first = true
            for f, ok in pairs(symbol.flags) do
                if ok then
                    if first then
                        print('flags:')
                        first = false
                    end
                    print('  '..f)
                end
            end
            if symbol.item_id ~= -1 then
                print('item_id: '..symbol.item_id)
            end
            if plural then
                if #adjective > 0 then
                    self:insert_text(adjective..' ')
                end
                self:insert_text(name_plural)
            else
                self:insert_text(article)
                if #adjective > 0 then
                    self:insert_text(adjective..' ')
                end
                self:insert_text(name)
            end
        elseif df.art_image_element_treest:is_instance(symbol) or df.art_image_element_plantst:is_instance(symbol) then
            local plant = df.global.world.raws.plants.all[symbol.plant_id]
            if plural then
                self:insert_text(plant.name_plural)
            else
                self:insert_text('a '..plant.name)
            end
        elseif df.art_image_element_creaturest:is_instance(symbol) then
            local name = 'creatures'
            if not plural then
                name = 'a creature'
            end

            if symbol.race ~= -1 then
                local race = df.global.world.raws.creatures.all[symbol.race]
                if plural then
                    name = race.name[1]
                else
                    name = 'a '..race.name[0]
                end

                if symbol.caste ~= -1 then
                    local caste = race.castes[symbol.caste]
                    if plural then
                        if #caste.caste_name[1] == 0 or name == caste.caste_name[1] then
                            name = string.lower(caste.caste_id)..' '..name
                        else
                            name = caste.caste_name[1]
                        end
                    else
                        if #caste.caste_name[0] == 0 or name == 'a '..caste.caste_name[0] then
                            name = 'a '..string.lower(caste.caste_id)..' '..name
                        else
                            name = 'a '..caste.caste_name[0]
                        end
                    end
                end

                if race.flags.CASTE_FEATURE_BEAST or race.flags.CASTE_TITAN or race.flags.CASTE_UNIQUE_DEMON then
                    for _, fig in ipairs(df.global.world.history.figures) do
                        if fig.race == symbol.race then
                            name = figure_link(fig)
                        end
                    end
                end
            end

            if symbol.histfig ~= -1 then
                name = figure_link(symbol.histfig)
            end
            if type(name) == 'table' then
                self:insert_link(name)
            else
                self:insert_text(name)
            end
        elseif df.art_image_element_shapest:is_instance(symbol) then
            local shape = df.global.world.raws.language.shapes[symbol.shape_id]
            local adj = ''
            if symbol.anon_1 ~= -1 then
                adj = shape.adj[symbol.anon_1].value..' '
            end
            if plural then
                self:insert_text(adj..shape.name_plural)
            else
                self:insert_text('a '..adj..shape.name)
            end
        else
            print(symbol)
            printall(symbol)
        end
    end

    for _, property in ipairs(art.properties) do
        print(property)
        printall(property)
    end
end

function Viewer:scroll(direction)
    if self.current_link ~= 0 then
        self.links[self.current_link].pen = COLOR_CYAN
        self.current_link = self.current_link + direction
        if self.current_link <= 0 then
            self.current_link = #self.links
        elseif self.current_link > #self.links then
            self.current_link = 1
        end
        self.links[self.current_link].pen = COLOR_LIGHTCYAN
        self.pages:setSelected(self.links[self.current_link].page)
    end
end

function Viewer:page_scroll(direction)
    local old = self.pages:getSelected()
    self.pages:setSelected(self.pages:getSelected() + direction)
    local new = self.pages:getSelected()
    if self.current_link ~= 0 then
        self.links[self.current_link].pen = COLOR_CYAN
        if (old == new) == (direction < 0) then
            for i, l in ipairs(self.links) do
                if l.page == new then
                    self.current_link = i
                    break
                end
            end
        else
            for i, l in ipairs(self.links) do
                if l.page == new then
                    self.current_link = i
                end
            end
        end
        self.links[self.current_link].pen = COLOR_LIGHTCYAN
    end
end

function Viewer:goto_link()
    if self.current_link ~= 0 and self.links[self.current_link].page == self.pages:getSelected() then
        self.links[self.current_link].target():show()
    end
end

function Viewer:do_test(callback)
    do_test_list(self, function(_, cb)
        self:scroll(1)
        cb()
    end, self.links, callback)
end

function Viewer:onRenderFrame(dc, rect)
    Viewer.super.onRenderFrame(self, dc, rect)

    if self.current_link ~= 0 and self.links[self.current_link].description then
        local desc = self.links[self.current_link].description
        if #desc > rect.x2 - rect.x1 - 7 then
            desc = desc:sub(0, rect.x2 - rect.x1 - 7)
        end
        dfhack.screen.paintString(self.frame_style.title_pen, rect.x1, rect.y2, desc)
    end
end

Figure = defclass(Figure, Viewer)
Figure.focus_path = 'legends/figure/view'

function Figure:init(args)
    local fig = args.ref
    self.target_figure = fig
    self.frame_title = translate_name(fig.name)
    if #self.frame_title > 0 then
        self:insert_text(self.frame_title)
        self:insert_text(' is')
    else
        if fig.race >= 0 then
            local race = df.global.world.raws.creatures.all[fig.race]
            local race_name = race.name[0]
            if fig.caste >= 0 then
                local caste = race.caste[fig.caste]
                if caste.caste_name[0] ~= '' then
                    race_name = caste.caste_name[0]
                end
            end
            self.frame_title = race_name
        end
        self:insert_text('There was')
    end
    if fig.flags.force then
        self:insert_text(' a force of nature')
    end
    if fig.flags.deity then
        self:insert_text(' a deity commonly depicted as')
    end
    if fig.flags.ghost then
        self:insert_text(' the ghost of')
    end

    if fig.sex == 0 then
        self:insert_text(' a female')
    elseif fig.sex == 1 then
        self:insert_text(' a male')
    elseif fig.race >= 0 then
        self:insert_text(' a')
    end
    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        local race_name = race.name[0]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            if caste.caste_name[0] ~= '' then
                race_name = caste.caste_name[0]
            end
        end
        self:insert_text(' '..race_name)
    end
    local profession = profession_name(fig)
    if profession then
        self:insert_text(' '..profession)
    end
    if fig.info and fig.info.spheres and #fig.info.spheres > 0 then
        self:insert_text(' associated with')
        for i, s in ipairs(fig.info.spheres) do
            self:insert_text(' '..string.lower(df.sphere_type[s]))
            if i < #fig.info.spheres - 1 and #fig.info.spheres ~= 2 then
                self:insert_text(',')
            end
            if i == #fig.info.spheres - 2 then
                self:insert_text(' and')
            end
        end
    end

    local born = timestamp(fig.born_year, fig.born_seconds)
    if born then
        self:insert_text(' born')
        self:insert_text(born)
    end

    local parents = {}

    for _, l in ipairs(fig.histfig_links) do
        if l:getType() == df.histfig_hf_link_type.MOTHER or l:getType() == df.histfig_hf_link_type.FATHER then
            local parent = figure_link(l.target_hf)
            if parent then
                table.insert(parents, parent)
            end
        end
    end

    if #parents > 0 then
        if not born then
            self:insert_text(' born')
        end
        self:insert_text(' to')
        self:insert_list_of_links(parents)
    end
    self:insert_text('.  ')

    local worshipped = {}
    for _, ent in ipairs(df.global.world.entities.all) do
        for _, v in ipairs(ent.unknown1b.worship) do
            if v == fig.id then
                table.insert(worshipped, entity_link(ent))
            end
        end
    end

    if #worshipped > 0 then
        if fig.sex == 0 then
            self:insert_text('She is worshipped by')
        elseif fig.sex == 1 then
            self:insert_text('He is worshipped by')
        else
            self:insert_text('It is worshipped by')
        end
        self:insert_list_of_links(worshipped)
        self:insert_text('.  ')
    end

    local deities = {}
    for _, l in ipairs(fig.histfig_links) do
        if l:getType() == df.histfig_hf_link_type.DEITY then
            local deity = figure_link(l.target_hf)
            if deity then
                table.insert(deities, deity)
            end
        end
    end

    local worshipers = {}
    for _, f in ipairs(df.global.world.history.figures) do
        for _, l in ipairs(f.histfig_links) do
            if l:getType() == df.histfig_hf_link_type.DEITY then
                if l.target_hf == fig.id then
                    table.insert(worshipers, f)
                end
            end
        end
    end

    if #deities > 0 then
        if fig.sex == 0 then
            self:insert_text('She worships')
        elseif fig.sex == 1 then
            self:insert_text('He worships')
        else
            self:insert_text('It worships')
        end
        self:insert_list_of_links(deities)
        self:insert_text('.  ')
    end

    if #worshipers > 0 then
        if fig.sex == 0 then
            self:insert_text('She ')
        elseif fig.sex == 1 then
            self:insert_text('He ')
        else
            self:insert_text('It ')
        end

        if #worshipers == 1 then
            self:insert_text('is worshiped by ')
            self:insert_link(figure_link(worshipers[1]))
        else
            self:insert_text('has ')
            self:insert_link({
                text = #worshipers..' worshipers',
                target = function()
                    return FigureList{
                        title = 'Worshipers of '..dfhack.TranslateName(fig.name),
                        list = worshipers
                    }
                end
            })
        end
        self:insert_text('.  ')
    end

    local spouses = {}
    local children = {}

    for _, l in ipairs(fig.histfig_links) do
        if l:getType() == df.histfig_hf_link_type.CHILD then
            local child = figure_link(l.target_hf)
            if child then
                table.insert(children, child)
            end
        elseif l:getType() == df.histfig_hf_link_type.SPOUSE then
            local spouse = figure_link(l.target_hf)
            if spouse then
                table.insert(spouses, spouse)
            end
        end
    end

    if #spouses > 0 then
        if fig.sex == 0 then
            self:insert_text('She')
        elseif fig.sex == 1 then
            self:insert_text('He')
        else
            self:insert_text('It')
        end
        self:insert_text(' is married to')
        self:insert_list_of_links(spouses)
    end

    if #children > 0 then
        if #spouses > 0 then
            self:insert_text(' and')
        elseif fig.sex == 0 then
            self:insert_text('She')
        elseif fig.sex == 1 then
            self:insert_text('He')
        else
            self:insert_text('It')
        end
        self:insert_text(' has ')
        if #children == 1 then
            self:insert_text('a child named')
        elseif #children <= #number_names then
            self:insert_text(number_names[#children]..' children:')
        else
            self:insert_text(#children..' children:')
        end
        self:insert_list_of_links(children)
        self:insert_text('.  ')
    elseif #spouses > 0 then
        self:insert_text('.  ')
    end

    if fig.info and fig.info.personality then
        -- strings from the wiki http://dwarffortresswiki.org/index.php/DF2014:Personality_trait#Beliefs
        local values = {
            [df.value_type.LAW] = {
                "is an absolute believer in the rule of law",
                "has a great deal of respect for the law",
                "respects the law",
                "doesn't feel strongly about the law",
                "does not respect the law",
                "disdains the law",
                "finds the idea of laws abhorent"
            },
            [df.value_type.LOYALTY] = {
                "has the highest regard for loyalty",
                "greatly prizes loyalty",
                "values loyalty",
                "doesn't particularly value loyalty",
                "views loyalty unfavorably",
                "disdains loyalty",
                "is disgusted by the idea of loyalty"
            },
            [df.value_type.FAMILY] = {
                "sees family as one of the most important things in life",
                "values family greatly",
                "values family",
                "does not care about family one way or the other",
                "is put off by family",
                "lacks any respect for family",
                "finds the idea of family loathsome"
            },
            [df.value_type.FRIENDSHIP] = {
                "believes friendship is a key to the ideal life",
                "sees friendship as one of the finer things in life",
                "thinks friendship is important",
                "does not care about friendship",
                "finds friendship burdensome",
                "is completely put off by the idea of friends",
                "finds the whole idea of friendship disgusting"
            },
            [df.value_type.POWER] = {
                "believes that the acquisition of power over others is the ideal goal in life and worthy of the highest respect",
                "sees power over others as something to strive for",
                "respects power",
                "doesn't find power particularly praiseworthy",
                "has a negative view of those who exercise power over others",
                "hates those who wield power over others",
                "finds the acquisition and use of power abhorent and would have all masters toppled"
            },
            [df.value_type.TRUTH] = {
                "believes the truth is inviolable regardless of the cost",
                "believes that honesty is a high ideal",
                "values honesty",
                "does not particularly value the truth",
                "finds blind honesty foolish",
                "sees lying as an important means to an end",
                "is repelled by the idea of honesty and lies without compunction"
            },
            [df.value_type.CUNNING] = {
                "holds well-laid plans and shrewd deceptions in the highest regard",
                "greatly respects the shrewd and guileful",
                "values cunning",
                "does not really value cunning and guile",
                "sees guile and cunning as indirect and somewhat worthless",
                "holds shrewd and crafty individuals in the lowest esteem",
                "is utterly disgusted by guile and cunning"
            },
            [df.value_type.ELOQUENCE] = {
                "believes that artful speech and eloquent expression are of the highest ideals",
                "deeply respects eloquent speakers",
                "values eloquence",
                "doesn't value eloquence so much",
                "finds eloquence and artful speech off-putting",
                "finds [him/her]self somewhat disgusted with eloquent speakers",
                "sees artful speech and eloquence as a wasteful form of deliberate deception and treats it as such"
            },
            [df.value_type.FAIRNESS] = {
                "holds fairness as one of the highest ideals and despises cheating of any kind",
                "has great respect for fairness",
                "respects fair-dealing and fair-play",
                "does not care about fairness",
                "sees life as unfair and doesn't mind it that way",
                "finds the idea of fair-dealing foolish and cheats when [he/she] finds it profitable",
                "is disgusted by the idea of fairness and will freely cheat anybody at any time"
            },
            [df.value_type.DECORUM] = {
                "views decorum as a high ideal and is deeply offended by those that fail to maintain it",
                "greatly respects those that observe decorum and maintain their dignity",
                "values decorum, dignity and proper behavior",
                "doesn't care very much about decorum",
                "finds maintaining decorum a silly, fumbling waste of time",
                "sees those that attempt to maintain dignified and proper behavior as vain and offensive",
                "is affronted by the whole notion of maintaining decorum and finds so-called dignified people disgusting"
            },
            [df.value_type.TRADITION] = {
                "holds the maintenance of tradition as one of the highest ideals",
                "is a firm believer in the value of tradition",
                "values tradition",
                "doesn't have any strong feelings about tradition",
                "disregards tradition",
                "finds the following of tradition foolish and limiting",
                "is disgusted by tradition and would flout any [he/she] encounters if given a chance"
            },
            [df.value_type.ARTWORK] = {
                "believes that the creation and appreciation of artwork is one of the highest ideals",
                "greatly respects artists and their works",
                "values artwork",
                "doesn't care about art one way or another",
                "finds artwork boring",
                "sees the whole pursuit of art as silly",
                "finds art offensive and would have it destroyed whenever possible"
            },
            [df.value_type.COOPERATION] = {
                "places cooperation as one of the highest ideals",
                "sees cooperation as very important in life",
                "values cooperation",
                "doesn't see cooperation as valuable",
                "dislikes cooperation",
                "views cooperation as a low ideal not worthy of any respect",
                "is thoroughly disgusted by cooperation"
            },
            [df.value_type.INDEPENDENCE] = {
                "believes that freedom and independence are completely non-negotiable and would fight to defend them",
                "treasures independence",
                "values independence",
                "doesn't really value independence one way or another",
                "finds the ideas of independence and freedom somewhat foolish",
                "sees freedom and independence as completely worthless",
                "hates freedom and would crush the independent spirit wherever it is found"
            },
            [df.value_type.STOICISM] = {
                "views any show of emotion as offensive",
                "thinks it is of the utmost importance to present a bold face and never grouse, complain or even show emotion",
                "believes it is important to conceal emotions and refrain from complaining",
                "doesn't see much value in being stoic",
                "sees no value in holding back complaints and concealing emotions",
                "feels that those who attempt to conceal their emotions are vain and foolish",
                "sees concealment of emotions as a betrayal and tries [his/her] best never to associate with such secretive fools"
            },
            [df.value_type.INTROSPECTION] = {
                "feels that introspection and all forms of self-examination are the keys to a good life and worthy of respect",
                "deeply values introspection",
                "sees introspection as important",
                "doesn't really see the value in self-examination",
                "finds introspection to be a waste of time",
                "thinks that introspection is valueless and those that waste time in self-examination are deluded fools",
                "finds the whole idea of introspection completely offensive and contrary to the ideals of a life well-lived"
            },
            [df.value_type.SELF_CONTROL] = {
                "believes that self-mastery and the denial of impulses are of the highest ideals",
                "finds moderation and self-control to be very important",
                "values self-control",
                "doesn't particularly value self-control",
                "finds those that deny their impulses somewhat stiff",
                "sees the denial of impulses as a vain and foolish pursuit",
                "has abandoned any attempt at self-control and finds the whole concept deeply offensive"
            },
            [df.value_type.TRANQUILITY] = {
                "views tranquility as one of the highest ideals",
                "strongly values tranquility and quiet",
                "values tranquility and a peaceful day",
                "doesn't have a preference between tranquility and tumult",
                "prefers a noisy, bustling life to boring days without activity",
                "is greatly disturbed by quiet and a peaceful existence",
                "is disgusted by tranquility and would that the world would constantly churn with noise and activity"
            },
            [df.value_type.HARMONY] = {
                "would have the world operate in complete harmony without the least bit of strife or disorder",
                "strongly believes that a peaceful and ordered society without dissent is best",
                "values a harmonious existence",
                "sees equal parts of harmony and discord as part of life",
                "doesn't respect a society that has settled into harmony without debate and strife",
                "can't fathom why anyone would want to live in an orderly and harmonious society",
                "believes deeply that chaos and disorder are the truest expressions of life and would disrupt harmony wherever it is found"
            },
            [df.value_type.MERRIMENT] = {
                "believes that little is better in life than a good party",
                "truly values merrymaking and parties",
                "finds merrymaking and partying worthwhile activities",
                "doesn't really value merrymaking",
                "sees merrymaking as a waste",
                "is disgusted by merrymakers",
                "is appalled by merrymaking, parties and other such worthless activities"
            },
            [df.value_type.CRAFTSMANSHIP] = {
                "holds crafts[man]ship to be of the highest ideals and celebrates talented artisans and their masterworks",
                "has a great deal of respect for worthy crafts[man]ship",
                "values good crafts[man]ship",
                "doesn't particularly care about crafts[man]ship",
                "considers crafts[man]ship to be relatively worthless",
                "sees the pursuit of good crafts[man]ship as a total waste",
                "views crafts[man]ship with disgust and would desecrate a so-called masterwork or two if [he/she] could get away with it"
            },
            [df.value_type.MARTIAL_PROWESS] = {
                "believes that martial prowess defines the good character of an individual",
                "deeply respects skill at arms",
                "values martial prowess",
                "does not really value skills related to fighting",
                "finds those that develop skill with weapons and fighting distasteful",
                "thinks that the pursuit of the skills of warfare and fighting is a low pursuit indeed",
                "abhors those that pursue the mastery of weapons and skill with fighting"
            },
            [df.value_type.SKILL] = {
                "believes that the mastery of a skill is one of the highest pursuits",
                "really respects those that take the time to master a skill",
                "respects the development of skill",
                "doesn't care if others take the time to master skills",
                "finds the pursuit of skill mastery off-putting",
                "believes that the time taken to master a skill is a horrible waste",
                "sees the whole idea of taking time to master a skill as appalling"
            },
            [df.value_type.HARD_WORK] = {
                "believes that hard work is one of the highest ideals and a key to the good life",
                "deeply respects those that work hard at their labors",
                "values hard work",
                "doesn't really see the point of working hard",
                "sees working hard as a foolish waste of time",
                "thinks working hard is an abject idiocy",
                "finds the proposition that one should work hard in life utterly abhorent"
            },
            [df.value_type.SACRIFICE] = {
                "finds sacrifice to be one of the highest ideals",
                "believes that those who sacrifice for others should be deeply respected",
                "values sacrifice",
                "doesn't particularly respect sacrifice as a virtue",
                "sees sacrifice as wasteful and foolish",
                "finds sacrifice to be the height of folly",
                "thinks that the entire concept of sacrifice for others is truly disgusting"
            },
            [df.value_type.COMPETITION] = {
                "holds the idea of competition among the most important and would encourage it wherever possible",
                "views competition as a crucial driving force in the world",
                "sees competition as reasonably important",
                "doesn't have strong views on competition",
                "sees competition as wasteful and silly",
                "deeply dislikes competition",
                "finds the very idea of competition obscene"
            },
            [df.value_type.PERSEVERENCE] = {
                "believes that perseverence is one of the greatest qualities somebody can have",
                "greatly respects individuals that persevere through their trials and labors",
                "respects perseverence",
                "doesn't think much about the idea of perseverence",
                "sees perseverence in the face of adversity as bull-headed and foolish",
                "thinks there is something deeply wrong with people that persevere through adversity",
                "finds the notion that one would persevere through adversity completely abhorent"
            },
            [df.value_type.LEISURE_TIME] = {
                "believes that it would be a fine thing if all time were leisure time",
                "treasures leisure time and thinks it is very important in life",
                "values leisure time",
                "doesn't think one way or the other about leisure time",
                "finds leisure time wasteful",
                "is offended by leisure time and leisurely living",
                "believes that those that take leisure time are evil and finds the whole idea disgusting"
            },
            [df.value_type.COMMERCE] = {
                "sees engaging in commerce as a high ideal in life",
                "really respects commerce and those that engage in trade",
                "respects commerce",
                "doesn't particularly respect commerce",
                "is somewhat put off by trade and commerce",
                "finds those that engage in trade and commerce to be fairly disgusting",
                "holds the view that commerce is a vile obscenity"
            },
            [df.value_type.ROMANCE] = {
                "sees romance as one of the highest ideals",
                "thinks romance is very important in life",
                "values romance",
                "doesn't care one way or the other about romance",
                "finds romance distasteful",
                "is somewhat disgusted by romance",
                "finds even the abstract idea of romance repellent"
            },
            [df.value_type.NATURE] = {
                "holds nature to be of greater value than most aspects of civilization",
                "has a deep respect for animals, plants and the natural world",
                "values nature",
                "doesn't care about nature one way or another",
                "finds nature somewhat disturbing",
                "has a deep dislike of the natural world",
                "would just as soon have nature and the great outdoors burned to ashes and converted into a great mining pit"
            },
            [df.value_type.PEACE] = {
                "believes the idea of war is utterly repellent and would have peace at all costs",
                "believes that peace is always preferable to war",
                "values peace over war",
                "doesn't particularly care between war and peace",
                "sees war as a useful means to an end",
                "believes war is preferable to peace in general",
                "thinks that the world should be engaged in perpetual warfare"
            }
        }
        local personality = fig.info.personality
        for _, v in ipairs(personality.values) do
            local s = ''
            if v.strength >= 41 then
                s = values[v.type][1]
            elseif v.strength >= 26 then
                s = values[v.type][2]
            elseif v.strength >= 11 then
                s = values[v.type][3]
            elseif v.strength >= -10 then
                s = values[v.type][4]
            elseif v.strength >= -25 then
                s = values[v.type][5]
            elseif v.strength >= -40 then
                s = values[v.type][6]
            else
                s = values[v.type][7]
            end

            if fig.sex == 0 then
                self:insert_text('She ')
                s = s:gsub('%[he/she%]', 'she')
                s = s:gsub('%[him/her%]', 'her')
                s = s:gsub('%[his/her%]', 'her')
            elseif fig.sex == 1 then
                self:insert_text('He ')
                s = s:gsub('%[he/she%]', 'he')
                s = s:gsub('%[him/her%]', 'him')
                s = s:gsub('%[his/her%]', 'his')
            else
                self:insert_text('It ')
                s = s:gsub('%[he/she%]', 'it')
                s = s:gsub('%[him/her%]self', 'itself')
                s = s:gsub('%[his/her%]', 'its')
            end

            local crafts = profession_name(fig, df.profession.CRAFTSMAN)
            s = s:gsub('crafts%[man%]', crafts)
            self:insert_text(s)
            self:insert_text('.  ')
        end
    end

    local died = timestamp(fig.died_year, fig.died_seconds)
    if died then
        local event = nil
        for _, e in ipairs(df.global.world.history.events) do
            if df.history_event_hist_figure_diedst:is_instance(e) and e.victim_hf == fig.id then
                event = e
                break
            end
        end

        if event then
            self:insert_event(event)
        else
            if fig.name.first_name ~= '' then
                local name = string.gsub(fig.name.first_name, '^(%l)', string.upper)
                self:insert_text(name)
            elseif fig.sex == 0 then
                self:insert_text('She')
            elseif fig.sex == 1 then
                self:insert_text('He')
            else
                self:insert_text('It')
            end
            self:insert_text(' died')
        end
        self:insert_text(died)
        local age = duration(fig.died_year - fig.born_year, fig.died_seconds - fig.born_seconds)
        if not fig.flags.deity and not fig.flags.force and age then
            self:insert_text(' at the age of ')
            self:insert_text(age)
        end
        self:insert_text('.  ')
    else
        local age = duration(df.global.cur_year - fig.born_year, df.global.cur_year_tick - fig.born_seconds)
        if not fig.flags.deity and not fig.flags.force and age then
            if fig.name.first_name ~= '' then
                local name = string.gsub(fig.name.first_name, '^(%l)', string.upper)
                self:insert_text(name)
            elseif fig.sex == 0 then
                self:insert_text('She')
            elseif fig.sex == 1 then
                self:insert_text('He')
            else
                self:insert_text('It')
            end
            self:insert_text(' is ')
            self:insert_text(age)
            self:insert_text(' old')
            self:insert_text('.  ')
        end
    end

    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            self:insert_text(NEWLINE)
            self:insert_text(NEWLINE)
            self:insert_text(caste.description)
            self:insert_text('  ')
        end

        for _, mat in ipairs(race.material) do
            local important = false

            local temperature = 10015 -- standard underground temperature
            if mat.heat.mat_fixed_temp ~= 60001 then
                temperature = mat.heat.mat_fixed_temp
                important = true
            end
            if #mat.syndrome > 0 then
                important = true
            end

            if important then
                self:insert_link(figure_link(fig))
                self:insert_text("'s ")
                if #mat.prefix > 0 then
                    self:insert_text(mat.prefix)
                    self:insert_text(' ')
                end
                if temperature < mat.heat.melting_point then
                    self:insert_text(mat.state_name.Solid)
                elseif temperature < mat.heat.boiling_point then
                    self:insert_text(mat.state_name.Liquid)
                else
                    self:insert_text(mat.state_name.Gas)
                end

                if mat.heat.mat_fixed_temp ~= 60001 then
                    if not important then
                        self:insert_text(' and')
                    end
                    self:insert_text(' has a temperature of ')
                    self:insert_text(mat.heat.mat_fixed_temp - 9968)
                    self:insert_text(' degrees fahrenheit')
                    important = false
                end

                for _, syn in ipairs(mat.syndrome) do
                    if not important then
                        self:insert_text(' and')
                    end
                    self:insert_text(' carries a syndrome known as ')
                    self:insert_text(syn.syn_name)
                    for i, e in ipairs(syn.ce) do
                        if i == 0 then
                            self:insert_text(' that causes')
                        else
                            self:insert_text(',')
                            if i == #syn.ce - 1 then
                                self:insert_text(' and')
                            end
                        end
                        local function severity(type)
                            if e.sev < 20 then
                                self:insert_text(' mild ')
                            elseif e.sev < 40 then
                                self:insert_text(' mild to moderate ')
                            elseif e.sev < 60 then
                                self:insert_text(' moderate ')
                            elseif e.sev < 80 then
                                self:insert_text(' moderate to severe ')
                            elseif e.sev < 120 then
                                self:insert_text(' severe ')
                            elseif e.sev < 250 then
                                self:insert_text(' very severe ')
                            else
                                self:insert_text(' extreme ')
                            end
                            if e.flags.LOCALIZED then
                                self:insert_text('localized ')
                            end
                            self:insert_text(type)
                        end
                        local function severity_target(type)
                            severity(type)
                            for i, mode in ipairs(e.target.mode) do
                                if mode == df.creature_interaction_effect_target_mode.BY_CATEGORY and e.target.key[i].value == 'ALL' then
                                    self:insert_text(' of '..string.lower(e.target.tissue[i].value)..' tissue')
                                else
                                    print('mode: '..df.creature_interaction_effect_target_mode[mode])
                                    print('key: '..e.target.key[i].value)
                                    print('tissue: '..e.target.tissue[i].value)
                                end
                            end
                        end
                        if df.creature_interaction_effect_painst:is_instance(e) then
                            severity_target('pain')
                        elseif df.creature_interaction_effect_swellingst:is_instance(e) then
                            severity_target('swelling')
                        elseif df.creature_interaction_effect_oozingst:is_instance(e) then
                            severity_target('oozing')
                        elseif df.creature_interaction_effect_bruisingst:is_instance(e) then
                            severity_target('bruising')
                        elseif df.creature_interaction_effect_blistersst:is_instance(e) then
                            severity_target('blisters')
                        elseif df.creature_interaction_effect_numbnessst:is_instance(e) then
                            severity_target('numbness')
                        elseif df.creature_interaction_effect_paralysisst:is_instance(e) then
                            severity_target('paralysis')
                        elseif df.creature_interaction_effect_feverst:is_instance(e) then
                            severity('fever')
                        elseif df.creature_interaction_effect_bleedingst:is_instance(e) then
                            severity_target('bleeding')
                        elseif df.creature_interaction_effect_cough_bloodst:is_instance(e) then
                            severity('coughing of blood')
                        elseif df.creature_interaction_effect_vomit_bloodst:is_instance(e) then
                            severity('vomiting of blood')
                        elseif df.creature_interaction_effect_nauseast:is_instance(e) then
                            severity('nausea')
                        elseif df.creature_interaction_effect_unconsciousnessst:is_instance(e) then
                            severity('unconsciousness')
                        elseif df.creature_interaction_effect_necrosisst:is_instance(e) then
                            severity_target('necrosis')
                        elseif df.creature_interaction_effect_impair_functionst:is_instance(e) then
                            severity_target('impaired function')
                        elseif df.creature_interaction_effect_drowsinessst:is_instance(e) then
                            severity('drowsiness')
                        elseif df.creature_interaction_effect_dizzinessst:is_instance(e) then
                            severity('dizziness')
                        else
                            self:insert_text(' '..tostring(e))
                            print(e)
                            printall(e)
                        end
                        if e.prob ~= 100 then
                            self:insert_text(' in '..e.prob..'% of cases')
                        end

                        self:insert_text(' starting after ')
                        local hours = math.floor(e.start / 50)
                        if hours < 1 then
                            self:insert_text('less than an hour')
                        elseif hours == 1 then
                            self:insert_text('about an hour')
                        else
                            if hours <= #number_names then
                                self:insert_text(number_names[hours])
                            else
                                self:insert_text(hours)
                            end
                            self:insert_text(' hours')
                        end

                        self:insert_text(', peaking after ')
                        hours = math.floor((e.peak - e.start) / 50)
                        if hours < 1 then
                            self:insert_text('less than an hour')
                        elseif hours == 1 then
                            self:insert_text('about an hour')
                        else
                            if hours <= #number_names then
                                self:insert_text(number_names[hours])
                            else
                                self:insert_text(hours)
                            end
                            self:insert_text(' hours')
                        end

                        self:insert_text(', and ending after ')
                        hours = math.floor((e['end'] - e.peak) / 50)
                        if hours < 1 then
                            self:insert_text('less than an hour')
                        elseif hours == 1 then
                            self:insert_text('about an hour')
                        else
                            if hours <= #number_names then
                                self:insert_text(number_names[hours])
                            else
                                self:insert_text(hours)
                            end
                            self:insert_text(' hours')
                        end
                    end
                    local sources = {}
                    if syn.flags.SYN_INJECTED then
                        table.insert(sources, ' injected')
                    end
                    if syn.flags.SYN_CONTACT then
                        table.insert(sources, ' touched')
                    end
                    if syn.flags.SYN_INHALED then
                        table.insert(sources, ' inhaled')
                    end
                    if syn.flags.SYN_INGESTED then
                        table.insert(sources, ' ingested')
                    end
                    if #sources > 0 then
                        self:insert_text(' when')
                        for i, source in ipairs(sources) do
                            self:insert_text(source)
                            if i < #sources and #sources ~= 2 then
                                self:insert_text(',')
                            end
                            if i == #sources - 1 then
                                self:insert_text(' or')
                            end
                        end
                    end
                    important = false
                end
                self:insert_text('.  ')
            end
        end
    end

    local first = true
    for _, l in ipairs(fig.entity_links) do
        local ent = utils.binsearch(df.global.world.entities.all, l.entity_id, 'id')
        local asn = utils.binsearch(ent.positions.assignments, l:getPosition(), 'id')
        if first then
            self:insert_text(NEWLINE)
            first = false
        end
        self:insert_text(NEWLINE)
        local link = entity_link(ent)
        self:insert_link(link)
        self:insert_text(', ')
        if asn then
            local pos = utils.binsearch(ent.positions.own, asn.position_id, 'id')
            local squad = utils.binsearch(df.global.world.squads.all, asn.squad_id, 'id')
            if fig.sex == 0 and #pos.name_female[0] > 0 then
                self:insert_text(pos.name_female[0])
            elseif fig.sex == 1 and #pos.name_male[0] > 0 then
                self:insert_text(pos.name_male[0])
            else
                self:insert_text(pos.name[0])
            end
            if squad then
                self:insert_text(' of '..translate_name(squad.name))
            end
            local start, stop = l:getPositionStartYear(), l:getPositionEndYear()
            if start == -1 then
                start = '?'
            end
            if stop == -1 then
                stop = 'present'
            end
            self:insert_text(' ('..start..' - '..stop..')')
        elseif l:getType() == df.histfig_entity_link_type.SQUAD or l:getType() == df.histfig_entity_link_type.FORMER_SQUAD then
            local squad = utils.binsearch(df.global.world.squads.all, l.squad_id, 'id')
            self:insert_text(({
                SQUAD = 'member',
                FORMER_SQUAD = 'former member'
            })[df.histfig_entity_link_type[l:getType()]])
            self:insert_text(' of '..translate_name(squad.name))
        else
            self:insert_text(({
                MEMBER = 'member',
                FORMER_MEMBER = 'former member',
                MERCENARY = 'mercenary',
                FORMER_MERCENARY = 'former mercenary',
                SLAVE = 'slave',
                FORMER_SLAVE = 'former slave',
                PRISONER = 'prisoner',
                FORMER_PRISONER = 'former prisoner',
                ENEMY = 'enemy',
                CRIMINAL = 'criminal'
            })[df.histfig_entity_link_type[l:getType()]])
        end
    end

    self:insert_history(function(event)
        return event:isRelatedToHistfigID(fig.id)
    end)

    self:init_text()
end

Site = defclass(Site, Viewer)
Site.focus_path = 'legends/entity/view'

function Site:init(args)
    local site = args.ref
    self.target_site = site
    self.frame_title = translate_name(site.name)
    if #self.frame_title > 0 then
        self:insert_text(self.frame_title)
        self:insert_text(' is')
    else
        self:insert_text('There was')
    end

    if site.type == df.world_site_type.PlayerFortress then
        self:insert_text(' a fortress')
    elseif site.type == df.world_site_type.DarkFortress then
        self:insert_text(' a dark fortress')
    elseif site.type == df.world_site_type.Cave then
        self:insert_text(' a cave')
    elseif site.type == df.world_site_type.MountainHalls then
        self:insert_text(' a mountain halls')
    elseif site.type == df.world_site_type.ForestRetreat then
        self:insert_text(' a forest retreat')
    elseif site.type == df.world_site_type.Town then
        if site.flags.Town then
            self:insert_text(' a town')
        else
            self:insert_text(' a hamlet')
        end
    elseif site.type == df.world_site_type.ImportantLocation then
        self:insert_text(' an important location')
    elseif site.type == df.world_site_type.LairShrine then
        if site.subtype_info and site.subtype_info.lair_type == 2 then
            self:insert_text(' a monument')
        elseif site.subtype_info and site.subtype_info.lair_type == 3 then
            self:insert_text(' a shrine')
        else
            self:insert_text(' a lair')
        end
    elseif site.type == df.world_site_type.Fortress then
        if site.subtype_info and site.subtype_info.is_tower == 1 then
            self:insert_text(' a tower')
        else
            self:insert_text(' a fortress')
        end
    elseif site.type == df.world_site_type.Camp then
        self:insert_text(' a camp')
    elseif site.type == df.world_site_type.Monument then
        if site.subtype_info and site.subtype_info.is_monument == 1 then
            self:insert_text(' a monument')
        else
            self:insert_text(' a tomb')
        end
    end

    local cur_owner = entity_link(site.cur_owner_id)
    if cur_owner then
        self:insert_text(' owned by ')
        self:insert_link(cur_owner)
    end
    local civ = entity_link(site.civ_id)
    if civ then
        self:insert_text(' of ')
        self:insert_link(civ)
    end
    local date = timestamp(site.created_year, site.created_tick)
    if date then
        self:insert_text(' founded')
        self:insert_text(date)
    end
    self:insert_text('.  ')

    if #site.entity_links > 0 then
        self:insert_text('Related entities include')
        local links = {}
        for _, l in ipairs(site.entity_links) do
            table.insert(links, entity_link(l.anon_2))
        end
        self:insert_list_of_links(links)
        self:insert_text('.  ')
    end

    self:insert_history(function(event)
        return event:isRelatedToSiteID(site.id)
    end)

    self:init_text()
end

Entity = defclass(Entity, Viewer)
Entity.focus_path = 'legends/entity/view'

function Entity:init(args)
    local ent = args.ref
    self.target_entity = ent
    self.frame_title = translate_name(ent.name)
    if #self.frame_title > 0 then
        self:insert_text(self.frame_title)
        self:insert_text(' is')
    else
        self.frame_title = df.global.world.raws.creatures.all[ent.race].name[1]
        self:insert_text('There was')
    end

    self:insert_text(' a ')
    self:insert_text(df.global.world.raws.creatures.all[ent.race].name[2])
    self:insert_text(entity_type_name[ent.type])

    local deities = {}

    for _, id in ipairs(ent.unknown1b.worship) do
        local deity = figure_link(id)
        if deity then
            table.insert(deities, deity)
        end
    end

    if #deities > 0 then
        self:insert_text(' that worships')
        self:insert_list_of_links(deities)
    end

    self:insert_text('.  ')

    local parents = {}
    local children = {}

    for _, l in ipairs(ent.entity_links) do
        local r = entity_link(l.target)
        if r then
            if l.type == df.entity_entity_link_type.PARENT then
                table.insert(parents, r)
            elseif l.type == df.entity_entity_link_type.CHILD then
                table.insert(children, r)
            end
        end
    end

    if #parents > 0 then
        self:insert_text('It is a part of')
        self:insert_list_of_links(parents)
    end

    if #children > 0 then
        if #parents > 0 then
            self:insert_text(', and contains')
        else
            self:insert_text('It contains')
        end
        self:insert_list_of_links(children)
        self:insert_text('.  ')
    elseif #parents > 0 then
        self:insert_text('.  ')
    end

    if #ent.site_links > 0 then
        self:insert_text('Sites related to ')
        self:insert_text(dfhack.TranslateName(ent.name))
        self:insert_text(' include')

        local links = {}
        for i, l in ipairs(ent.site_links) do
            -- entity_site_link
            -- anon_1 -> site_id
            -- anon_2 -> entity_id
            -- anon_3 -> ? (-1)
            -- anon_4 -> ? (-1, 0)
            -- anon_5 -> ? (-1)
            -- anon_6 -> ? (-1)
            -- anon_7 -> ? (1, 8)
            -- anon_8 -> ? (0)
            -- anon_9 -> link_strength
            -- anon_10 -> ? (0)
            -- anon_11 -> ? (0)
            -- anon_12 -> ? (empty)
            -- anon_13 -> ? (223, 226)
            -- anon_13 -> ? (215, 216)

            table.insert(links, site_link(l.anon_1))
        end
        self:insert_list_of_links(links)
        self:insert_text('.  ')
    end

    for i, t in ipairs(ent.resources.art_image_types) do
        if t == 0 then
            self:insert_text('Their symbol is ')
            self:insert_art_image(ent.resources.art_image_ids[i], ent.resources.art_image_subids[i], {ref = true})
            self:insert_text('.  ')
        end
    end

    local any_members = false
    local positions = {}
    local linked_hfs = {}
    for _, fig in ipairs(df.global.world.history.figures) do
        if fig.id >= 0 then
            for _, l in ipairs(fig.entity_links) do
                if l.entity_id == ent.id then
                    local pos = l:getPosition()
                    if pos < 0 then
                        local t = df.histfig_entity_link_type[l:getType()]
                        if not linked_hfs[t] then
                            linked_hfs[t] = {}
                        end
                        table.insert(linked_hfs[t], fig)
                    else
                        if not positions[pos] then
                            positions[pos] = {}
                        end
                        table.insert(positions[pos], {fig = fig, link = l})
                    end
                    any_members = true
                end
            end
        end
    end

    for _, pos in pairs(positions) do
        table.sort(pos, function(a, b)
            if a.link:getPositionStartYear() < b.link:getPositionStartYear() then
                return true
            elseif a.link:getPositionEndYear() == -1 then
                return false
            elseif b.link:getPositionEndYear() == -1 then
                return true
            else
                return a.link:getPositionEndYear() < b.link:getPositionEndYear()
            end
        end)
    end

    local first = true
    for t, desc in pairs({
            MEMBER = {'Member', 'Members'},
            FORMER_MEMBER = {'Former Member', 'Former Members'},
            MERCENARY = {'Mercenary', 'Mercenaries'},
            FORMER_MERCENARY = {'Former Mercenary', 'Former Mercenaries'},
            SLAVE = {'Slave', 'Slaves'},
            FORMER_SLAVE = {'Former Slave', 'Former Slaves'},
            PRISONER = {'Prisoner', 'Prisoners'},
            FORMER_PRISONER = {'Former Prisoner', 'Former Prisoners'},
            ENEMY = {'Enemy', 'Enemies'},
            CRIMINAL = {'Criminal', 'Criminals'}
        }) do
        if linked_hfs[t] then
            local figs = linked_hfs[t]
            if first then
                self:insert_text(NEWLINE)
                first = false
            end
            self:insert_text(NEWLINE)
            local num = 2
            if #figs == 1 then
                num = 1
            end
            local link = {
                text = #figs..' '..desc[num],
                target = function()
                    return FigureList{
                        title = desc[2]..' of '..dfhack.TranslateName(ent.name), -- always use plural in the title
                        list = figs
                    }
                end
            }
            self:insert_link(link)
        end
    end

    first = true
    for _, id in ipairs(ent.populations) do
        local pop = utils.binsearch(df.global.world.entity_populations, id, 'id')
        for i, race_id in ipairs(pop.races) do
            local count = pop.counts[i]
            local race = df.global.world.raws.creatures.all[race_id]
            if first then
                self:insert_text(NEWLINE)
                self:insert_text(NEWLINE)
                if any_members then
                    self:insert_text('Other ')
                end
                self:insert_text('Members')
            end
            self:insert_text(NEWLINE)
            self:insert_text(count)
            self:insert_text(' ')
            if count == 1 then
                self:insert_text(race.name[0])
            else
                self:insert_text(race.name[1])
            end
            if pop.name.has_name == 1 then
                self:insert_text(' - ')
                self:insert_text(translate_name(pop.name))
            end
        end
    end

    local assignments = {}
    for _, asn in ipairs(ent.positions.assignments) do
        table.insert(assignments, asn)
    end
    table.sort(assignments, function(a, b)
        local pos_a = utils.binsearch(ent.positions.own, a.position_id, 'id')
        local pos_b = utils.binsearch(ent.positions.own, b.position_id, 'id')
        return pos_a.precedence < pos_b.precedence
    end)

    for _, asn in ipairs(assignments) do
        local pos = utils.binsearch(ent.positions.own, asn.position_id, 'id')
        local squad = utils.binsearch(df.global.world.squads.all, asn.squad_id, 'id')
        first = true
        if positions[asn.id] then
            for _, l in ipairs(positions[asn.id]) do
                if first then
                    self:insert_text(NEWLINE)
                    self:insert_text(NEWLINE)
                    self:insert_text(pos.name[1])
                    if squad then
                        self:insert_text(' of '..translate_name(squad.name))
                    end
                    first = false
                end
                self:insert_text(NEWLINE)
                local link = figure_link(l.fig)
                self:insert_link(link)
                local start, stop = l.link:getPositionStartYear(), l.link:getPositionEndYear()
                if start == -1 then
                    start = '?'
                end
                if stop == -1 then
                    stop = 'present'
                end
                self:insert_text(' ('..start..' - '..stop..')')
            end
        end
    end

    self:insert_history(function(event)
        return event:isRelatedToEntityID(ent.id)
    end)

    self:init_text()
end

Region = defclass(Region, Viewer)
Region.focus_path = 'legends/region/view'

function Region:init(args)
    local region = args.ref
    self.target_region = region
    self.frame_title = translate_name(region.name)

    self:insert_history(function(event)
        return event:isRelatedToRegionID(region.index)
    end)

    self:init_text()
end

Layer = defclass(Layer, Viewer)
Layer.focus_path = 'legends/layer/view'

function Layer:init(args)
    local layer = args.ref
    self.target_layer = layer
    self.frame_title = translate_name(layer.name)
    if #self.frame_title == 0 then
        self.frame_title = layer_type_name[layer.type]
    end

    self:insert_history(function(event)
        return event:isRelatedToLayerID(layer.index)
    end)

    self:init_text()
end

local args = {...}

if not df.global.world.world_data then
    print('no world loaded')
elseif dfhack.gui.getCurFocus():find('^dfhack/lua/') then
    print('gui/legends must be used from a non-dfhack screen')
elseif args[1] == 'do_test' then
    Legends{}:do_test(function()
        print('Done!')
    end)
else
    local fig = nil
    local unit = dfhack.gui.getSelectedUnit(true)
    if unit then
        fig = utils.binsearch(df.global.world.history.figures, unit.hist_figure_id, 'id')
    end

    if fig then
        Figure{ref = fig}:show()
    else
        Legends{}:show()
    end
end
