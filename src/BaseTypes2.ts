import { Constr, Value, _, make } from "./Value2"

export abstract class Bool extends Constr<Bool> {
}

export class True extends Bool {
}

export function true_ (): Bool {
   return make(True, {})
}

export class False extends Bool {
}

export function false_ (): Bool {
   return make(False, {})
}

export abstract class List<T> extends Constr<List<T>> {
}

export class Nil<T> extends List<T> {
   static is<T> (xs: List<T>): xs is Nil<T> {
      return xs instanceof Nil
   }
}

export function nil<T> (): List<T> {
   return make(Nil, {})
}

export class Cons<T extends Value> extends List<T> {
   head: T = _
   tail: List<T> = _

   static is<T> (xs: List<T>): xs is Cons<T> {
      return xs instanceof Cons
   }
}

export function cons<T extends Value> (head: T, tail: List<T>): Cons<T> {
   return make<Cons<T>>(Cons, { head, tail })
}

export class Pair<T, U> extends Constr<Pair<T, U>> {
   fst: T = _
   snd: U = _
}

export abstract class Tree<T> extends Constr<Tree<T>> {
}

export class Empty<T> extends Tree<T> {
}

export class NonEmpty<T> extends Tree<T> {
   left: Tree<T> = _
   t: T = _
   right: Tree<T> = _
}

export function map<T, U> (t: Tree<T>, f: (t: T) => U): Tree<U> {
   throw new Error
}