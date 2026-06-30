# Decisions

## 2026-06-25

- Preserve multiline bracketed pastes in `zsh/plugins/custom/safe-paste.zsh`.
- Rationale: converting pasted newlines to spaces breaks common workflows where a multi-line command block should stay multi-line before execution.
- Effect: pasted command blocks keep their line structure; CRLF input is normalized to LF.
