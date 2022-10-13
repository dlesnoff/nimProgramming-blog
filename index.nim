import strformat, strutils
import nimib

nbInit

import std/[macros]
nbText: """
# Nim Metaprogramming (Macros) Tutorial
This tutorial aims to be a step-by-step introduction to the metaprogramming features of the Nim Language.
There are already many resources on the Web, but I strive to provide more thorough details on the development process all in one place.

## Existing resources
Press `Ctrl` + `Click` to open following links in a new tab.

First, there are three official resources at the Nim's website:
  1. [Nim Tutorial (Part III)](https://nim-lang.org/docs/tut3.html)
  2. [Manual section about macros](https://nim-lang.org/docs/manual.html#macros)
  3. [The Standard Documentation of the std/macros library](https://nim-lang.org/docs/macros.html)
The 1. and 2. documentations are complementary learning resources while the last one will be your up-to-date exhaustive reference.

Many developers have written their macro's tutorial:
  1. [Jason Beetham a.k.a ElegantBeef's dev.to tutorial](https://dev.to/beef331/demystification-of-macros-in-nim-13n8). This tutorial contains a lot of good first examples.
  2. [Pattern matching (sadly outdated) in macros by DevOnDuty](https://www.youtube.com/watch?v=GJpn6SfR_1M)
  3. [Tomohiro's FAQ section about macros](https://internet-of-tomohiro.netlify.app/nim/faq.en.html#macro)
  4. [The Making of NimYAML's article of flyx](https://flyx.org/nimyaml-making-of/)

There are plentiful of posts in the forum that are good references:
  1. [What is "Metaprogramming" paradigm used for ?](https://forum.nim-lang.org/t/2587)
  2. [Custom macro inserts macro help](https://forum.nim-lang.org/t/9470)
  3. [See generated code after template processing](https://forum.nim-lang.org/t/9498)
  4. etc … Please use the forum search bar with keywords like `macro`, `metaprogramming`, `generics`, `template`, …

Last but no least, there are three Nim books:
  1. [Nim In Action, ed. Manning](https://book.picheta.me) and [github repo](https://github.com/dom96/nim-in-action-code)
  2. [Mastering Nim, auto-published by A. Rumpf/Araq, Nim's creator](https://www.amazon.fr/dp/B0B4R7B9YX). (This link is NOT affiliated)
  3. [Nim Programming Book, by S.Salewski](https://ssalewski.de/nimprogramming.html#_macros_and_meta_programming)

We can also count many projects that are macro- or template-based:
  1. [genny](https://github.com/treeform/genny) and [benchy](https://github.com/treeform/genny). Benchy is a template based library that benchmarks your code snippet under bench blocks. Genny is used to export a Nim library to other languages (C, C++, Node, Python, Zig).
  In general, treeform projects source code are good Nim references
  2. My favorite macro : the [neural network domain specific language (DSL) of the tensor library Arraymancer](https://github.com/mratsim/Arraymancer/blob/68786e147a94069a96f069bab327d67afdaa5a3e/src/arraymancer/nn/nn_dsl.nim)
Do not just look at the header of procedures to determine if it is a macro or not. Often a macro relies on a lot of smaller procedures.

Let us start with introduction to `template` and `untyped` parameters. Another form of metaprogramming is done with `generics`, but these are not explained in the scope of this tutorial.
"""

nbText: """
## Templates
We can see *templates* as procedures that modify code through a copy-paste mechanism. Pieces of code are given to (and outputted by) the template with a special type : `untyped`. 
For those familiar with [preprocessing](https://gcc.gnu.org/onlinedocs/cpp/) in the C family of languages (C, C++, C#), it does the same than the `#define` or `#if`, `#endif` macros and much more.
"""
nbText: """
Nim's language defines boolean operator like `!=` with templates. You can even look at Nim's source code, that's almost the same code. See the [documentation](https://nim-lang.org/docs/system.html#%21%3D.t%2Cuntyped%2Cuntyped).
"""
nbCode:
  ## Example from std/manual
  template `!=` (a, b: untyped): untyped =
    not (a == b)

  doAssert(4 != 5)

nbText: """
We can easily repeat code under a custom block. Here duplicate, just duplicate code and repeat takes an additional parameter, an int, as a generalisation of the `duplicate` template.
Notice that duplicate is not smart. It will repeat any assignment twice in the code's block.
"""

nbCode:
  template duplicate(statements: untyped) =
    statements
    statements

  duplicate:
    echo 5

nbCode:
  ## Example from Nim In Action
  from std/os import sleep
  template repeat(count: int, statements: untyped) =
    for i in 0 ..< count:
      statements

  repeat 5:
    echo("Hello Templates!")
    sleep(1000)

nbText: """
In standard Nim, there are very few restricted keywords and special control-flow mechanisms, but nothing restrains us from creating a doWhile construct. And this is very simple.
"""

nbCode:
  template doWhile(conditional, loop: untyped) =
    loop
    while conditional:
      loop
  
  var myInt = 5
  doWhile myInt >= 6:
      echo myInt
      if myInt mod 2 == 1:
        myInt *= 3
        myInt.inc
      else:
        myInt = myInt div 2

nbText:"""
We can not do certain things with template, like not returning any code.
"""

nbCode:
  template `discard`(statements: untyped): untyped =
    discard nil # Cheat here

  `discard`:
    echo "Test the discard template, if you see this message, it has failed. If not, well …"

nbText:"""
## Macros
Macros can be seen as an empowered template procedure.
Instead of simply taking untyped blocks and reuse them as lego bricks to return a code, we can parse our untyped parameter and do something conditionally to informations given in these parameters.
"""
nbCode:
  macro discard2(statements: untyped): untyped =
    result = newStmtList()
  discard2:
    while true:
      echo "If you do not discard me, you'll never get out!"

nbSave
