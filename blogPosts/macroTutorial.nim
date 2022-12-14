import std/[strutils, macros]
import nimib

nbInit
# nb.darkMode

# a custom text block that shows markdown source
template nbTextWithSource*(body: untyped) =
  newNbBlock("nbTextWithSource", false, nb, nb.blk, body):
    nb.blk.output = body
  nb.blk.context["code"] = body

nb.renderPlans["nbTextWithSource"] = @["mdOutputToHtml"]
nb.partials["nbTextWithSource"] = """{{&outputToHtml}}
<pre><code class=\"language-markdown\">{{code}}</code></pre>"""

# how to add a ToC
var nbToc: NbBlock

template addToc =
  newNbBlock("nbText", false, nb, nbToc, ""):
    nbToc.output = "## Table of Contents:\n\n"

template nbSection(name:string) =
  let anchorName = name.toLower.replace(" ", "-")
  nbText "<a name = \"" & anchorName & "\"></a>\n# " & name & "\n\n---"
  # see below, but any number works for a numbered list
  nbToc.output.add "1. <a href=\"#" & anchorName & "\">" & name & "</a>\n" 

nbText: hlMd"""
# Nim Metaprogramming / Macro Tutorial

This tutorial aims to be a _step-by-step_ introduction to the metaprogramming features of the Nim Language and to provide as much detail as possible to kickstart your craziest projects.
There are already many resources on the Web, but I strive to provide more thorough details on the development process and to gather them all in one place. You are encouraged to code along and modify examples.
"""

addToc()

nbSection "Introduction"
nbText: hlMd"""
There are four kind/levels of procedures:
  1. ordinary proc/iterator
  2. generic proc/iterator
  3. template
  4. macro
The higher the number, the more meta we get. It is recommended to program one's procedure with the lowest level of metaprogramming possible. 
Let us start with `template`s and `untyped` parameters. I do not present generics in this tutorial.
"""

nbSection "Templates"
nbText: """
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

nbText:hlMd"""
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
Another example is benchmarking code in Nim. It suffices to put our bench code inside a special block.
"""

nbCode:
  import std/times
  template benchmark(benchmarkName: string, code: untyped) =
    block:
      let t0 = epochTime()
      code
      let elapsed = epochTime() - t0
      let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
      echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"

  benchmark "test1":
    sleep(100)

# nbText:"""
# Though powerful, templates are still limited. As an example, I didn't achieve to make a throwAway template (that does not run a code).
# """

# nbCode:
#   template throwAway(statements: untyped): untyped = discard nil

#   throwAway:
#     echo "Test the discard template, if you see this message, it has failed. If not, well ???"

nbSection "Macros"
nbText:"""
Macros can be seen as an empowered template procedure. While template substitute code, macros do introspection.
Instead of simply taking untyped blocks and reuse them as lego bricks to return a code, we can parse our untyped parameter and do something conditionally to informations given in these parameters.
We can also inject variables into scopes.
"""
nbCode:
  macro throwAway(statements: untyped): untyped =
    result = newStmtList()
  throwAway:
    while true:
      echo "If you do not throw me, I'll spam you indefinitely!"

nbText:"""
### AST Manipulation
In Nim, the code is read and transformed in an internal intermediate representation called an Abstract Syntax Tree (AST). To get a representation of the AST corresponding to a code, we can use the `macro` `dumpTree`.
"""

nbCode:
  dumpTree:
    type
      myObject {.packed.} = ref object of RootObj
        left: seq[myObject]
        right: seq[myObject]

nbText:"""
This output is given with the
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
We can better visualize the AST with the following picture.
"""

nbImage(url="ASTtree.jpg", caption="Nim's Abstract Syntax Tree visualized with a tree")

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
```raw
StmtList
  TypeSection
    TypeDef
      Ident "Thing"
      Empty
      ObjectTy
        Empty
        Empty
        RecList
          IdentDefs
            Ident "a"
            Ident "float32"
            Empty
```
"""

nbText:"""

