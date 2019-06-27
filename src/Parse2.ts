// Generated automatically by nearley, version 2.16.0
// http://github.com/Hardmath123/nearley
// Bypasses TS6133. Allow declared but unused functions.
// @ts-ignore
function id(d: any[]): any { return d[0]; }
declare var ident: any;
declare var string: any;
declare var compareOp: any;
declare var WS: any;
declare var exponentOp: any;
declare var productOp: any;
declare var sumOp: any;

const moo = require('moo')
const lexer = moo.compile({
   ident: {
      match: /[a-zA-Z_][0-9a-zA-Z_]*/, // greedy
      type: moo.keywords({
        keyword: ["as", "match", "fun", "in", "let", "letrec", "primitive", "typematch"],
      })
   },
   WS: {
      match: /[ \t\n]+/, // include \s?
      lineBreaks: true
   },
   comment: /\/\/.*?$/,
   number: /0|[1-9][0-9]*/,
   string: /"(?:\\["\\]|[^\n"\\])*"/,
   // not quite sure why I can't use literals here:
   sumOp: /\+|\-|\+\+/,
   productOp: /\*|\//,
   exponentOp: /\*\*/,
   compareOp: /==|===|<=|<==|<|>=|>==|>/,
   symbol: ["(", ")", "=", "→", ";", "{", "}", ",", "[", "]"], // needs to come after compareOp
})

export interface Token { value: any; [key: string]: any };

export interface Lexer {
  reset: (chunk: string, info: any) => void;
  next: () => Token | undefined;
  save: () => any;
  formatError: (token: Token) => string;
  has: (tokenType: string) => boolean
};

export interface NearleyRule {
  name: string;
  symbols: NearleySymbol[];
  postprocess?: (d: any[], loc?: number, reject?: {}) => any
};

export type NearleySymbol = string | { literal: any } | { test: (token: any) => boolean };

export var Lexer: Lexer | undefined = lexer;

