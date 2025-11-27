import std/macros
import std/strutils
import std/os
import std/osproc

type
  NodeId = object
    value: string

proc initNodeId(): NodeId =
  result.value = "a"

proc next(id: var NodeId) =
  var pos = id.value.high
  while true:
    id.value[pos] = if id.value[pos] == 'z': 'a' else: chr(id.value[pos].ord + 1)
    if id.value[pos] == 'a':
      dec pos
      if pos == -1:
        id.value.add 'a'
        break
    else:
      break

proc escapeLabel(s: string): string =
  ## Escape special characters for GraphViz labels
  result = s.replace("\"", "'").replace("\n", "\\n")

proc determineLabelShape(node: NimNode): tuple[label: string, shape: string] =
  var label: string
  var shape = "rect"

  case node.kind
  of nnkIdent:
    label = escapeLabel(node.strVal)
    shape = "circle"
  of nnkSym:
    label = escapeLabel(node.strVal)
    shape = "circle"
  of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
    label = $node.kind & "\\n\"" & escapeLabel(node.strVal) & "\""
  of nnkIntLit, nnkInt8Lit, nnkInt16Lit, nnkInt32Lit, nnkInt64Lit,
     nnkUIntLit, nnkUInt8Lit, nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit:
    label = $node.kind & "\\n" & $node.intVal
  of nnkFloatLit, nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit:
    label = $node.kind & "\\n" & $node.floatVal
  of nnkCharLit:
    label = $node.kind & "\\n'" & escapeLabel($chr(node.intVal)) & "'"
  else:
    label = $node.kind
  return (label, shape)


proc nodeToGraphViz(node: NimNode, currentId: var NodeId, parentId: string, result: var string, parents: var seq[string]) =
  ## Recursively convert a NimNode to GraphViz format
  let myId = currentId.value
  currentId.next()

  # Determine node label and shape
  var style = ""
  var (label, shape) = determineLabelShape(node)

  # Output node definition
  result.add myId & "[label=\"" & label & "\", shape=" & shape
  if style != "":
    result.add ", style=" & style
  result.add "];\n"

  # Output edge from parent if exists
  # echo "parentId: ", parentId
  # echo "parents:\n", parents
  if parents.len() > 0:
    result.add parents[^1] & " -> " & myId & ";\n"

  # Track if this node has children (for highlighting)
  let hasChildren = node.len > 0
  if hasChildren:
    parents.add myId

  # Process children
  for child in node:
    nodeToGraphViz(child, currentId, myId, result, parents)

macro toGraphViz*(code: untyped): untyped =
  ## Converts Nim code AST to GraphViz dot format
  ## Returns a string literal containing the GraphViz diagram

  var output = "digraph {\n"
  var currentId = initNodeId()
  var parents: seq[string] = @[]

  nodeToGraphViz(code, currentId, "", output, parents)

  # Highlight parent nodes (nodes with children)
  for parent in parents:
    output.add parent & "[style=filled, fillcolor=lightgray];\n"

  output.add "}\n"

  result = newLit(output)


proc generateGraph*(dotContent, basename: string, format = "jpg", outputDir = "pictures") =
  ## Generate a graph image from GraphViz dot content
  ## - dotContent: the GraphViz dot format string
  ## - basename: base name for files (without extension)
  ## - format: output format (jpg, png, svg, etc.)
  ## - outputDir: directory for output files

  # Create output directory if it doesn't exist
  createDir(outputDir)

  let dotFile = outputDir / basename & ".dot"
  let imgFile = outputDir / basename & "." & format

  # Write dot file
  writeFile(dotFile, dotContent)
  echo "Created: ", dotFile

  # Execute dot command
  let cmd = "dot -T" & format & " -o " & imgFile & " " & dotFile
  let (output, exitCode) = execCmdEx(cmd)

  if exitCode == 0:
    echo "Generated: ", imgFile
  else:
    echo "Error running dot command: ", output
    echo "Command was: ", cmd

## Default arguments are just to showcase what is expected
## They can not be omitted
template astToImage*(basename: string, caption = "", format = "jpg", outputDir = "pictures", code: untyped): untyped =
  ## Template that:
  ## 1. Generates GraphViz from code AST
  ## 2. Writes it to a .dot file
  ## 3. Converts it to an image using dot
  ## 4. Displays it in nimib if available

  # Generate the GraphViz content
  let graphVizContent = toGraphViz:
    code

  # Generate the image
  generateGraph(graphVizContent, basename, format, outputDir)

  # If we're in nimib context, display the image
  when declared(nbImage):
    let imgPath = outputDir / basename & "." & format
    let captionText = if caption == "": basename else: caption
    nbImage(url = imgPath, caption = captionText)

# Example usage:
when isMainModule:
  # Example 1: Simple usage
  echo "=== Example 1: Generate graph without nimib ==="
  astToImage("ast_type_def", "Type definition AST", "jpg", "pictures"):
    type myObject {.packed.} = ref object of RootObj
        left: seq[myObject]
        right: seq[myObject]

  echo ""

  # Example 2: For loop
  echo "=== Example 2: For loop with tuple unpacking ==="
  astToImage("ast_for_loop_tuple", "AST for loop tuple", "jpg", "pictures"):
    for (a, b) in [(1, 2), (3, 4)]:
      echo a, b

# when isMainModule:
  echo "=== Example 1bis: For Loop Graph ==="
  astToImage("ast_for_loop", "AST for loop", "jpg", "pictures"):
    for i in 0..10:
      echo i

  # Example 4: Procedure definition
  astToImage("ast_proc_def", "AST procedure definition", "jpg", "pictures"):
    proc myProc(x: int, y: string): bool =
      return x > 0

  # Example 5: Complex expression
  astToImage("ast_ternary_expression", "AST ternary expression", "jpg", "pictures"):
    let result = if x > 0: "positive" else: "negative"