"""

nbText:"""
We have to get outputs as much complex as possible to detect edge cases, while keeping the information to the minimum to easily read the AST and locate errors.
I present here first some samples of type definition on which I will run my macro.
"""

nbText:hlMd"""
```nim
  when defined(typeMemoryRepr):
    typeMemoryRepr:
      type
        Thing2 = object
          oneChar: char
          myStr: string
      type
        Thing = object of RootObj
          a: float32
          b: uint64
          c: char
    when false: # erroneous code
      # type with pragmas aren't supported yet
      typeMemoryRepr:
        type
          Thing {.packed.} = object
            oneChar: char
            myStr: string
```
"""

nbText:"""
It is not easy (if even possible) to list all possible types.
Yet by adding some other informations we can get a better picture of the general AST of a type.
"""

nbCode:
  dumpTree:
    type
      Thing {.packed.} = object of RootObj
        a: float32
        b: string

nbText:"""
```nim
StmtList
  TypeSection
    TypeDef
      PragmaExpr
        Ident "Thing"
        Pragma
          Ident "packed"
      Empty
      ObjectTy
        Empty
        OfInherit
          Ident "RootObj"
        RecList
          IdentDefs
            Ident "a"
            Ident "float32"
            Empty
          IdentDefs
            Ident "b"
            Ident "string"
            Empty
```
"""

nbText:"""
Notice how the name of the type went under the PragmaExpr section. We have to be careful about this when trying to parse the type.
"""

nbText:"""
A macro does always the same steps:

  1. Search for a node of a specific kind, inside the input AST or check that the given node is of the expected kind.
  2. Fetch properties of the selected node.
  3. Form AST output in function of these input node's properties.
  4. Continue exploring the AST.
"""

nbText:"""
Your macros will require a long docstring and many comments both with thorough details.

