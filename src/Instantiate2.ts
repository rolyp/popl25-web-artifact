import { absurd } from "./util/Core"
import { List, Pair, pair } from "./BaseTypes2"
import { Env } from "./Env2"
import { Expr } from "./Expr2"
import { Id, Str, Value, _, make } from "./Value2"

import Args = Expr.Args
import Kont = Expr.Kont
import RecDef = Expr.RecDef
import Trie = Expr.Trie

// The "runtime identity" of an expression. In the formalism we use a "flat" representation so that e always has an external id;
// here it is more convenient to use an isomorphic nested format.
export class ExprId extends Id {
   j: List<Value> = _
   e: Expr | RecDef = _
}

export function exprId (j: List<Value>, e: Expr | RecDef): ExprId {
   return make(ExprId, j, e)
}

// F-bounded polymorphism doesn't work well here. I've used it for the smaller helper functions 
// (but with horrendous casts), but not for the two main top-level functions.
export function instantiate<T extends Expr> (ρ: Env, e: T): Expr {
   const j: ExprId = exprId(ρ.entries(), e)
   if (e instanceof Expr.ConstNum) {
      return Expr.constNum(j, e.val)
   } else
   if (e instanceof Expr.ConstStr) {
      return Expr.constStr(j, e.val)
   } else
   if (e instanceof Expr.Constr) {
      return Expr.constr(j, e.ctr, e.args.map(e => instantiate(ρ, e)))
   } else
   if (e instanceof Expr.Fun) {
      return Expr.fun(j, instantiateTrie(ρ, e.σ))
   } else
   if (e instanceof Expr.Var) {
      return Expr.var_(j, e.x)
   } else
   if (e instanceof Expr.Let) {
      return Expr.let_(j, instantiate(ρ, e.e), instantiateTrie(ρ, e.σ))
   } else
   if (e instanceof Expr.LetRec) {
      const δ: List<RecDef> = e.δ.map(def => {
         const i: ExprId = exprId(ρ.entries(), def)
         return Expr.recDef(i, def.x, instantiateTrie(ρ, def.σ))
      })
      return Expr.letRec(j, δ, instantiate(ρ, e.e))
   } else
   if (e instanceof Expr.MatchAs) {
      return Expr.matchAs(j, instantiate(ρ, e.e), instantiateTrie(ρ, e.σ))
   } else
   if (e instanceof Expr.App) {
      return Expr.app(j, instantiate(ρ, e.func), instantiate(ρ, e.arg))
   } else
   if (e instanceof Expr.BinaryApp) {
      return Expr.binaryApp(j, instantiate(ρ, e.e1), e.opName, instantiate(ρ, e.e2))
   } else {
      return absurd()
   }
}

function instantiateTrie<K extends Kont<K>, T extends Trie<K>> (ρ: Env, σ: T): T {
   if (Trie.Var.is(σ)) {
      return Trie.var_(σ.x, instantiateKont(ρ, σ.κ) as K) as Trie<K> as T
   } else
   if (Trie.Constr.is(σ)) {
      return Trie.constr<K>(σ.cases.map(
         ({ fst: ctr, snd: Π }: Pair<Str, Args<K>>): Pair<Str, Args<K>> => {
            return pair(ctr, instantiateArgs(ρ, Π))
         })
      ) as Trie<K> as T
   } else {
      return absurd()
   }
}

// See issue #33.
function instantiateKont<K extends Kont<K>> (ρ: Env, κ: K): K {
   if (κ instanceof Trie.Trie) {
      return instantiateTrie<K, Trie<K>>(ρ, κ) as K 
   } else
   if (κ instanceof Expr.Expr) {
      return instantiate(ρ, κ) as Kont<K> as K
   } else
   if (κ instanceof Args.Args) {
      return instantiateArgs(ρ, κ) as K
   } else {
      return absurd()
   }
}

function instantiateArgs<K extends Kont<K>> (ρ: Env, Π: Args<K>): Args<K> {
   if (Args.End.is(Π)) {
      return Args.end(instantiateKont(ρ, Π.κ))
   } else
   if (Args.Next.is(Π)) {
      return Args.next(instantiateTrie(ρ, Π.σ))
   } else {
      return absurd()
   }
}