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
local slider_widget = slider.new({
    screen = awesome.screen.focused(), -- The screen to attach the slider to
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
slider.show(slider_widget)

-- Hide the slider
slider.hide(slider_widget)

-- Show the slider with a timer
slider.show_with_timer(slider_widget)
```

#### Customization

You can customize the appearance and behavior of the slider by adjusting the parameters passed to the `slider.new` function.

#### Signals

This library emits the following signals:

- `module::slider::hide`: Triggered when a slider is hidden.
- `module::slider::show`: Triggered when a slider is shown.

#### Examples

```lua
-- Create a slider with a custom template
local my_template = {
    -- Your widget or template definition here
}

awful.screen.connect_for_each_screen(function(s)
    slider.new({
        screen = s,
        template = my_template,
        position = "bottom",
        margin = 4,
        bg = "#000000",
        size = 65,
        init_point = 100,
        radius = 10,
        name = "custom_slider"
    })

    s.dock:connect_signal("mouse::enter", dock.show)

    s.dock:connect_signal("mouse::leave", function()
        if not dock.clients_allow_to_display("floating") then
            dock.show_with_timer(s.dock)
        end
    end)
end)
```

#### Contributing

Contributions are welcome! Feel free to submit bug reports, feature requests, or pull requests on the [GitHub repository](https://github.com/lorem10/awesome-slider_widget.git).
