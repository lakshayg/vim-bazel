function! health#bazel#check() abort
  if executable('bazel')
    call health#report_ok("bazel is installed")
  else
    call health#report_error("bazel is NOT installed")
  endif

  if exists('g:bazel_make_command')
    call health#report_info(printf("g:bazel_make_command is set (%s)", g:bazel_make_command))
  else
    call health#report_info("g:bazel_make_command is NOT set (builds will be synchronous)")
  endif
endfunction
