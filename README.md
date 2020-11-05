# vim-bazel

This plugin allows invoking bazel from vim

## Commands

```
:Bazel {command} [arguments...]
```

This is identical to calling :!bazel {command} [arguments...] except
when the command is "build" or "test", in which case, it provides some
niceties

* Errors from the compiler are loaded into the quickfix list
* Test failure logs are loaded into the quickfix list
* Parses errors due to missing dependencies in bazel target definitions
* If no targets are specified, it calls bazel for the current file
* If the current file is a BUILD file, calls the command for all the
  targets in the BUILD file

Some other general improvements:

* Adds bazel-bin and bazel-<project> to the path so `gf` and other
  related command work seamlessly
* Provides the :Bld command to jump to BUILD files

Note: It is currently tuned for C++ development in the sense that the
errorformat is set to recognize error messages from gcc/clang

## Command completion

To enable completion of targets in bazel commands, vim-bazel tries to
determine the location of the bazel bash completion script. If target
completion does not work, set g:bazel_bash_completion_path to the path
of the bazel bash completion script on your system. To locate the script
on your system see: https://docs.bazel.build/versions/master/completion.html

```
let g:bazel_bash_completion_path = "/usr/local/etc/bash_completion.d/bazel-complete.bash"
```

## Asynchronous builds

vim-bazel can be used with async plugins to run builds in the background.
This can be done by setting g:bazel_make_command. Here are some examples
on how to set this up with various plugins:

```
tpope/vim-dispatch        let g:bazel_make_command = "Make"
skywind3000/asyncrun.vim  let g:bazel_make_command = "AsyncRun -program=make"
hauleth/asyncdo.vim       let g:bazel_make_command = "AsyncDo bazel"
```

## Error Filtering

This plugin filters errors using regexes. By default, only the messages
that match the regexes are loaded into the quickfix list. However, the
user might sometimes want to load all the messages without filtering. This
can be done by setting:

```
let g:bazel_filter_aggressively = 0
```

## Might do in the future

* Unit tests
* Support for languages besides C++
