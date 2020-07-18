command! -complete=customlist,s:Completions -nargs=+ Bazel :call bazel#Execute(<f-args>)
