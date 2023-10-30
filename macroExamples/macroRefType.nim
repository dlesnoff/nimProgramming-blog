import std/macros

macro defineEquality(typedef: untyped): untyped =
  result = quote do:
    `typedef`

  for statement in typedef:
    if statement.kind == nnkTypeSection:
      for i in 0 ..< statement.len:
        if statement[i].kind == nnkTypeDef:
          var tnode = statement[i]
          if tnode[2].kind == nnkRefTy:
            # When the type section is given in a macro block
            var node = tnode.findChild(it.kind == nnkIdent)
            # When the macro is given as a pragma expression
            if node == nil and tnode[0].kind == nnkPragmaExpr:
              node = tnode[0].findChild(it.kind == nnkIdent)
            if node == nil and tnode[0].kind != nnkPragmaExpr:
              echo "Parsing Error"
            let nameOfType = node
            result = result.add(
              quote("@") do:
                proc `==`*(x, y: `@nameOfType`): bool =
                  if system.`==`(x, y):
                    return true
                  if x.isNil() or y.isNil():
                    return false
                  else:
                    return system.`==`(x[], y[])
              )

when isMainModule:
  type
    MyType = object
      value: int
  # type MyTypeRef = ref MyType
  defineEquality:
    type MyTypeRef = ref MyType
  # type MyTypeRef {.defineEquality.} = ref MyType
  var
    first, second: MyTypeRef
    a = MyType(value:2)
    ptrA = MyTypeRef(value:a.value)
    ptrB = MyTypeRef(value:a.value)

  doAssert first.isNil() == true
  doAssert second.isNil() == true
  doAssert ptrA.isNil() == false
  doAssert ptrB.isNil() == false

  # Two ref objects are equal iff they are both nil or reference to the same object
  doAssert (first == second) == true
  doAssert (ptrA == second) == false
  doAssert (ptrA == ptrB) == true
