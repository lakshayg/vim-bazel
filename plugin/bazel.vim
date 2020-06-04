function! bazel#PathRelativeToWsRoot(path)
  let l:full_path = fnamemodify(a:path, ":p")
  " cd into the WORKSPACE root
  exe "cd" fnamemodify(findfile("WORKSPACE", ".;"), ":p:h")
  " get path to file relative to current dir (WORKSPACE root)
  let l:rel_path = fnamemodify(l:full_path, ":.")
  cd -
  return l:rel_path
endfunction


function! bazel#Target(fname)
  let l:build_file_path = findfile("BUILD", ".;")
  let l:relative_path = bazel#PathRelativeToWsRoot(l:build_file_path)
  let l:package_path = fnamemodify(l:relative_path, ":h")
  let l:package_spec = "//" . l:package_path . "/..."

  let l:bazel_query_cmd = [
        \ "bazel", "query",
        \ "'kind(rule, rdeps(" . l:package_spec . ", " . a:fname . ", 1))'",
        \ "2> /dev/null"
        \ ]

  echo join(l:bazel_query_cmd)
  return systemlist(join(l:bazel_query_cmd))
endfunction


function! bazel#BuildOrTestCommand(cmd)
  return a:cmd + ['--noshow_timestamps']
endfunction


function! bazel#BuildOrTestTargets(targets)
  if !empty(a:targets)
    return a:targets
  endif

  let l:fname = expand("%")

  " Is the current file a BUILD file?
  if fnamemodify(l:fname, ":t") == "BUILD"
    let l:rel_path = bazel#PathRelativeToWsRoot(l:fname)
    let l:package_path = fnamemodify(l:rel_path, ":h")
    return ["//" . l:package_path . ":all"]
  endif

  " Assume that the current file is a source file
  let l:targets = bazel#Target(l:fname)
  echo "Target: " . join(l:targets)
  return l:targets
endfunction


function! bazel#Execute(action, ...)
  compiler bazel
  let l:cmd = [a:action]
  " We currently do not support flags passed by the
  " user and assume that all the varargs are targets
  let l:targets = a:000

  " Special handling is required for build and test because we want
  " to support reading errors into the quickfix list and triggering
  " build/test for current file if targets are left unspecified
  if a:action == "build" || a:action == "test"
    let l:cmd = bazel#BuildOrTestCommand(l:cmd)
    let l:targets = bazel#BuildOrTestTargets(l:targets)
  endif

  exe "make" join(l:cmd + l:targets)
endfunction


command! -nargs=+ Bazel :call bazel#Execute(<f-args>)

" Test cases
" ==============================================================================
" * Build/test current file without passing args to Bazel build/test
" * Build/test current file when pwd is not the bazel project root
" * Build/test another file by passing args to Bazel build/test
" * Build/test from a BUILD file
" * Bazel run a binary
