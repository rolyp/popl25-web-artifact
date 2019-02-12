import { __nonNull, absurd, assert } from "./Core"
import { Ord } from "./Ord"

// An object which can be used as a key in an ES6 map (i.e. one for which equality is ===). In particular
// interned objects are persistent objects. Interface so can be extended by VersionedObject, which it is
// convenient to have as an interface.
export interface PersistentObject {
   // ES6 only allows constructor calls via "new".
   constructor_ (...args: Persistent[]): void
}

// Functions are persistent to support primitives.
export type Persistent = null | PersistentObject | string | number | Function

// Versioned objects are persistent objects that have state that varies across worlds.
export interface VersionedObject<K extends PersistentObject = PersistentObject> extends PersistentObject {
   // Initialise these at object creation (not enumerable).
   __history: Map<World, ObjectState> // history records only enumerable fields
   __id: K
}

// A memo key which is sourced externally to the system. (The name "External" exists in the global namespace.)
export class ExternalObject implements PersistentObject {
   public id: number

   constructor_ (id: number) {
      this.id = id
   }

   static make (id: number): ExternalObject {
      return make(ExternalObject, id)
   }
}

// Curried map from constructors and arguments to interned objects; curried because composite keys would 
// require either custom equality, which isn't possible with ES6 maps, or interning, which would essentially
// involve the same memoisation logic.
type InternedObjects = Map<Persistent, PersistentObject | Map<Persistent, Object>> // approximate recursive type
const __instances: InternedObjects = new Map

// For versioned objects the map is not curried but takes an (interned) composite key. TODO: treating the constructor
// as part of the key isn't correct because objects can change class. To match the formalism, we need a notion of 
// "metatype" or kind, so that traces and values are distinguished, but within those "kinds" the class can change.
type VersionedObjects = Map<PersistentObject, PersistentObject>
const __ctrInstances: Map<PersistentClass<PersistentObject>, VersionedObjects> = new Map

function lookupArg<T extends PersistentObject> (
   ctr: PersistentClass<T>, 
   m: InternedObjects, 
   args: Persistent[], 
   n: number
): PersistentObject | Map<Persistent, Object> {
   // for memoisation purposes, treat constructor itself as argument -1
   const k: Persistent = n === -1 ? ctr : args[n]
   let v: PersistentObject | Map<Persistent, Object> | undefined = m.get(k)
   if (v === undefined) {
      if (n === args.length - 1) {
         v = new ctr
         v.constructor_(...args)
      } else {
         v = new Map
      }
      m.set(k, v)
   }
   return v
}

type PersistentClass<T extends PersistentObject = PersistentObject> = new () => T

// Hash-consing (interning) object construction.
export function make<T extends PersistentObject> (ctr: PersistentClass<T>, ...args: Persistent[]): T {
   let v: PersistentObject | Map<Persistent, Object> = lookupArg(ctr, __instances, args, -1)
   for (var n: number = 0; n < args.length; ++n) {
      // since there are more arguments, the last v was a (nested) map
      v = lookupArg(ctr, v as InternedObjects, args, n)
   }
   Object.freeze(v)
   return v as T
}

export function versioned (o: Persistent): o is VersionedObject {
   return o !== null && (o as any).__id !== undefined
}

export function interned (o: Persistent): boolean {
   return o !== null && !versioned(o)
}

// The (possibly already extant) versioned object uniquely identified by a memo-key.
export function at<K extends PersistentObject, T extends PersistentObject> (α: K, ctr: PersistentClass<T>, ...args: Persistent[]): T {
   assert(interned(α))
   let instances: VersionedObjects | undefined = __ctrInstances.get(ctr)
   if (instances === undefined) {
      instances = new Map
      __ctrInstances.set(ctr, instances)
   }
   let o: PersistentObject | undefined = instances.get(α) as PersistentObject
   if (o === undefined) {
      o = new ctr
      // This may massively suck, performance-wise. Could move to VersionedObject now we have ubiquitous constructors.
      Object.defineProperty(o, "__id", {
         value: α,
         enumerable: false
      })
      Object.defineProperty(o, "__history", {
         value: new Map,
         enumerable: false
      })
      instances.set(α, o)
   }
   // Couldn't get datatype-generic construction to work because fields not created by "new ctr".
   o.constructor_(...args)
   return __commit(o) as T
}

// Fresh keys represent inputs to the system.
export const ν: () => ExternalObject =
   (() => {
      let count: number = 0
      return () => {
         return ExternalObject.make(count++)
      }
   })()

