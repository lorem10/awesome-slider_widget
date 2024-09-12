local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local rubato = require "rubato"
local dpi = require("beautiful.xresources").apply_dpi

local slider = {
    hide_timer = nil,
    moveAnimation = {},
    widget = {}
}
slider.__index = slider

---@param s table awesome screen
---@param position 'bottom'|'right'|'left'|'top'
---@param slf table
---@return number,number
local function calc_hide_position(s, slf, position)

    if position == "bottom" then
        return slf.init_point or ((s.geometry.width / 2 - (s.geometry.x))), (s.geometry.height - slf.offset)
    elseif position == "top" then
        return slf.init_point or (s.geometry.width / 2) - (s.geometry.x), (slf.offset - slf.widget.height)
    elseif position == "left" then
        return (slf.offset - slf.widget.width), slf.init_point or s.geometry.height / 2 - s.geometry.y
    end
    return (s.geometry.width - slf.offset), slf.init_point or (s.geometry.height / 2 - s.geometry.y)
end

---@return number
local function calc_show_position(slf)
    if slf.position == "top" then
        return slf.init_y + slf.widget.height + slf.margin
    elseif slf.position == "bottom" then
        return slf.init_y - (slf.widget.height + slf.margin)
    elseif slf.position == "right" then
        return slf.init_x - (slf.widget.width + slf.margin)
    end
    return slf.init_x + slf.widget.width + slf.margin
end

---@param layout_names table|string The state of the slider that can be displayed or not
---@param t? table awesome tag
---@return boolean
function slider.clients_allow_to_display(layout_names, t)
    local clients = {}
    -- Get all clients from all selected tags
    for _, t in ipairs(awful.screen.focused().selected_tags) do
        for _, c in ipairs(t:clients()) do
            table.insert(clients, c)
        end
    end

    local filtered_clients = {}
    -- Filter clients that are not hidden or floated
    for _, client in ipairs(clients) do
        if not client.minimized and not (client.floating and not client.maximized) or client.fullscreen then
            table.insert(filtered_clients, client)
        end
    end

    if layout_names then
        local tg = t or awful.screen.focused().selected_tag
        if type(layout_names) == "table" then
            local status_of_show_in_spcific_layout = false
            for _, tag_name in ipairs(layout_names) do
                if tg.layout.name == tag_name then
                    status_of_show_in_spcific_layout = true
                    break
                end
            end
            return #filtered_clients == 0 or status_of_show_in_spcific_layout
        end
        return #filtered_clients == 0 or tg.layout.name == layout_names
    end
    return #filtered_clients == 0
end

-- hide slider
function slider:hide()
    local init_position = self.init_y

    if self.position == "left" or self.position == "right" then
        init_position = self.init_x
    end

    self.moveAnimation.target = init_position
    self.hide_timer:stop()
end

function slider:show()
    self.hide_timer:stop()
    local position_sec = calc_show_position(self)
    self.moveAnimation.target = position_sec
end

-- show slider with timer that a few moment it hide
function slider:hide_with_timer()
    if self.hide_timer.started then
        self.hide_timer:again()
    else
        self.hide_timer:start()
    end
end

---@class Args
---@field screen table Awesome table
---@field template table Awesome template
---@field position? 'top'|'left'|'bottom'|'right'
---@field margin? number
---@field bg? string
---@field size? number
---@field init_point? number
---@field radius? number
---@field instant_show? boolean
---@field offset? number

---@param args Args
---@return table  SliderWidget
function slider.new(args)
    local self = setmetatable({}, slider)
    args = args or {}
    local s = args.screen
    local template = args.template
    local position = args.position or "bottom"
    local margin = args.margin or 4
    local bg = args.bg or beautiful.slider_bg
    local size = args.size or 65
    local init_point = args.init_point
    local radius = args.radius or beautiful.rounded
    local instant_show = args.instant_show or false
    local offset = args.offset or 2

    if position ~= "top" and position ~= "bottom" and position ~= "left" and position ~= "right" then
        error("Invalid position in slider module, you may only use" .. " 'top', 'bottom', 'left' and 'right'")
    end

    local popup_min_size, popup_max_size, popup_size
    if position == "right" or position == "left" then
        popup_min_size, popup_max_size, popup_size = "minimum_width", "maximum_width", "width"
    elseif position == "top" or position == "bottom" then
        popup_min_size, popup_max_size, popup_size = "minimum_height", "maximum_height", "height"
    end

    self.widget = awful.popup {
        [popup_max_size] = dpi(size),
        [popup_min_size] = dpi(size),
        [popup_size] = dpi(size),
        bg = bg,
        ontop = true,
        type = "slider",
        y = 0,
        x = 0,
        screen = s,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, radius)
        end,
        widget = {}
    }
    self.hide_timer = gears.timer {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            self:hide()
        end
    }

    self.widget:setup(template)
    self.init_point = init_point
    self.position = position
    self.offset = offset
    if position == "left" or position == "right" then
        self.axis = "x"
    elseif position == "top" or position == "bottom" then
        self.axis = "y"
    end
    self.margin = margin
    local init_x, init_y = calc_hide_position(s, self, position)
    self.widget.x = init_x
    self.widget.y = init_y
    self.init_x = init_x
    self.init_y = init_y

    if not self.init_position then
        if position == 'bottom' or position == 'top' then
            self.widget:connect_signal("property::width", function()
                self.widget.x = s.geometry.x + s.geometry.width / 2 - self.widget.width / 2
            end)
        else
            self.widget:connect_signal("property::height", function()
                self.widget.y = s.geometry.y + s.geometry.height / 2 - self.widget.height / 2
            end)
        end
    end

    local position_init = self.widget.y

    if self.widget.position == "right" or self.widget.position == "left" then
        position_init = self.widget.x
    end

    self.moveAnimation = rubato.timed {
        pos = position_init,
        intro = 0.1,
        duration = 0.23
    }
    self.moveAnimation:subscribe(function(pos)
        self.widget[self.axis] = pos
    end)
    -- show slider when loaded awesome
    if instant_show then
        self:show()
    end

    return self
end

return slider
