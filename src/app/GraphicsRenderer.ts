import { __nonNull, absurd, assert } from "../util/Core"
import { Cons, List } from "../BaseTypes"
import { Graphic, GraphicsElement, LinearTransform, Polygon, Polyline, Point, Scale, Transform, Translate, Transpose } from "../Graphics"
import { asVersioned } from "../Versioned"

export const svgNS: "http://www.w3.org/2000/svg" = "http://www.w3.org/2000/svg"
type TransformFun = (p: [number, number]) => [number, number]

// No counterpart of this in the graphics DSL yet.
export const reflect_y: TransformFun =
   ([x, y]): [number, number] => {
      return [x, -y]
   }

function scale (x_scale: number, y_scale: number): TransformFun {
   return ([x, y]): [number, number] => {
      return [x * x_scale, y * y_scale]
   }
}

function translate (x_inc: number, y_inc: number): TransformFun {
   return ([x, y]): [number, number] => {
      return [x + x_inc, y + y_inc]
   }
}

function postcompose (f1: TransformFun, f2: TransformFun): TransformFun {
   return ([x, y]): [number, number] => {
      return f1(f2([x, y]))
   }
}

const transpose: TransformFun =
   ([x, y]): [number, number] => {
      return [y, x]
   }

export interface Slicer {
   bwdSlice (): void
   bwdSlice (): void
}

export class GraphicsRenderer {
   transforms: TransformFun[] // stack of successive compositions of linear transformations
   svg: SVGSVGElement
   slicer: Slicer

   constructor (svg: SVGSVGElement, slicer: Slicer) {
      this.svg = svg
      this.slicer = slicer
      this.transforms = [x => x]
   }

   get transform (): TransformFun {
      assert(this.transforms.length > 0)
      // query the current transform rather than returing a closure that accesses it...
      const transform: TransformFun = this.transforms[this.transforms.length - 1]
      return ([x, y]) => {
         const [xʹ, yʹ] = transform([x, y])
         return [Math.round(xʹ), Math.round(yʹ)]
      } 
   }

   render (g: GraphicsElement): void {
      while (this.svg.firstChild !== null) {
         this.svg.removeChild(this.svg.firstChild)
      }
      this.renderElement(g)
   }

   renderElement (g: GraphicsElement): void {
      if (g instanceof Graphic) {   
         for (let gs: List<GraphicsElement> = g.gs; Cons.is(gs); gs = gs.tail) {
            this.renderElement(gs.head)
         }
      } else 
      if (g instanceof Polyline) {
         this.polyline(g.points)
      } else
      if (g instanceof Polygon) {
         this.polygon(g.points)
      } else
      if (g instanceof Transform) {
         const t: LinearTransform = g.t
         if (t instanceof Scale) {
            this.renderWith(g.g, scale(t.x.val, t.y.val))
         } else
         if (t instanceof Translate) {
            this.renderWith(g.g, translate(t.x.val, t.y.val))
         } else
         if (t instanceof Transpose) {
            this.renderWith(g.g, transpose)
         } else {
            return absurd()
         }
      }
      else {
         return absurd()
      }
   }

   renderWith (g: GraphicsElement, f: TransformFun): void {
      const transform: TransformFun = this.transform
      this.transforms.push(postcompose(transform, f))
      this.renderElement(g)
      this.transforms.pop()
   }

   svgPath (p̅: List<Point>): [number, number][] {
      return p̅.toArray().map(({ x, y }): [number, number] => this.transform([x.val, y.val]))
   }

   points (p̅: List<Point>): string {
      return this.svgPath(p̅).map(([x, y]: [number, number]) => `${x},${y}`).join(" ")
   }

   polyline (p̅: List<Point>): void {
      const path = document.createElementNS(svgNS, "polyline")
      path.setAttribute("points", this.points(p̅))
      path.setAttribute("stroke", "black")
      this.svg.appendChild(path)
      this.pointHighlights(p̅)
   }

   pointHighlights (p̅: List<Point>): void {
      for (; Cons.is(p̅); p̅ = p̅.tail) {
         const p: Point = p̅.head,
               [x, y]: [number, number] = this.transform([p.x.val, p.y.val])
         if (!__nonNull(asVersioned(p.x).__α) || !__nonNull(asVersioned(p.y).__α)) {
            this.circle(x, y, 3)
         }
      }
   }

   circle (x: number, y: number, radius: number): void {
      const circle = document.createElementNS(svgNS, "circle")
      circle.setAttribute("cx", x.toString())
      circle.setAttribute("cy", y.toString())
      circle.setAttribute("r", radius.toString())
      circle.setAttribute("stroke", "#0000ff")
      circle.setAttribute("fill", "none")
      this.svg.appendChild(circle)
   }

   // DELETE ME
   p̅: Point[]

   polygon (p̅: List<Point>): void {
      const polygon = document.createElementNS(svgNS, "polygon")
      polygon.setAttribute("points", this.points(p̅))
      polygon.setAttribute("stroke", "black")
      polygon.setAttribute("fill", "#f6831e")
      polygon.addEventListener("click", (e: MouseEvent): void => {
         this.p̅ = []
         p̅.toArray().map((p: Point): void => {
            this.p̅.push(p)
            console.log(`Clearing annotation on ${p}`)
            asVersioned(p.x).__α = false
            asVersioned(p.y).__α = false
         })
         this.slicer.bwdSlice()
      })
      this.svg.appendChild(polygon)
      this.pointHighlights(p̅)
   }
}
