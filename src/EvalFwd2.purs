module EvalFwd2 where

import Prelude hiding (absurd)
import Data.Array (fromFoldable) as A
import Data.List (List(..), (:), length, range, singleton, zip)
import Data.Profunctor.Strong ((***), (&&&), first, second)
import Bindings2 (Bindings, (↦), find, key, val)
import Expl2 (Expl(..), Match(..), VarDef(..)) as T
import Expl2 (Expl, Match)
import Expr2 (Cont, Elim(..), Expr(..), RecDefs, VarDef(..), asElim, asExpr)
import Lattice2 (𝔹, (∧))
import Primitive2 (match_fwd) as P
import Util2 (type (×), (×), (!), absurd, assert, error, mustLookup, successful)
import Util.SnocList2 (SnocList(..), (:-))
import Util.SnocList2 (unzip, zip, zipWith) as S
import Val2 (Env, PrimOp(..), Val)
import Val2 (Val(..)) as V

matchFwd :: Val 𝔹 -> Elim 𝔹 -> Match 𝔹 -> Env 𝔹 × Cont 𝔹 × 𝔹
matchFwd v (ElimVar _ κ) (T.MatchVar x) = (Lin :- x ↦ v) × κ × true
matchFwd _ (ElimVar _ κ) (T.MatchVarAnon _) = Lin × κ × true
matchFwd (V.Constr α _ vs) (ElimConstr m) (T.MatchConstr c ws _) =
   second (_ ∧ α) (matchArgsFwd vs (mustLookup c m) ws)
matchFwd (V.Record α xvs) (ElimRecord _ κ) (T.MatchRecord xws) =
   second (_ ∧ α) (matchRecordFwd xvs κ xws)
matchFwd _ _ _ = error absurd

matchArgsFwd :: List (Val 𝔹) -> Cont 𝔹 -> List (Match 𝔹) -> Env 𝔹 × Cont 𝔹 × 𝔹
matchArgsFwd Nil κ Nil = Lin × κ × true
matchArgsFwd (v : vs) σ (w : ws) =
   let ρ × κ × α = matchFwd v (asElim σ) w in
   (first (ρ <> _) *** (_ ∧ α)) (matchArgsFwd vs κ ws)
matchArgsFwd _ _ _ = error absurd

matchRecordFwd :: Bindings (Val 𝔹) -> Cont 𝔹 -> Bindings (Match 𝔹) -> Env 𝔹 × Cont 𝔹 × 𝔹
matchRecordFwd Lin κ Lin = Lin × κ × true
matchRecordFwd (xvs :- x ↦ v) σ (xws :- x' ↦ w) | x == x' =
   let ρ × σ' × α = matchRecordFwd xvs σ xws in
   (first (ρ <> _) *** (_ ∧ α)) (matchFwd v (asElim σ') w)
matchRecordFwd _ _ _ = error absurd

closeDefsFwd :: Env 𝔹 -> RecDefs 𝔹 -> 𝔹 -> RecDefs 𝔹 -> Env 𝔹
closeDefsFwd _ _ _ Lin = Lin
closeDefsFwd ρ δ0 α (δ :- f ↦ σ) = closeDefsFwd ρ δ0 α δ :- f ↦ V.Closure ρ δ0 α σ

evalFwd :: Env 𝔹 -> Expr 𝔹 -> 𝔹 -> Expl 𝔹 -> Val 𝔹
evalFwd ρ (Var _) _ (T.Var _ x) = successful (find x ρ)
evalFwd ρ (Op _) _ (T.Op _ op) = successful (find op ρ)
evalFwd _ (Int α _) α' (T.Int _ n) = V.Int (α ∧ α') n
evalFwd _ (Float α _) α' (T.Float _ n) = V.Float (α ∧ α') n
evalFwd _ (Str α _) α' (T.Str _ str) = V.Str (α ∧ α') str
evalFwd ρ (Record α xes) α' (T.Record _ xts) =
   let xs × ts = xts <#> (key &&& val) # S.unzip
       es = xes <#> val
       vs = (\(e' × t) -> evalFwd ρ e' α' t) <$> S.zip es ts in
   V.Record (α ∧ α') (S.zipWith (↦) xs vs)
evalFwd ρ (Constr α _ es) α' (T.Constr _ c ts) =
   V.Constr (α ∧ α') c ((\(e' × t) -> evalFwd ρ e' α' t) <$> zip es ts)
evalFwd ρ (Matrix α e1 _ e2) α' (T.Matrix tss (x × y) (i' × j') t2) =
   case evalFwd ρ e2 α' t2 of
      V.Constr _ _ (v1 : v2 : Nil) ->
         let (i'' × β) × (j'' × β') = P.match_fwd v1 × P.match_fwd v2
             vss = assert (i'' == i' && j'' == j') $ A.fromFoldable $ do
                i <- range 1 i'
                singleton $ A.fromFoldable $ do
                   j <- range 1 j'
                   singleton (evalFwd (ρ :- x ↦ V.Int β i :- y ↦ V.Int β' j) e1 α' (tss!(i - 1)!(j - 1)))
         in V.Matrix (α ∧ α') (vss × (i' × β) × (j' × β'))
      _ -> error absurd
evalFwd ρ (LetRec δ e') α (T.LetRec _ t) =
   let ρ' = closeDefsFwd ρ δ α δ in
   evalFwd (ρ <> ρ') e' α t
evalFwd ρ (Lambda σ) α (T.Lambda _ _) = V.Closure ρ Lin α σ
evalFwd ρ (RecordLookup e' _) α (T.RecordLookup t xs x) =
   case evalFwd ρ e' α t of
      V.Record _ xvs -> assert ((xvs <#> key) == xs) $ successful (find x xvs)
      _ -> error absurd
evalFwd ρ (App e1 e2) α (T.App (t1 × _ × _ × _) t2 w t3) =
   case evalFwd ρ e1 α t1 of
      V.Closure ρ1 δ β σ' ->
         let v = evalFwd ρ e2 α t2
             ρ2 = closeDefsFwd ρ1 δ β δ
             ρ3 × e3 × β' = matchFwd v σ' w in
         evalFwd (ρ1 <> ρ2 <> ρ3) (asExpr e3) (β ∧ β') t3
      _ -> error absurd
evalFwd ρ (App e1 e2) α (T.AppPrim (t1 × PrimOp φ × _) (t2 × _)) =
   case evalFwd ρ e1 α t1 of
      V.Primitive _ vs' ->
         let v2' = evalFwd ρ e2 α t2
             vs'' = vs' <> singleton v2' in
         if φ.arity > length vs'' then V.Primitive (PrimOp φ) vs'' else φ.op_fwd vs''
      _ -> error absurd
evalFwd ρ (App e1 e2) α (T.AppConstr (t1 × c × _) t2) =
   case evalFwd ρ e1 α t1 of
      V.Constr α' _ vs' ->
         let v = evalFwd ρ e2 α t2 in
         V.Constr (α ∧ α') c (vs' <> singleton v)
      _ -> error absurd
evalFwd ρ (Let (VarDef σ e1) e2) α (T.Let (T.VarDef w t1) t2) =
   let v = evalFwd ρ e1 α t1
       ρ' × _ × α' = matchFwd v σ w in
   evalFwd (ρ <> ρ') e2 α' t2
evalFwd _ _ _ _ = error absurd