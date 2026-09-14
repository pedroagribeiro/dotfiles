-- VS Code 2026 for Neovim.
--
-- The palette below is generated from home/programs/zed/themes/vscode-2026.json
-- -- the same theme file Zed loads and the same colours Ghostty's
-- themes/vscode-{dark,light}-2026 palettes carry -- so all three editors stay
-- in step. Change colours THERE, not here, then regenerate.
--
-- Two details worth knowing before editing:
--
--   * Zed's format carries 8-digit #RRGGBBAA colours, and Neovim highlights are
--     opaque. Those values are composited over the surface they actually sit on
--     (editor background for selections and search, panel background for hover
--     and border states); each one keeps its source value in a trailing comment
--     so the blend can be checked.
--   * `groups()` is shared by both variants deliberately. Dark and light differ
--     only in their palette, so a group added for one can never go missing from
--     the other.

local M = {}

-- Which surfaces let the terminal background through. Ghostty runs at
-- `background-opacity = 0.9`, so this reads as a 10% wash of the desktop
-- rather than true glass.
--
-- Floats stay legible without a painted background: a float's cells COVER the
-- buffer rather than blending with it, so what shows through is the terminal,
-- not the text underneath.
--
-- Set any entry to false to paint that surface from the palette again.
M.transparent = {
  editor  = true,  -- buffer body, sign and fold columns, window separators
  chrome  = true,  -- statusline, tabline, winbar
  sidebar = true,  -- neo-tree
  floats  = true,  -- popup menu, telescope, LSP hover, borders
}

