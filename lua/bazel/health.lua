local M = {}
M.check = function()
  if vim.fn.executable("bazel") == 1 then
    vim.health.ok("bazel is installed")
  else
    vim.health.error("bazel is NOT installed")
  end

  local bazel_bash_completion_path = vim.g["bazel_bash_completion_path"]
  if bazel_bash_completion_path ~= nil then
    if vim.fn.filereadable(bazel_bash_completion_path) == 1 then
      vim.health.ok(string.format("Found bazel bash completion script at: %s", bazel_bash_completion_path))
    else
      vim.health.error(
        string.format("g:bazel_bash_completion_path (%s) does NOT exist", bazel_bash_completion_path), {
          "Ensure that g:bazel_bash_completion_path points to a valid file",
          "unset g:bazel_bash_completion_path and let the plugin find the completion script"
        })
    end
  else
    vim.health.warn(
      "A bazel bash completion script was not found", {
        "See https://bazel.build/install/completion for instructions on locating the completion script",
        "Set g:bazel_bash_completion_path to point to the completion script"
      })
  end

  local bazel_make_command = vim.g["bazel_make_command"]
  if bazel_make_command ~= nil then
    vim.health.info(string.format("g:bazel_make_command is set (%s)", bazel_make_command))
  else
    vim.health.info("g:bazel_make_command is NOT set (builds will be synchronous)")
  end
end
return M
