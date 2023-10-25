module Test.Util.Many where

import Prelude
import App.Fig (linkResult, loadLinkFig)
import Data.Array (zip)
import Effect.Aff (Aff)
import Module (File(..), Folder(..), datasetAs, defaultImports, loadFile)
import Test.Benchmark.Util (BenchRow)
import Test.Util (TestBwdSpec, TestLinkSpec, TestSpec, TestWithDatasetSpec, checkPretty, test)
import Util (type (×), (×))

many :: Array TestSpec -> (Int × Boolean) -> Array (String × Aff BenchRow)
many specs (n × is_bench) = zip (specs <#> _.file) (specs <#> one)
   where
   one { file, fwd_expect } = do
      progCxt <- defaultImports
      test (File file) progCxt { δv: identity, fwd_expect, bwd_expect: mempty } (n × is_bench)

bwdMany :: Array TestBwdSpec -> (Int × Boolean) -> Array (String × Aff BenchRow)
bwdMany specs (n × is_bench) = zip (specs <#> (\spec -> "slicing/" <> spec.file)) (specs <#> one)
   where
   folder = File "slicing/"
   one { file, file_expect, δv, fwd_expect } = do
      progCxt <- defaultImports
      bwd_expect <- loadFile (Folder "fluid/example") (folder <> File file_expect)
      test (folder <> File file) progCxt { δv, fwd_expect, bwd_expect } (n × is_bench)

withDatasetMany :: Array TestWithDatasetSpec -> (Int × Boolean) -> Array (String × Aff BenchRow)
withDatasetMany specs (n × is_bench) = zip (specs <#> _.file) (specs <#> one)
   where
   one { dataset, file } = do
      progCxt <- defaultImports >>= datasetAs (File dataset) "data"
      test (File file) progCxt { δv: identity, fwd_expect: mempty, bwd_expect: mempty } (n × is_bench)

linkMany :: Array TestLinkSpec -> Array (String × Aff Unit)
linkMany specs = zip (specs <#> name) (specs <#> one)
   where
   name spec = "linking/" <> show spec.spec.file1 <> "<->" <> show spec.spec.file2
   one { spec, δv1, v2_expect } = do
      { γ, e1, e2, t1, t2, v1 } <- loadLinkFig spec
      { v': v2' } <- linkResult spec.x γ e1 e2 t1 t2 (δv1 v1)
      checkPretty "Linked output" v2_expect v2'