local palettes = {
  dark = {
    bg               = "#121314",
    fg               = "#bbbebf",
    surface          = "#191a1b",
    elevated         = "#202122",
    float_bg         = "#202122",
    border           = "#2a2b2c",
    border_focus     = "#2f708c",  -- #3994BCB3 over #191A1B
    text             = "#bfbfbf",
    muted            = "#8c8c8c",
    placeholder      = "#555555",
    accent           = "#48a0c7",
    cursor_line      = "#242526",
    line_nr          = "#858889",
    line_nr_active   = "#bbbebf",
    invisible        = "#373838",  -- #8C8C8C4D over #121314
    wrap_guide       = "#848484",
    visual           = "#245c73",  -- #276782dd over #121314
    search           = "#1d3d4b",  -- #27678280 over #121314
    hl_read          = "#192d37",  -- #27678250 over #121314
    hl_write         = "#1d3d4b",  -- #27678280 over #121314
    hover            = "#2b2c2d",  -- #FFFFFF14 over #191A1B
    active           = "#383939",  -- #FFFFFF22 over #191A1B
    selected         = "#383939",  -- #FFFFFF22 over #191A1B
    scrollbar        = "#646566",  -- #A8A9AA85 over #191A1B
    tab_active       = "#121314",
    tab_inactive     = "#191a1b",
    statusline       = "#191a1b",
    panel            = "#191a1b",
    cursor           = "#bbbebf",
    added            = "#73c991",
    changed          = "#e5ba7d",
    removed          = "#f48771",
    renamed          = "#2472c8",
    conflict         = "#f48771",
    error            = "#cd3131",
    warning          = "#e5e510",
    info             = "#2472c8",
    hint             = "#2472c8",
    success          = "#0dbc79",
    ignored          = "#8c8c8c",
    syntax = {
      ["comment"] = { fg = "#8b949e" },
      ["comment.doc"] = { fg = "#8b949e" },
      ["keyword"] = { fg = "#ff7b72" },
      ["operator"] = { fg = "#ff7b72" },
      ["string"] = { fg = "#a5d6ff" },
      ["string.escape"] = { fg = "#7ee787", bold = true },
      ["string.regex"] = { fg = "#a5d6ff" },
      ["string.special"] = { fg = "#a5d6ff" },
      ["string.special.symbol"] = { fg = "#79c0ff" },
      ["number"] = { fg = "#79c0ff" },
      ["boolean"] = { fg = "#79c0ff" },
      ["constant"] = { fg = "#79c0ff" },
      ["function"] = { fg = "#d2a8ff" },
      ["function.method"] = { fg = "#d2a8ff" },
      ["constructor"] = { fg = "#d2a8ff" },
      ["type"] = { fg = "#79c0ff" },
      ["type.builtin"] = { fg = "#ff7b72" },
      ["variable"] = { fg = "#c9d1d9" },
      ["variable.special"] = { fg = "#79c0ff" },
      ["property"] = { fg = "#79c0ff" },
      ["attribute"] = { fg = "#79c0ff" },
      ["tag"] = { fg = "#7ee787" },
      ["title"] = { fg = "#79c0ff", bold = true },
      ["emphasis"] = { fg = "#c9d1d9", italic = true },
      ["emphasis.strong"] = { fg = "#c9d1d9", bold = true },
      ["link_uri"] = { fg = "#a5d6ff" },
      ["link_text"] = { fg = "#a5d6ff" },
      ["punctuation"] = { fg = "#c9d1d9" },
      ["punctuation.bracket"] = { fg = "#c9d1d9" },
      ["punctuation.delimiter"] = { fg = "#c9d1d9" },
      ["punctuation.list_marker"] = { fg = "#ffa657" },
      ["punctuation.special"] = { fg = "#ff7b72" },
      ["preproc"] = { fg = "#ff7b72" },
      ["enum"] = { fg = "#79c0ff" },
      ["variant"] = { fg = "#79c0ff" },
      ["label"] = { fg = "#79c0ff" },
      ["predictive"] = { fg = "#8b949e" },
      ["hint"] = { fg = "#8b949e" },
      ["primary"] = { fg = "#c9d1d9" },
    },
    terminal = {
      [0] = "#000000",
      [1] = "#cd3131",
      [2] = "#0dbc79",
      [3] = "#e5e510",
      [4] = "#2472c8",
      [5] = "#bc3fbc",
      [6] = "#11a8cd",
      [7] = "#e5e5e5",
      [8] = "#666666",
      [9] = "#f14c4c",
      [10] = "#23d18b",
      [11] = "#f5f543",
      [12] = "#3b8eea",
      [13] = "#d670d6",
      [14] = "#29b8db",
      [15] = "#e5e5e5",
    },
  },
  light = {
    bg               = "#ffffff",
    fg               = "#202020",
    surface          = "#fafafd",
    elevated         = "#fafafd",
    float_bg         = "#fafafd",
    border           = "#f0f1f2",
    border_focus     = "#0069cc",
    text             = "#202020",
    muted            = "#606060",
    placeholder      = "#999999",
    accent           = "#0069cc",
    cursor_line      = "#fafafa",  -- #EAEAEA40 over #FFFFFF
    line_nr          = "#606060",
    line_nr_active   = "#202020",
    invisible        = "#d7d7d7",  -- #60606040 over #FFFFFF
    wrap_guide       = "#f7f7f7",
    visual           = "#bfd9f2",  -- #0069CC40 over #FFFFFF
    search           = "#e5f0fa",  -- #0069CC1A over #FFFFFF
    hl_read          = "#d9e9f7",  -- #0069CC26 over #FFFFFF
    hl_write         = "#d9e9f7",  -- #0069CC26 over #FFFFFF
    hover            = "#e6e6e9",  -- #00000014 over #FAFAFD
    active           = "#d6d6d8",  -- #00000025 over #FAFAFD
    selected         = "#d6d6d8",  -- #00000025 over #FAFAFD
    scrollbar        = "#89898a",  -- #646464C0 over #FAFAFD
    tab_active       = "#ffffff",
    tab_inactive     = "#fafafd",
    statusline       = "#fafafd",
    panel            = "#fafafd",
    cursor           = "#202020",
    added            = "#587c0c",
    changed          = "#667309",
    removed          = "#ad0707",
    renamed          = "#0451a5",
    conflict         = "#ad0707",
    error            = "#cd3131",
    warning          = "#949800",
    info             = "#0451a5",
    hint             = "#0451a5",
    success          = "#107c10",
    ignored          = "#8e8e90",
    syntax = {
      ["comment"] = { fg = "#6e7781" },
      ["comment.doc"] = { fg = "#6e7781" },
      ["keyword"] = { fg = "#cf222e" },
      ["operator"] = { fg = "#cf222e" },
      ["string"] = { fg = "#0a3069" },
      ["string.escape"] = { fg = "#116329", bold = true },
      ["string.regex"] = { fg = "#0a3069" },
      ["string.special"] = { fg = "#0a3069" },
      ["string.special.symbol"] = { fg = "#0550ae" },
      ["number"] = { fg = "#0550ae" },
      ["boolean"] = { fg = "#0550ae" },
      ["constant"] = { fg = "#0550ae" },
      ["function"] = { fg = "#8250df" },
      ["function.method"] = { fg = "#8250df" },
      ["constructor"] = { fg = "#8250df" },
      ["type"] = { fg = "#0550ae" },
      ["type.builtin"] = { fg = "#cf222e" },
      ["variable"] = { fg = "#1f2328" },
      ["variable.special"] = { fg = "#0550ae" },
      ["property"] = { fg = "#0550ae" },
      ["attribute"] = { fg = "#0550ae" },
      ["tag"] = { fg = "#116329" },
      ["title"] = { fg = "#0550ae", bold = true },
      ["emphasis"] = { fg = "#1f2328", italic = true },
      ["emphasis.strong"] = { fg = "#1f2328", bold = true },
      ["link_uri"] = { fg = "#0a3069" },
      ["link_text"] = { fg = "#0a3069" },
      ["punctuation"] = { fg = "#1f2328" },
      ["punctuation.bracket"] = { fg = "#1f2328" },
      ["punctuation.delimiter"] = { fg = "#1f2328" },
      ["punctuation.list_marker"] = { fg = "#953800" },
      ["punctuation.special"] = { fg = "#cf222e" },
      ["preproc"] = { fg = "#cf222e" },
      ["enum"] = { fg = "#0550ae" },
      ["variant"] = { fg = "#0550ae" },
      ["label"] = { fg = "#0550ae" },
      ["predictive"] = { fg = "#6e7781" },
      ["hint"] = { fg = "#6e7781" },
      ["primary"] = { fg = "#1f2328" },
    },
    terminal = {
      [0] = "#000000",
      [1] = "#cd3131",
      [2] = "#107c10",
      [3] = "#949800",
      [4] = "#0451a5",
      [5] = "#bc05bc",
      [6] = "#0598bc",
      [7] = "#555555",
      [8] = "#666666",
      [9] = "#cd3131",
      [10] = "#14ce14",
      [11] = "#b5ba00",
      [12] = "#0451a5",
      [13] = "#bc05bc",
      [14] = "#0598bc",
      [15] = "#a5a5a5",
    },
  },
}

