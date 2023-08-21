function! bazel#ModifyPath(bazel_root)
  if !isdirectory(a:bazel_root . "/bazel-bin")
    return
  endif

  let project_dir = fnamemodify(a:bazel_root, ":t")
  let &path = &path . "," . resolve(a:bazel_root . "/bazel-bin")
  let &path = &path . "," . resolve(a:bazel_root . "/bazel-" . project_dir)
endfunction

" Jump to build file and search for filename where this command was called
function! bazel#JumpToBuildFile()
  let current_file = expand("%:t")
  let pattern = "\\V\\<" . current_file . "\\>"
  exe "edit" findfile("BUILD", ".;")
  call search(pattern, "w", 0, 500)
endfunction


function! s:PathRelativeToWsRoot(path) abort
  let full_path = fnamemodify(a:path, ":p")
  " cd into the WORKSPACE root
  exe "cd" fnamemodify(findfile("WORKSPACE", ".;"), ":p:h")
  " get path to file relative to current dir (WORKSPACE root)
  let rel_path = fnamemodify(full_path, ":.")
  cd -
  return rel_path
endfunction

function! s:GetTargetsFromContext() abort
  let rel_fname = <SID>PathRelativeToWsRoot(fname)

  " Is the current file a BUILD file?
  if fnamemodify(fname, ":t") ==# "BUILD"
    let package_path = fnamemodify(rel_fname, ":h")
    return "//" . package_path . ":all"
  endif

  " Assume that the current file is a source file
  let build_file_path = findfile("BUILD", ".;")
  let relative_path = <SID>PathRelativeToWsRoot(build_file_path)
  let package_path = fnamemodify(relative_path, ":h")
  let package_spec = "//" . package_path . "/..."
  let fmt = "$(bazel cquery --collapse_duplicate_defines --noshow_timestamps --output=starlark 'kind(rule, rdeps(%s, %s, 1))' || echo CQUERY_FAILED)"
  return printf(fmt, package_spec, rel_fname)
endfunction

function! bazel#Execute(action, ...) abort
  let flags = ['--collapse_duplicate_defines', '--noshow_timestamps', '--color=no']
  let targets = []

  let i = 0

  " Add all arguments that start with "--" to flags
  while i < a:0 && a:000[i] =~ "^--."
    call add(flags, a:000[i])
    let i = i + 1
  endwhile

  " Add everything until we find "--" to targets
  while i < a:0 && a:000[i] !~ "^--"
    call add(targets, a:000[i])
    let i = i + 1
  endwhile

  " Everything that remains gets added to this list
  let rest = a:000[i:]

  if empty(targets)
    let targets = [<SID>GetTargetsFromContext()]
  endif

  compiler bazel
  exe get(g:, "bazel_make_command", "make") join(
        \ [a:action] + flags + targets + rest)
endfunction

" Completions for the :Bazel command {{{
" Completions are extracted from the bash bazel completion function.
" Taken from https://github.com/bazelbuild/vim-bazel/blob/master/autoload/bazel.vim
" with minor modifications
function! s:CompletionsFromBash(arglead, line, pos) abort
  " The bash complete script does not truly support autocompleting within a
  " word, return nothing here rather than returning bad suggestions.
  if a:pos + 1 < strlen(a:line)
    return []
  endif

  let cmd = substitute(a:line[0:a:pos], '\v\w+', 'bazel', '')

  let comp_words = split(cmd, '\v\s+')
  if cmd =~# '\v\s$'
    call add(comp_words, '')
  endif
  let comp_line = join(comp_words)

  " Note: Bashisms below are intentional. We invoke this via bash explicitly,
  " and it should work correctly even if &shell is actually not bash-compatible.

  " Extracts the bash completion command, should be something like:
  " _bazel__complete
  let complete_wrapper_command = ' $(complete -p ' . comp_words[0] .
      \ ' | sed "s/.*-F \\([^ ]*\\) .*/\\1/")'

  " Build a list of all the arguments that have to be passed in to autocomplete.
  let comp_arguments = {
      \ 'COMP_LINE' : '"' .comp_line . '"',
      \ 'COMP_WORDS' : '(' . comp_line . ')',
      \ 'COMP_CWORD' : string(len(comp_words) - 1),
      \ 'COMP_POINT' : string(strlen(comp_line)),
      \ }
  let comp_arguments_string =
      \ join(map(items(comp_arguments), 'v:val[0] . "=" . v:val[1]'))

  " Build the command to run with bash
  let shell_script = shellescape(printf(
      \ 'source %s; export %s; %s && echo ${COMPREPLY[*]}',
      \ g:bazel_bash_completion_path,
      \ comp_arguments_string,
      \ complete_wrapper_command))

  let bash_command = 'bash -norc -i -c ' . shell_script . ' 2>/dev/null'
  let result = system(bash_command)

  let bash_suggestions = split(result)
  " The bash complete not include anything before the colon, add it.
  let word_prefix = substitute(comp_words[-1], '\v[^:]+$', '', '')
  return map(bash_suggestions, 'word_prefix . v:val')
endfunction


let s:bazel_commands=[]
function! bazel#Completions(arglead, cmdline, cursorpos) abort
  " Initialize s:bazel_commands if it hasn't been initialized
  if empty(s:bazel_commands)
    let s:bazel_commands = split(system("bazel help completion | awk -F'\"' '/BAZEL_COMMAND_LIST=/ { print $2 }'"))
  endif

  " Complete commands
  let cmdlist = split(a:cmdline)
  if len(cmdlist) == 1 || (len(cmdlist) == 2 && index(s:bazel_commands, cmdlist[-1]) < 0)
    return filter(deepcopy(s:bazel_commands), printf('v:val =~ "^%s"', a:arglead))
  endif

  " Complete targets by using the bash completion logic
  " We wrap this function because if completions from bash are used directly,
  " they also include commandline flags which users don't need in most cases
  return exists("g:bazel_bash_completion_path")
        \ ? <SID>CompletionsFromBash(a:arglead, a:cmdline, a:cursorpos)
        \ : []
endfunction
" }}}

" Test cases
" ==============================================================================
" * Build/test current file without passing args to Bazel build/test
" * Build/test current file when pwd is not the bazel project root
" * Build/test another file by passing args to Bazel build/test
" * Build/test from a BUILD file
" * Bazel run a binary

" vim:foldmethod=marker
