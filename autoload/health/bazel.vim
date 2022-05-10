function! health#bazel#check() abort
  if executable('bazel')
    call health#report_ok("bazel is installed")
  else
    call health#report_error("bazel is NOT installed")
  endif

  if exists("g:bazel_bash_completion_path")
    if filereadable(g:bazel_bash_completion_path)
      call health#report_ok(printf("Found bazel bash completion script at: %s", g:bazel_bash_completion_path))
    else
      call health#report_error(
            \ printf("g:bazel_bash_completion_path (%s) does NOT exist", g:bazel_bash_completion_path),
            \ [
            \   "Ensure that g:bazel_bash_completion_path points to a valid file",
            \   "unset g:bazel_bash_completion_path and let the plugin find the completion script"
            \ ])
    endif
  else
    call health#report_warn(
          \ "A bazel bash completion script was not found",
          \ [
          \     "See https://bazel.build/install/completion for instructions on locating the completion script",
          \     "Set g:bazel_bash_completion_path to point to the completion script"
          \ ])
  endif

  if exists('g:bazel_make_command')
    call health#report_info(printf("g:bazel_make_command is set (%s)", g:bazel_make_command))
  else
    call health#report_info("g:bazel_make_command is NOT set (builds will be synchronous)")
  endif
endfunction