-- `p.syntax` is keyed by Zed's scope names, so every highlight below traces
-- back to a line in the JSON rather than to a colour picked here.
local function groups(p)
  local s = p.syntax

  return {
    -- Editor chrome
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.float_bg },
    FloatBorder = { fg = p.border, bg = p.float_bg },
    FloatTitle = { fg = p.text, bg = p.float_bg, bold = true },
    ColorColumn = { bg = p.surface },
    Conceal = { fg = p.muted },
    Cursor = { fg = p.bg, bg = p.cursor },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { link = "Cursor" },
    CursorColumn = { bg = p.cursor_line },
    CursorLine = { bg = p.cursor_line },
    CursorLineNr = { fg = p.line_nr_active, bold = true },
    LineNr = { fg = p.line_nr },
    LineNrAbove = { link = "LineNr" },
    LineNrBelow = { link = "LineNr" },
    SignColumn = { bg = p.bg },
    FoldColumn = { fg = p.muted, bg = p.bg },
    Folded = { fg = p.muted, bg = p.surface },
    Directory = { fg = p.accent },
    EndOfBuffer = { fg = p.bg },
    ErrorMsg = { fg = p.error, bold = true },
    WarningMsg = { fg = p.warning },
    ModeMsg = { fg = p.fg, bold = true },
    MoreMsg = { fg = p.accent },
    MsgArea = { fg = p.fg },
    MsgSeparator = { fg = p.border },
    Question = { fg = p.accent },
    NonText = { fg = p.invisible },
    Whitespace = { fg = p.invisible },
    SpecialKey = { fg = p.invisible },
    MatchParen = { fg = p.warning, bold = true },
    Search = { fg = p.fg, bg = p.search },
    IncSearch = { fg = p.bg, bg = p.accent },
    CurSearch = { fg = p.bg, bg = p.accent },
    Substitute = { fg = p.bg, bg = p.removed },
    Visual = { bg = p.visual },
    VisualNOS = { bg = p.visual },
    WinSeparator = { fg = p.border, bg = p.bg },
    VertSplit = { link = "WinSeparator" },
    QuickFixLine = { bg = p.selected },
    WildMenu = { bg = p.selected },
    Title = s["title"],

    -- Statusline, tabline, winbar
    StatusLine = { fg = p.text, bg = p.statusline },
    StatusLineNC = { fg = p.muted, bg = p.statusline },
    TabLine = { fg = p.muted, bg = p.tab_inactive },
    TabLineFill = { bg = p.surface },
    TabLineSel = { fg = p.text, bg = p.tab_active },
    WinBar = { fg = p.text, bg = p.bg },
    WinBarNC = { fg = p.muted, bg = p.bg },

    -- Completion / popup menu
    Pmenu = { fg = p.text, bg = p.elevated },
    PmenuSel = { bg = p.selected },
    PmenuKind = { fg = p.accent, bg = p.elevated },
    PmenuKindSel = { fg = p.accent, bg = p.selected },
    PmenuExtra = { fg = p.muted, bg = p.elevated },
    PmenuExtraSel = { fg = p.muted, bg = p.selected },
    PmenuSbar = { bg = p.elevated },
    PmenuThumb = { bg = p.scrollbar },

    -- Spelling
    SpellBad = { sp = p.error, undercurl = true },
    SpellCap = { sp = p.warning, undercurl = true },
    SpellLocal = { sp = p.info, undercurl = true },
    SpellRare = { sp = p.hint, undercurl = true },

    -- Legacy syntax groups. These matter for every buffer without a treesitter
    -- parser (and for :Man, fugitive, and friends), so they are mapped from the
    -- same scopes as the @-captures rather than left to Neovim's defaults.
    Comment = s["comment"],
    SpecialComment = s["comment.doc"],
    Constant = s["constant"],
    String = s["string"],
    Character = s["string"],
    Number = s["number"],
    Float = s["number"],
    Boolean = s["boolean"],
    Identifier = s["variable"],
    Function = s["function"],
    Statement = s["keyword"],
    Conditional = s["keyword"],
    Repeat = s["keyword"],
    Exception = s["keyword"],
    Keyword = s["keyword"],
    Label = s["label"],
    Operator = s["operator"],
    PreProc = s["preproc"],
    Include = s["preproc"],
    Define = s["preproc"],
    Macro = s["preproc"],
    PreCondit = s["preproc"],
    Type = s["type"],
    StorageClass = s["type"],
    Structure = s["type"],
    Typedef = s["type"],
    Special = s["punctuation.special"],
    SpecialChar = s["string.escape"],
    Tag = s["tag"],
    Delimiter = s["punctuation.delimiter"],
    Debug = s["punctuation.special"],
    Underlined = { fg = p.accent, underline = true },
    Bold = { bold = true },
    Italic = { italic = true },
    Ignore = { fg = p.ignored },
    Error = { fg = p.error },
    Todo = { fg = p.bg, bg = p.warning, bold = true },

    -- Treesitter captures
    ["@comment"] = s["comment"],
    ["@comment.documentation"] = s["comment.doc"],
    ["@comment.error"] = { fg = p.error },
    ["@comment.warning"] = { fg = p.warning },
    ["@comment.note"] = { fg = p.info },
    ["@comment.todo"] = { link = "Todo" },
    ["@keyword"] = s["keyword"],
    ["@keyword.function"] = s["keyword"],
    ["@keyword.operator"] = s["operator"],
    ["@keyword.return"] = s["keyword"],
    ["@keyword.conditional"] = s["keyword"],
    ["@keyword.repeat"] = s["keyword"],
    ["@keyword.exception"] = s["keyword"],
    ["@keyword.import"] = s["preproc"],
    ["@keyword.directive"] = s["preproc"],
    ["@operator"] = s["operator"],
    ["@string"] = s["string"],
    ["@string.escape"] = s["string.escape"],
    ["@string.regexp"] = s["string.regex"],
    ["@string.special"] = s["string.special"],
    ["@string.special.symbol"] = s["string.special.symbol"],
    ["@string.special.url"] = s["link_uri"],
    ["@character"] = s["string"],
    ["@character.special"] = s["string.escape"],
    ["@number"] = s["number"],
    ["@number.float"] = s["number"],
    ["@boolean"] = s["boolean"],
    ["@constant"] = s["constant"],
    ["@constant.builtin"] = s["constant"],
    ["@constant.macro"] = s["preproc"],
    ["@function"] = s["function"],
    ["@function.builtin"] = s["function"],
    ["@function.call"] = s["function"],
    ["@function.macro"] = s["preproc"],
    ["@function.method"] = s["function.method"],
    ["@function.method.call"] = s["function.method"],
    ["@constructor"] = s["constructor"],
    ["@type"] = s["type"],
    ["@type.builtin"] = s["type.builtin"],
    ["@type.definition"] = s["type"],
    ["@variable"] = s["variable"],
    ["@variable.builtin"] = s["variable.special"],
    ["@variable.parameter"] = s["variable"],
    ["@variable.member"] = s["property"],
    ["@property"] = s["property"],
    ["@field"] = s["property"],
    ["@attribute"] = s["attribute"],
    ["@tag"] = s["tag"],
    ["@tag.builtin"] = s["tag"],
    ["@tag.attribute"] = s["attribute"],
    ["@tag.delimiter"] = s["punctuation.bracket"],
    ["@module"] = s["type"],
    ["@label"] = s["label"],
    ["@preproc"] = s["preproc"],
    ["@punctuation"] = s["punctuation"],
    ["@punctuation.bracket"] = s["punctuation.bracket"],
    ["@punctuation.delimiter"] = s["punctuation.delimiter"],
    ["@punctuation.special"] = s["punctuation.special"],

    -- Treesitter markup (render-markdown, obsidian, help buffers)
    ["@markup"] = s["primary"],
    ["@markup.heading"] = s["title"],
    ["@markup.strong"] = s["emphasis.strong"],
    ["@markup.italic"] = s["emphasis"],
    ["@markup.strikethrough"] = { fg = p.muted, strikethrough = true },
    ["@markup.underline"] = { link = "Underlined" },
    ["@markup.link"] = s["link_text"],
    ["@markup.link.url"] = s["link_uri"],
    ["@markup.link.label"] = s["link_text"],
    ["@markup.list"] = s["punctuation.list_marker"],
    ["@markup.list.checked"] = { fg = p.success },
    ["@markup.list.unchecked"] = { fg = p.muted },
    ["@markup.raw"] = s["string"],
    ["@markup.quote"] = s["comment"],
    ["@markup.math"] = s["number"],
    ["@diff.plus"] = { fg = p.added },
    ["@diff.minus"] = { fg = p.removed },
    ["@diff.delta"] = { fg = p.changed },

    -- LSP semantic tokens. Zed's `enum`/`variant` scopes have no treesitter
    -- capture, so semantic tokens are where those two colours actually land.
    ["@lsp.type.class"] = s["type"],
    ["@lsp.type.enum"] = s["enum"],
    ["@lsp.type.enumMember"] = s["variant"],
    ["@lsp.type.interface"] = s["type"],
    ["@lsp.type.struct"] = s["type"],
    ["@lsp.type.macro"] = s["preproc"],
    ["@lsp.type.method"] = s["function.method"],
    ["@lsp.type.namespace"] = s["type"],
    ["@lsp.type.parameter"] = s["variable"],
    ["@lsp.type.property"] = s["property"],
    ["@lsp.type.variable"] = s["variable"],
    ["@lsp.type.type"] = s["type"],
    ["@lsp.type.typeParameter"] = s["type"],
    ["@lsp.type.decorator"] = s["attribute"],

    -- Diagnostics
    DiagnosticError = { fg = p.error },
    DiagnosticWarn = { fg = p.warning },
    DiagnosticInfo = { fg = p.info },
    DiagnosticHint = { fg = p.hint },
    DiagnosticOk = { fg = p.success },
    DiagnosticVirtualTextError = { fg = p.error },
    DiagnosticVirtualTextWarn = { fg = p.warning },
    DiagnosticVirtualTextInfo = { fg = p.info },
    DiagnosticVirtualTextHint = { fg = p.hint },
    DiagnosticVirtualTextOk = { fg = p.success },
    DiagnosticUnderlineError = { sp = p.error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = p.warning, undercurl = true },
    DiagnosticUnderlineInfo = { sp = p.info, undercurl = true },
    DiagnosticUnderlineHint = { sp = p.hint, undercurl = true },
    DiagnosticUnderlineOk = { sp = p.success, undercurl = true },
    DiagnosticSignError = { fg = p.error, bg = p.bg },
    DiagnosticSignWarn = { fg = p.warning, bg = p.bg },
    DiagnosticSignInfo = { fg = p.info, bg = p.bg },
    DiagnosticSignHint = { fg = p.hint, bg = p.bg },
    DiagnosticUnnecessary = { fg = p.ignored },
    DiagnosticDeprecated = { fg = p.ignored, strikethrough = true },

    -- LSP
    LspReferenceText = { bg = p.hl_read },
    LspReferenceRead = { bg = p.hl_read },
    LspReferenceWrite = { bg = p.hl_write },
    LspInlayHint = { fg = p.muted, bg = p.surface },
    LspSignatureActiveParameter = { fg = p.accent, bold = true },
    LspCodeLens = { fg = p.muted },
    LspInfoBorder = { fg = p.border, bg = p.float_bg },

    -- Diff and git. The JSON gives only foregrounds for created/modified/
    -- deleted (its *.background keys are all just the panel surface), so signs
    -- and diff text are tinted rather than block-filled.
    DiffAdd = { fg = p.added },
    DiffChange = { fg = p.changed },
    DiffDelete = { fg = p.removed },
    DiffText = { fg = p.changed, bold = true },
    diffAdded = { fg = p.added },
    diffRemoved = { fg = p.removed },
    diffChanged = { fg = p.changed },
    diffNewFile = { fg = p.added },
    diffOldFile = { fg = p.removed },
    diffFile = { fg = p.accent },
    diffLine = { fg = p.muted },
    diffIndexLine = { fg = p.muted },
    GitSignsAdd = { fg = p.added, bg = p.bg },
    GitSignsChange = { fg = p.changed, bg = p.bg },
    GitSignsDelete = { fg = p.removed, bg = p.bg },
    GitSignsAddLn = { bg = p.hl_read },
    GitSignsChangeLn = { bg = p.hl_read },
    GitSignsDeleteLn = { bg = p.hl_read },
    GitSignsCurrentLineBlame = { fg = p.muted, italic = true },
    GitBlameVirtualText = { fg = p.muted, italic = true },

    -- Telescope
    TelescopeNormal = { fg = p.fg, bg = p.float_bg },
    TelescopeBorder = { fg = p.border, bg = p.float_bg },
    TelescopeTitle = { fg = p.text, bold = true },
    TelescopePromptNormal = { fg = p.fg, bg = p.elevated },
    TelescopePromptBorder = { fg = p.border, bg = p.elevated },
    TelescopePromptTitle = { fg = p.bg, bg = p.accent, bold = true },
    TelescopePromptPrefix = { fg = p.accent },
    TelescopePromptCounter = { fg = p.muted },
    TelescopeResultsTitle = { fg = p.border, bg = p.border },
    TelescopePreviewTitle = { fg = p.bg, bg = p.accent, bold = true },
    TelescopeSelection = { fg = p.text, bg = p.selected },
    TelescopeSelectionCaret = { fg = p.accent, bg = p.selected },
    TelescopeMultiSelection = { fg = p.accent },
    TelescopeMatching = { fg = p.accent, bold = true },

    -- Neo-tree
    NeoTreeNormal = { fg = p.text, bg = p.panel },
    NeoTreeNormalNC = { fg = p.text, bg = p.panel },
    NeoTreeWinSeparator = { fg = p.border, bg = p.panel },
    NeoTreeEndOfBuffer = { fg = p.panel, bg = p.panel },
    NeoTreeCursorLine = { bg = p.selected },
    NeoTreeRootName = { fg = p.text, bold = true },
    NeoTreeTitleBar = { fg = p.bg, bg = p.accent },
    NeoTreeDirectoryName = { fg = p.accent },
    NeoTreeDirectoryIcon = { fg = p.accent },
    NeoTreeFileName = { fg = p.text },
    NeoTreeFileIcon = { fg = p.muted },
    NeoTreeFileNameOpened = { fg = p.text, bold = true },
    NeoTreeIndentMarker = { fg = p.border },
    NeoTreeExpander = { fg = p.muted },
    NeoTreeDimText = { fg = p.placeholder },
    NeoTreeGitAdded = { fg = p.added },
    NeoTreeGitModified = { fg = p.changed },
    NeoTreeGitDeleted = { fg = p.removed },
    NeoTreeGitRenamed = { fg = p.renamed },
    NeoTreeGitConflict = { fg = p.conflict },
    NeoTreeGitIgnored = { fg = p.ignored },
    NeoTreeGitUntracked = { fg = p.muted },

    -- Oil
    OilDir = { fg = p.accent },
    OilDirIcon = { fg = p.accent },
    OilFile = { fg = p.text },
    OilLink = { fg = p.accent, underline = true },
    OilLinkTarget = { fg = p.muted },
    OilCreate = { fg = p.added },
    OilDelete = { fg = p.removed },
    OilMove = { fg = p.changed },
    OilCopy = { fg = p.renamed },

    -- nvim-cmp
    CmpItemAbbr = { fg = p.text },
    CmpItemAbbrDeprecated = { fg = p.muted, strikethrough = true },
    CmpItemAbbrMatch = { fg = p.accent, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = p.accent },
    CmpItemMenu = { fg = p.muted },
    CmpItemKindDefault = { fg = p.muted },
    CmpItemKindText = { fg = p.text },
    CmpItemKindKeyword = s["keyword"],
    CmpItemKindVariable = s["variable"],
    CmpItemKindConstant = s["constant"],
    CmpItemKindFunction = s["function"],
    CmpItemKindMethod = s["function.method"],
    CmpItemKindConstructor = s["constructor"],
    CmpItemKindClass = s["type"],
    CmpItemKindInterface = s["type"],
    CmpItemKindStruct = s["type"],
    CmpItemKindEnum = s["enum"],
    CmpItemKindEnumMember = s["variant"],
    CmpItemKindField = s["property"],
    CmpItemKindProperty = s["property"],
    CmpItemKindModule = s["type"],
    CmpItemKindSnippet = { fg = p.added },

    -- dashboard-nvim
    DashboardHeader = { fg = p.accent },
    DashboardFooter = { fg = p.muted },
    DashboardDesc = { fg = p.text },
    DashboardKey = { fg = p.changed },
    DashboardIcon = { fg = p.accent },
    DashboardShortCut = { fg = p.muted },

    -- render-markdown
    RenderMarkdownH1Bg = { bg = p.surface },
    RenderMarkdownH2Bg = { bg = p.surface },
    RenderMarkdownH3Bg = { bg = p.surface },
    RenderMarkdownH4Bg = { bg = p.surface },
    RenderMarkdownH5Bg = { bg = p.surface },
    RenderMarkdownH6Bg = { bg = p.surface },
    RenderMarkdownCode = { bg = p.surface },
    RenderMarkdownCodeInline = { fg = s["string"].fg, bg = p.surface },
    RenderMarkdownBullet = s["punctuation.list_marker"],
    RenderMarkdownQuote = s["comment"],
    RenderMarkdownDash = { fg = p.border },
    RenderMarkdownLink = s["link_text"],
    RenderMarkdownTableHead = { fg = p.muted },
    RenderMarkdownTableRow = { fg = p.muted },

    -- supermaven inline suggestions
    SupermavenSuggestion = s["predictive"],
  }
