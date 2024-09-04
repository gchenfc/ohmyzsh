
# Commands: https://web.cs.elte.hu/local/texinfo/zsh/zsh_10.html
# Hex Codes:  https://www.csee.umbc.edu/portal/help/theory/ascii.txt
# Useful examples:
#   ^[ is escape
#   ^? is backspace
#   ^letter is control then letter
#       In the Hex Codes site, C-letter means control-letter, so anytime the shortcut is ^letter,
#       then use the hex code for C-letter.
# In iTerm, go to
#   Preferences -> Profiles -> My keyboard shortcuts -> keys
# In vscode, go to
#   "Preferences: Open Keyboard Shortcuts (JSON)"
# and make an entry of the form:
#   {
#     "key": "<KEY BINDING>",
#     "command": "workbench.action.terminal.sendSequence",
#     "when": "terminalFocus",
#     "args": {
#         "text": "<HEX CODE IN THE FORM \u00XX>"
#     }
#   },

bindkey "^U" backward-kill-line

# type command in editor
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
