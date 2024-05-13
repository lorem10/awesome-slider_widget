# Lua AwesomeWM Slider Library

This library provides a flexible slider component for use in AwesomeWM configurations. It allows you to create customizable sliders that can be displayed on various screen positions.

#### Requirements

- [AwesomeWM](https://awesomewm.org/)
- [rubato](https://github.com/andOrlando/rubato)

#### Installation

To use this library, clone the repository into your AwesomeWM configuration directory:

```bash
git clone https://github.com/lorem10/awesome-slider_widget.git ~/.config/awesome/slider
```

Then, require the library in your `rc.lua`:

```lua
local slider = require("slider")
```

#### Usage

##### Creating a Slider

```lua
local slider_instance = slider.new({
    screen = awesome.screen.focused(), -- The screen to attach the slider to
    instant_show = true,               -- when created a new slider automatic show
    template = my_template,            -- Widget or template to display in the slider
    position = "bottom",               -- Position of the slider ("top", "bottom", "left", "right")
    margin = 4,                        -- Margin around the slider
    bg = "#000000",                    -- Background color of the slider
    size = 65,                         -- Size of the slider
    init_point = 100,                  -- Initial position of the slider (optional)
    radius = 10,                       -- Corner radius of the slider
    name = "my_slider"                 -- Unique name for the slider (optional)
})
```

##### Showing and Hiding the Slider

```lua
-- Show the slider
slider_instance:show()

-- Hide the slider
slider_instance:hide()

-- Show the slider with a timer
slider_instance:hide_with_timer()
```

#### Customization

You can customize the appearance and behavior of the slider by adjusting the parameters passed to the `slider.new` function.

#### Examples

```lua
-- Create a slider with a custom template
local my_template = {
    -- Your widget or template definition here
}

-- Connect the slider to each screen
awful.screen.connect_for_each_screen(function(s)
    -- Create a dock slider at the bottom of the screen
    local slider_instance = slider.new({
        screen = s,
        template = my_template,
        position = "bottom",
        margin = 4,
        bg = "#000000",
        size = 65,
        instant_show = true,
        init_point = 100,
        radius = 10,
    })

    s.dock = slider_instance.widget

    -- Show the slider when mouse enters the dock area
    s.dock:connect_signal("mouse::enter", dock.show)

    -- Hide the slider with a timer when mouse leaves the dock area
    s.dock:connect_signal("mouse::leave", function()
        if not slider_instance.clients_allow_to_display("floating") then
            slider_instance:hide_with_timer()
        end
    end)
end)


-- Define a function to smartly show the dock slider with a timer
local function smart_show_dock_with_timer(t)
    if slider_instance.clients_allow_to_display("floating", t) then
        slider_instance:show()
    else
        slider_instance:hide_with_timer()
    end
end

-- Connect the function to the tag's selected property change signal
tag.connect_signal("property::selected", function(t)
    smart_show_dock_with_timer(t)
end)
```

#### Contributing

Contributions are welcome! Feel free to submit bug reports, feature requests, or pull requests on the [GitHub repository](https://github.com/lorem10/awesome-slider_widget.git).
