module Pattern where

import Prelude hiding (absurd, join)
import Data.List (List(..), (:))
import Data.List.NonEmpty (NonEmptyList(..))
import Data.Map (Map, insert, lookup, singleton, update)
import Data.Map.Internal (keys)
import Data.Maybe (Maybe(..))
import Data.NonEmpty ((:|))
import Data.Traversable (foldl)
import Bindings (Var)
import DataType (DataType, Ctr, arity, dataTypeFor, typeName)
import Expr (Cont, Cont'(..), Elim, Elim'(..), Expr, Expr'(..), RawExpr(..), expr)
import Util (MayFail, (≞), (=<<<), absurd, error, om, report, with)

data PCont =
   PNone |              -- intermediate state during construction, but also for structured let
   PBody Expr |
   PLambda Pattern |    -- unnecessary if surface language supports piecewise definitions
   PArg Pattern

toCont :: PCont -> MayFail Cont
toCont PNone         = pure None
toCont (PBody e)     = pure $ Body e
toCont (PLambda π)   = Body <$> (expr <$> (Lambda <$> toElim π))
toCont (PArg π)      = Arg <$> toElim π

data Pattern =
   PattVar Var PCont |
   PattConstr Ctr Int PCont

toElim :: Pattern -> MayFail Elim
toElim (PattVar x κ)      = ElimVar x <$> toCont κ
toElim (PattConstr c n κ) = checkArity c n *> (ElimConstr <$> (singleton c <$> toCont κ))

class MapCont a where
   -- replace a None continuation by a non-None one
   setCont :: PCont -> a -> a

instance setContPCont :: MapCont PCont where
   setCont κ PNone         = κ
   setCont κ (PBody _)     = error absurd
   setCont κ (PLambda π)   = PLambda $ setCont κ π
   setCont κ (PArg π)      = PArg $ setCont κ π

instance setContPattern :: MapCont Pattern where
   setCont κ (PattVar x κ')      = PattVar x $ setCont κ κ'
   setCont κ (PattConstr c n κ') = PattConstr c n $ setCont κ κ'

class Joinable a b | a -> b where
   maybeJoin :: b -> a -> MayFail b

dataType :: Map Ctr Cont -> MayFail DataType
dataType κs = case keys κs of
   Nil   -> error absurd
   c : _ -> dataTypeFor c

instance joinablePatternElim :: Joinable Pattern (Elim' Boolean) where
   maybeJoin (ElimVar x κ) (PattVar y κ')       = ElimVar <$> x ≞ y <*> maybeJoin κ κ'
   maybeJoin (ElimConstr κs) (PattConstr c n κ) = ElimConstr <$> mayFailUpdate
      where
      mayFailUpdate :: MayFail (Map Ctr Cont)
      mayFailUpdate =
         case lookup c κs of
            Nothing -> do
               checkDataType
               insert <$> pure c <*> toCont κ <@> κs
               where
               checkDataType :: MayFail Unit
               checkDataType = void $ do
                  (with "Non-uniform patterns" $
                     (typeName <$> dataType κs) `(=<<<) (≞)` (typeName <$> dataTypeFor c))
                  *> checkArity c n
            Just κ' -> update <$> (const <$> pure <$> maybeJoin κ' κ) <@> c <@> κs
   maybeJoin _ _                               = report "Can't join variable and constructor patterns"

instance joinablePContCont :: Joinable PCont (Cont' Boolean) where
   maybeJoin None PNone                               = pure None
   maybeJoin (Arg σ) (PArg π)                         = Arg <$> maybeJoin σ π
   maybeJoin (Body (Expr _ (Lambda σ))) (PLambda π)   = Body<$> (expr <$> (Lambda <$> maybeJoin σ π))
   maybeJoin _ _                                      = report "Incompatible continuations"

joinAll :: NonEmptyList Pattern -> MayFail Elim
joinAll (NonEmptyList (π :| πs)) = foldl (om $ maybeJoin) (toElim π) πs

checkArity :: Ctr -> Int -> MayFail Int
checkArity c n = with ("Checking arity of " <> show c) $ arity c `(=<<<) (≞)` pure n
