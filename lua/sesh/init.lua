-- bug: argument to vim -S is overridden by plugin session_file opt if set
-- bug: if session_file opt is set, session is created but not updated
local M = {}

---Get a global variable set by this plugin; these variables are prefixed with
---"sesh#".
---@param name string The name of the global variable to get
local function get_g(name)
  return vim.g["sesh#" .. name]
end

---Set a global variable set by this plugin; these variables are prefixed with
---"sesh#". Any previous values are overridden.
---@param name string The name of the global variable to set
---@param value any The value to set the global variable to
local function set_g(name, value)
  vim.g["sesh#" .. name] = value
end

---@class Config
---@field session_file string|nil The path of the Session file. If nil, this will be saved in neovim's state directory.

---@type Config
M.config = get_g("config") or {
  session_file = nil,
}

M.augroup_name = "Sesh"

local function register_user_commands()
  vim.api.nvim_create_user_command("SeshFile", function() print(M.get_session_file()) end, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshDisable", M.disable, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshEnable", M.enable, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshToggle", M.toggle, { nargs = 0 })
end

local function setup_default_session()
  if vim.uv.fs_stat(M.config.session_file) ~= nil then
    vim.cmd("source " .. vim.fn.fnameescape(M.config.session_file))
  else
    local session_dir = vim.fs.dirname(M.config.session_file)
    vim.uv.fs_mkdir(session_dir, 493)
  end
end

local function init(opts)
  -- If a session file was specified, use that instead of the session_file opt
  if vim.g.SessionLoad == 1 then
    print("SessionLoad is set")
  end

  local using_session_arg = vim.v.this_session ~= ""
  if #vim.fn.argv() > 0 and not using_session_arg then
    -- If files were given as arguments, don't activate.
    -- Only check this if a session arg wasn't specified because session files
    -- are just vim scripts that add call :addarg to restore files.
    -- TODO: activate if no existing session exists
    print("files given as arguments, exiting...")
    return
  end

  if using_session_arg then
    M.config.session_file = vim.v.this_session
  else
    local session_file = M.get_default_session_file()
    M.config.session_file = session_file
  end

  M.config = vim.tbl_deep_extend("force", M.config, opts)

  local using_default_session = not using_session_arg and (opts.session_file == nil or opts.session_file == "")
  if using_default_session then
    setup_default_session()
  end

  register_user_commands()
  M.enable()
end

---@param opts Config
function M.setup(opts)
  if get_g("loaded") then
    return
  end
  set_g("loaded", true)

  if vim.g.did_vim_enter == 1 then
    -- Initialize now
    init(opts)
  else
    -- Initialize after VimEnter
    local augroup_name = M.augroup_name .. "Init"
    vim.api.nvim_create_autocmd({ "VimEnter", }, {
      group = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
      callback = function()
        init(opts)
      end,
    })
  end
end

function M.get_default_session_file()
  local encoded_pwd = vim.env.PWD:gsub("/", "%%")
  return vim.fn.stdpath("state") .. "/sesh/" .. encoded_pwd .. ".vim"
end

function M.get_session_file()
  return M.config.session_file
end

function M.disable()
  vim.api.nvim_del_augroup_by_name(M.augroup_name)
  set_g("enabled", false)
end

function M.enable()
  local augroup_id = vim.api.nvim_create_augroup(M.augroup_name, { clear = true })
  vim.api.nvim_create_autocmd({
    "BufAdd", "BufDelete",
    "WinNew", "WinClosed",
    "ExitPre",
  }, {
    group = augroup_id,
    callback = M.save_session,
  })
  set_g("enabled", true)
end

function M.toggle()
  if get_g("enabled") then
    M.disable()
  else
    M.enable()
  end
end

function M.save_session()
  print("saving session " .. vim.fn.fnameescape(M.config.session_file))
  vim.cmd("mksession! " .. vim.fn.fnameescape(M.config.session_file))
end

return M
