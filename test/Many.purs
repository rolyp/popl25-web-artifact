module Test.Many where

import Prelude

import App.Fig (linkResult, loadLinkFig)
import Benchmark.Util (BenchRow)
import Data.Array (zip)
import Data.List.Lazy (replicateM)
import Effect.Aff (Aff)
import Module (File(..), Folder(..), loadFile, open, openDatasetAs, openDefaultImports)
import Test.Util (TestBwdSpec, TestLinkSpec, TestSpec, TestWithDatasetSpec, averageRows, checkPretty, testWithSetup)
import Util (type (×), (×), successful)
import Val ((<+>))

many :: Array TestSpec -> Array (String × Aff BenchRow)
many fxs = zip names affs
   where
   affs = fxs <#> \{ file, fwd_expect } -> do
      default <- openDefaultImports
      expr <- open (File file)
      rows <- replicateM 1 $ testWithSetup file expr default { δv: identity, fwd_expect, bwd_expect: mempty }
      pure $ averageRows rows
   names = map _.file fxs

bwdMany :: Array TestBwdSpec -> Array (String × Aff BenchRow)
bwdMany fxs = zip names affs
   where
   folder = File "slicing/"
   affs = fxs <#> \{ file, file_expect, δv, fwd_expect } -> do
      default <- openDefaultImports
      bwd_expect <- loadFile (Folder "fluid/example") (folder <> File file_expect)
      expr <- open (folder <> File file)
      rows <- replicateM 1 $ testWithSetup file expr default { δv, fwd_expect, bwd_expect }
      pure $ averageRows rows
   names = map _.file fxs

withDatasetMany :: Array TestWithDatasetSpec -> Array (String × Aff BenchRow)
withDatasetMany fxs = zip names affs
   where
   affs = fxs <#> \{ dataset, file } -> do
      default <- openDefaultImports
      { g, n, γα } × xv <- openDatasetAs (File dataset) "data" default
      let loadedData = { g, n, γα: γα <+> xv }
      expr <- open (File file)
      rows <- replicateM 1 $
         testWithSetup file expr loadedData { δv: identity, fwd_expect: mempty, bwd_expect: mempty }
      pure $ averageRows rows
   names = fxs <#> _.file

linkMany :: Array TestLinkSpec -> Array (String × Aff Unit)
linkMany fxs = zip names affs
   where
   names = fxs <#> \spec -> "linking/" <> show spec.spec.file1 <> "<->" <> show spec.spec.file2
   affs = fxs <#> \{ spec, δv1, v2_expect } -> do
      { γ0, γ, e1, e2, t1, t2, v1 } <- loadLinkFig spec
      let { v': v2' } = successful $ linkResult spec.x γ0 γ e1 e2 t1 t2 (δv1 v1)
      checkPretty "Linked output" v2_expect v2'