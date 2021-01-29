import macros

import ezfunchook
import ezutils

import ./importmc, ./hookctx
import ./private/abifix

macro hookmc*(sym: static string, body: untyped{nkProcDef}) =
  let params = if body[4].kind == nnkPragma and body[4].len == 1 and $body[4][0][0] == "thisabi":
    transformParams(body[4][0][1], body[3])
  else:
    body[3].copy()
  let xtype = nnkProcTy.newTree(
    params,
    nnkPragma.newTree(ident "cdecl")
  )
  let fname = getNimIdent(body[0])
  let origin_id = ident(fname & "_origin")
  let hooked_id = ident(fname & "_hooked")
  result = nnkStmtList.newTree()
  result.add nnkLetSection.newTree(
    nnkIdentDefs.newTree(
      body[0],
      newEmptyNode(),
      nnkCall.newTree(
        bindSym "findSymbol",
        newLit sym,
        xtype,
      )
    )
  )
  result.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      origin_id,
      xtype,
      newEmptyNode()
    )
  )
  let hooked = body.copy()
  hooked[0] = hooked_id
  hooked[3] = params
  hooked[4] = nnkPragma.newTree(
    ident "cdecl"
  )
  result.add hooked
  result.add nnkAsgn.newTree(
    origin_id,
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          bindSym "getHookContext"
        ),
        bindSym "hook"
      ),
      ident fname,
      hooked_id,
    )
  )