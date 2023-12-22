module Graph.Slice where

import Prelude hiding (add)

import Control.Monad.Rec.Class (Step(..), tailRecM)
import Data.List (List(..), (:))
import Data.List as L
import Data.Map (Map, lookup)
import Data.Map as M
import Data.Maybe (Maybe(..), maybe)
import Data.Set (Set, empty, insert)
import Data.Set.NonEmpty (cons, fromSet, singleton, toSet)
import Data.Tuple (fst)
import Graph (class Graph, Edge, Vertex, inEdges, inEdges', outN, showGraph, showVertices)
import Graph.WithGraph (WithGraph, extend, runWithGraph)
import Test.Util.Debug (tracing)
import Util (type (×), spyWhen, (×), (∈))

type PendingVertices = Map Vertex (Set Vertex)

bwdSlice :: forall g. Graph g => Set Vertex -> g -> g
bwdSlice αs_ g_ =
   fst $ runWithGraph $ tailRecM go (empty × L.fromFoldable αs)
   where
   αs = spyWhen tracing.graphBwdSliceInput "bwdSlice input" showVertices αs_
   g = spyWhen tracing.graphBwdSliceOutput "bwdSlice graph" showGraph g_

   go :: Set Vertex × List Vertex -> WithGraph (Step _ Unit)
   go (_ × Nil) = pure $ Done unit
   go (visited × (α : αs')) =
      if α ∈ visited then
         pure $ Loop (visited × αs')
      else do
         let visited' = visited # insert α
         case fromSet (outN g α) of
            Nothing ->
               pure $ Loop (visited' × αs')
            Just βs -> do
               extend α βs
               pure $ Loop (visited' × (L.fromFoldable βs <> αs'))

fwdSlice :: forall g. Graph g => Set Vertex -> g -> g
fwdSlice αs_ g_ =
   fst $ runWithGraph $ tailRecM go (M.empty × inEdges g αs)
   where
   αs = spyWhen tracing.graphFwdSliceInput "fwdSlice" showVertices αs_
   g = spyWhen tracing.graphFwdSliceOutput "fwdSlice graph" showGraph g_

   go :: PendingVertices × List Edge -> WithGraph (Step _ PendingVertices)
   go (h × Nil) = pure $ Done h
   go (h × ((α × β) : es)) = do
      let βs = maybe (singleton β) (cons β) (lookup α h)
      if toSet βs == outN g α then do
         extend α βs
         pure $ Loop (M.delete α h × (inEdges' g α <> es))
      else
         pure $ Loop (M.insert α (toSet βs) h × es)
