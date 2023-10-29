import std/[strutils, macros]
import std/[enumerate, math]
import nimib, nimoji

nbInit

# add a ToC
var nbToc: NbBlock

template addToc =
  newNbBlock("nbText", false, nb, nbToc, ""):
    nbToc.output = "### Table of Contents:\n\n"

template nbSection(name:string) =
  let anchorName = name.toLower.replace(" ", "-")
  nbText "<a name = \"" & anchorName & "\"></a>\n## " & name & "\n\n---"
  # see below, but any number works for a numbered list
  nbToc.output.add "1. <a href=\"#" & anchorName & "\">" & name & "</a>\n"

nbText: hlMd"""
<h1 style="text-align: center;">Nim Metaprogramming - Macro Tutorial</h1>

This tutorial aims to be a _step-by-step_ introduction to the metaprogramming features of the Nim Language and to provide as much detail as possible to kickstart your craziest projects.
There are already many resources on the Web, but I strive to provide more thorough details on the development process and to gather them all in one place.
> :warning: This tutorial is still under heavy development.
""".emojize

addToc()

nbSection "Introduction"
nbText: hlMd"""
### Four levels of abstraction
There are four levels of abstraction in metaprogramming that are each a special kind of procedure:
  1. Ordinary procedures/iterators (No metaprogramming)
  2. Generic procedures/iterators and typedescs (Type level)
  3. Template (Copy-paste mechanism)
  4. Macro (AST substitution)

It is recommended to start to program one's procedure with the lowest level of metaprogramming possible.
As more metaprogramming features are used, the compilation process takes longer and error debugging gets harder.
"""

nbSection "Generics"
nbText: """
We often program to perform repetitive tasks easily.
Programs must adapt themselves to many cases and might be redundant in a first approach.
To limit the scope for debugging, we like to avoid redundancy and let the compiler do code duplication for us.
Code duplication means that the generated assembly code has very similar or identical block instructions.

One common example is linear algebra. Imagine you want to perform an addition. Your input data is very general and may as well be integers, floating-point numbers.
You do not want to write twice your addition function.
"""

nbCodeSkip:
  # What to not do!
  proc add(x, y: int): int =
    return x + y

  proc add(x, y: float): float =
    return x + y

  echo add 2 3
  echo add 3.7 4.5

nbText:"""
Indeed, what if you want to add a function for other types like `int32` or `float16`?
You will have to copy-paste your function, and change the type. Not a problem?
There is nothing in the code telling you how many `add` functions there is in total.
Whenever a code slip in one of your function, you will have to track all the `add` functions and fix the bug in all of them.

Generics bring a solution to this:
"""

nbCodeSkip:
  proc add[T](x,y: T): T =
    return x + y


nbText:"""
Let us start with `template`s and `untyped` parameters.

To run each snippet of code in this tutorial, you will need to import the `std/macros` package.
"""
nbCodeSkip:
  import std/macros

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
#### Do-While keyword
In Nim, there are few restricted keywords and special control-flow mechanisms, as to incite us to create our own constructs (and keep the language simple). Nothing restrains us from defining a `doWhile` construct similar to languages like `C` or `Javascript`.

For those only knowing Nim, this construct enables to run a loop once before testing the condition.

This C code always print `Hello World` at least once independantly from the start value of the variable `i`.
```cpp
int i = 10;
do{
  printf("Hello World");
  i += 1;
}while(i < 10);
```
"""

nbCode:

  template doWhile(conditional, loop: untyped) =
    loop
    while conditional:
      loop

  var i = 10
  doWhile i < 10:
      echo "Hello World"
      i.inc

nbText:hlMd"""
Notice though that _syntaxically_ the resulting source code is fairly different than the C++ code.

In the C source code, appear in this order:
  1. the `do` keyword
  2. the block of instruction
  3. the `while` keyword
  4. the conditional (boolean expression)

In Nim, we have in this order:
  1. the `doWhile` indent
  2. the conditional
  3. block of instruction

There is no way to modify Nim's syntax as to match C's syntax.
"""

nbText:"""
#### Benchmark example
Another example is benchmarking code in Nim. It suffices to put our bench code inside a special block.
"""

nbCode:
  import std/[times, monotimes]
  template benchmark(benchmarkName: string, code: untyped) =
    block:
      let t0 = getMonoTime()
      code
      let elapsed = getMonoTime() - t0
      echo "CPU Time [", benchmarkName, "] ", elapsed

  benchmark "test1":
    sleep(100)

nbText:"""
The code inside the `benchmark` code block will be enclosed by our template code.

