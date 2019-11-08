import { Grammar, Parser } from "nearley"
import { __nonNull, as, error } from "./util/Core"
import { Cons, List, Nil, Pair } from "./BaseTypes"
import { exprClass } from "./DataType"
import { Env, ExtendEnv, emptyEnv, extendEnv } from "./Env"
import { Eval } from "./Eval"
import { Expr } from "./Expr"
import "./Graphics" // for datatypes
import grammar from "./Parse"
import { PrimValue, Str } from "./Value"
import { ν, at, num, str } from "./Versioned"

// Kindergarten modules.
type Module = List<Expr.Def>

// Define as constants to enforce sharing; could use memoisation.
export const module_prelude: Module = loadModule("prelude"),
             module_graphics: Module = loadModule("graphics2")
             // module_renderData: Module = loadModule("renderData")

function import_ (modules: Module[], e: Expr): Expr {
   if (modules.length === 0) {
      return e
   } else {
      return Expr.defs(modules[0], import_(modules.slice(1), e))(ν())
   }
}

export function loadTestFile (folder: string, file: string): string {
   let text: string
   const xmlhttp: XMLHttpRequest = new XMLHttpRequest
   xmlhttp.open("GET", "./" + folder + "/" + file + ".fld", false)
   xmlhttp.send()
   if (xmlhttp.status === 200) {
      text = xmlhttp.responseText
   }
   return __nonNull(text!)
}

// Not sure if Nearley can parse arbitrary non-terminal, as opposed to root.
export function loadModule (file: string): Module {
   const fileʹ: string = loadTestFile("fluid/lib", file) + " in 0",
         e: Expr.Defs = as(successfulParse(fileʹ), Expr.Defs)
   return e.def̅
}

export function openWithImports (file: string, ...modules: Module[]): Expr {
   return parseWithImports(loadTestFile("fluid/example", file), ...modules)
}

export function openDatasetAs (file: string, x: string): ExtendEnv {
   return Env.singleton(str(x)(ν()), Eval.eval_(emptyEnv(), parseWithImports(loadTestFile("fluid/dataset", file))))
}

export function parseWithImports (src: string, ...modules: Module[]): Expr {
   return import_([module_prelude, module_graphics, ...modules], successfulParse(src))
}

// https://github.com/kach/nearley/issues/276#issuecomment-324162234
export function successfulParse (str: string): Expr {
   const { results }: Parser = new Parser(Grammar.fromCompiled(grammar)).feed(str)
   if (results.length > 1) {
      error("Ambiguous parse.")
   } else
   if (results.length === 0) {
      error("Unsuccessful parse.")
   }
   return results[0]
}

export type Record = List<Pair<Str, PrimValue>> // entry in dataset

// create an expression and evaluate it, so we have an explained value
export function bindDataset (ρ: Env, vs: Object[], x: string): ExtendEnv {
   return extendEnv(ρ, str(x)(ν()), Eval.eval_(ρ, asList(vs.map(asRecord))))
}

function asRecord (v: Object): Expr {
   return asList(Object.getOwnPropertyNames(v).map(k => asPair(k, (v as any)[k])))
}

function asPair (k: string, v: unknown): Expr {
   return at(exprClass(Pair), asPrimValue(k), asPrimValue(v))(ν())
}

function asList (e̅: Expr[]): Expr {
   let e̅ʹ: Expr = at(exprClass(Nil))(ν())
   for (let e of [...e̅].reverse()) {
      e̅ʹ = at(exprClass(Cons), e, e̅ʹ)(ν())
   }
   return e̅ʹ
}

function asPrimValue (v: unknown): Expr {
   if (typeof v === "number") {
      return Expr.constNum(num(v)(ν()))(ν())
   } else
   if (typeof v === "string") {
      return Expr.constStr(str(v)(ν()))(ν())
   } else {
      return error(`Ill-formed data: expected string or number, found ${typeof v}.`)
   }
}
