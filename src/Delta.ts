import { absurd } from "./util/Core"
import { Ord } from "./util/Ord"
import { State, Value, leq, mergeInto } from "./Value"

export class Deltas {
   ẟ̅: Map<Value, Delta> = new Map()

   get size (): number {
      return this.ẟ̅.size
   }

   // Updates to a change set must be increasing at a given revision. Because of sharing within
   // a revision, a node may first appear new (or reclassified) and then later appear changed; again,
   // the later changes must be compatible with the initial state of the object at that revision.
   changed (v: Value, s: State): void {
      let v_ẟ: Delta | undefined = this.ẟ̅.get(v)
      if (v_ẟ === undefined) {
         this.ẟ̅.set(v, new Change(s))
      } else
      if (v_ẟ instanceof Change) {
         mergeInto(v_ẟ.changed, s)
      } else
      if (v_ẟ instanceof New || v_ẟ instanceof Reclassify) {
         mergeInto(v_ẟ.state, s)
      } else {
         absurd()
      }
   }

   // A value cannot be reclassified twice at the same revision.
   reclassified (v: Value, s: State): void {
      let v_ẟ: Delta | undefined = this.ẟ̅.get(v)
      if (v_ẟ === undefined) {
         this.ẟ̅.set(v, new Reclassify(s))
      } else {
         absurd()
      }
   }

   // A value cannot be created twice at the same revision.
   created (v: Value, s: State): void {
      let v_ẟ: Delta | undefined = this.ẟ̅.get(v)
      if (v_ẟ === undefined) {
         this.ẟ̅.set(v, new New(s))
      } else {
         absurd()
      }
   }

   clear (): void {
      this.ẟ̅.clear()
   }
}

export const __deltas: Deltas = new Deltas()

export abstract class Delta implements Ord<Delta> {
   abstract leq (ẟ: Delta): boolean

   eq (ẟ: Delta): boolean {
      return this.leq(ẟ) && ẟ.leq(this)
   }
}

export class New extends Delta {
   state: State

   constructor (state: State) {
      super()
      this.state = state
   }

   leq (ẟ: Delta): boolean {
      return ẟ instanceof New && leq(this.state, ẟ.state)
   }
}

export class Change extends Delta {
   changed: State

   constructor (changed: State) {
      super()
      this.changed = changed
   }

   leq (ẟ: Delta): boolean {
      return ẟ instanceof Change && leq(this.changed, ẟ.changed)
   }
}

// Constructor has changed, and therefore fields may not align. More sophisticated reclassification
// delta could allow for fields to be shared when an object changes class.
export class Reclassify extends Delta {
   state: State

   constructor (state: State) {
      super()
      this.state = state
   }

   leq (ẟ: Delta): boolean {
      return ẟ instanceof Reclassify && leq(this.state, ẟ.state)
   }
}