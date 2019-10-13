import { zip } from "../util/Array"
import { absurd, as, className, error } from "../util/Core"
import { Cons, List, Nil } from "../BaseTypes"
import { exprClass } from "../DataType"
import { ExplValue } from "../DataValue"
import { Change, New, Reclassify, __deltas } from "../Delta"
import { emptyEnv } from "../Env"
import { Eval } from "../Eval"
import { Expr, strings } from "../Expr"
import { DataElim, Elim, VarElim } from "../Match"
import { openWithImports } from "../Module"
import { Num, Str, Value, fields } from "../Value"
import { versioned } from "../Versioned"
import { SVG } from "./Core"
import { ExprCursor } from "./Cursor"
import "./styles.css"

import Cont = Expr.Cont

const svg: SVG = new SVG(false)
const fontSize: number = 18
const classes: string = "code"
// bizarrely, if I do this later, font metrics are borked:
const lineHeight = svg.textHeight(svg.textElement(0, 0, fontSize, classes, "m")) // representative character 
// ASCII spaces seem to be trimmed; only Unicode space that seems to render monospaced is this: 
const space: string = "\u00a0"

// Populate explicity, rather than using a memoised function.
type Dimensions = { width: number, height: number }
const dimensions: Map<SVGElement, Dimensions> = new Map()

class Renderer {
   x: number
   line: number

   constructor () {
      this.x = 0
      this.line = 1
   }

   renderPrompt(e: Expr, v: Value): SVGElement {
      const e_g: SVGElement = this.renderExpr(e)
      this.line++
      this.x = 0
      return Renderer.group(
         e_g,
         Renderer.group(
            this.renderText(">"),
            this.space(), this.renderValue(v)
         )
      )
   }

   renderValue (v: Value): SVGElement {
      if (v instanceof Num) {
         return this.renderNum(v, false)
      } else
      if (v instanceof Str) {
         return this.renderText(v.val.toString(), deltaStyle(v))
      } else 
      if (v instanceof List) {
         return Renderer.group(this.renderText("["), ...this.renderElements_([v.toArray(), null]), this.renderText("]"))
      } else {
         return this.renderText(`<${className(v)}>`)
      }
   }

   render (v: Value): SVGElement {
      if (v instanceof Expr.Expr) {
         return this.renderExpr(v)
      } else {
         return this.renderValue(v)
      }
   }

   // Post-condition: returned element has an entry in "dimensions" map. 
   renderExpr (e: Expr): SVGElement {
      if (e instanceof Expr.ConstNum) {
         return this.renderNum(e.val, true)
      } else
      if (e instanceof Expr.ConstStr) {
         return this.renderText(e.val.toString())
      } else
      if (e instanceof Expr.DataExpr) {
         if (className(e) === exprClass(Nil.name).name || className(e) === exprClass(Cons.name).name) {
            return Renderer.group(this.renderText("["), ...this.renderElements_(elements_expr(e)), this.renderText("]"))
         } else {
            return this.renderText(`<${className(e)}>`)
         }
      } else
      if (e instanceof Expr.Var) {
         return this.renderText(e.x.val)
      } else
      if (e instanceof Expr.Fun) {
         return this.renderElim(e.σ)
      } else
      if (e instanceof Expr.BinaryApp) {
         return Renderer.group(this.renderExpr(e.e1), this.space(), this.renderText(e.opName.val), this.space(), this.renderExpr(e.e2))
      } else
      if (e instanceof Expr.App) {
         const g_f: SVGElement = e.f instanceof Expr.Fun ? this.renderParens(e.f) : this.renderExpr(e.f),
               sp: SVGElement = this.space(),
               g_e: SVGElement = e.e instanceof Expr.Fun ? this.renderParens(e.e) : this.renderExpr(e.e)
         return Renderer.group(g_f, sp, g_e)
      } else
      if (e instanceof Expr.Defs) {
         const defs_g: SVGElement = this.renderText(`<${className(e)}>`)
         this.line++
         this.x = 0
         return Renderer.group(defs_g, this.renderExpr(e.e))
      } else {
         return absurd()
      }
   }

   renderParens (e: Expr): SVGElement {
      return Renderer.group(
         this.renderText("("),
         this.renderExpr(e),
         this.renderText(")")
      )
   }

   renderNum (n: Num, editable: boolean): SVGElement {
      const v: SVGElement = this.renderText(n.toString(), deltaStyle(n))
      if (editable && Number.isInteger(n.val)) {
         v.addEventListener("click", (ev: MouseEvent): void => {
            new ExprCursor(n).setNum(n.val + 1)
            ev.stopPropagation()
            editor.onEdit()
         })
      }
      return v
   }

   space (): SVGElement {
      return this.renderText(`${space}`)
   }

   renderElements (e: Expr): SVGElement[] {
      const [es, eʹ]: [Expr[], Expr | null] = elements_expr(e),
            vs: SVGElement[] = []
      es.forEach((e: Expr, n: number): void => {
         vs.push(this.renderExpr(e))
         if (n < es.length - 1) {
            vs.push(this.renderText(","), this.space())
         }
      })
      if (eʹ !== null) {
         vs.push(this.renderText(", ..."), this.renderExpr(eʹ))
      }
      return vs
   }

