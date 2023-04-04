import nimib, nimib / [paths, gits], os, strutils, strformat

nbInit

var
  listOfDrafts: string = ""
  link: string = ""

for file in walkDirRec(nbHomeDir):
  # echo getFileInfo(file).id.repr
  if not file.endswith(".html") or file.name.startsWith("index") or (not file.isGitTracked):
    # echo file.repr, " ", file.isGitTracked
    continue
  link = file.relPath.replace(r"\", "/")
  echo "adding link: ", link
  when defined(nblogRerun):
    let cmd = "nim r " & link.replace(".html", ".nim")
    echo "executing " & cmd
    if execShellCmd(cmd) != 0:
      echo cmd & " FAILED"
  listOfDrafts.add(&"* [{link}]({link})\n")

nbText: """# Dimitri Lesnoff's blog
A blog about the Nim language. You can find some of my programs and tutorials.
""" & listOfDrafts

nbText: """
based on [Pietro Peterlongo's blog](https://pietroppeter.github.io/nblog).
"""
nbSave
