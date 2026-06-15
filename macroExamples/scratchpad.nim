import std/macros

macro oneMacro() =
  echo repr quote do:
    let x = "hello world"
    echo x

macro anotherMacro() =
  echo repr quote do:
    let x = "dlrow olleh"
    echo x

macro class(name, body: untyped) = echo repr quote("@") do:
  type
    `@name` = ref object of system.RootObj
        `body`

oneMacro
anotherMacro

class TestClass:
    b = 10
