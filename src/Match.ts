import { Class, __nonNull, absurd, assert, className, error } from "./util/Core"
import { Annotation, ann } from "./util/Lattice"
import { setjoinα } from "./Annotated"
import { List, Pair, cons, nil } from "./BaseTypes"
import { DataValue, ExplValue } from "./DataValue"
import { DataType, ctrToDataType, elimToDataType } from "./DataType"
import { Env, emptyEnv } from "./Env"
import { Expl } from "./Expl"
import { Expr } from "./Expr"
import { Str, Value, _, make } from "./Value"

import Cont = Expr.Cont
import Trie = Expr.Trie

type RuntimeCont = Expr | DataValue<"Elim">

// Conceptually (syntactic) tries map to (semantic) elim forms, and exprs map to exprs; no easy way to 
// express this in the type system.
export function evalTrie (σ: Trie<Expr>): Elim<Expr> {
   return evalTrie_(σ) as Elim<Expr>
}

function evalTrie_<K extends Cont> (σ: Trie<K>): Elim {
   if (Trie.Var.is(σ)) {
      return varElim(σ.x, evalCont(σ.κ))
   } else
   if (Trie.Constr.is(σ)) {
      const cases: Pair<Str, K>[] = σ.cases.toArray(),
            c̅: string[] = cases.map(({ fst: c }) => c.val),
            d: DataType = __nonNull(ctrToDataType.get(c̅[0])),
            c̅ʹ: string[] = [...d.ctrs.keys()], // also sorted
            f̅: RuntimeCont[] = []
      let n: number = 0
      for (let nʹ: number = 0; nʹ < c̅ʹ.length; ++nʹ) {
         if (c̅.includes(c̅ʹ[nʹ])) {
            f̅.push(evalCont(cases[n++].snd))
         } else {
            f̅.push(undefined as any)
         }
      }
      assert(n === cases.length)
      return make(d.elimC as Class<DataElim>, ...f̅)
   } else {
      return absurd()
   }
}

function evalCont<K extends Cont> (κ: K): RuntimeCont {
   if (κ instanceof Trie.Trie) {
      const σ: Trie<K> = κ
      return evalTrie(σ)
   } else
   if (κ instanceof Expr.Expr) {
      return κ
   } else {
      return absurd()
   }
}

// Preorder traversal of all nodes in the matched prefix.
type MatchPrefix = List<ExplValue>

export class Match<K> extends DataValue<"Match"> {
   tv̅: MatchPrefix = _
   κ: K = _
}

export function match<K extends RuntimeCont> (ξ: MatchPrefix, κ: K): Match<K> {
   return make(Match, ξ, κ) as Match<K>
}

// See GitHub issue #128.
export abstract class Elim<K extends RuntimeCont = RuntimeCont> extends DataValue<"Elim"> {
   // could have called this "match", but conflicts with factory method of same name
   apply (tv: ExplValue): [Env, Match<K>] {
      return this.apply_(tv, nil())
   }

   abstract apply_ (tv: ExplValue, ξ: MatchPrefix): [Env, Match<K>]
}

// Parser ensures constructor calls are saturated.
function matchArgs (κ: RuntimeCont, tv̅: ExplValue[], u̅: MatchPrefix): [Env, Match<RuntimeCont>] {
   if (tv̅.length === 0) {
      return [emptyEnv(), match(u̅, κ)]
   } else {
      const [tv, ...tv̅ʹ] = tv̅
      if (κ instanceof Elim) {
         const f: Elim = κ, // "unfold" K into Elim<K>
               [ρ, ξ]: [Env, Match<RuntimeCont>] = f.apply_(tv, u̅),
               [ρʹ, ξʹ]: [Env, Match<RuntimeCont>] = matchArgs(ξ.κ, tv̅ʹ, ξ.tv̅)
         return [ρ.concat(ρʹ), ξʹ]
      } else {
         return absurd("Too many arguments to constructor.")
      }
   }
}

// No need to parameterise these two claseses over subtypes of RuntimeCont because only ever use them at RuntimeCont 
// itself. Concrete instances have a field per constructor, in *lexicographical* order.
export abstract class DataElim extends Elim {
   apply_ (tv: ExplValue, u̅: MatchPrefix): [Env, Match<RuntimeCont>] {
      const v: Value = tv.v,
            c: string = className(v)
      if (v instanceof DataValue) {
         const κ: RuntimeCont = (this as any)[c] as RuntimeCont
         if (κ !== undefined) {
            const tv̅: ExplValue[] = Expl.explChildren(tv.t, v),
            [ρ, ξ]: [Env, Match<RuntimeCont>] = matchArgs(κ, tv̅, u̅)
            return [ρ, match(cons(tv, ξ.tv̅), ξ.κ)]
         } else {
            const d: DataType = elimToDataType.get(className(this))!
            if (d.ctrs.has(c)) {
               return error(`Pattern mismatch: ${c} case is undefined for ${d.name.val} eliminator.`)
            } else {
               return error(`Pattern mismatch: found ${c}, expected ${d.name.val}.`)
            }
         }
      } else {
         return error(`Pattern mismatch: ${c} is not a datatype.`, v, this)
      }
   }
}

class VarElim extends Elim {
   x: Str = _
   κ: RuntimeCont = _

   apply_ (tv: ExplValue, ξ: MatchPrefix): [Env, Match<RuntimeCont>] {
      return [Env.singleton(this.x, tv), match(ξ, this.κ)]
   }
}

function varElim (x: Str, κ: RuntimeCont): VarElim {
   return make(VarElim, x, κ) as VarElim
}

export function apply_fwd (ξ: Match<Expr>): Annotation {
   return ξ.tv̅.toArray().reduce((α: Annotation, tv: ExplValue): Annotation => ann.meet(α, tv.t.__α), ann.top)
}

export function apply_bwd (ξ: Match<Expr>, α: Annotation): void {
   ξ.tv̅.toArray().map((tv: ExplValue): Value => setjoinα(α, tv.t))
}