// Not sure what the T parameter is for here but Typescript seems to get confused without it.
function __blankCopy<T extends VersionedObject> (src: T): ObjectState {
   const tgt: ObjectState = Object.create(src.constructor.prototype)
   for (let x of Object.keys(src)) {
      tgt[x] = null
   }
   return tgt
}

// "State object" whose identity doesn't matter and whose contents we can access by key.
export interface ObjectState {
   [index: string]: Persistent
}

// Combine information from src into tgt and vice versa, at an existing world.
// Precondition: the two are upper-bounded; postcondition: they are equal.
function __mergeState (tgt: ObjectState, src: Object): void {
   assert(__nonNull(tgt).constructor === __nonNull(src.constructor))
   const src_: ObjectState = src as ObjectState
   Object.keys(tgt).forEach((k: string): void => {
      tgt[k] = src_[k] = __merge(tgt[k], src_[k])
   })
}

// Least upper bound of two upper-bounded objects.
function __merge (tgt: Persistent, src: Persistent): Persistent {
   if (src === null) {
      return tgt
   } else 
   if (tgt === null) {
      return src
   } else
   if (src === tgt) {
      return src
   } else 
   if (versioned(tgt) && versioned(src)) {
      return absurd("Address collision (different child).")
   } else
   if (interned(tgt) && interned(src)) {
      assert(tgt.constructor === src.constructor, "Address collision (different constructor).")
      const tgt_: ObjectState = tgt as Object as ObjectState, // retarded
            src_: ObjectState = src as Object as ObjectState,
            args: Persistent[] = Object.keys(tgt).map((k: string): Persistent => {
         return __merge(tgt_[k], src_[k])
      })
      return make(src.constructor as PersistentClass, ...args)
   } else {
      return absurd()
   }
}

// Assign contents of src to tgt; return whether anything changed. TODO: whether anything changed is not
// necessarily significant because of call-by-need: a slot may evolve from null to non-null during a run.
function __assignState (tgt: ObjectState, src: Object): boolean {
   assert(__nonNull(tgt).constructor === __nonNull(src.constructor))
   let changed: boolean = false
   const src_: ObjectState = src as ObjectState
   Object.keys(tgt).forEach((k: string): void => {
      if (tgt[k] !== src_[k]) {
         tgt[k] = src_[k]
         changed = true
      }
   })
   return changed
}

// At a given world, enforce "increasing" (LVar) semantics. Only permit non-increasing changes at new worlds.
function __commit (o: PersistentObject): Object {
   if (versioned(o)) {
      if (o.__history.size === 0) {
         const state: ObjectState = __blankCopy(o)
         __mergeState(state, o)
         o.__history.set(__w, state)
      } else {
         const [w, state]: [World, ObjectState] = stateAt(o, __w)
         if (w === __w) {
            __mergeState(state, o)
         } else {
            // Semantics of copy-on-write but inefficient - we create the copy even if we don't need it: 
            const prev: ObjectState = __blankCopy(o)
            __mergeState(prev, state)
            if (__assignState(state, o)) {
               o.__history.set(w, prev)
               o.__history.set(__w, state)
            }
         }
      }
      return o
   } else {
      return absurd()
   }
}

// State of o at w, plus predecessor of w at which that state was set.
function stateAt (o: VersionedObject, w: World): [World, ObjectState] {
   const v: ObjectState | undefined = o.__history.get(w)
   if (v === undefined) {
      if (w.parent !== null) {
         return stateAt(o, w.parent)
      } else {
         return absurd("No initial state.")
      }
   } else {
      return [w, v]
   }
}

// Versioned objects can have different metatypes at different worlds; here we assume T is its type at the 
// current world.
export function getProp<T extends VersionedObject> (o: T, k: keyof T): Persistent {
   return stateAt(o, __w)[1][k as string]
}

export class World implements PersistentObject, Ord<World> {
   public parent: World | null

   constructor_ (
      parent: World | null
   ) {
      this.parent = parent
   }

   eq (w: World): boolean {
      return this === w
   }

   leq (w: World): boolean {
      return this === w || (this.parent !== null && this.parent.leq(w))
   }

   static make (parent: World | null) {
      return make(World, parent)
   }

   static newRevision (): World {
      return __w = World.make(__w)
   }

   static undo (): void {
      if (__w.parent !== null) {
         __w = __w.parent
      } else {
         absurd()
      }
   }
}

export let __w: World = World.make(null)
