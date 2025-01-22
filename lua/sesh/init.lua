local M = {}

---@class Config
---@field session_file string|nil The path of the Session file. If nil, this will be saved in neovim's state directory.

---@type Config
M.config = {
  session_file = nil,
}

function M.augroup_name()
  return "Sesh"
end

---@param opts Config
function M.setup(opts)
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
    vim.uv.fs_mkdir(vim.fs.dirname(session_file), 0755)
    M.config.session_file = session_file
  end

  M.config = vim.tbl_deep_extend("force", M.config, opts)

  local augroup_id = vim.api.nvim_create_augroup(M.augroup_name(), { clear = true })
  vim.api.nvim_create_autocmd({
    "BufAdd", "BufDelete",
    "WinNew", "WinClosed",
    "ExitPre",
  }, {
    group = augroup_id,
    callback = M.save_session()
  })
end

function M.get_default_session_file()
  local encoded_pwd = vim.env.PWD:gsub("/", "\\%%")
  return vim.fn.stdpath("state") .. "/sesh/" .. encoded_pwd .. ".vim"
end

function M.save_session()
  vim.cmd("mksession! " .. M.config.session_file)
end

return M
