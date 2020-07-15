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
  elseif a:action == "run" && len(l:targets) == 0
    let l:targets = [ bazel#Target(expand("%"))[0] ]
  endif

  exe "make" join(l:cmd + l:targets)
endfunction

" Completions for the :Bazel command {{{
let s:bazel_bash_complete_path_candidates = [
      \ "/etc/bash_completion.d/bazel",
      \ "/usr/local/lib/bazel/bin/bazel-complete.bash"
      \ ]
for f in s:bazel_bash_complete_path_candidates
  if filereadable(f)
    let g:bazel_bash_completion_path = f
  endif
endfor


" Completions are extracted from the bash bazel completion function.
" Taken from https://github.com/bazelbuild/vim-bazel/blob/master/autoload/bazel.vim
" with minor modifications
function! bazel#CompletionsFromBash(arglead, line, pos) abort
  " The bash complete script does not truly support autocompleting within a
  " word, return nothing here rather than returning bad suggestions.
  if a:pos + 1 < strlen(a:line)
    return []
  endif

  let l:cmd = substitute(a:line[0:a:pos], '\v\w+', 'bazel', '')

  let l:comp_words = split(l:cmd, '\v\s+')
  if l:cmd =~# '\v\s$'
    call add(l:comp_words, '')
  endif
  let l:comp_line = join(l:comp_words)

  " Note: Bashisms below are intentional. We invoke this via bash explicitly,
  " and it should work correctly even if &shell is actually not bash-compatible.

  " Extracts the bash completion command, should be something like:
  " _bazel__complete
  let l:complete_wrapper_command = ' $(complete -p ' . l:comp_words[0] .
      \ ' | sed "s/.*-F \\([^ ]*\\) .*/\\1/")'

  " Build a list of all the arguments that have to be passed in to autocomplete.
  let l:comp_arguments = {
      \ 'COMP_LINE' : '"' .l:comp_line . '"',
      \ 'COMP_WORDS' : '(' . l:comp_line . ')',
      \ 'COMP_CWORD' : string(len(l:comp_words) - 1),
      \ 'COMP_POINT' : string(strlen(l:comp_line)),
      \ }
  let l:comp_arguments_string =
      \ join(map(items(l:comp_arguments), 'v:val[0] . "=" . v:val[1]'))

  " Build the command to run with bash
  let l:shell_script = shellescape(printf(
      \ 'source %s; export %s; %s && echo ${COMPREPLY[*]}',
      \ g:bazel_bash_completion_path,
      \ l:comp_arguments_string,
      \ l:complete_wrapper_command))

  let l:bash_command = 'bash -norc -i -c ' . l:shell_script . ' 2>/dev/null'
  let l:result = system(l:bash_command)

  let l:bash_suggestions = split(l:result)
  " The bash complete not include anything before the colon, add it.
  let l:word_prefix = substitute(l:comp_words[-1], '\v[^:]+$', '', '')
  return map(l:bash_suggestions, 'l:word_prefix . v:val')
endfunction


let s:bazel_commands=[]
function! bazel#Completions(arglead, cmdline, cursorpos)
  " Initialize s:bazel_commands if it hasn't been initialized
  if empty(s:bazel_commands)
    let s:bazel_commands = split(system("bazel help completion | awk -F'\"' '/BAZEL_COMMAND_LIST=/ { print $2 }'"))
  endif

  " Complete commands
  let l:cmdlist = split(a:cmdline)
  if len(l:cmdlist) == 1 || (len(l:cmdlist) == 2 && index(s:bazel_commands, l:cmdlist[-1]) < 0)
    return filter(deepcopy(s:bazel_commands), printf('v:val =~ "^%s"', a:arglead))
  endif

  " Complete targets by using the bash completion logic
  " We wrap this function because if completions from bash are used directly,
  " they also include commandline flags which we don't support at the moment
  if exists("g:bazel_bash_completion_path")
    return bazel#CompletionsFromBash(a:arglead, a:cmdline, a:cursorpos)
  else
    return []
  endif
endfunction
" }}}

command! -complete=customlist,bazel#Completions -nargs=+ Bazel :call bazel#Execute(<f-args>)

" Test cases
" ==============================================================================
" * Build/test current file without passing args to Bazel build/test
" * Build/test current file when pwd is not the bazel project root
" * Build/test another file by passing args to Bazel build/test
" * Build/test from a BUILD file
" * Bazel run a binary

" vim:foldmethod=marker
