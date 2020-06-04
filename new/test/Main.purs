module Test.Main where

import Prelude
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Test.Spec (before, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Mocha (runMocha)
import Eval (eval)
import Fwd (eval_fwd)
import Module (openWithImports)
import Pretty (pretty, render)
import Primitive (primitives)
import Selected (Selected(..))
import Val (Val(..))

runExample :: String -> String -> Effect Unit
runExample file expected = runMocha $
   before (openWithImports file) $
      it file $ \(Tuple ρ e) -> do
         let ρ' = ρ <> primitives
         let (Val _ u) = (eval ρ' e).v
         let (Val _ u') = eval_fwd ρ' e Top
         (render $ pretty u) `shouldEqual` (render $ pretty u')
         (render $ pretty u') `shouldEqual` expected

main :: Effect Unit
main = do
   runExample "arithmetic" "42"
   runExample "compose" "5"
   runExample "factorial" "40320"
   runExample "lexicalScoping" "\"6\""
   runExample "normalise" "(33, 66)"

   runExample "temp" "\"true\""