Since the code replacement is done at compile time, this transformation does not add additional runtime to our benchmarked code.
On the contrary, a function or procedure for benchmarking would have add runtime due to the nested function calls.
"""

nbSection "Macros"
nbText:"""
Template uses `untyped` parameters as lego bricks. It can not break it down into smaller pieces.
We can not check untyped parameters in a template. If our template works when given an object as argument, nothing restrics an user to give a function as argument.

Macros can be seen as an empowered template procedure. While template substitute code, macros do introspection.
The main difference is that a template can not look inside an untyped parameter. This means that we can not check the input we get as to verify that the user did not give a function when we expect a type.


One can parse untyped parameters with macros. We can even act something conditionally to informations given in these parameters.
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
  # Don't forget to import std/macros!
  # You can use --hints:off to display only the AST tree
  dumpTree:
    type
      myObject {.packed.} = ref object of RootObj
        left: seq[myObject]
        right: seq[myObject]

nbText:"""
This code outputs the following AST tree (it should not change among Nim versions).
```nim
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
We can better visualize the tree structure of the AST with the following picture.
"""

nbImage(url="ASTtree.jpg", caption="Nim's Abstract Syntax Tree visualized with a tree")

nbText:"""
### Multiply by two macro
This example of macro is taken from [this Youtube video](https://www.youtube.com/watch?v=WHyOHQ_GkNo) made by [Fireship](https://www.youtube.com/c/Fireship).
"""

nbCode:
  macro timesTwo(statements: untyped): untyped =
    for s in result:
      for node in s:
        if node.kind == nnkIntLit:
          node.intVal = node.intVal*2

  timesTwo:
    echo 1 # 2
    echo 2 # 4
    echo 3 # 6

nbText:"""
This macro multiplies each integer values by two before plotting!
Let us breakdown this macro, shall we ?
To understand how a macro work, we first may look at the AST given as input.
"""

nbCode:
  dumpTree:
    echo 1

nbText:"""
By compiling this code, you will get the corresponding AST.
This simple AST is made of four nodes:
```nim
StmtList
  Command
    Ident "echo"
    IntLit 1
```

`StmtList` stands for *statements list*. It groups together all the instructions in your block.

The `Command` node indicates that you use a function whose name is given by its child `Ident` node. An `Ident` can be any variable, object, procedure name.

Our integer literal whose value is 1 has the node kind `IntLit`.

Notice that the order of the nodes in the AST is crucial. If we invert the two last nodes, we would get the AST of the code `1 echo` which does not compile.
```nim
StmtList
  Command
    IntLit 1
    Ident "echo"
```

`StmtList`, `Command`, `IntLit` and `Ident` are the NodeKind of the code's AST.
Inside your macro, they are denoted with the extra prefix `nnk`, e.g. `nnkIdent`.
You can get the full list of node kinds [at the std/macros source code](https://github.com/nim-lang/Nim/blob/a8c6e36323601a64dcb6947a694f0bde97b632b2/lib/core/macros.nim#L25-L89).
"""
nbCode:
  macro timesTwoAndEcho(statements: untyped): untyped =
    for s in result:
      for node in s:
        if node.kind == nnkIntLit:
          node.intVal = node.intVal*2
    echo repr result

  timesTwoAndEcho:
    echo 1
    echo 2
    echo 3

nbText:"""
The output of a macro is an AST, and we can try to write it for a few examples:
```nim
StmtList
  Command
    Ident "echo"
    IntLit 2
  Command
    Ident "echo"
    IntLit 4
  Command
    Ident "echo"
    IntLit 6
```
Please note that line breaks are not part of the Nim's AST!

Here, the output AST is almost the same as the input. We only change the integer literal value.

Our root node in the input AST is a statement list.
To fetch the `Command` children node, we may use the list syntax.
A Node contains the list of its childrens. To get the first children, it suffices to write `statements[0]`.
To loop over all the child nodes, one can use a `for statement in statements` loop.

We need to fetch the nodes under a `Command` instruction that are integer literals.
So for each node in the statement, we test if the node kind is equal to `nnkIntLit`. We get their value with the attribute `node.intVal`.
"""


