import { zip } from "./util/Array"
import { Expl } from "./ExplValue"
import { DataValueTag, State, Value, fields } from "./Value"
import { Versioned } from "./Versioned"

// Value of a datatype constructor; fields are always user-level values (i.e. not ES6 primitives).
export class DataValue<Tag extends DataValueTag = DataValueTag> extends Value<Tag> {
   __expl: DataExpl

   fieldValues (): Value[] {
      return fields(this).map(k => (this as any as State)[k] as Value)
   }

   fieldExplValues(): [Expl, Versioned<Value>][] {
      const t̅: Expl[] = this.__expl.fieldValues(),
            v̅: Versioned<Value>[] = this.fieldValues() as Versioned<Value>[]
      return zip(t̅, v̅)
   }
}

export class DataExpl extends DataValue<"DataExpl"> {
   fieldValues (): Expl[] {
      return fields(this).map(k => (this as any as State)[k] as Expl)
   }
}