I present now my macro `typeMemoryRepr` inspired from the [nim memory guide](https://zevv.nl/nim-memory/) on memory representation.
In this guide, we manually print types fields address, to get an idea of the memory layout and the space taken by each variable and its fields.

```nim
type Thing = object
  a: uint32
  b: uint8
  c: uint16

var t: Thing

echo "size t.a ", t.a.sizeof
echo "size t.b ", t.b.sizeof
echo "size t.c ", t.c.sizeof
echo "size t   ", t.sizeof

echo "addr t.a ", t.a.addr.repr
echo "addr t.b ", t.b.addr.repr
echo "addr t.c ", t.c.addr.repr
echo "addr t   ", t.addr.repr
```

All these echo's are redundant and have to be changed each time we change the type field. For types with more than four or five fields, this becomes not manageable.

I have split this macro into different procedures.
The `echoSizeVarFieldStmt` will take the name of a variable, let us say `a` and of its field `field` and return the code:
```nim
echo a.field.sizeof
```
We create a NimNode of kind `StmtList` (a statement list), that contains `IdentNode`s.
The first `IdentNode` is the command `echo`.
We do not represent spaces in the AST. Each term separated by a dot is an Ident and part of a `nnkDotExpr`.

It suffices to output the above code under a `dumpTree` block, to understand the AST we have to generate.
```nim
dumpTree:
  echo a.field.sizeof
```
"""

nbCode:
  proc echoSizeVarFieldStmt(variable: string, nameOfField: string): NimNode =
    ## quote do:
    ##   echo `variable`.`nameOfField`.sizeof
    newStmtList(nnkCommand.newTree(
              newIdentNode("echo"),
              nnkDotExpr.newTree(
                nnkDotExpr.newTree(
                  newIdentNode(variable),
                  newIdentNode(nameOfField) # The name of the field is the first ident
                  ),
                  newIdentNode("sizeof")
              )
              ))

nbText:"""
The `echoAddressVarFieldStmt` will take the name of a variable, let us say `a` and of its field `field` and return its address:
```nim
echo a.field.addr.repr
```
"""

nbCode:
  proc echoAddressVarFieldStmt(variable: string, nameOfField: string): NimNode =
    ## quote do:
    ##   echo `variable`.`nameOfField`.addr.repr
    newStmtList(nnkCommand.newTree(
                newIdentNode("echo"),
                nnkDotExpr.newTree(
                  nnkDotExpr.newTree(
                    nnkDotExpr.newTree(
                      newIdentNode(variable),
                      newIdentNode(nameOfField)
                    ),
                    newIdentNode("addr")
                  ),
                  newIdentNode("repr")
                )
                ))


nbCode:
  macro typeMemoryRepr(typedef: untyped): untyped =
    ## This macro takes a type definition as an argument and:
    ## * defines the type (outputs typedef as is)
    ## * initializes a variable of this type
    ## * echoes the size and address of the variable
    ## Then, for each field:
    ## * echoes the size and address of the variable field

    # We begin by running the type definition.
    result = quote do:
      `typedef`

    # Parse the type definition to find the TypeDef section's node
    # We create the output's AST along parsing.
    # We will receive a statement list as the root of the AST 
    for statement in typedef:
      # We select only the type section in the StmtList
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
              var `testVariable`:`nameOfType` # instanciate variable with type defined in typedef
              echo `testVariable`.sizeof # echo the total size
              echo `testVariable`.addr.repr # gives the address in memory
            )
            # myTypeVar.field[i] memory size and address in memory
            tnode = tnode[2][2] # The third child of the third child is the fields's AST
            assert tnode.kind == nnkRecList
            for i in 0 ..< tnode.len:
              # myTypeVar.field[i].sizeof
              result = result.add(echoSizeVarFieldStmt(nameOfTestVariable, tnode[i][0].strVal))
              # myTypeVar.field[i].addr.repr
              result = result.add(echoAddressVarFieldStmt(nameOfTestVariable, tnode[i][0].strVal))

    echo result.repr

nbCode:
  typeMemoryRepr:
    type
      Thing = object of RootObj
        a: float32
        b: string

nbText:"""
Trying to parse a type ourselve is risky, since there are numerous easily forgettable possibilities (due to pragma expressions, cyclic types, and many kind of types: object, enum, type alias, etc..., case of fields, branching and conditionals inside the object, ??? ).

There is actually already a function to do so:
"""

nbSection "Existing resources / References / Bibliography"
nbText: """
Press `Ctrl` + `Click` to open following links in a new tab.

First, there are four official resources at the Nim's website:
  1. [Nim by Example](https://nim-by-example.github.io/macros/)
  2. [Nim Tutorial (Part III)](https://nim-lang.org/docs/tut3.html)
  3. [Manual section about macros](https://nim-lang.org/docs/manual.html#macros)
  4. [The Standard Documentation of the std/macros library](https://nim-lang.org/docs/macros.html)
The 2. and 3. documentations are complementary learning resources while the last one will be your up-to-date exhaustive reference. It provides dumped AST (explained later) for all the nodes.

Many developers have written their macro's tutorial:
  1. [Nim in Y minutes](https://learnxinyminutes.com/docs/nim/)
  2. [Jason Beetham a.k.a ElegantBeef's dev.to tutorial](https://dev.to/beef331/demystification-of-macros-in-nim-13n8). This tutorial contains a lot of good first examples.
  3. [Pattern matching (sadly outdated) in macros by DevOnDuty](https://www.youtube.com/watch?v=GJpn6SfR_1M)
  4. [Tomohiro's FAQ section about macros](https://internet-of-tomohiro.netlify.app/nim/faq.en.html#macro)
  5. [The Making of NimYAML's article of flyx](https://flyx.org/nimyaml-making-of/)

There are plentiful of posts in the forum that are good references:
  1. [What is "Metaprogramming" paradigm used for ?](https://forum.nim-lang.org/t/2587)
  2. [Custom macro inserts macro help](https://forum.nim-lang.org/t/9470)
  3. [See generated code after template processing](https://forum.nim-lang.org/t/9498)
  4. etc ??? Please use the forum search bar with specific keywords like `macro`, `metaprogramming`, `generics`, `template`, ???

Last but no least, there are three Nim books:
  1. [Nim In Action, ed. Manning](https://book.picheta.me) and [github repo](https://github.com/dom96/nim-in-action-code)
  2. [Mastering Nim, auto-published by A. Rumpf/Araq, Nim's creator](https://www.amazon.fr/dp/B0B4R7B9YX).
  3. [Nim Programming Book, by S.Salewski](https://ssalewski.de/nimprogramming.html#_macros_and_meta_programming)

We can also count many projects that are macro- or template-based:
  1. [genny](https://github.com/treeform/genny) and [benchy](https://github.com/treeform/genny). Benchy is a template based library that benchmarks your code snippet under bench blocks. Genny is used to export a Nim library to other languages (C, C++, Node, Python, Zig).
  In general, treeform projects source code are good Nim references
  2. My favorite DSL : the [neural network domain specific language (DSL) of the tensor library Arraymancer](https://github.com/mratsim/Arraymancer/blob/68786e147a94069a96f069bab327d67afdaa5a3e/src/arraymancer/nn/nn_dsl.nim)
  [mratsim](https://github.com/mratsim/) develops this library, and made [a list of all his DSL](https://forum.nim-lang.org/t/9551#62851) in the forum.
  3. [Jester](https://github.com/dom96/jester) library is a really nice HTML DSL, where each block defines a route in your web application.
  4. [nimib](https://pietroppeter.github.io/nimib/) with which this blog post has been written, has been developed with a macro DSL too.
  5. The most complex macro system that I know of apart from genny for the moment is the [Nim4UE](https://github.com/jmgomez/NimForUE). You can develop Nim code for the Unreal Engine 5 game engine. The macro system parses your procs and outputs DLL for UE.
"""
nbSave
