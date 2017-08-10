atom.keymaps.keyBindings = atom.keymaps.keyBindings.filter(
  ({keystrokes}) -> not keystrokes.match(/ctrl-w\s/)
)
