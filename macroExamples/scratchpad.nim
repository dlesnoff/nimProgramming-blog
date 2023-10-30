import std/macros

macro oneMacro(): untyped =
  echo repr quote do:
    let x = "hello world"
    echo x

macro anotherMacro(): untyped =
  echo repr quote do:
    let x = "dlrow olleh"
    echo x

oneMacro
anotherMacro