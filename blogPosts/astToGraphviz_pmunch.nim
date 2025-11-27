import strutils

var
  nodeName = "a"
  lastIndent = 0
  parents: seq[string]

var test: string = readAll(open("astTexts/ASTtree.txt"))
test = test.strip(chars= {'\n'}) # Remove closing end of line

echo "digraph {"
for line in test.splitLines:
  if parents.len == 0:
    echo nodeName, "[label=\"", line.strip, "\", shape=rect]"
  else:
    var thisIndent = (line.len - line.strip(trailing = false, chars = {' '}).len) div 2
    if thisIndent == lastIndent:
      parents.setLen(parents.len - 1) # Discard old non-parent node
    elif thisIndent < lastIndent:
      parents.setLen(parents.len - 1 - (lastIndent - thisIndent)) # Discard old non-parent node and last parent
    lastIndent = thisIndent
    echo nodeName, "[label=\"", line.strip.replace("\"", "'"), "\", shape=rect]"
    echo parents[parents.high], " -> ", nodeName
  parents.add nodeName

  var pos = nodeName.high
  while true:
    nodeName[pos] = if nodeName[pos] == 'z': 'a' else: chr(nodeName[pos].ord + 1)
    if nodeName[pos] == 'a':
      dec pos
      if pos == -1:
        nodeName.add 'a'
        break
    else:
      break
for parent in 0..<parents.high:
  echo parents[parent], "[style=filled]"
echo "}"
