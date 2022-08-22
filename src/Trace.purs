module Trace where

import Prelude
import Data.List (List)
import Data.Map (Map)
import Data.Set (Set, empty, singleton, unions)
import Bindings (Bindings, Var, val)
import DataType (Ctr)
import Expr (class BV, Cont, Elim, RecDefs, bv)
import Util (type (×))
import Val (Array2, Env, PrimOp, Val)

data VarDef a = VarDef (Match a) (Trace a)

-- We record "raw" (unannotated) values in some cases; represent as values annotated with false.
data Trace a =
   Var Var |
   Op Var |
   Int Int |
   Float Number |
   Str String |
   Record (Env a) (Bindings (Trace a)) |
   Constr (Env a) Ctr (List (Trace a)) |
   Matrix (Array2 (Trace a)) (Var × Var) (Int × Int) (Trace a) |
   Lambda (Elim a) |
   Project (Trace a) (Bindings (Val a)) Var |
   App (Trace a × Set Var × Elim a) (Trace a) (Match a) (Trace a) |
   AppPrim (Trace a × PrimOp × List (Val a)) (Trace a × Val a) | -- record prior arguments
   AppConstr (Trace a × Ctr × Int) (Trace a) |                   -- record number of prior arguments
   Let (VarDef a) (Trace a) |
   LetRec (RecDefs a) (Trace a)

data Match a =
   MatchVar Var (Val a) |
   MatchVarAnon (Val a) |
   -- list of matches should be a snoc list
   MatchConstr Ctr (List (Match a)) (Map Ctr (Cont a)) |
   MatchRecord (Bindings (Match a))

instance BV (Match a) where
   bv (MatchVar x _)        = singleton x
   bv (MatchVarAnon _)      = empty
   bv (MatchConstr _ ws _)  = unions (bv <$> ws)
   bv (MatchRecord xws)     = unions (bv <$> val <$> xws)