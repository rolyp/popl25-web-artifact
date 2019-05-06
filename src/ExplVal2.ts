import { List } from "./BaseTypes2"
import { Expr } from "./Expr2"
import { Func, Env } from "./Func2"
import { Value, make } from "./Value2"

// TODO: break dependency on Expr, by compiling expressions to values?
export class Closure extends Value {
   ρ: Env // ρ is _not_ closing for σ; need to extend with the bindings in δ
   δ: List<Expr.RecDef>
   f: Func<Expr>
}

export function closure (ρ: Env, δ: List<Expr.RecDef>, f: Func<Expr>): Closure {
   return make(Closure, { ρ, δ, f })
}

export namespace Expl {
   export abstract class Expl extends Value {
   }

   export class Empty extends Expl {
   }

   export function empty (): Empty {
      return make(Empty, {})
   }
}

type Expl = Expl.Expl

export type ExplVal = [Expl, Value]