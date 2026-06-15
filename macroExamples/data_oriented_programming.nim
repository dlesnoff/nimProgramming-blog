## Objective: transform a seq of a type into a type of seqs
type
  Enemy = object
    x, y: float32
    hp: int
    speed: float32

import macros

macro soa*(name, T: typed): untyped =
  let impl = T.getImpl()

  if impl.kind != nnkTypeDef:
    error("expected object type")

  let obj = impl[2]

  if obj.kind != nnkObjectTy:
    error("expected object")

  var recList = newNimNode(nnkRecList)

  for field in obj[2]:
    if field.kind == nnkIdentDefs:
      let fieldType = field[^2]

      for i in 0 ..< field.len - 2:
        let fieldName = field[i]

        recList.add(
          nnkIdentDefs.newTree(
            fieldName,
            nnkBracketExpr.newTree(
              ident("seq"),
              fieldType
            ),
            newEmptyNode()
          )
        )

  result = quote do:
    type
      `name` = object
        `recList`


soa(World, Enemy)
var w: World