   renderElements_ ([es, eʹ]: [Value[], Value | null]): SVGElement[] {
      const vs: SVGElement[] = []
      es.forEach((e: Value, n: number): void => {
         vs.push(this.render(e))
         if (n < es.length - 1) {
            vs.push(this.renderText(","), this.space())
         }
      })
      if (eʹ !== null) {
         vs.push(this.renderText(", ..."), this.render(eʹ))
      }
      return vs
   }

   renderElim<K extends Cont> (σ: Elim<K>): SVGElement {
      if (VarElim.is(σ)) {
         return Renderer.group(
            this.renderText(σ.x.val),
            this.space(), this.renderText(strings.arrow), 
            this.space(), this.renderCont(σ.κ)
         )
      } else
      if (DataElim.is(σ)) {
         return Renderer.group(
            ...zip(fields(σ), σ.__children as Cont[]).map(([ctr, κ]) => {
               return Renderer.group(
                  this.renderText(ctr),
                  this.space(),
                  this.renderText(strings.arrow),
                  this.space(),
                  this.renderCont(κ)
               )
            })
         )
      } else {
         return absurd()
      }
   }

   renderCont (κ: Cont): SVGElement {
      if (κ instanceof Expr.Expr) {
         return this.renderExpr(κ)
      } else
      if (κ instanceof Elim) {
         return this.renderElim(κ)
      } else {
         return absurd()
      }
   }

   // TODO: completely broken; ignores the fact that elements have x, y coordinates :-/
   static group (...vs: SVGElement[]): SVGElement {
      const g: SVGGElement = document.createElementNS(SVG.NS, "g")
      let width_sum: number = 0,
          height_max: number = 0
      g.setAttribute("pointer-events", "bounding-box")
      vs.forEach((v: SVGElement): void => {
         const { width, height }: Dimensions = dimensions.get(v)!
         width_sum += width
         height_max = Math.max(height_max, height)
         g.appendChild(v)
      })
      dimensions.set(g, { width: width_sum, height: height_max })
      return g
   }

   renderText (str: string, ẟ_style?: string): SVGTextElement {
      ẟ_style = ẟ_style || "unchanged" // default
      const text: SVGTextElement = svg.textElement(this.x, this.line * lineHeight, fontSize, [classes, ẟ_style].join(" "), str)
      const width: number = svg.textWidth(text)
      dimensions.set(text, { width, height: lineHeight })
      text.remove()
      this.x += width
      return text
   }
}

function deltaStyle (v: Value): string{
   if (versioned(v)) {
      if (v.__ẟ instanceof New) {
         return "new"
      } else
      if (v.__ẟ instanceof Change) {
         if (Object.keys(v.__ẟ.changed).length === 0) {
            return "unchanged"
         } else {
            return "changed"
         }
      } else
      if (v.__ẟ instanceof Reclassify) {
         return "changed"
      } else {
         return absurd()
      }
   } else {
      return absurd()
   }
} 

// Expressions for the elements, plus expression for tail (or null if list terminates with nil).
function elements_expr (e: Expr): [Expr[], Expr | null] {
   if (e instanceof Expr.DataExpr) {
      if (className(e) === exprClass(Nil.name).name) {
         return [[], null]
      } else
      if (className(e) === exprClass(Cons.name).name) {
         // use cursor interface instead?
         const [es, eʹ]: [Expr[], Expr | null] = elements_expr(as(e.__child("tail"), Expr.Expr))
         return [[as(e.__child("head"), Expr.Expr), ...es], eʹ]
      } else {
         return error(`Found ${e.ctr}, expected list.`)
      }
   } else {
      return [[], e]
   }
}

class Editor {
   root: SVGSVGElement
   e0: Expr
   e: Expr
   e_cursor: ExprCursor
   tv: ExplValue

   constructor () {
      this.root = svg.createSvg(800, 400)
      document.body.appendChild(this.root)
      this.e0 = openWithImports("ic2019"),
      this.e = as(this.e0, Expr.Defs).e
      this.e_cursor = new ExprCursor(this.e)
      this.tv = Eval.eval_(emptyEnv(), this.e0) 
      __deltas.clear()         
      // Wait for fonts to load before rendering, otherwise metrics will be wrong.
      window.onload = (ev: Event): void => {
         this.render()
      }
   }

   render (): void {
      // not sure why this shenanigan to clear view
      while (this.root.firstChild !== null) {
         this.root.removeChild(this.root.firstChild)
      }
      this.root.appendChild(new Renderer().renderPrompt(this.e, this.tv.v))
      document.onkeydown = function(ev: KeyboardEvent) {
         if (ev.keyCode == 40) {
           console.log("Down!")
         }
      }
   }

   onEdit (): void {
      this.tv = Eval.eval_(emptyEnv(), this.e0)
      this.render()
   }
}

const editor: Editor =  new Editor()