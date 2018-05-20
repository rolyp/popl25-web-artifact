import * as $ from "jquery"
import { initDataTypes } from "../src/DataType"
import { Env } from "../src/Env"
import { Eval } from "../src/Eval"
import { Expr, Lex } from "../src/Expr"
import { singleton } from "../src/FiniteMap"
import { instantiate } from "../src/Instantiate"
import { Parse } from "../src/Parse"
import { prelude } from "../src/Primitive"
import { Kont, Trie } from "../src/Traced"
import { parse } from "../src/util/parse/Core"
import { __nonNull } from "../src/util/Core"

export function initialise (): void {
   // Fix the toString impl on String to behave sensibly.
   String.prototype.toString = function (this: String): string {
      return "'" + this + "'"
   }
   initDataTypes()
}

export enum Profile {
   Parse,
   Run,
   Visualise
}

const defaultProfile = Profile.Parse

export namespace τ {
   export function arg (σ: Trie): Trie.Cons {
      return Trie.Cons.make(σ)
   }

   export function var_ (t: Kont): Trie {
      return Trie.Var.make(new Lex.Var("x"), t)
   }

   export function int (t: Kont): Trie {
      return Trie.ConstInt.make(t)
   }

   export function str (t: Kont): Trie {
      return Trie.ConstStr.make(t)
   }

   export function cons (Π: Trie.Args) {
      return Trie.Constr.make(singleton("Cons", Π))
   }

   export function pair (Π: Trie.Args): Trie {
      return Trie.Constr.make(singleton("Pair", Π))
   }

   export function some (Π: Trie.Args): Trie {
      return Trie.Constr.make(singleton("Some", Π))
   }
}

export function runExample (p: Profile, src: string, σ: Trie): void {
   const e: Expr = __nonNull(parse(Parse.expr, __nonNull(src))).ast
   if (p >= Profile.Run) {
      const [tv, , ]: Eval.Result = Eval.eval_(ρ, instantiate(ρ)(e), σ)
      console.log(tv)
   }
}

export let ρ: Env = prelude()

export function runTest (prog: string, profile: Profile = defaultProfile, σ: Trie = τ.var_(null)): void {
   runExample(profile, prog, σ)
}

// An asychronously loading test file; when loading completes text will be non-null.
export class TestFile {
   text: string | null

   constructor() {
      this.text = null
   }
}

// Maybe there's a way to use ES6 promises instead.
export function loadTestFile(folder: string, file: string): TestFile {
   let testFile: TestFile = new TestFile
   before((done: MochaDone) => {
      const filename: string = folder + "/" + file + ".lcalc"
      $.get(filename, text => {
         testFile.text = text
         console.log("Loaded " + filename)
         done()
      })
   })
   return testFile
}

// For now just see if all the examples run without an exception.
export function testAll (): void {
   console.log("Default test profile: " + Profile[defaultProfile] + ".")
   initialise()
}
