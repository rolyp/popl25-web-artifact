/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { Edit } from "./util/Core"
import { assert } from "../src/util/Core"
import { Expr } from "../src/Expr"
import { open } from "../src/Module"
import { Delta } from "../src/Value"
import { ExprCursor } from "..//src/app/Cursor"

import Trie = Expr.Trie

before((done: MochaDone) => {
   done()
})

describe("edit", () => {
   describe("arithmetic-edit", () => {
      it("ok", () => {
         const e: Expr = open("arithmetic")
         new (class extends Edit {
            setup (here: ExprCursor) {
               here.skipImports()
                   .to(Expr.BinaryApp, "e1")
                   .to(Expr.BinaryApp, "e2")
                   .to(Expr.ConstNum, "val")
                   .setNum(6)
            }

            expect (delta: Delta) {
               assert(delta.size === 3)
               const [[, prop1, v1], [, prop2, v2], [, prop3, v3]] = delta
               assert(prop1 === "val" && typeof v1 === "number" && v1 === 6)
               assert(prop2 === "val" && typeof v2 === "number" && v2 === 7)
               assert(prop3 === "val" && typeof v3 === "number" && v3 === 49)
            }
         })(e)
      })
   })

   describe("filter-edit", () => {
      it("ok", () => {
         const e: Expr = open("filter")
         new (class extends Edit {
            setup (here: ExprCursor) {
               here.skipImports()
                   .to(Expr.App, "f")
                   .to(Expr.App, "e")
                   .to(Expr.Fun, "σ")
                   .to(Trie.Var, "κ")
                   .to(Expr.BinaryApp, "e1")
                   .to(Expr.ConstNum, "val")
                   .setNum(3)
            }

            expect (delta: Delta) {
               assert(delta.size === 0)
            }
         })(e)
      })
   })
})
