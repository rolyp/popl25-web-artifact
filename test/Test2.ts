/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { initialise, load, parse, prelude } from "./util/Core2"
import { Eval } from "../src/Eval2"

before((done: MochaDone) => {
	initialise()
	done()
})

describe("example", () => {
   // putting test name in a variable interacts poorly with asynchronous execution
   
	describe("arithmetic", () => {
		it("ok", () => {
			console.log(Eval.interpret(parse(load("arithmetic")))(prelude))
		})
	})

   describe("compose", () => {
		it("ok", () => {
			console.log(Eval.interpret(parse(load("compose")))(prelude))
		})
	})

	describe("lexicalScoping", () => {
		it("ok", () => {
			console.log(Eval.interpret(parse(load("lexicalScoping")))(prelude))
		})
	})

	describe("normalise", () => {
		it("ok", () => {
			console.log(Eval.interpret(parse(load("normalise")))(prelude))
		})
   })
})
