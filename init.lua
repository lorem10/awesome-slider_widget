local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local rubato = require "rubato"
local dpi = require("beautiful.xresources").apply_dpi

local slider = {}

---@type table
local moveAnimation = {}
local hide_timer = nil

-- This table used for store slider names
slider.names = {}

---@param slider_name? string
---@return string slider_name
local function register_new_slider(slider_name)
    -- If you not pass slider_name param, this function will generate a name (like slider_1, slider_2, etc)
    local sn = slider_name or ('slider_' .. tostring(#slider.names + 1))
    table.insert(slider.names, sn)
    return sn
end

---@param s table awesome screen
---@param position 'bottom'|'right'|'left'|'top'
---@param slider_widget table
---@return number,number
local function calc_hide_position(s, slider_widget, position)
    slider_widget = slider_widget or awful.screen.focused().slider

    if position == "bottom" then
        return slider_widget.init_point or ((s.geometry.width / 2 - (s.geometry.x))), (s.geometry.height - 1)
    elseif position == "top" then
        return slider_widget.init_point or (s.geometry.width / 2) - (s.geometry.x), (1 - s.slider.height)
    elseif position == "left" then
        return (2 - slider_widget.width), slider_widget.init_point or s.geometry.height / 2 - s.geometry.y
    end
    return (s.geometry.width - 2), slider_widget.init_point or (s.geometry.height / 2 - s.geometry.y)
end

---@param slider_widget table
---@return number
local function calc_show_position(slider_widget)
    if slider_widget.position == "top" then
        return slider_widget.init_y + slider_widget.height + slider_widget.margin
    elseif slider_widget.position == "bottom" then
        return slider_widget.init_y - (slider_widget.height + slider_widget.margin)
    elseif slider_widget.position == "right" then
        return slider_widget.init_x - (slider_widget.width + slider_widget.margin)
    end
    return slider_widget.init_x + slider_widget.width + slider_widget.margin
end

local function timer_rerun()
    if hide_timer.started then
        hide_timer:again()
    else
        hide_timer:start()
    end
end

---@param slider_widget table
---@param position_sec number
local function show_slider(slider_widget, position_sec)
    local axis = slider_widget.axis
    moveAnimation:subscribe(function(pos)
        slider_widget[axis] = pos
    end)
    moveAnimation.target = position_sec
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
---@param slider_widget table
function slider.hide(slider_widget)
    local init_position = slider_widget.init_y

    if slider_widget.position == "left" or slider_widget.position == "right" then
        init_position = slider_widget.init_x
    end

    moveAnimation:subscribe(function(pos)
        slider_widget[slider_widget.axis or "y"] = pos
    end)
    moveAnimation.target = init_position
    hide_timer:stop()
end

---@param slider_widget table
function slider.show(slider_widget)
    hide_timer:stop()

    local position_sec = calc_show_position(slider_widget)
    show_slider(slider_widget, position_sec)
end

-- show slider with timer that a few moment it hide
---@param slider_widget table
function slider.show_with_timer(slider_widget)
    slider.show(slider_widget)
    timer_rerun()
end

---@class Args
---@field screen table Awesome table
---@field template table Awesome template
---@field position? 'top'|'left'|'bottom'|'right'
---@field margin? number
---@field bg? string
---@field size? number
---@field init_point number
---@field radius? number
---@field name? string

---@param args Args
function slider.new(args)
    args = args or {}
    local s = args.screen
    local template = args.template
    local position = args.position or "bottom"
    local margin = args.margin or 4
    local bg = args.bg or beautiful.slider_bg
    local size = args.size or 65
    local init_point = args.init_point
    local radius = args.radius or beautiful.rounded
    local slider_name = register_new_slider(args.name)

    if position ~= "top" and position ~= "bottom" and position ~= "left" and position ~= "right" then
        error("Invalid position in slider module, you may only use" .. " 'top', 'bottom', 'left' and 'right'")
    end

    local popup_min_size, popup_max_size, popup_size
    if position == "right" or position == "left" then
        popup_min_size, popup_max_size, popup_size = "minimum_width", "maximum_width", "width"
    elseif position == "top" or position == "bottom" then
        popup_min_size, popup_max_size, popup_size = "minimum_height", "maximum_height", "height"
    end

    s[slider_name] = awful.popup {
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
    hide_timer = gears.timer {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            slider.hide(s[slider_name])
        end
    }

    s[slider_name]:setup(template)
    s[slider_name].init_point = init_point
    s[slider_name].position = position
    if position == "left" or position == "right" then
        s[slider_name].axis = "x"
    elseif position == "top" or position == "bottom" then
        s[slider_name].axis = "y"
    end
    s[slider_name].margin = margin
    local init_x, init_y = calc_hide_position(s, s[slider_name], position)
    s[slider_name].x = init_x
    s[slider_name].y = init_y
    s[slider_name].init_x = init_x
    s[slider_name].init_y = init_y

    --TODO: complete this function
    -- if init_position then
    --     s[slider_name]:connect_signal("property::width", function() --for centered placement, wanted to keep the offset
    --         s[slider_name].s[slider_name].axis = s.geometry.x + s.geometry.width / 2 - s[slider_name].width / 2
    --     end)
    -- end

    local position_init = s[slider_name].y

    if s[slider_name].position == "right" or s[slider_name].position == "left" then
        position_init = s[slider_name].x
    end

    moveAnimation = rubato.timed {
        pos = position_init,
        intro = 0.1,
        duration = 0.23
    }
    -- show slider when loaded awesome
    slider.show(s[slider_name])

    return s[slider_name]
end

awesome.connect_signal('module::slider::hide', function(slider_widget)
    slider.hide(slider_widget)
end)

awesome.connect_signal('module::slider::show', function(slider_widget)
    slider.show(slider_widget)
end)

local mt = {}

---@param ... Args
function mt.__call(_, ...)
    new(...)
end

return setmetatable(slider, mt)
