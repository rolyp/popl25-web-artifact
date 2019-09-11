import { Class, __nonNull } from "./util/Core"
import { Annotation, ann } from "./util/Lattice"
import { DataValue } from "./DataValue"
import { MemoFunType, Num, Persistent, Str, Value, ValueTag, _, memo } from "./Value"
import { ν, at } from "./Versioned"

// For trait idiom see https://www.bryntum.com/blog/the-mixin-pattern-in-typescript-all-you-need-to-know/ and
// https://github.com/Microsoft/TypeScript/issues/21710.
export function AnnotatedC<T extends Class<Value>> (C: T) {
   // https://stackoverflow.com/questions/33605775
   return {
      [C.name]: class extends C {
            __α: Annotation = _
         }
   }[C.name] // give versioned class same name as C
}

export type Annotated<T> = T & {
   __α: Annotation
}

export function annotated<T extends Object> (v: T): v is Annotated<T> {
   return v.hasOwnProperty("__α")
}

export function setα<T, U extends Annotated<T>> (α: Annotation, v: U): U {
   v.__α = α
   return v
}

// Memoising an imperative function makes any side effects idempotent. Not clear yet how to "partially" 
// memoise LVar-like functions like joinα, but setall isn't one of those.
export function setallα<T extends Persistent> (α: Annotation, v: T): T {	
   return memo<T>(setallα_ as MemoFunType<T>, α, v)
}	

export function setallα_<Tag extends ValueTag, T extends Value<Tag>> (α: Annotation, v: T): T {
   if (annotated(v)) {
      setα(α, v)
   }
   v.children().forEach((v: Persistent): void => {
      if (v instanceof Value) {
         setallα(α, v)
      }
   })
   // Hack to recurse into traces; revisit idea of integrating traces into values.
   // Can't assume every data value has a trace, since traces are also data values.
   if (v instanceof DataValue && v.__expl !== undefined) {
      setallα(α, v.__expl) 
   }
   return v
}

export function negateallα<T extends Persistent> (v: T): T {	
   return memo<T>(negateallα_ as MemoFunType<T>, v)
}	

export function negateallα_<Tag extends ValueTag, T extends Value<Tag>> (v: T): T {
   if (annotated(v)) {
      setα(ann.negate(v.__α), v)
   }
   v.children().forEach((v: Persistent): void => {
      if (v instanceof Value) {
         negateallα(v)
      }
   })
   // Similar hack to setallα.
   if (v instanceof DataValue && v.__expl !== undefined) {
      negateallα(v.__expl) 
   }
   return v
}

export function joinα<T, U extends Annotated<T>> (α: Annotation, v: U): U {
   v.__α = ann.join(α, v.__α)
   return v
}

export function meetα<T, U extends Annotated<T>> (α: Annotation, v: U): U {
   v.__α = ann.meet(α, v.__α)
   return v
}

export function num (val: number): Num {
   return at(ν(), Num, val)
}

export function str (val: string): Str {
   return at(ν(), Str, val)
}
