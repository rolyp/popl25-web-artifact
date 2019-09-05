import { absurd } from "./util/Core"
import { DataValue, Expl_ } from "./DataValue"
import { Str, _, make } from "./Value"

// Idiom is to permit instance methods on reflected datatypes, but not have them use polymorphism.

// Environments are snoc lists.
export abstract class Env extends DataValue<"Env"> {
   get (k: Str): Expl_ | undefined {
      if (this instanceof EmptyEnv) {
         return undefined
      } else
      if (this instanceof ExtendEnv) {
         if (this.k.val === k.val) {
            return this.tv
         } else {
            return this.ρ.get(k)
         }
      } else {
         return absurd()
      }
   }
   
   has (k: Str): boolean {
      return this.get(k) !== undefined
   }

   static singleton (k: Str, tv: Expl_): ExtendEnv {
      return extendEnv(emptyEnv(), k, tv)
   }
   
   concat (ρ: Env): Env {
      if (ρ instanceof EmptyEnv) {
         return this
      } else
      if (ρ instanceof ExtendEnv) {
         return extendEnv(this.concat(ρ.ρ), ρ.k, ρ.tv)
      } else {
         return absurd()
      }
   }
}

export class EmptyEnv extends Env {
}

export function emptyEnv (): EmptyEnv {
   return make(EmptyEnv)
}

export class ExtendEnv extends Env {
   ρ: Env = _
   k: Str = _
   tv: Expl_ = _
}

export function extendEnv (ρ: Env, k: Str, tv: Expl_): ExtendEnv {
   return make(ExtendEnv, ρ, k, tv)
}
