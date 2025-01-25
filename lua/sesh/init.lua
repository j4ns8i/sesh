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

function M.get_default_session_file()
  local encoded_pwd = vim.env.PWD:gsub("/", "%%")
  return vim.fn.stdpath("state") .. "/sesh/" .. encoded_pwd .. ".vim"
end

function M.get_session_file()
  return M.config.session_file
end

function M.deactivate()
  vim.api.nvim_del_augroup_by_name(M.augroup_name)
  set_g("enabled", false)
end

function M.activate()
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
    M.deactivate()
  else
    M.activate()
  end
end

function M.save_session()
  vim.cmd("mksession! " .. vim.fn.fnameescape(M.config.session_file))
end

---@class Config
---@field session_file string The path of the Session file.

---@type Config
M.config = get_g("config") or {
  session_file = M.get_default_session_file(),
}

M.augroup_name = "Sesh"

local function create_user_commands()
  vim.api.nvim_create_user_command("SeshFile", function() print(M.get_session_file()) end, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshDeactivate", M.deactivate, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshActivate", M.activate, { nargs = 0 })
  vim.api.nvim_create_user_command("SeshToggle", M.toggle, { nargs = 0 })
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

  M.config = vim.tbl_deep_extend("force", M.config, opts)

  if using_session_arg then
    -- Using vim -S takes precedence over this plugin's session_file opt
    M.config.session_file = vim.v.this_session
  else
    if vim.uv.fs_stat(M.config.session_file) ~= nil then
      vim.cmd("source " .. vim.fn.fnameescape(M.config.session_file))
    end
  end

  local using_default_session = M.config.session_file == M.get_default_session_file()
  if using_default_session then
    vim.uv.fs_mkdir(vim.fs.dirname(M.config.session_file), 493)
  end

  create_user_commands()
  M.activate()
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
      nested = true,
    })
  end
end

return M
