# Aider Addons

A collection of Neovim plugins that enhance the [aider](https://github.com/paul-gauthier/aider) AI pair programming experience.

## Features

### Diff Module
- **Undo-based diffing**: Compare your current buffer with the previous undo state
- **Visual diff**: Side-by-side comparison using Neovim's built-in diff mode

### Commit Message Module
- **AI-generated commit messages**: Automatically generate conventional commit messages based **only** on staged changes without actually committing the changes, and directly put the generated message to the clipboard
- **Model flexibility**: Configure different AI models for commit message generation

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "iammmiru/aider-addons.nvim",
  dependencies = {
    "nvim_aider" -- Optional for using sending commit prompt to `aider`
  },
  config = function()
    require("aider-addons").setup({
      -- Configuration options (see below)
    })
  end
}
```

## Configuration

### Diff Module

```lua
require("aider-addons.diff").setup({
  keymaps = {
    close = "q",  -- Close diff split
    undo = "gr",   -- Revert to previous state
  },
  confirm_revert = true, -- Whether to confirm before reverting
})
```

### Commit Message Module

```lua
require("aider-addons.commit_message").setup({
  commit_model = "gpt-4.1",
  main_model = "claude-4",
  -- Can be any aider neovim wrapper that can send a custom message to `aider`
  send_to_aider_api = require("nvim_aider").api.send_to_terminal 
})
```

## Usage

### Diff Commands

Once configured, you can use the diff functionality:

```lua
require("aider-addons.diff").diff_with_previous_undo()
```

**Keymaps (when in diff mode):**
- `q` - Close the diff split
- `gr` - Revert to the previous undo state

### Commit Message Generation

Use the `:CommitMsg` command to generate a commit message based on your staged changes:

```vim
:CommitMsg
```

This will:
1. Switch to the configured commit model
2. Analyze your staged diff
3. Generate a conventional commit message
4. Copy the message to clipboard
5. Switch back to your main model

## Requirements

- Neovim 0.7+
- [aider](https://github.com/paul-gauthier/aider) AI pair programming tool
- `nvim_aider` (Optional) for commit message generation
- Git (for commit message functionality)

## License

MIT
