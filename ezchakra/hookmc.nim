import macros

import importmc
import ezfunchook
import ezutils

import hookctx

macro hookmc*(sym: static string, body: untyped) =
  let xtype = nnkProcTy.newTree(
    body[3].copy(),
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