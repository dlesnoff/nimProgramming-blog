import strutils
import macros

const tmpl = """
\documentclass{standalone}
\usepackage{tikz}
\usetikzlibrary{trees}
\begin{document}
\tikzstyle{every node}=[draw=black, rectangle, fill=teal]
\tikzstyle{Ident}=[thick, fill=orange]
\begin{tikzpicture}[%
  sibling distance=25mm,
  % TODO: think about sibling dstances
  edge from parent fork down
]
$#
\end{tikzpicture}
\end{document}
"""

proc removePrefix(s, p: string): string =
  result = s
  result.removePrefix(p)

proc node(n: NimNode): string =
  let nK = n.kind.repr.removePrefix("nnk")
  case n.kind
  of nnkIdent: "node [Ident] {\"" & n.strVal & "\"} "
  else:"node {" & nK & "} "

proc child(s: string): string = "child { $# } " % s

proc child(n: NimNode): string =
  let nStr = n.repr
  result = child(nStr)

proc astToTikz(n: NimNode): string =
  case n.kind
  of nnkLiterals, nnkIdent, nnkSym:
    result = node(n)
  else:
    result = node(n)
    for ch in n:
      result.add child(astToTikz(ch))

macro toTikZ(n: untyped): untyped =
  let data = "\\" & astToTikz(n) & ";"
  result = newLit(data)

let str = toTikZ:
  type
    myObject {.packed.} = ref object of RootObj
      left: seq[myObject]
      right: seq[myObject]

when isMainModule:
  import latexdsl # to compile directly
  compile("./pictures/tikz_type.tex", str, tmpl)
