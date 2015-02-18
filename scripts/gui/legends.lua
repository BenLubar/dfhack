-- legends.lua
-- A replacement for legends mode.
-- version 0.1
-- author: BenLubar

local gui     = require 'gui'
local widgets = require 'gui.widgets'
local utils   = require 'utils'

local function translate_name(name)
    local t = dfhack.TranslateName(name)
    local e = dfhack.TranslateName(name, 1)
    if e ~= t then
        t = t..', "'..e..'"'
    end
    return t
end

local function figure_link(fig)
    if type(fig) == 'number' then
        fig = utils.binsearch(df.global.world.history.figures, fig, 'id')
    end
    if fig then
        return {
            text = dfhack.TranslateName(fig.name),
            target_figure = fig
        }
    end
end

local function entity_link(ent)
    if type(ent) == 'number' then
        ent = utils.binsearch(df.global.world.entities.all, ent, 'id')
    end
    if ent then
        return {
            text = dfhack.TranslateName(ent.name),
            target_entity = ent
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
    frame_title = 'List',
    view = nil
}

function List:init(args)
end

function List:init_list(list)
    local choices = {}
    for i, v in ipairs(list) do
        if v.id >= 0 then -- ignore dfhack config
            table.insert(choices, {
                icon = self:icon(v),
                text = self:name(v),
                search_key = string.lower(self:search_key(v)),
                index = i
            })
        end
    end
    self:addviews{widgets.FilteredList{
        frame      = {yalign = 0},
        choices    = choices,
        edit_below = true,
        on_submit  = function(index, choice)
            self.view{index = choice.index}:show()
        end,
        text_pen   = COLOR_GREY,
        cursor_pen = COLOR_WHITE,
        edit_pen   = COLOR_LIGHTCYAN
    }}
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
    frame_title = 'Historical Figures',
    view = Figure
}

function FigureList:init(args)
    self:init_list(df.global.world.history.figures)
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
        if fig.profession >= 0 and fig.profession ~= df.profession.STANDARD then
            local profession = df.profession.attrs[fig.profession].caption
            if fig.race >= 0 then
                local race = df.global.world.raws.creatures.all[fig.race]
                if race.profession_name.singular[fig.profession] ~= '' then
                    profession = race.profession_name.singular[fig.profession]
                end
                if fig.caste >= 0 then
                    local caste = race.caste[fig.caste]
                    if caste.caste_profession_name.singular[fig.profession] ~= '' then
                        profession = caste.caste_profession_name.singular[fig.profession]
                    end
                end
            end
            race_name = race_name..' '..string.lower(profession)
        end
        if name:len() > 0 then
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
    frame_title = 'Sites',
    view = Site
}

function SiteList:init(args)
    self:init_list(df.global.world.world_data.sites)
end

function SiteList:name(site)
    return dfhack.TranslateName(site.name)
end

EntityList = defclass(EntityList, List)
EntityList.focus_path = 'legends/entity/list'
EntityList.ATTRS = {
    frame_title = 'Entities',
    view = Entity
}

function EntityList:init(args)
    self:init_list(df.global.world.entities.all)
end

function EntityList:name(ent)
    local name = dfhack.TranslateName(ent.name)
    if name:len() > 0 then
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

Viewer = defclass(Viewer, gui.FramedScreen)
Viewer.ATTRS = {
    frame_style = gui.BOUNDARY_FRAME,
    frame_inset = 1
}

function Viewer:init(args)
end

function Viewer:init_text(text)
    local width, height = dfhack.screen.getWindowSize()
    width, height = width - 4, height - 4 -- 1 unit border + 1 unit padding

    local out = {}

    local x = 1
    for _, t in ipairs(text) do
        if type(t) == 'table' then
            -- don't split tables
            x = x + t.text:len()
            if x > width then
                table.insert(out, NEWLINE)
                x = t.text:len()
            end
            table.insert(out, t)
        elseif t == NEWLINE then
            table.insert(out, t)
            x = 1
        else
            x = x - 1
            for i, s in ipairs(utils.split_string(t, ' ')) do
                x = x + s:len() + 1
                if x > width then
                    table.insert(out, NEWLINE)
                    x = s:len()
                elseif i ~= 1 and x ~= s:len() then
                    table.insert(out, ' ')
                end
                table.insert(out, s)
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

