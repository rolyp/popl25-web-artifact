module Expl where

import Prelude
import Data.Foldable (sum)
import Data.List (List)
import Bindings (Bindings, Var, (↦), foldBindings)
import DataType (Ctr)
import Expr (Elim, RecDefs)
import Util (type (×))
import Val (Array2, Env, PrimOp, Val)

data VarDef a = VarDef (Match a) (Expl a)

-- We record values in some cases, which should be assumed to be "unannotated" (= annotated with false).
data Expl a =
   Var (Env a) Var |
   Op (Env a) Var |
   Int (Env a) Int |
   Float (Env a) Number |
   Str (Env a) String |
   Record (Env a) (Bindings Expl a) |
   Constr (Env a) Ctr (List (Expl a)) |
   Matrix (Array2 (Expl a)) (Var × Var) (Int × Int) (Expl a) |
   Lambda (Env a) (Elim a) |
   App (Expl a × Env a × RecDefs a × Elim a) (Expl a) (Match a) (Expl a) |
   AppPrim (Expl a × PrimOp × List (Val a)) (Expl a × Val a) | -- record prior arguments
   AppConstr (Expl a × Ctr × Int) (Expl a) |                   -- record number of prior arguments
   Let (VarDef a) (Expl a) |
   LetRec (RecDefs a) (Expl a)

-- Constructor matches store the non-matched constructors too, because we tolerate partial eliminators
-- and need hole expansion to be defined for those too.
data Match a =
   MatchVar Var |
   MatchVarAnon (Val a) |
   MatchConstr Ctr (List (Match a)) (List Ctr) |  -- list of matches should be a snoc list
   MatchRecord (Bindings Match a)

numVars :: forall a . Match a -> Int
numVars (MatchVar _)          = 1
numVars (MatchVarAnon _)      = 0
numVars (MatchConstr _ ws _)  = sum (numVars <$> ws)
numVars (MatchRecord xws)     = foldBindings (\(_ ↦ w) n -> n + numVars w) 0 xws