end

-- The groups each surface paints, dropped to `bg = "NONE"` when that surface is
-- transparent. Kept as a list rather than threaded through `groups()`, so the
-- palette stays the single description of what a surface looks like when it IS
-- painted, and switching transparency off needs no second set of colours.
--
-- Only groups that carry their own `bg` appear here. Linked groups (VertSplit,
-- lCursor) are deliberately absent: writing a `bg` onto a link would break it.
local transparent_groups = {
  editor = {
    "Normal", "NormalNC", "SignColumn", "FoldColumn", "EndOfBuffer",
    "WinSeparator", "WinBar", "WinBarNC",
    "DiagnosticSignError", "DiagnosticSignWarn",
    "DiagnosticSignInfo", "DiagnosticSignHint",
    "GitSignsAdd", "GitSignsChange", "GitSignsDelete",
  },
  chrome = {
    "StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "TabLineSel",
  },
  sidebar = {
    "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeWinSeparator",
    "NeoTreeEndOfBuffer",
  },
  floats = {
    "NormalFloat", "FloatBorder", "FloatTitle",
    "Pmenu", "PmenuKind", "PmenuExtra", "PmenuSbar",
    "TelescopeNormal", "TelescopeBorder",
    "TelescopePromptNormal", "TelescopePromptBorder",
    "LspInfoBorder",
  },
}

-- variant is "dark" or "light"; anything else falls back to dark.
function M.load(variant)
  local name = variant == "light" and "light" or "dark"
  local p = palettes[name]

  if vim.g.colors_name then
    vim.cmd("highlight clear")
  end
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.o.background = name
  -- Set after `highlight clear`, which wipes colors_name.
  vim.g.colors_name = "vscode-" .. name .. "-2026"

  local hl = groups(p)

  for surface, surface_groups in pairs(transparent_groups) do
    if M.transparent[surface] then
      for _, group in ipairs(surface_groups) do
        -- `tbl_extend` rather than an in-place write: several entries share one
        -- palette table (`s["comment"]` backs both Comment and @comment), and
        -- mutating in place would leak the change into every alias.
        hl[group] = vim.tbl_extend("force", hl[group], { bg = "NONE" })
      end
    end
  end

  for group, spec in pairs(hl) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Keeps :terminal splits on the same 16 colours Ghostty renders.
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = p.terminal[i]
  end
end

return M
