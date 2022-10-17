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

## Introduction
There are four kind/levels of procedures:
  1. ordinary proc/iterator
  2. generic proc/iterator
  3. template
  4. macro
The higher the number, the more meta we get. It is recommended to program one's procedure with the lowest level of metaprogramming possible. 
Let us start with `template`s and `untyped` parameters. I do not `present` generics in this tutorial.
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
    sleep(100)

nbText: """
In Nim, there are few restricted keywords and special control-flow mechanisms, as to incite us to create our own constructs (and keep the language simple). Nothing restrains us from defining a `doWhile` construct.
"""

nbCode:
  proc nextSyracuseTerm(term: var int) =
    ## This sequence should resolve to the cyclic sequence 1, 4, 2, 1, ...
    if term mod 2 == 1:
      term *= 3
      term.inc
    else:
      term = term div 2

  template doWhile(conditional, loop: untyped) =
    loop
    while conditional:
      loop
  
  var myInt = 5
  doWhile myInt >= 6:
      echo myInt
      nextSyracuseTerm(myInt)

nbText:"""
Notice though that the end result is fairly different than C++ code
```cpp
int i = 0;
do{
  printf("Hello World");
  i += 1;
}while(i < 10);
```
The instructions and the conditional appear before the `while` whereas this doWhile Nim construct will have the conditional after the `doWhile`:
```nim
var i: int = 0 # superfluous type annotation
doWhile i < 10:
  echo "Hello World!"
  i.inc
```
"""
  
nbText:"""
Though powerful, templates are still limited. As an example, I didn't achieve to make a discard template (that ta disabling a code.
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

nbText:"""
### AST Manipulation
In Nim, the code is read and transformed in an internal intermediate representation called an Abstract Syntax Tree (AST) (refer to the [manual AST section]()
"""

nbCode:
  dumpTree:
    type
      myObject {.packed.} = ref object of RootObj
        left: seq[myObject]
        right: seq[myObject]
nbText:"""
```raw
StmtList
  TypeSection
    TypeDef
      PragmaExpr
        Ident "myObject"
        Pragma
          Ident "packed"
      Empty
      RefTy
        ObjectTy
          Empty
          OfInherit
            Ident "RootObj"
          RecList
            IdentDefs
              Ident "left"
              BracketExpr
                Ident "seq"
                Ident "myObject"
              Empty
            IdentDefs
              Ident "right"
              BracketExpr
                Ident "seq"
                Ident "myObject"
              Empty
```
"""

nbText:"""
I present down my first macro as an example.
I want to print the memory layout of a given type.
My goal is to find misaligned fields making useless unocuppied memory.
We should be able in the future to automatically swap the fields to remove the holes (or at least propose a fixed type).
The first step is to look at the AST of the input code we want to parse.
"""

nbCode:
  dumpTree:
    type
      Thing = object
        a: float32

nbText:"""
It is not easy (if even possible) to list all the possible types.
By adding some other informations we get a better picture of the general AST of a type.
"""

nbCode:
  dumpTree:
    type
      Thing {.packed.} = object of RootObj
        a: float32
        b: string

nbText:"""
A macro does three steps in this order:
  0. Check that the node is of the expected kind.
  1. Get properties of the input AST node (Maybe by going through node child's Ident).
  2. Form AST output in function of these input node's properties.
  3. Go through the node's child.
"""

nbText:"""
A good macro is necessary complex enough to require a long docstring with thorough details.
We begin by running the type definition.
"""

nbCode:
  macro typeMemoryRepr(typedef: untyped): untyped =
    ## This macro takes a type definition as an argument and:
    ## * defines the type (outputs typedef as is)
    ## * initializes a variable of this type
    ## * echoes the size of the variable
    ## * echoes the address of the variable
    ## Then, for each field:
    ## * echoes the size of the variable field
    ## * echoes the address of the variable field

    # Parse the type definition to find the TypeDef section's node
    result = quote do:
      `typedef`
    for statement in typedef:
      if statement.kind == nnkTypeSection:
        let typeSection = statement
        for i in 0 ..< typeSection.len:
          if typeSection[i].kind == nnkTypeDef:
            var tnode = typeSection[i]
            # The name of the type is the first Ident child. We can get the ident's string with strVal or repr
            let nameOfType = typeSection[i].findChild(it.kind == nnkIdent)

            ## Generation of AST:
            # We create a variable of the given type definition (hopefully not already defined) name for the "myTypenameVar"
            let nameOfTestVariable = "my" & nameOfType.strVal.capitalizeAscii() & "Var"
            let testVariable = newIdentNode(nameOfTestVariable)
            result = result.add(
            quote do:
              var `testVariable`:`nameOfType` # instanciate type defined in typedef
              echo `testVariable`.sizeof # echo the total size
              echo `testVariable`.addr.repr # gives the address in memory
            )
            # myTypeVar.field[i] memory size and address in memory
            tnode = tnode[2][2] # The third child of the third child is the fields's AST
            assert tnode.kind == nnkRecList
            for i in 0 ..< tnode.len:
              # myTypeVar.field[i].sizeof
              result = result.add(newStmtList(nnkCommand.newTree(
                newIdentNode("echo"),
                nnkDotExpr.newTree(
                  nnkDotExpr.newTree(
                    newIdentNode(nameOfTestVariable),
                    newIdentNode(tnode[i][0].strVal) # The name of the field is the first ident
                    ),
                    newIdentNode("sizeof")
                )
                )))
              # myTypeVar.field[i].addr.repr

              result = result.add(newStmtList(nnkCommand.newTree(
                newIdentNode("echo"),
                nnkDotExpr.newTree(
                  nnkDotExpr.newTree(
                    nnkDotExpr.newTree(
                      newIdentNode(nameOfTestVariable),
                      newIdentNode(tnode[i][0].strVal)
                    ),
                    newIdentNode("addr")
                  ),
                  newIdentNode("repr")
                )
                )))
    echo result.repr

  when isMainModule:
    typeMemoryRepr:
      type
        Thing = object of RootObj
          a: float32
          b: uint64
          c: char
      type
        Thing2 = object
          oneChar: char
          myStr: string
    when false: # erroneous code
      # type with pragmas aren't supported yet
      typeMemoryRepr:
        type
          Thing {.packed.} = object
            oneChar: char
            myStr: string
nbSave
