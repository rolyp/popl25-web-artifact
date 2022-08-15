module App.Main2 where

import Prelude hiding (absurd)
import Data.Either (Either(..))
import Data.Traversable (sequence, sequence_)
import Effect (Effect)
import Effect.Aff (Aff, runAff_)
import Effect.Console (log)
import App.Fig2 (Fig, FigSpec, LinkFig, LinkFigSpec, drawFig, drawLinkFig, loadFig, loadLinkFig)
import Module2 (File(..))
import Util2 (error, unimplemented)

linkingFig1 :: LinkFigSpec
linkingFig1 = {
   divId: "fig-1",
   file1: File "bar-chart",
   file2: File "line-chart",
   dataFile: File "renewables",
   x: "data"
}

fig1 :: FigSpec
fig1 = {
   divId: "fig-conv-1",
   file: File "slicing/conv-emboss",
   xs: ["image", "filter"]
}

fig2 :: FigSpec
fig2 = {
   divId: "fig-conv-2",
   file: File "slicing/conv-emboss-wrap",
   xs: ["image", "filter"]
}

-- TODO: consolidate these two.
drawLinkFigs :: Array (Aff LinkFig) -> Effect Unit
drawLinkFigs loadFigs =
   flip runAff_ (sequence loadFigs)
   case _ of
      Left err -> log $ show err
      Right figs -> sequence_ $ flip drawLinkFig (Left $ error unimplemented {-Hole false-}) <$> figs

drawFigs :: Array (Aff Fig) -> Effect Unit
drawFigs loadFigs =
   flip runAff_ (sequence loadFigs)
   case _ of
      Left err -> log $ show err
      Right figs -> sequence_ $ flip drawFig (error unimplemented {-Hole false-}) <$> figs

main :: Effect Unit
main = do
   drawFigs [loadFig fig1, loadFig fig2]
   drawLinkFigs [loadLinkFig linkingFig1]