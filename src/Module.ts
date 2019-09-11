import { Grammar, Parser } from "nearley"
import { __nonNull, as, error } from "./util/Core"
import { Annotation } from "./util/Lattice"
import { negateallα, setallα, str } from "./Annotated"
import { List } from "./BaseTypes"
import { Expl_ } from "./DataValue"
import { Env, ExtendEnv, emptyEnv } from "./Env"
import { Eval } from "./Eval"
import { Expr } from "./Expr"
import "./Graphics" // for datatypes
import * as grammar from "./Parse"
import { ν } from "./Versioned"

// Kindergarten modules.
type Module = List<Expr.Def>

// Define as constants to enforce sharing; could use memoisation.
export const module_prelude: Module = loadModule("prelude"),
             module_graphics: Module = loadModule("graphics"),
             module_renderData: Module = loadModule("renderData")

function import_ (modules: Module[], e: Expr): Expr {
   if (modules.length === 0) {
      return e
   } else {
      return Expr.defs(ν(), modules[0], import_(modules.slice(1), e))
   }
}

export function loadTestFile (folder: string, file: string): string {
   let text: string
   const xmlhttp: XMLHttpRequest = new XMLHttpRequest
   xmlhttp.open("GET", "./" + folder + "/" + file + ".lcalc", false)
   xmlhttp.send()
   if (xmlhttp.status === 200) {
      text = xmlhttp.responseText
   }
   return __nonNull(text!)
}

// Not sure if Nearley can parse arbitrary non-terminal, as opposed to root.
export function loadModule (file: string): Module {
   const fileʹ: string = loadTestFile("lcalc/lib", file) + " in 0",
         e: Expr.Defs = as(successfulParse(fileʹ), Expr.Defs)
   return e.def̅
}

export function open (file: string): Expr {
   return openWithImports(file, [])
}

export function openWithImports (file: string, modules: Module[]): Expr {
   return parseWithImports(loadTestFile("lcalc/example", file), modules)
}

// Explicit notion of "dataset" to provide way to set/clear annotations on source code.
export class Dataset {
   private e: Expr
   tv: Expl_
   ρ: ExtendEnv

   constructor (x: string, e: Expr) {
      this.e = e
      this.tv = Eval.eval_(emptyEnv(), this.e)
      this.ρ = Env.singleton(str(x), this.tv)
   }

   setallα (α: Annotation): void {
      setallα(α, this.e)
      Eval.eval_fwd(this.e, this.tv)
   }

   negateallα (): void {
      negateallα(this.e)
      Eval.eval_fwd(this.e, this.tv)
   }
}

export function openDatasetAs (file: string, x: string): Dataset {
   return new Dataset(x, parseWithImports(loadTestFile("lcalc/dataset", file), []))
}

export function parseWithImports (src: string, modules: Module[]): Expr {
   return import_([module_prelude], import_(modules, successfulParse(src)))
}

// https://github.com/kach/nearley/issues/276#issuecomment-324162234
export function successfulParse (str: string): Expr {
   const { results }: Parser = new Parser(Grammar.fromCompiled(grammar)).feed(str)
   if (results.length > 1) {
      error("Ambiguous parse.")
   }
   return results[0]
}
