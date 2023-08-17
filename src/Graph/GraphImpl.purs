module Graph.GraphImpl
   ( GraphImpl(..)
   , AdjMap
   ) where

import Prelude

import Control.Monad.Rec.Class (Step(..), tailRecM)
import Control.Monad.ST (ST)
import Data.Foldable (foldl, foldM)
import Data.List (List(..), (:))
import Data.List (fromFoldable) as L
import Data.Maybe (Maybe(..), isJust)
import Data.Newtype (unwrap)
import Data.Set as S
import Dict (Dict)
import Dict as D
import Foreign.Object (runST, filter)
import Foreign.Object.ST (STObject)
import Foreign.Object.ST as OST
import Graph (class Graph, Vertex(..), op, outN)
import Set (class Set, delete, insert, singleton, union)
import Set as Set
import Util (type (×), (×), definitely)

-- Maintain out neighbours and in neighbours as separate adjacency maps with a common domain.
type AdjMap s = Dict (s Vertex)
data GraphImpl s = GraphImpl (AdjMap s) (AdjMap s)

-- Provided for completeness, but for efficiency we avoid them.
instance Set s Vertex => Semigroup (GraphImpl s) where
   append (GraphImpl out1 in1) (GraphImpl out2 in2) =
      GraphImpl (D.unionWith union out1 out2) (D.unionWith union in1 in2)

instance Set s Vertex => Monoid (GraphImpl s) where
   mempty = GraphImpl D.empty D.empty

-- Dict-based implementation with inefficient (linear) add and remove.
instance Set s Vertex => Graph (GraphImpl s) s where
   remove α (GraphImpl out in_) = GraphImpl out' in'
      where
      out' = delete α <$> D.delete (unwrap α) out
      in' = delete α <$> D.delete (unwrap α) in_

   add α αs (GraphImpl out in_) = GraphImpl out' in'
      where
      out' = D.insert (unwrap α) αs out
      in' = foldl (\acc α' -> D.insertWith union (unwrap α') (singleton α) acc)
         (D.insertWith union (unwrap α) Set.empty in_)
         αs

   outN (GraphImpl out _) α = D.lookup (unwrap α) out # definitely "in graph"
   inN g = outN (op g)

   elem α (GraphImpl out _) = isJust (D.lookup (unwrap α) out)
   size (GraphImpl out _) = D.size out

   vertices (GraphImpl out _) = Set.fromFoldable $ S.map Vertex $ D.keys out
   sinks (GraphImpl out _) = Set.fromFoldable $ S.map Vertex $ D.keys (filter Set.isEmpty out)
   sources (GraphImpl _ in_) = Set.fromFoldable $ S.map Vertex $ D.keys (filter Set.isEmpty in_)

   op (GraphImpl out in_) = GraphImpl in_ out

   discreteG αs = GraphImpl discreteM discreteM
      where
      discreteM = D.fromFoldable $ Set.map (\α -> unwrap α × Set.empty) αs

   empty = mempty

   fromFoldable α_αs = GraphImpl out in_
      where
      α_αs' = L.fromFoldable α_αs
      out × in_ = runST (outMap α_αs') × runST (inMap α_αs')

-- In-place update of mutable object to calculate opposite adjacency map.
type MutableAdjMap s r = STObject r (s Vertex)

addMissing :: forall s r. Set s Vertex => STObject r (s Vertex) -> Vertex -> ST r (STObject r (s Vertex))
addMissing acc (Vertex β) = do
   OST.peek β acc >>= case _ of
      Nothing -> OST.poke β Set.empty acc
      Just _ -> pure acc

outMap :: forall s. Set s Vertex => List (Vertex × s Vertex) -> forall r. ST r (MutableAdjMap s r)
outMap α_αs = do
   out <- OST.new
   tailRecM addEdges (α_αs × out)
   where
   addEdges (Nil × acc) = pure $ Done acc
   addEdges (((α × βs) : rest) × acc) = do
      acc' <- OST.poke (unwrap α) βs acc >>= flip (foldM addMissing) βs
      pure $ Loop (rest × acc')

inMap :: forall s. Set s Vertex => List (Vertex × s Vertex) -> forall r. ST r (MutableAdjMap s r)
inMap α_αs = do
   in_ <- OST.new
   tailRecM addEdges (α_αs × in_)
   where
   addEdges (Nil × acc) = pure $ Done acc
   addEdges (((α × βs) : rest) × acc) = do
      acc' <- foldM (addEdge α) acc βs >>= flip addMissing α
      pure $ Loop (rest × acc')

   addEdge α acc (Vertex β) = do
      OST.peek β acc >>= case _ of
         Nothing -> OST.poke β (singleton α) acc
         Just αs -> OST.poke β (insert α αs) acc

instance Show (s Vertex) => Show (GraphImpl s) where
   show (GraphImpl out in_) = "GraphImpl (" <> show out <> " × " <> show in_ <> ")"