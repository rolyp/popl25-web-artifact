module Test.Main where

import Prelude
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Node.Encoding (Encoding(..))
import Node.FS.Sync (readTextFile)
import Text.Parsing.Parser (runParser)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Eval (eval)
import Parse (program)
import Pretty (pretty)
import Util (error)
import Val (primitives)

import Test.Test (main) as Test

main :: Effect Unit
main = do
   Test.main
   test_normalise

test_normalise :: Effect Unit
test_normalise = do
   text <- readTextFile ASCII "fluid/example/normalise.fld"
   let result = runParser text program
   launchAff_ $ runSpec [consoleReporter] do
      describe "Parse" do
         it "blah" do
            case result of
               Left parseError -> do
                  error $ show parseError
               Right e -> do
                  let { u } = (eval primitives e).v
                  (show $ pretty u) `shouldEqual` "5"