nbText:"""
I present down my first macro as an example.
I want to print the memory layout of a given type.
My goal is to find misaligned fields making useless unocuppied memory in a type object definition.
This happens when the attributes have types of different sizes. The order of the attributes then changes the memory used by an object.
To deal with important chunks of memory, the processor stores an object and its attributes with [some rules](https://en.wikipedia.org/wiki/Data_structure_alignment).

It likes when adresses are separated by powers of two. If it is not, it inserts a padding (unoccupied memory) between two attributes.

We can pack a structure with the pragma `{.packed.}`, which removes this extra space. This has the disadvantage to slow down memory accesses.

We would like to detect the presence of holes in an object.

The first step is to look at the AST of the input code we want to parse.

One can look first at the most basic type definition possible, before trying to complexify the AST to get a feel of all the edge cases.
"""

nbCode:
  dumpTree:
    type
      Thing = object
        a: float32

nbText:"""
```nim
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
```

Type with pragmas aren't supported yet
```nim


when false: # erroneous code

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
Trying to parse a type ourselve is risky, since there are numerous easily forgettable possibilities (due to pragma expressions, cyclic types, and many kind of types: object, enum, type alias, etc..., case of fields, branching and conditionals inside the object, … ).

There is actually already a function to do so and this will be the object of a future release of this tutorial.
"""

nbText:"""
The following macro enables to create enums with power of two values.
"""

nbCodeSkip:
  import std/[enumerate, math]

nbCode:
  # jmgomez on Discord
  macro power2Enum(body: untyped): untyped =
    let srcFields = body[^1][1..^1]
    var dstFields =  nnkEnumTy.newTree(newEmptyNode())
    for idx, field in enumerate(srcFields):
      dstFields.add nnkEnumFieldDef.newTree(field, newIntLitNode(pow(2.0, idx.float).int))

    body[^1] = dstFields
    echo repr body
    body


  type Test {.power2Enum.}  = enum
    a, b, c, d

nbText:"""
A macro is not always the best alternative. A simple set and a cast gives the same result.
"""

nbCode:
  # Rika
  type
    Setting = enum
      a, b, c
    Settings = set[Setting]
  let settings: Settings = {a, c}
  echo cast[uint8](settings)

nbSection "References and Bibliography"
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
  4. [Fast array assignment](https://forum.nim-lang.org/t/10037)
  5. [Variable injection](https://forum.nim-lang.org/t/10513)
  6. [Proc inspection](https://forum.nim-lang.org/t/9127)
  7. etc … Please use the forum search bar with specific keywords like `macro`, `metaprogramming`, `generics`, `template`, …

Last but no least, there are three Nim books:
  1. [Nim In Action, ed. Manning](https://book.picheta.me) and [github repo](https://github.com/dom96/nim-in-action-code)
  2. [Mastering Nim, auto-published by A. Rumpf/Araq, Nim's creator](https://www.amazon.fr/dp/B0B4R7B9YX).
  3. [Nim Programming Book, by S.Salewski](https://ssalewski.de/nimprogramming.html#_macros_and_meta_programming)

We can also count many projects that are macro- or template-based:
  1. [genny](https://github.com/treeform/genny) and [benchy](https://github.com/treeform/genny). Benchy is a template based library that benchmarks your code snippet under bench blocks. Genny is used to export a Nim library to other languages (C, C++, Node, Python, Zig).
  In general, treeform projects source code are good Nim references
  2. My favorite DSL : the [neural network domain specific language (DSL) of the tensor library Arraymancer](https://github.com/mratsim/Arraymancer/blob/68786e147a94069a96f069bab327d67afdaa5a3e/src/arraymancer/nn/nn_dsl.nim)
  [mratsim](https://github.com/mratsim/) develops this library, and made [a list of all his DSL](https://forum.nim-lang.org/t/9551#62851) in the forum.
  3. [Jester](https://github.com/dom96/jester) library is a HTML DSL, where each block defines a route in your web application.
  4. [nimib](https://pietroppeter.github.io/nimib/) with which this blog post has been written.
  5. [Nim4UE](https://github.com/jmgomez/NimForUE). You can develop Nim code for the Unreal Engine 5 game engine. The macro system parses your procs and outputs DLL for UE.
"""
nbSave
