/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { BwdSlice, FwdSlice } from "./util/Core"
import { Cons, List, Nil, NonEmpty, Pair, Some, True } from "../src/BaseTypes"
import { Env, ExtendEnv, emptyEnv } from "../src/Env"
import { Expr } from "../src/Expr"
import { bindDataset, openDatasetAs, openWithImports, openWithImports2 } from "../src/Module"
import { Str } from "../src/Value"
import { ExprCursor, ExplValueCursor } from "..//src/app/Cursor"

before((done: MochaDone) => {
   done()
})

// Putting test name in a variable interacts poorly with asynchronous execution.
describe("slice", () => {
   describe("arithmetic", () => {
      it("ok", () => {
         const e: Expr = openWithImports("arithmetic")
         new (class extends FwdSlice {
            setup (here: ExprCursor): void {
               here
                  .skipImports()
                  .to(Expr.BinaryApp, "e1").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αclear()
            } 
         })(true, e)
         new BwdSlice(true, e)
      })
   })

/*
   describe("bar-chart", () => {
      it("ok", () => {
         const ρ: ExtendEnv = openDatasetAs("renewables", "data"),
               e: Expr = openWithImports("bar-chart")
         new (class extends FwdSlice {
            setup (_: ExprCursor): void {
               const here: ExplValueCursor = ExplValueCursor.descendant(null, ρ.tv)
               here.to(Cons, "head")
                   .to(Pair, "snd")
                   .to(Cons, "head")
                   .to(Pair, "snd")
                   .to(Cons, "head")
                   .to(Pair, "snd").clearα()
            }
            expect (here: ExplValueCursor): void {
					const hereʹ = here
                  .to(Graphic, "gs")
                  .to(Cons, "head")
                  .to(Graphic, "gs")
                  .to(Cons, "tail")
                  .to(Cons, "head")
                  .to(Translate, "g")
                  .to(Graphic, "gs")
                  .to(Cons, "head")
                  .to(Translate, "g")
                  .to(Translate, "g")
                  .to(Graphic, "gs")
                  .to(Cons, "head")
                  .to(Translate, "g")
                  .to(Graphic, "gs")
                  .to(Cons, "head")
                  .to(Translate, "g")
                  .to(Polygon, "points")
                  .to(Cons, "tail")
                  .to(Cons, "tail")
               hereʹ.to(Cons, "head").to(Point, "y").αclear()
               hereʹ.to(Cons, "tail").to(Cons, "head").to(Point, "y").αclear()
            }
         })(e, ρ)
         new (class extends BwdSlice {
            setup (here: ExplValueCursor): void {
               here.setα()
            }
            expect (here: ExprCursor): void {
               here.αset()
            }
         })(e, ρ)
      })
   })
*/

   describe("compose", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("compose")
         new FwdSlice(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   // merge with bar-chart test case once we implement loading from JSON or similar
   describe("create-dataset", () => {
      it("ok", () => {
         const data: Object[] = [
            // some subset of the renewables dataset
            { year: 2015, country: "China", energyType: "Bio", value: 10.3 },
            { year: 2015, country: "China", energyType: "Geothermal", value: 0 },
            { year: 2015, country: "China", energyType: "Hydro", value: 296 }
         ]
         const ρ: ExtendEnv = bindDataset(emptyEnv(), data, "data")
         const [ρʹ, e]: [Env, Expr] = openWithImports2("create-dataset")
         new FwdSlice(false, e, ρ.concat(ρʹ))
      })
   })

   describe("factorial", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("factorial")
         new FwdSlice(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("filter", () => {
      it("ok", () => {
         const e: Expr = openWithImports("filter")
         new (class extends FwdSlice {
            setup (here: ExprCursor): void {
               here
                  .toDef("filter")
                  .to(Expr.RecDef, "σ")
                  .var_("p")
                  .to(Expr.Fun, "σ")
                  .toCase(Cons)
                  .var_("x").var_("xs")
                  .to(Expr.Defs, "e")
                  .to(Expr.MatchAs, "σ")
                  .toCase(True)
                  .constr_to(Cons, "head").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αset()
               here.to(Cons, "head").αclear()
               here.to(Cons, "tail").to(Cons, "tail").assert(List, v => Nil.is(v))
            }
         })(true, e)
         new BwdSlice(true, e)
      })
   })

   describe("foldr_sumSquares", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("foldr_sumSquares")
         new FwdSlice(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("length", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("length"),
               here: ExprCursor = new ExprCursor(e).to(Expr.App, "e")
         // erasing the elements doesn't affect the count:
         new (class extends FwdSlice {
            setup (_: ExprCursor): void {
               here.constr_to(Cons, "head").clearα()
               here.constr_to(Cons, "tail").constr_to(Cons, "head").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αset()
            }
         })(false, e, ρ)
         // deleting the tail of the tail means length can't be computed:
         new (class extends FwdSlice {
            setup (_: ExprCursor): void {
               here.constr_to(Cons, "tail").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αclear()
            }
         })(false, e, ρ)
         // needing the result only needs the cons cells:
         new (class extends BwdSlice {
            setup (here: ExplValueCursor): void {
               here.setα()
            }
            expect (): void {
               here.αset()
               here.constr_to(Cons, "head").αclear()
               let hereʹ = here.constr_to(Cons, "tail").αset()
               hereʹ.constr_to(Cons, "head").αclear()
               hereʹ.constr_to(Cons, "tail").αset()
            }
         })(false, e, ρ)
      })
   })

   describe("lexicalScoping", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("lexicalScoping")
         new FwdSlice(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("lookup", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("lookup"),
               here: ExprCursor = new ExprCursor(e)
            .to(Expr.Defs, "e")
            .to(Expr.App, "e")
	      new (class extends FwdSlice {
            setup (_: ExprCursor): void {
					here
						.constr_to(NonEmpty, "left")
						.constr_to(NonEmpty, "t")
						.constr_to(Pair, "fst").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.to(Some, "t").assert(Str, str => str.toString() === `"sarah"`)
               here.αset()
            }
         })(false, e, ρ)
         new (class extends FwdSlice {
            setup (_: ExprCursor): void {
               here
                  .constr_to(NonEmpty, "t")
                  .constr_to(Pair, "fst").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αclear()
            }
         })(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("map", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("map")
         new (class extends FwdSlice {
            setup (here: ExprCursor): void {
               here
                  .to(Expr.Defs, "e")
                  .to(Expr.App, "e")
                  .constr_to(Cons, "head").clearα()
              }
            expect (here: ExplValueCursor): void {
               here.to(Cons, "head").αclear()
               here.to(Cons, "tail").αset()
            }
         })(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("mergeSort", () => {
      it("ok", () => {
         const [ρ, e]: [Env, Expr] = openWithImports2("mergeSort")
         new FwdSlice(false, e, ρ)
         new BwdSlice(false, e, ρ)
      })
   })

   describe("graphics/background", () => {
      it("ok", () => {
         const e: Expr = openWithImports("graphics/background")
         new FwdSlice(true, e)
         new BwdSlice(true, e)
      })
   })

   describe("graphics/grouped-bar-chart", () => {
      it("ok", () => {
         const ρ: ExtendEnv = openDatasetAs("renewables", "data")
         const e: Expr = openWithImports("graphics/grouped-bar-chart")
         new FwdSlice(true, e, ρ)
         new BwdSlice(true, e, ρ)
      })
   })

   describe("graphics/line-chart", () => {
      it("ok", () => {
         const ρ: ExtendEnv = openDatasetAs("renewables", "data")
         const e: Expr = openWithImports("graphics/line-chart")
         new FwdSlice(true, e, ρ)
         new BwdSlice(true, e, ρ)
      })
   })

   describe("graphics/stacked-bar-chart", () => {
      it("ok", () => {
         const ρ: ExtendEnv = openDatasetAs("renewables", "data")
         const e: Expr = openWithImports("graphics/stacked-bar-chart")
         new FwdSlice(true, e, ρ)
         new BwdSlice(true, e, ρ)
      })
   })

   describe("normalise", () => {
      it("ok", () => {
         const e: Expr = openWithImports("normalise")
         new FwdSlice(true, e)
         // retaining either component of pair retains both subcomputations:
         new (class extends BwdSlice {
            setup (here: ExplValueCursor): void {
               here.to(Pair, "fst").setα()
            }
            expect (here: ExprCursor): void {
               here = here.skipImports()
               here.toDef("x").to(Expr.Let, "e").αset()
               here.toDef("y").to(Expr.Let, "e").αset()
            }
         })(true, e)
      })
   })

   describe("pattern-match", () => {
      it("ok", () => {
         const e: Expr = openWithImports("pattern-match")
         new BwdSlice(true, e)
         new FwdSlice(true, e)
      })
   })

   describe("reverse", () => {
      it("ok", () => {
         const e: Expr = openWithImports("reverse")
         new (class extends FwdSlice {
            setup (here: ExprCursor): void {
               here
                  .skipImports()
                  .to(Expr.App, "e")
                  .constr_to(Cons, "tail")
                  .constr_to(Cons, "tail").clearα()
            }
            expect (here: ExplValueCursor): void {
               here.αclear()
               here.to(Cons, "head").αset()
               here.to(Cons, "tail").αset()
            }
         })(true, e)
         new BwdSlice(true, e)
      })
   })

   describe("typematch", () => {
      it("ok", () => {
         const e: Expr = openWithImports("typematch")
         new FwdSlice(true, e)
         new BwdSlice(true, e)
      })
   })

   describe("zipWith", () => {
      it("ok", () => {
         const e: Expr = openWithImports("zipWith")
         new FwdSlice(true, e)
         // needing first cons cell of output needs same amount of input lists
         new (class extends BwdSlice {
            setup (here: ExplValueCursor): void {
               here.setα()
            }
            expect (here: ExprCursor): void {
               here.toDef("zipWith").αset().to(Expr.RecDef, "σ").var_("op").αset()
               here = here.skipImports()
               here.to(Expr.App, "e").αset()
               here.to(Expr.App, "f").to(Expr.App, "e").αset()
            }
         })(true, e)
         // needing constructor of first element requires constructor at head of supplied op, plus application of op in zipW
         new (class extends BwdSlice {
            setup (here: ExplValueCursor): void {
               here.to(Cons, "head").setα()
            }
            expect (here: ExprCursor): void {
               let hereʹ: ExprCursor = here
                  .toDef("zipWith")
                  .to(Expr.RecDef, "σ")
                  .var_("op")
                  .to(Expr.Fun, "σ")
               hereʹ.toCase(Nil).αclear() // body of outer Nil clause
               hereʹ = hereʹ
                  .toCase(Cons)
                  .var_("x").var_("xs").αclear()
                  .to(Expr.Fun, "σ")
                  .toCase(Cons)
                  .var_("y").var_("ys").αclear() // cons constructor
                  .constr_to(Cons, "head").αset() // application of op
                  .to(Expr.App, "e").αset()  // pair constructor
               hereʹ.constr_to(Pair, "fst").αclear()
               hereʹ.constr_to(Pair, "snd").αclear()
               here
                  .skipImports()
                  .to(Expr.App, "f")
                  .to(Expr.App, "f")
                  .to(Expr.App, "e")
                  .to(Expr.Fun, "σ")
                  .toCase(Pair)
                  .var_("x").var_("y").αset()
            }
         })(true, e)
      })
   })
})
