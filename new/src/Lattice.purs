module Lattice where

import Prelude hiding (absurd, join)
import Data.Maybe (Maybe(..))
import Util (fromJust)

class Lattice a where
   maybeMeet   :: a -> a -> Maybe a
   maybeJoin   :: a -> a -> Maybe a
   top         :: a -> a
   bot         :: a -> a

join :: forall a . Lattice a => a -> a -> a
join p q = fromJust $ p ∨? q

meet :: forall a . Lattice a => a -> a -> a
meet p q = fromJust $ p ∧? q

-- Give ∧ and ∨ same associativity and precedence as * and +
infixl 7 meet as ∧
infixl 6 join as ∨
infix 7 maybeMeet as ∧?
infix 6 maybeJoin as ∨?

data Selected = TT | FF -- maybe tt, ff would be better

derive instance eqSelected :: Eq Selected

instance latticeSelected :: Lattice Selected where
   maybeMeet TT TT = Just TT
   maybeMeet _ _   = Just FF
   maybeJoin FF FF = Just FF
   maybeJoin _ _   = Just TT
   top _ = TT
   bot _ = FF

instance unitLattice :: Lattice Unit where
   maybeMeet _ _ = pure unit
   maybeJoin _ _ = pure unit
   top _ = unit
   bot _ = unit