module Test.App.Main where

import Prelude
import Data.Traversable (sequence)
import Effect (Effect)
import Partial.Unsafe (unsafePartial)
import Test.Spec (before, it)
import App.Main (fig1, linkingFig1)
import App.Renderer (FigSpec, LinkingFigSpec, loadFig, loadLinkingFig)
import Test.Util (Test, run)

-- For now app tests just exercise figure creation code.
test_fig :: FigSpec -> Test Unit
test_fig spec =
   before (loadFig spec) $
      it spec.divId \_ ->
         pure unit

test_linkingFig :: Partial => LinkingFigSpec -> Test Unit
test_linkingFig spec =
   before (loadLinkingFig spec) $
      it spec.divId \_ ->
         pure unit

tests :: Array (Test Unit)
tests = unsafePartial [test_fig fig1, test_linkingFig linkingFig1]

main :: Effect Unit
main = void (sequence (run <$> tests))
