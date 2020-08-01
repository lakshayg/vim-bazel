command! -complete=customlist,bazel#Completions -nargs=+ Bazel :call bazel#Execute(<f-args>)
