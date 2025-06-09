-- aider-addons.lua: Provides undo-based diff and revert utilities using UndoTree
local Diff = {}

-- state table to hold buffer references
local state = {
  buffers = {
    curr = nil,
    prev = nil
  },
  window_ids = {
    curr = nil,
    prev = nil,
  },
  prev_seq = nil,
}

local config = {
  keymaps = {
    close = "ga",
    undo = "gr",
  },
  confirm_revert = true, -- Whether to confirm before reverting
}

local function foreach_buf(cb)
  for name, bufnr in pairs(state.buffers) do
    cb(name, bufnr)
  end
end

function Diff.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(config), opts or {})
end

-- Diff current buffer with previous undo state
function Diff.diff_with_previous_undo()
  local current_file = vim.fn.expand('%:p')
  if current_file == '' then
    vim.notify("No file open in current buffer.", vim.log.levels.ERROR)
    return
  end

  -- Check if there's undo history available
  if vim.fn.undotree().seq_cur <= 1 then
    vim.notify("No previous undo state available.", vim.log.levels.ERROR)
    return
  end

  -- Save current buffer state and position
  state.buffers.curr = vim.api.nvim_get_current_buf()
  state.window_ids.curr = vim.api.nvim_get_current_win()

  -- Create a new buffer for the previous version
  vim.cmd('vnew')
  state.buffers.prev = vim.api.nvim_get_current_buf()
  state.window_ids.prev = vim.api.nvim_get_current_win()

  -- Temporarily go back to get previous content without affecting original buffer
  vim.api.nvim_set_current_buf(state.buffers.curr)
  vim.cmd('silent! undo')
  local prev_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  state.prev_seq = vim.fn.changenr()
  vim.cmd('silent! redo') -- Restore to current state

  -- Put previous content in the new buffer
  vim.api.nvim_set_current_buf(state.buffers.prev)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, prev_content)
  vim.bo.buftype = 'nofile'
  vim.bo.filetype = vim.bo[state.buffers.curr].filetype

  -- Mark this as our undo diff buffer
  vim.api.nvim_buf_set_var(state.buffers.prev, 'aider_undo_diff_buffer', true)

  -- Start diff mode
  vim.cmd('diffthis')
  vim.api.nvim_set_current_win(state.window_ids.curr) -- Switch back to original buffer
  vim.cmd('diffthis')

  -- Set up keymap to close diff (only for these buffers)
  foreach_buf(
    function(_, bufnr)
      local opts_close = { buffer = bufnr, silent = true, desc = "Close diff split buffer" }
      vim.keymap.set('n', config.keymaps.close, function()
        Diff.close_undo_diff()
      end, opts_close)

      local opts_undo = vim.tbl_deep_extend('force', opts_close, { desc = "Revert to previous state" })
      vim.keymap.set('n', config.keymaps.undo, function()
        Diff.revert_to_previous_undo()
      end, opts_undo)
    end
  )
end

-- Revert to previous undo state
function Diff.revert_to_previous_undo()
  if config.confirm_revert then
    local confirm = vim.fn.confirm(
      "Revert to previous undo state?",
      "&Yes\n&No", 2, "Warning"
    )
    if confirm ~= 1 then
      vim.notify("Revert cancelled.", vim.log.levels.INFO)
      return
    end
  end

  vim.api.nvim_set_current_win(state.window_ids.curr) -- Switch back to original buffer
  vim.cmd('silent! undo ' .. state.prev_seq)

  Diff.close_undo_diff()
end

-- Close undo diff split window
function Diff.close_undo_diff()
  -- Turn off diff mode for all windows
  vim.cmd('diffoff!')
  state.prev_seq = nil

  -- Close only our marked undo diff buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local ok, is_undo_diff = pcall(vim.api.nvim_buf_get_var, bufnr, 'aider_undo_diff_buffer')
      if ok and is_undo_diff then
        -- Find windows showing this buffer and close them
        for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
          if vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_win_close(winid, false)
          end
        end
        -- Delete the buffer
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
  end
end

return Diff
