--  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
--  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
--  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
--  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
--  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
--  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

-- Add configuration directory to the paths where Lua loader looks for on require.
-- Learn more [here](https://www.lua.org/manual/5.1/manual.html#pdf-package.path).
package.path = package.path .. string.format(";%s/home/programs/nvim/?.lua", os.getenv("DOTFILES"))

require("options")
require("keymaps")
require("commands")
require("plugins")

-- The colorscheme is pinned to VS Code 2026 in plugins.lua, tracking the
-- Zed/Ghostty 2026 theme.
