import { as } from "../util/Core"
import { ExplValue, explValue } from "../DataValue"
import { __deltas } from "../Delta"
import { Env, emptyEnv } from "../Env"
import { Eval } from "../Eval"
import { Expl } from "../Expl"
import { Expr } from "../Expr"
import { Renderer, svg } from "./Renderer"
import { Renderer2 } from "./View"
import { newRevision } from "../Versioned"
import "./styles.css"

export class Editor {
   root: SVGSVGElement
   e: Expr
   tv: ExplValue

   constructor (e: Expr, ρ: Env = emptyEnv()) {
      this.root = svg.createSvg(1400, 600)
      document.body.appendChild(this.root)
      this.e = e,
      this.tv = Eval.eval_(ρ, this.e)
      newRevision()
      Eval.eval_(ρ, this.e) // reestablish reachable nodes
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
      const tv: ExplValue = explValue(as(this.tv.t, Expl.Defs).t, this.tv.v) // skip prelude
      const [g1, height]: [SVGElement, number] = new Renderer2().render(tv, this)
      this.root.appendChild(g1)
      const g2: SVGElement = new Renderer(this).explValue(false, tv)
      g2.setAttribute("y", height.toString())
      this.root.appendChild(g2)
      document.onkeydown = function(ev: KeyboardEvent) {
         if (ev.keyCode == 40) {
           console.log("Down!")
         }
      }
   }

   onEdit (): void {
      this.tv = Eval.eval_(emptyEnv(), this.e)
      this.render()
   }
}
