import { __nonNull, absurd, error } from "./util/Core"
import { Cons, List, Nil } from "./BaseTypes2"
import { DataType, datatypeFor } from "./DataType2"
import { Env } from "./Env2"
import { Closure, closure } from "./ExplVal2"
import { Expr } from "./Expr2"
import { interpretTrie } from "./Match2"
import { BinaryOp, binaryOps } from "./Primitive2"
import { State_Dyn, Value, construct, num, primOp, str } from "./Value2"

type InterpretExpr = (ρ: Env) => Value

// Repeatedly reinterprets subexpressions, so probably as slow as the previous implementation.
// Should be able to significantly speed up by memoisation.
export function interpret (e: Expr): InterpretExpr {
   return (ρ: Env): Value => {
      if (e instanceof Expr.ConstNum) {
         return num(e.val)
      } else
      if (e instanceof Expr.ConstStr) {
         return str(e.val)
      } else
      if (e instanceof Expr.Fun) {
         return closure(ρ, interpretTrie(e.σ))
      } else
      if (e instanceof Expr.Var) {
         const x: string = e.x.str
         if (ρ.has(x)) { 
            return ρ.get(x)!
         } else {
            return error(`Variable '${x}' not found.`)
         }
      } else
      if (e instanceof Expr.PrimOp) {
         return primOp(e.op)
      } else
      if (e instanceof Expr.App) {
         const v: Value = interpret(e.func)(ρ)
         if (v instanceof Closure) {
            const [ρʹ, eʹ]: [Env, Expr] = v.f.__apply(interpret(e.arg))
            // TODO: closeDefs
            return interpret(eʹ)(Env.concat(ρ, ρʹ))
         } else {
            return error("Not a function")
         }
      } else
      // Operators (currently all binary) are "syntax", rather than names.
      if (e instanceof Expr.BinaryApp) {
         if (binaryOps.has(e.opName.str)) {
            const op: BinaryOp = binaryOps.get(e.opName.str)!, // opName lacks annotations
                  [v1, v2]: [Value, Value] = [interpret(e.e1)(ρ), interpret(e.e2)(ρ)]
            return op.b.op(v1, v2)
         } else {
            return error("Operator name not found.", e.opName)
         }
      } else
      if (e instanceof Expr.Constr) {
         const d: DataType = __nonNull(datatypeFor.get(e.ctr.str)),
               state: State_Dyn = {}
         let e̅: List<Expr> = e.args
         for (const f of d.fields) {
            if (Cons.is(e̅)) {
               state[f] = interpret(e̅.head)(ρ)
               e̅ = e̅.tail
            } else
            if (Nil.is(e̅)) {
               absurd()
            } 
         }
         return construct(new d.cls, state)
      } else 
      if (e instanceof Expr.Let) {
         const [ρʹ, eʹ]: [Env, Expr] = interpretTrie<Expr>(e.σ).__apply(interpret(e.e)(ρ))
         return interpret(eʹ)(Env.concat(ρ, ρʹ))
      } else
      if (e instanceof Expr.MatchAs) {
         const [ρʹ, eʹ]: [Env, Expr] = interpretTrie(e.σ).__apply(interpret(e)(ρ))
         return interpret(eʹ)(Env.concat(ρ, ρʹ))
      } else {
         return absurd()
      }
   }
}