export var ParserRules: NearleyRule[] = [
    {"name": "rootExpr", "symbols": ["_", "expr"]},
    {"name": "expr", "symbols": ["compareExpr"]},
    {"name": "compareExpr", "symbols": ["compareExpr", "compareOp", "sumExpr"]},
    {"name": "compareExpr", "symbols": ["sumExpr"]},
    {"name": "sumExpr", "symbols": ["sumExpr", "sumOp", "productExpr"]},
    {"name": "sumExpr", "symbols": ["productExpr"]},
    {"name": "productExpr", "symbols": ["productExpr", "productOp", "exponentExpr"]},
    {"name": "productExpr", "symbols": ["exponentExpr"]},
    {"name": "exponentExpr", "symbols": ["exponentExpr", "exponentOp", "appChain"]},
    {"name": "exponentExpr", "symbols": ["appChain"]},
    {"name": "appChain", "symbols": ["simpleExpr"]},
    {"name": "appChain", "symbols": ["appChain", "simpleExpr"]},
    {"name": "simpleExpr", "symbols": ["var"]},
    {"name": "simpleExpr", "symbols": ["string"]},
    {"name": "simpleExpr", "symbols": ["number"]},
    {"name": "simpleExpr", "symbols": ["parenthExpr"]},
    {"name": "simpleExpr", "symbols": ["pair"]},
    {"name": "simpleExpr", "symbols": ["defs1"]},
    {"name": "simpleExpr", "symbols": ["list"]},
    {"name": "simpleExpr", "symbols": ["matchAs"]},
    {"name": "simpleExpr", "symbols": ["fun"]},
    {"name": "var$macrocall$2", "symbols": [(lexer.has("ident") ? {type: "ident"} : ident)]},
    {"name": "var$macrocall$1", "symbols": ["var$macrocall$2", "_"]},
    {"name": "var", "symbols": ["var$macrocall$1"]},
    {"name": "string$macrocall$2", "symbols": [(lexer.has("string") ? {type: "string"} : string)]},
    {"name": "string$macrocall$1", "symbols": ["string$macrocall$2", "_"]},
    {"name": "string", "symbols": ["string$macrocall$1"]},
    {"name": "number$macrocall$2", "symbols": ["number_"]},
    {"name": "number$macrocall$1", "symbols": ["number$macrocall$2", "_"]},
    {"name": "number", "symbols": ["number$macrocall$1"]},
    {"name": "parenthExpr$macrocall$2", "symbols": [{"literal":"("}]},
    {"name": "parenthExpr$macrocall$1", "symbols": ["parenthExpr$macrocall$2", "_"]},
    {"name": "parenthExpr$macrocall$4", "symbols": [{"literal":")"}]},
    {"name": "parenthExpr$macrocall$3", "symbols": ["parenthExpr$macrocall$4", "_"]},
    {"name": "parenthExpr", "symbols": ["parenthExpr$macrocall$1", "expr", "parenthExpr$macrocall$3"]},
    {"name": "pair$macrocall$2", "symbols": [{"literal":"("}]},
    {"name": "pair$macrocall$1", "symbols": ["pair$macrocall$2", "_"]},
    {"name": "pair$macrocall$4", "symbols": [{"literal":","}]},
    {"name": "pair$macrocall$3", "symbols": ["pair$macrocall$4", "_"]},
    {"name": "pair$macrocall$6", "symbols": [{"literal":")"}]},
    {"name": "pair$macrocall$5", "symbols": ["pair$macrocall$6", "_"]},
    {"name": "pair", "symbols": ["pair$macrocall$1", "expr", "pair$macrocall$3", "expr", "pair$macrocall$5"]},
    {"name": "defs1$macrocall$2", "symbols": [{"literal":"in"}]},
    {"name": "defs1$macrocall$1$macrocall$2", "symbols": ["defs1$macrocall$2"]},
    {"name": "defs1$macrocall$1$macrocall$1", "symbols": ["defs1$macrocall$1$macrocall$2", "_"]},
    {"name": "defs1$macrocall$1", "symbols": ["defs1$macrocall$1$macrocall$1"]},
    {"name": "defs1", "symbols": ["defList", "defs1$macrocall$1", "expr"]},
    {"name": "list$macrocall$2", "symbols": [{"literal":"["}]},
    {"name": "list$macrocall$1", "symbols": ["list$macrocall$2", "_"]},
    {"name": "list$macrocall$4", "symbols": [{"literal":"]"}]},
    {"name": "list$macrocall$3", "symbols": ["list$macrocall$4", "_"]},
    {"name": "list", "symbols": ["list$macrocall$1", "list_", "list$macrocall$3"]},
    {"name": "defList$ebnf$1", "symbols": []},
    {"name": "defList$ebnf$1$subexpression$1$macrocall$2", "symbols": [{"literal":";"}]},
    {"name": "defList$ebnf$1$subexpression$1$macrocall$1", "symbols": ["defList$ebnf$1$subexpression$1$macrocall$2", "_"]},
    {"name": "defList$ebnf$1$subexpression$1", "symbols": ["defList$ebnf$1$subexpression$1$macrocall$1", "def"]},
    {"name": "defList$ebnf$1", "symbols": ["defList$ebnf$1", "defList$ebnf$1$subexpression$1"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "defList", "symbols": ["def", "defList$ebnf$1"]},
    {"name": "def", "symbols": ["let"]},
    {"name": "def", "symbols": ["letrec"]},
    {"name": "let$macrocall$2", "symbols": [{"literal":"let"}]},
    {"name": "let$macrocall$1$macrocall$2", "symbols": ["let$macrocall$2"]},
    {"name": "let$macrocall$1$macrocall$1", "symbols": ["let$macrocall$1$macrocall$2", "_"]},
    {"name": "let$macrocall$1", "symbols": ["let$macrocall$1$macrocall$1"]},
    {"name": "let$macrocall$4", "symbols": [{"literal":"="}]},
    {"name": "let$macrocall$3", "symbols": ["let$macrocall$4", "_"]},
    {"name": "let", "symbols": ["let$macrocall$1", "var", "let$macrocall$3", "expr"]},
    {"name": "letrec$macrocall$2", "symbols": [{"literal":"letrec"}]},
    {"name": "letrec$macrocall$1$macrocall$2", "symbols": ["letrec$macrocall$2"]},
    {"name": "letrec$macrocall$1$macrocall$1", "symbols": ["letrec$macrocall$1$macrocall$2", "_"]},
    {"name": "letrec$macrocall$1", "symbols": ["letrec$macrocall$1$macrocall$1"]},
    {"name": "letrec$ebnf$1", "symbols": []},
    {"name": "letrec$ebnf$1$subexpression$1$macrocall$2", "symbols": [{"literal":";"}]},
    {"name": "letrec$ebnf$1$subexpression$1$macrocall$1", "symbols": ["letrec$ebnf$1$subexpression$1$macrocall$2", "_"]},
    {"name": "letrec$ebnf$1$subexpression$1", "symbols": ["letrec$ebnf$1$subexpression$1$macrocall$1", "recDef"]},
    {"name": "letrec$ebnf$1", "symbols": ["letrec$ebnf$1", "letrec$ebnf$1$subexpression$1"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "letrec", "symbols": ["letrec$macrocall$1", "recDef", "letrec$ebnf$1"]},
    {"name": "recDef$macrocall$2", "symbols": [{"literal":"fun"}]},
    {"name": "recDef$macrocall$1$macrocall$2", "symbols": ["recDef$macrocall$2"]},
    {"name": "recDef$macrocall$1$macrocall$1", "symbols": ["recDef$macrocall$1$macrocall$2", "_"]},
    {"name": "recDef$macrocall$1", "symbols": ["recDef$macrocall$1$macrocall$1"]},
    {"name": "recDef", "symbols": ["recDef$macrocall$1", "var", "matches"]},
    {"name": "fun$macrocall$2", "symbols": [{"literal":"fun"}]},
    {"name": "fun$macrocall$1$macrocall$2", "symbols": ["fun$macrocall$2"]},
    {"name": "fun$macrocall$1$macrocall$1", "symbols": ["fun$macrocall$1$macrocall$2", "_"]},
    {"name": "fun$macrocall$1", "symbols": ["fun$macrocall$1$macrocall$1"]},
    {"name": "fun", "symbols": ["fun$macrocall$1", "matches"]},
    {"name": "matchAs$macrocall$2", "symbols": [{"literal":"match"}]},
    {"name": "matchAs$macrocall$1$macrocall$2", "symbols": ["matchAs$macrocall$2"]},
    {"name": "matchAs$macrocall$1$macrocall$1", "symbols": ["matchAs$macrocall$1$macrocall$2", "_"]},
    {"name": "matchAs$macrocall$1", "symbols": ["matchAs$macrocall$1$macrocall$1"]},
    {"name": "matchAs$macrocall$4", "symbols": [{"literal":"as"}]},
    {"name": "matchAs$macrocall$3$macrocall$2", "symbols": ["matchAs$macrocall$4"]},
    {"name": "matchAs$macrocall$3$macrocall$1", "symbols": ["matchAs$macrocall$3$macrocall$2", "_"]},
    {"name": "matchAs$macrocall$3", "symbols": ["matchAs$macrocall$3$macrocall$1"]},
    {"name": "matchAs", "symbols": ["matchAs$macrocall$1", "expr", "matchAs$macrocall$3", "matches"]},
    {"name": "matches", "symbols": ["match"]},
    {"name": "matches$macrocall$2", "symbols": [{"literal":"{"}]},
    {"name": "matches$macrocall$1", "symbols": ["matches$macrocall$2", "_"]},
    {"name": "matches$ebnf$1", "symbols": []},
    {"name": "matches$ebnf$1$subexpression$1$macrocall$2", "symbols": [{"literal":";"}]},
    {"name": "matches$ebnf$1$subexpression$1$macrocall$1", "symbols": ["matches$ebnf$1$subexpression$1$macrocall$2", "_"]},
    {"name": "matches$ebnf$1$subexpression$1", "symbols": ["matches$ebnf$1$subexpression$1$macrocall$1", "match"]},
    {"name": "matches$ebnf$1", "symbols": ["matches$ebnf$1", "matches$ebnf$1$subexpression$1"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "matches$macrocall$4", "symbols": [{"literal":"}"}]},
    {"name": "matches$macrocall$3", "symbols": ["matches$macrocall$4", "_"]},
    {"name": "matches", "symbols": ["matches$macrocall$1", "match", "matches$ebnf$1", "matches$macrocall$3"]},
    {"name": "match$macrocall$2", "symbols": [{"literal":"→"}]},
    {"name": "match$macrocall$1", "symbols": ["match$macrocall$2", "_"]},
    {"name": "match", "symbols": ["pattern", "match$macrocall$1", "expr"]},
    {"name": "match", "symbols": ["pattern", "matches"]},
    {"name": "list_", "symbols": []},
    {"name": "list_$ebnf$1", "symbols": []},
    {"name": "list_$ebnf$1$subexpression$1$macrocall$2", "symbols": [{"literal":","}]},
    {"name": "list_$ebnf$1$subexpression$1$macrocall$1", "symbols": ["list_$ebnf$1$subexpression$1$macrocall$2", "_"]},
    {"name": "list_$ebnf$1$subexpression$1", "symbols": ["list_$ebnf$1$subexpression$1$macrocall$1", "expr"]},
    {"name": "list_$ebnf$1", "symbols": ["list_$ebnf$1", "list_$ebnf$1$subexpression$1"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "list_", "symbols": ["expr", "list_$ebnf$1"]},
    {"name": "pattern", "symbols": ["var_pattern"]},
    {"name": "pattern", "symbols": ["pair_pattern"]},
    {"name": "var_pattern", "symbols": ["var"]},
    {"name": "pair_pattern$macrocall$2", "symbols": [{"literal":"("}]},
    {"name": "pair_pattern$macrocall$1", "symbols": ["pair_pattern$macrocall$2", "_"]},
    {"name": "pair_pattern$macrocall$4", "symbols": [{"literal":","}]},
    {"name": "pair_pattern$macrocall$3", "symbols": ["pair_pattern$macrocall$4", "_"]},
    {"name": "pair_pattern$macrocall$6", "symbols": [{"literal":")"}]},
    {"name": "pair_pattern$macrocall$5", "symbols": ["pair_pattern$macrocall$6", "_"]},
    {"name": "pair_pattern", "symbols": ["pair_pattern$macrocall$1", "pattern", "pair_pattern$macrocall$3", "pattern", "pair_pattern$macrocall$5"]},
    {"name": "compareOp$macrocall$2", "symbols": [(lexer.has("compareOp") ? {type: "compareOp"} : compareOp)]},
    {"name": "compareOp$macrocall$1", "symbols": ["compareOp$macrocall$2"]},
    {"name": "compareOp$macrocall$1", "symbols": ["compareOp$macrocall$2", (lexer.has("WS") ? {type: "WS"} : WS)]},
    {"name": "compareOp", "symbols": ["compareOp$macrocall$1"]},
    {"name": "exponentOp$macrocall$2", "symbols": [(lexer.has("exponentOp") ? {type: "exponentOp"} : exponentOp)]},
    {"name": "exponentOp$macrocall$1", "symbols": ["exponentOp$macrocall$2"]},
    {"name": "exponentOp$macrocall$1", "symbols": ["exponentOp$macrocall$2", (lexer.has("WS") ? {type: "WS"} : WS)]},
    {"name": "exponentOp", "symbols": ["exponentOp$macrocall$1"]},
    {"name": "productOp$macrocall$2", "symbols": [(lexer.has("productOp") ? {type: "productOp"} : productOp)]},
    {"name": "productOp$macrocall$1", "symbols": ["productOp$macrocall$2"]},
    {"name": "productOp$macrocall$1", "symbols": ["productOp$macrocall$2", (lexer.has("WS") ? {type: "WS"} : WS)]},
    {"name": "productOp", "symbols": ["productOp$macrocall$1"]},
    {"name": "sumOp$macrocall$2", "symbols": [(lexer.has("sumOp") ? {type: "sumOp"} : sumOp)]},
    {"name": "sumOp$macrocall$1", "symbols": ["sumOp$macrocall$2"]},
    {"name": "sumOp$macrocall$1", "symbols": ["sumOp$macrocall$2", (lexer.has("WS") ? {type: "WS"} : WS)]},
    {"name": "sumOp", "symbols": ["sumOp$macrocall$1"]},
    {"name": "number_", "symbols": ["int"]},
    {"name": "int", "symbols": [/[0]/]},
    {"name": "int$ebnf$1", "symbols": []},
    {"name": "int$ebnf$1", "symbols": ["int$ebnf$1", "DIGIT"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "int", "symbols": ["digit1to9", "int$ebnf$1"]},
    {"name": "digit1to9", "symbols": [/[1-9]/]},
    {"name": "DIGIT", "symbols": [/[0-9]/]},
    {"name": "_$ebnf$1", "symbols": []},
    {"name": "_$ebnf$1$subexpression$1", "symbols": ["whitespace"]},
    {"name": "_$ebnf$1$subexpression$1", "symbols": ["singleLineComment"]},
    {"name": "_$ebnf$1", "symbols": ["_$ebnf$1", "_$ebnf$1$subexpression$1"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "_", "symbols": ["_$ebnf$1"]},
    {"name": "whitespace$ebnf$1", "symbols": [/[\s]/]},
    {"name": "whitespace$ebnf$1", "symbols": ["whitespace$ebnf$1", /[\s]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "whitespace", "symbols": ["whitespace$ebnf$1"], "postprocess": d => null},
    {"name": "singleLineComment$ebnf$1", "symbols": []},
    {"name": "singleLineComment$ebnf$1", "symbols": ["singleLineComment$ebnf$1", /[^\n]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "singleLineComment", "symbols": [{"literal":"//"}, "singleLineComment$ebnf$1"], "postprocess": d => null}
];

export var ParserStart: string = "rootExpr";
