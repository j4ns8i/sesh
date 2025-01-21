local M = {}

---@class Config
---@field session_file string|nil The path of the Session file. If nil, this will be saved in neovim's state directory.

---@type Config
M.config = {
  session_file = nil,
}

---@param opts Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  print("initializing with config: " .. vim.inspect(M.config))

  -- If a session file was specified, use that instead of the session_file opt
  if vim.g.SessionLoad == 1 then
    print("SessionLoad is set")
  end

  if vim.v.this_session ~= "" then
    print("session: " .. vim.v.this_session)
    M.config.session_file = vim.v.this_session
  end

  if vim.v.this_session == "" and #vim.fn.argv() > 0 then
    -- If files were given as arguments, don't activate.
    -- Only check this if a session file wasn't specified because session files
    -- are just vim scripts that add call :addarg to restore files.
    print("files given as arguments, exiting...")
  end

  print("initialized with config: " .. vim.inspect(M.config))
end

return M
