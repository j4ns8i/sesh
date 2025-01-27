# Sesh

Sesh is designed to manage neovim sessions out of the box with little
configuration.

It automatically records your sessions in `~/.local/state/nvim/sesh/` and will
automatically restore them when `vim` is launched with no file arguments. If
file arguments are provided, you can control whether to never create
a session, create a session only if one doesn't already exist, or always
overwrite any pre-existing sessions with `on_file_arguments`.

This plugin is built off of Neovim's native sessions (see `:h Session`). By
default, these litter your filesystem and require diligent `:mksession` and `vim
-S` usage. Sesh is designed to handle this automatically and store sessions
named after your current directory.

## Features

* Opening vim without arguments restores your last session from that directory.
* Sessions are automatically saved on every buffer added or deleted, on every
  window opened or closed, and on exit.
* Session files are automatically saved under Neovim's state directory so you
  don't have to add it to a .gitignore or stow it away yourself.
