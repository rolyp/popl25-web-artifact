module Test.Many where

import Prelude

import Benchmark.Util (BenchRow)
import Data.Array (zip)
import Data.List.Lazy (replicateM)
import Effect.Aff (Aff)
import EvalGraph (GraphConfig)
import Graph.GraphImpl (GraphImpl)
import Module (File(..), Folder(..), loadFile, open, openDatasetAs, openDefaultImports)
import Test.Util (TestBwdSpec, TestSpec, TestWithDatasetSpec, averageRows, testWithSetup)
import Util (type (×), (×))
import Val ((<+>))

many :: Boolean -> Array TestSpec -> Array (String × Aff BenchRow)
many is_bench fxs = zip names affs
   where
   affs = map
      ( \{ file, fwd_expect } -> do
           default <- openDefaultImports :: Aff (GraphConfig GraphImpl)
           expr <- open (File file)
           rows <- replicateM 10 $ testWithSetup file is_bench expr default { δv: identity, fwd_expect, bwd_expect: mempty }
           pure $ averageRows rows
      )
      fxs
   names = map _.file fxs

bwdMany :: Boolean -> Array TestBwdSpec -> Array (String × Aff BenchRow)
bwdMany is_bench fxs = zip names affs
   where
   folder = File "slicing/"
   affs = map
      ( \{ file, file_expect, δv, fwd_expect } -> do
           default <- openDefaultImports :: Aff (GraphConfig GraphImpl)
           bwd_expect <- loadFile (Folder "fluid/example") (folder <> File file_expect)
           expr <- open (folder <> File file)
           rows <- replicateM 10 $ testWithSetup file is_bench expr default { δv, fwd_expect, bwd_expect }
           pure $ averageRows rows
      )
      fxs
   names = map _.file fxs

withDatasetMany :: Boolean -> Array TestWithDatasetSpec -> Array (String × Aff BenchRow)
withDatasetMany is_bench fxs = zip names affs
   where
   affs = map
      ( \{ dataset, file } -> do
           default <- openDefaultImports :: Aff (GraphConfig GraphImpl)
           { g, n, γα } × xv <- openDatasetAs (File dataset) "data" default
           let loadedData = { g, n, γα: γα <+> xv }
           expr <- open (File file)
           rows <- replicateM 10 $ testWithSetup file is_bench expr loadedData { δv: identity, fwd_expect: mempty, bwd_expect: mempty }
           pure $ averageRows rows
      )
      fxs
   names = map (\spec -> spec.file) fxs