function Viewer:scroll(direction)
    if self.current_link ~= 0 and self.links[self.current_link].page == self.pages:getSelected() then
        self.links[self.current_link].pen = COLOR_CYAN
        self.current_link = self.current_link + direction
        if self.current_link <= 0 then
            self.current_link = #self.links
            if self.links[1].page == 1 then
                self.pages:setSelected(#self.pages.subviews)
            else
                self.pages:setSelected(self.pages:getSelected() + direction)
            end
        elseif self.current_link > #self.links then
            self.current_link = 1
            if self.links[#self.links].page == self.pages:getSelected() then
                self.pages:setSelected(1)
            else
                self.pages:setSelected(self.pages:getSelected() + direction)
            end
        elseif self.links[self.current_link].page ~= self.pages:getSelected() then
            self.pages:setSelected(self.pages:getSelected() + direction)
        end
        self.links[self.current_link].pen = COLOR_LIGHTCYAN
    else
        self.pages:setSelected(self.pages:getSelected() + direction)
    end
end

function Viewer:goto_link()
    if self.current_link ~= 0 and self.links[self.current_link].page == self.pages:getSelected() then
        if self.links[self.current_link].target_figure then
            Figure{ref = self.links[self.current_link].target_figure}:show()
        elseif self.links[self.current_link].target_entity then
            Entity{ref = self.links[self.current_link].target_entity}:show()
        end
    end
end

Figure = defclass(Figure, Viewer)
Figure.focus_path = 'legends/figure/view'

function Figure:init(args)
    local fig = args.ref
    if args.index ~= nil then
        fig = df.global.world.history.figures[args.index]
    end
    self.frame_title = translate_name(fig.name)
    self.links = {}
    local text = {}
    if self.frame_title:len() > 0 then
        table.insert(text, self.frame_title)
        table.insert(text, ' is')
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
        table.insert(text, 'There was')
    end
    if fig.flags.force then
        table.insert(text, ' a force of nature')
    end
    if fig.flags.deity then
        table.insert(text, ' a deity commonly depicted as')
    end
    if fig.flags.ghost then
        table.insert(text, ' the ghost of')
    end

    if fig.sex == 0 then
        table.insert(text, ' a female')
    elseif fig.sex == 1 then
        table.insert(text, ' a male')
    elseif fig.race >= 0 then
        table.insert(text, ' a')
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
        table.insert(text, ' '..race_name)
    end
    if fig.profession >= 0 and fig.profession ~= df.profession.STANDARD then
        local profession = df.profession.attrs[fig.profession].caption
        if fig.race >= 0 then
            local race = df.global.world.raws.creatures.all[fig.race]
            if race.profession_name.singular[fig.profession] ~= '' then
                profession = race.profession_name.singular[fig.profession]
            end
            if fig.caste >= 0 then
                local caste = race.caste[fig.caste]
                if caste.caste_profession_name.singular[fig.profession] ~= '' then
                    profession = caste.caste_profession_name.singular[fig.profession]
                end
            end
        end
        table.insert(text, ' '..string.lower(profession))
    end
    if fig.info and fig.info.spheres and #fig.info.spheres > 0 then
        table.insert(text, ' associated with')
        for i, s in ipairs(fig.info.spheres) do
            table.insert(text, ' '..string.lower(df.sphere_type[s]))
            if i < #fig.info.spheres - 1 and #fig.info.spheres ~= 2 then
                table.insert(text, ',')
            end
            if i == #fig.info.spheres - 2 then
                table.insert(text, ' and')
            end
        end
    end

    local born = timestamp(fig.born_year, fig.born_seconds)
    if born then
        table.insert(text, ' born')
        table.insert(text, born)
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
            table.insert(text, ' born')
        end
        table.insert(text, ' to ')
        for i, parent in ipairs(parents) do
            table.insert(text, ' ')
            table.insert(self.links, parent)
            table.insert(text, parent)
            if i < #parents and #parents ~= 2 then
                table.insert(text, ',')
            end
            if i == #parents - 1 then
                table.insert(text, ' and')
            end
        end
    end
    table.insert(text, '.  ')

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
            table.insert(text, 'She is worshipped by')
        elseif fig.sex == 1 then
            table.insert(text, 'He is worshipped by')
        else
            table.insert(text, 'It is worshipped by')
        end
        for i, worshipper in ipairs(worshipped) do
            table.insert(text, ' ')
            table.insert(self.links, worshipper)
            table.insert(text, worshipper)
            if i < #worshipped and #worshipped ~= 2 then
                table.insert(text, ',')
            end
            if i == #worshipped - 1 then
                table.insert(text, ' and')
            end
        end
        table.insert(text, '.  ')
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

    if #deities > 0 then
        if fig.sex == 0 then
            table.insert(text, 'She worships')
        elseif fig.sex == 1 then
            table.insert(text, 'He worships')
        else
            table.insert(text, 'It worships')
        end
        for i, deity in ipairs(deities) do
            table.insert(text, ' ')
            table.insert(self.links, deity)
            table.insert(text, deity)
            if i < #deities and #deities ~= 2 then
                table.insert(text, ',')
            end
            if i == #deities - 1 then
                table.insert(text, ' and')
            end
        end
        table.insert(text, '.  ')
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
            table.insert(text, 'She')
        elseif fig.sex == 1 then
            table.insert(text, 'He')
        else
            table.insert(text, 'It')
        end
        table.insert(text, ' is married to')
        for i, spouse in ipairs(spouses) do
            table.insert(text, ' ')
            table.insert(self.links, spouse)
            table.insert(text, spouse)
            if i < #spouses and #spouses ~= 2 then
                table.insert(text, ',')
            end
            if i == #spouses - 1 then
                table.insert(text, ' and')
            end
        end
    end

    if #children > 0 then
        if #spouses > 0 then
            table.insert(text, ' and')
        elseif fig.sex == 0 then
            table.insert(text, 'She')
        elseif fig.sex == 1 then
            table.insert(text, 'He')
        else
            table.insert(text, 'It')
        end
        table.insert(text, ' has ')
        if #children == 1 then
            table.insert(text, 'a child named')
        elseif #children <= 15 then
            table.insert(text, ({[2] = "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen"})[#children]..' children:')
        else
            table.insert(text, #children..' children:')
        end

        for i, child in ipairs(children) do
            table.insert(text, ' ')
            table.insert(self.links, child)
            table.insert(text, child)
            if i < #children and #children ~= 2 then
                table.insert(text, ',')
            end
            if i == #children - 1 then
                table.insert(text, ' and')
            end
        end
        table.insert(text, '.  ')
    elseif #spouses > 0 then
        table.insert(text, '.  ')
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
                table.insert(text, 'She ')
                s = s:gsub('%[he/she%]', 'he')
                s = s:gsub('%[him/her%]', 'him')
                s = s:gsub('%[his/her%]', 'his')
            elseif fig.sex == 1 then
                table.insert(text, 'He ')
                s = s:gsub('%[he/she%]', 'she')
                s = s:gsub('%[him/her%]', 'her')
                s = s:gsub('%[his/her%]', 'her')
            else
                table.insert(text, 'It ')
                s = s:gsub('%[he/she%]', 'it')
                s = s:gsub('%[him/her%]self', 'itself')
                s = s:gsub('%[his/her%]', 'its')
            end

            local crafts = df.profession.attrs[df.profession.CRAFTSMAN].caption
            if fig.race >= 0 then
                local race = df.global.world.raws.creatures.all[fig.race]
                if race.profession_name.singular[df.profession.CRAFTSMAN] ~= '' then
                    crafts = race.profession_name.singular[df.profession.CRAFTSMAN]
                end
                if fig.caste >= 0 then
                    local caste = race.caste[fig.caste]
                    if caste.caste_profession_name.singular[df.profession.CRAFTSMAN] ~= '' then
                        crafts = caste.caste_profession_name.singular[df.profession.CRAFTSMAN]
                    end
                end
            end
            s = s:gsub('crafts%[man%]', crafts)
            table.insert(text, s)
            table.insert(text, '.  ')
        end
    end

    local died = timestamp(fig.died_year, fig.died_seconds)
    if died then
        if fig.name.first_name ~= '' then
            local name = string.gsub(fig.name.first_name, '^(%l)', string.upper)
            table.insert(text, name)
        elseif fig.sex == 0 then
            table.insert(text, 'She')
        elseif fig.sex == 1 then
            table.insert(text, 'He')
        else
            table.insert(text, 'It')
        end
        table.insert(text, ' died')
        table.insert(text, died)
        table.insert(text, '.  ')
    end

    if fig.race >= 0 then
        local race = df.global.world.raws.creatures.all[fig.race]
        if fig.caste >= 0 then
            local caste = race.caste[fig.caste]
            table.insert(text, NEWLINE)
            table.insert(text, NEWLINE)
            table.insert(text, caste.description)
        end
    end

    self:init_text(text)
end

Site = defclass(Site, Viewer)
Site.focus_path = 'legends/entity/view'

function Site:init(args)
    local site = args.ref
    if args.index ~= nil then
        site = df.global.world.world_data.sites[args.index]
    end
    self.frame_title = translate_name(site.name)
    self.links = {}
    local text = {}
    if self.frame_title:len() > 0 then
        table.insert(text, self.frame_title)
        table.insert(text, ' is')
    else
        table.insert(text, 'There was')
    end

    self:init_text(text)
end

Entity = defclass(Entity, Viewer)
Entity.focus_path = 'legends/entity/view'

function Entity:init(args)
    local ent = args.ref
    if args.index ~= nil then
        ent = df.global.world.entities.all[args.index]
    end
    self.frame_title = translate_name(ent.name)
    self.links = {}
    local text = {}
    if self.frame_title:len() > 0 then
        table.insert(text, self.frame_title)
        table.insert(text, ' is')
    else
        self.frame_title = df.global.world.raws.creatures.all[ent.race].name[1]
        table.insert(text, 'There was')
    end

    table.insert(text, ' a ')
    table.insert(text, df.global.world.raws.creatures.all[ent.race].name[2])
    table.insert(text, entity_type_name[ent.type])

    local deities = {}

    for _, id in ipairs(ent.unknown1b.worship) do
        local deity = figure_link(id)
        if deity then
            table.insert(deities, deity)
        end
    end

    if #deities > 0 then
        table.insert(text, ' that worships')
        for i, deity in ipairs(deities) do
            table.insert(text, ' ')
            table.insert(self.links, deity)
            table.insert(text, deity)
            if i < #deities and #deities ~= 2 then
                table.insert(text, ',')
            end
            if i == #deities - 1 then
                table.insert(text, ' and')
            end
        end
    end

    table.insert(text, '.  ')

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
        table.insert(text, 'It is a part of')
        for i, parent in ipairs(parents) do
            table.insert(text, ' ')
            table.insert(self.links, parent)
            table.insert(text, parent)
            if i < #parents and #parents ~= 2 then
                table.insert(text, ',')
            end
            if i == #parents - 1 then
                table.insert(text, ' and')
            end
        end
    end

    if #children > 0 then
        if #parents > 0 then
            table.insert(text, ', and contains')
        else
            table.insert(text, 'It contains')
        end
        for i, child in ipairs(children) do
            table.insert(text, ' ')
            table.insert(self.links, child)
            table.insert(text, child)
            if i < #children and #children ~= 2 then
                table.insert(text, ',')
            end
            if i == #children - 1 then
                table.insert(text, ' and')
            end
        end
        table.insert(text, '.  ')
    elseif #parents > 0 then
        table.insert(text, '.  ')
    end

    self:init_text(text)
end

if not dfhack.gui.getCurFocus():find('^dfhack/lua/') then
    Legends{}:show()
end
