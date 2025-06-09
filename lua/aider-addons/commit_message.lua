local config = {
  commit_model = "gpt-4.1",
  main_model = "claude-4",
  send_to_aider_api = require("nvim_aider").api.send_to_terminal
}

local CommitMessage = {}

function CommitMessage.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(config), opts or {})
  vim.api.nvim_create_user_command("CommitMsg", CommitMessage.create, {})
end


function CommitMessage.create()
  local staged_diff = vim.fn.system("git diff --cached")
  local prefix = [[
  You are an expert software engineer that generates concise, \
  explanatory Git commit messages based on the provided diffs.
  Review the provided context and diffs which are about to be committed to a git repo.
  Review the diffs carefully.
  Generate a commit message for those changes.
  The commit message should be structured as follows: <type>: <description>
  Use these for <type>: fix, feat, build, chore, ci, docs, style, refactor, perf, test
  
  Ensure the commit message:
  - Starts with the appropriate prefix.
  - Is in the imperative mood (e.g., \"add feature\" not \"added feature\" or \"adding feature\").

  You don't have to write out all miscellaneous changes, e.g.,
  the content of lock files update or dependency updates,
  but focus on the main changes made in the staged files.\n
  Do not generate any files.\n
  ]]
  config.send_to_aider_api("/model " .. config.commit_model)
  config.send_to_aider_api("/ask")
  config.send_to_aider_api(prefix .. staged_diff)
  config.send_to_aider_api("/copy")
  config.send_to_aider_api("/model " .. config.main_model)
  config.send_to_aider_api("/code")
end

return CommitMessage
