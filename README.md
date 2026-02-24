# muslim.nvim

<div style="text-align: right">السلام عليكم</div>

A plugin to get prayer times and useful islamic essentials inside neovim

![lualine-integration](./img/lualine-integration.png)

## ✨ Features

- complete offline calculation based on [Equation of Time](https://en.wikipedia.org/wiki/Equation_of_time) and [Declination of Sun](https://www.pveducation.org/pvcdrom/properties-of-sunlight/declination-angle)
- supports hanafi school of thought adjustments
- supported methods: MWL, ISNA, Egypt, Makkah, Karachi, Tehran, Jafari, France, Russia, Singapore.
- supports higher latitude adjustment
- lualine integration to display current waqt status

## 📦 Requriements

- Neovim >= 0.11
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [lualine](https://github.com/nvim-lualine/lualine.nvim) _(optional)_

## 🚀 Installation

Install the plugin with your preferred package manager

```lua
{
    "tajirhas9/muslim.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- OPTIONAL
        "nvim-lualine/lualine.nvim"
    }
}
```

## ⚙️ Configuration

**`muslim.nvim`** comes with the following defaults:

```lua
{
    refresh     = 1,         -- Refresh interval in minutes to update prayer waqt times
    latitude    = nil,       -- MANDATORY TO BE PROVIDED. Geolocation latitude of the place of calculation
    longitude   = nil,       -- MANDATORY TO BE PROVIDED. Geolocation longitude of the place of calculation
    utc_offset  = 0,         -- timezone, default is GMT+0
    school      = 'hanafi',  -- school of thought
    method      = 'MWL',     -- calculation method. default is Muslim World League
    time_format = '12H',     -- time display format: '12H' for 12-hour with AM/PM, '24h' for 24-hour
    countdown_only = false,  -- show only countdown to next prayer
}
```
## 🛠️ Setup

```lua
local muslim = require("muslim")
muslim.setup({
    latitude = 23.816237996387994, 
    longitude = 90.79664030627636,
    timezone = 'Asia/Dhaka',
    utc_offset = 6,
    refresh = 5
})

```

## 🧭 Commands

**`muslim.nvim`** supports the following user commands.

| Command | Description |
| -- | -- |
| `:PrayerTimes` | Returns a table with formatted waqt times for the day |

### `:PrayerTimes` sample return value

```lua
|-------------------------|
| Waqt       | Time       |
|-------------------------|
| fajr       | 05:05 AM   |
| sunrise    | 06:20 AM   |
| dhuhr      | 12:06 PM   |
| asr        | 04:15 PM   |
| sunset     | 05:53 PM   |
| maghrib    | 05:53 PM   |
| isha       | 07:03 PM   |
| midnight   | 12:06 AM   |
|-------------------------|
```

## 🧰 Utility functions

| Function name | Description |
| -- | -- |
| `prayer_time`  | Returns a formatted text. Shows remaining time for current waqt (if valid) and start time of next waqt |
| `today_prayer_time_epochs` | Returns a table with all the waqt time _(in epochs)_ for the day |

These functions can be used to enhance the behavior of the plugin. For example, create a scheduler with `vim.schedule` and show the prayer time as a popup notification for certain warnings.

## 🧩 Integration with lualine

If you want the prayer times to appear in the statusline, you have to update your lualine configuration to add the following to the section of the lualine you want the text to be.

```lua
{ muslim.prayer_time, id = "muslim.nvim" }
```

### 🎨 Sample lualine configuration

To get something similar to the image above, the configuration can be as below:

```lua
require("lualine").setup({
    sections = {
        lualine_a = { { 'mode', icons_enabled = true, separator = { left = '' }, right_padding = 2 } },
        lualine_b = { { 'filename', path = 1 }, 'branch' },
        lualine_c = {
            { clients_lsp }
        },
        -- added muslim.nvim here
        lualine_x = { { 'datetime', style = 'default' }, { muslim.prayer_time, id = "muslim.nvim", color = { fg = colors.blue } } },
        lualine_y = { 'filetype', 'progress' },
        lualine_z = {
            { 'location', separator = { right = '' }, left_padding = 2 },
        },
    }
})
```
