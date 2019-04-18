import { ann } from "../../src/util/Annotated"
import { __nonNull, assert } from "../../src/util/Core"
import { World, setall, ν } from "../../src/util/Versioned"
import { successfulParse } from "../../src/util/parse/Core"
import { initDataTypes } from "../../src/DataType"
import { Env } from "../../src/Env"
import { Eval } from "../../src/Eval"
import { ExplVal } from "../../src/ExplVal"
import { Expr, Kont } from "../../src/Expr"
import { unionWith } from "../../src/FiniteMap"
import { instantiate } from "../../src/Instantiate"
import { Parse } from "../../src/Parse"
import { createPrelude } from "../../src/Primitive"
import { Cursor } from "./Cursor"

import Args = Expr.Args
import Trie = Expr.Trie

export function initialise (): void {
   // Fix the toString impl on String to behave sensibly.
   String.prototype.toString = function (this: String): string {
      return "'" + this + "'"
   }
   initDataTypes()
}

export class FwdSlice {
   expr: Cursor
   val: Cursor

   constructor (e: Expr) {
      World.newRevision()
      setall(e, ann.top) // parser should no longer need to do this
      this.expr = new Cursor(e)
      this.setup()
      this.val = new Cursor(Eval.eval_(prelude, e).v)
      this.expect()
   }

   setup (): void {      
   }

   expect (): void {
   }

   get e (): Expr {
      return this.expr.o as Expr
   }
}

// Precondition: must be safe to reexecute e in the current revision, to obtain a trace.
export class BwdSlice {
   val: Cursor
   expr: Cursor

   constructor (e: Expr) {
      World.newRevision()
      setall(e, ann.bot)
      const tv: ExplVal = Eval.eval_(prelude, e) // just to obtain tv
      setall(tv, ann.bot) // TODO: contrive a test that reveals why this matters :-/
      World.newRevision()
      this.val = new Cursor(tv.v)
      this.setup()
      this.expr = new Cursor(Eval.uneval(tv))
      this.expect()
   }

   setup (): void {
   }

   expect (): void {      
   }
}

export enum Profile {
   Parse,
   Run,
   Visualise
}

// Could have used join, but only defined for syntactic tries.
export function merge<K extends Kont<K>> (σ1: Trie.Constr<K>, σ2: Trie.Constr<K>): Trie.Constr<K> {
   return Trie.constr(unionWith(σ1.cases, σ2.cases, (v: Args<K>, vʹ: Args<K>) => assert(false)))
}

// Kindergarten modules: load another file as though it were a letrec block, with body e.
export function prependModule (src: string, e: Expr): Expr.LetRec {
   return Expr.letRec(ν(), ann.top, successfulParse(Parse.recDefs1, src), e)
}

export function parse (src: string): Expr {
   return instantiate(prelude, 
      prependModule(loadLib("prelude"), 
      prependModule(loadLib("graphics"), 
      successfulParse(Parse.expr, src)))
   )
}

export let prelude: Env = createPrelude()

// An asychronously loading test file; when loading completes text will be non-null.
export class TestFile {
   text: string | null

   constructor () {
      this.text = null
   }
}

// Maybe there's a way to use ES6 promises instead.
export function loadTestFile (folder: string, file: string): string {
   let testFile: TestFile = new TestFile
   const xmlhttp: XMLHttpRequest = new XMLHttpRequest
   xmlhttp.open("GET", folder + "/" + file + ".lcalc", false)
   xmlhttp.send()
   if (xmlhttp.status === 200) {
      testFile.text = xmlhttp.responseText
   }
   return __nonNull(testFile.text)
}

export function load (file: string): string {
	return loadTestFile("example", file)
}

export function loadLib (file: string): string {
	return loadTestFile("example/lib", file)
}
