module Bwd where

import Prelude hiding (absurd)
import Data.List (List(..), (:))
import Data.Map (insert)
import Bindings (Binding, Bindings(..), (:+:), (↦), (◃), length, find, foldEnv, splitAt)
import Expl (Expl(..), Match(..))
import Expl (RawExpl(..), VarDef(..)) as T
import Expr (Cont(..), Elim(..), Expr(..), RawExpr(..), VarDef(..), RecDefs, varAnon)
import Lattice (𝔹, bot, (∨))
import Util (Endo, type (×), (×), (≜), absurd, error, successful)
import Val (Env, Val(Val))
import Val (RawVal(..), Val(Hole)) as V

unmatch :: Env 𝔹 -> Match 𝔹 -> Env 𝔹 × Env 𝔹
unmatch (ρ :+: x ↦ v) (MatchVar x') = ρ × (Empty :+: (x ≜ x') ↦ v)
unmatch Empty (MatchVar x')         = error absurd
unmatch ρ (MatchVarAnon _)          = ρ × Empty
unmatch ρ (MatchConstr (_ × ξs) _) =  unmatchArgs ρ ξs

unmatchArgs :: Env 𝔹 -> List (Match 𝔹) -> Env 𝔹 × Env 𝔹
unmatchArgs ρ Nil = ρ × Empty
unmatchArgs ρ (ξ : ξs) =
   let ρ'  × ρ2   = unmatch ρ ξ
       ρ'' × ρ1   = unmatchArgs ρ' ξs in
   ρ'' × (ρ1 <> ρ2)

-- second argument contains original environment and recursive definitions
closeDefs_bwd :: Env 𝔹 -> Env 𝔹 × RecDefs 𝔹 -> Env 𝔹 × RecDefs 𝔹 × 𝔹
closeDefs_bwd ρ (ρ0 × δ0) =
   case foldEnv joinDefs (Empty × bot ρ0 × bot δ0 × false) ρ of
   δ' × ρ' × δ × α -> ρ' × (δ ∨ δ') × α
   where
   joinDefs :: Binding Val 𝔹 -> Endo (RecDefs 𝔹 × Env 𝔹 × RecDefs 𝔹 × 𝔹)
   joinDefs (f ↦ Val α_f (V.Closure ρ_f δ_f σ_f)) (δ_acc × ρ' × δ × α)
      = (δ_acc :+: f ↦ σ_f) × (ρ' ∨ ρ_f) × (δ ∨ δ_f) × (α ∨ α_f)
   joinDefs (_ ↦ Val _ _) _                     = error absurd
   joinDefs (f ↦ V.Hole) (δ_acc × ρ' × δ × α)   = (δ_acc :+: f ↦ bot (successful $ find f δ0)) × ρ' × δ × α

match_bwd :: Env 𝔹 -> Cont 𝔹 -> 𝔹 -> Match 𝔹 -> Val 𝔹 × Elim 𝔹
match_bwd (Empty :+: x ↦ v) κ α (MatchVar x')   = v × ElimVar (x ≜ x') κ
match_bwd Empty κ α (MatchVarAnon v)            = bot v × ElimVar varAnon κ
match_bwd ρ κ α (MatchConstr (c × ξs) κs)       =
   let vs × κ' = matchArgs_bwd ρ κ α ξs in
   (Val α $ V.Constr c vs) × (ElimConstr $ insert c κ' $ map bot κs)
match_bwd _ _ _ _                               = error absurd

matchArgs_bwd :: Env 𝔹 -> Cont 𝔹 -> 𝔹 -> List (Match 𝔹) -> List (Val 𝔹) × Cont 𝔹
matchArgs_bwd ρ κ α Nil       = Nil × κ
matchArgs_bwd ρ κ α (ξ : ξs)  =
   let ρ' × ρ1   = unmatch ρ ξ
       v  × σ    = match_bwd ρ1 κ α ξ
       vs × κ'   = matchArgs_bwd ρ' (Arg σ) α ξs in
   (vs <> v : Nil) × κ'

eval_bwd :: Val 𝔹 -> Expl 𝔹 -> Env 𝔹 × Expr 𝔹 × 𝔹
eval_bwd v (Expl ρ (T.Var x _))
   = (bot ρ ◃ x ↦ v) × Expr false (Var x) × false
eval_bwd (Val α (V.Str s)) (Expl ρ (T.Str _ _))
   = bot ρ × Expr α (Str s) × α
eval_bwd (Val α (V.Int n)) (Expl ρ (T.Int _ _))
   = bot ρ × Expr α (Int n) × α
eval_bwd v@(Val α (V.Primitive φ)) (Expl ρ (T.Op op _))
   = (bot ρ ◃ op ↦ v) × Expr false (Op op) × false
eval_bwd (Val α (V.Closure ρ δ σ)) (Expl _ (T.Lambda σ'))
   = ρ × Expr α (Lambda σ) × α
eval_bwd (Val α (V.Constr c vs)) (Expl ρ (T.Constr c' ts))
   = let evalArgs_bwd :: List (Val 𝔹) -> List (Expl 𝔹) -> Env 𝔹 × List (Expr 𝔹) × 𝔹
         evalArgs_bwd (v : vs') (t : ts') =
            let ρ  × e  × α   = eval_bwd v t
                ρ' × es × α'  = evalArgs_bwd vs' ts'
            in  case ρ' of Empty -> ρ × (e : Nil) × α
                           _     -> (ρ ∨ ρ') × (e : es) × (α ∨ α')
         evalArgs_bwd Nil Nil = bot ρ × Nil × α
         evalArgs_bwd _ _ = error absurd

         ρ' × es × α' = evalArgs_bwd vs ts in
     ρ' × Expr α (Constr c es) × α'
eval_bwd v (Expl _ (T.App (t × δ) t' ξ t''))
   = let ρ1ρ2ρ3 × e × α    = eval_bwd v t''
         ρ1ρ2 × ρ3         = unmatch ρ1ρ2ρ3 ξ
         v' × σ            = match_bwd ρ3 (Body e) α ξ
         ρ1 × ρ2           = splitAt (length δ) ρ1ρ2
         ρ' × e' × α'      = eval_bwd v' t'
         ρ1' × δ' × α2     = closeDefs_bwd ρ2 (ρ1 × δ)
         ρ'' × e'' × α''   = eval_bwd (Val (α ∨ α2) $ V.Closure (ρ1 ∨ ρ1') δ' σ) t in
      (ρ' ∨ ρ'') × Expr (α' ∨ α'') (App e'' e') × (α' ∨ α'')
eval_bwd (Val α v) (Expl _ (T.BinaryApp (t1 × v1) (op × Val _ φ) (t2 × v2)))
   = let ρ  × e  × _ = eval_bwd v1 t1
         ρ' × e' × _ = eval_bwd v2 t2 in
     (ρ ∨ ρ' ◃ op ↦ Val α φ) × Expr α (BinaryApp e op e') × α
eval_bwd (Val α v) (Expl _ (T.AppOp (t1 × v1) (t2 × v2)))
   = let ρ  × e  × _ = eval_bwd v1 t1
         ρ' × e' × _ = eval_bwd v2 t2 in
     (ρ ∨ ρ') × Expr α (App e e') × α
eval_bwd v (Expl _ (T.MatchAs t1 ξ t2))
   = let ρ1ρ2 × e × α   = eval_bwd v t2
         ρ1 × ρ2        = unmatch ρ1ρ2 ξ
         v1 × σ         = match_bwd ρ2 (Body e) α ξ
         ρ1' × e' × α'  = eval_bwd v1 t1 in
     (ρ1' ∨ ρ1) × Expr (α ∨ α') (MatchAs e' σ) × (α ∨ α')
eval_bwd v (Expl _ (T.Let (T.VarDef ξ t1) t2))
   = let ρ1ρ2 × e2 × α2 = eval_bwd v t2
         ρ1 × ρ2        = unmatch ρ1ρ2 ξ
         v' × σ         = match_bwd ρ2 None α2 ξ
         ρ1' × e1 × α1  = eval_bwd v' t1 in
     (ρ1 ∨ ρ1') × Expr (α1 ∨ α2) (Let (VarDef σ e1) e2) × (α1 ∨ α2)
eval_bwd v (Expl _ (T.LetRec δ t))
   = let ρ1ρ2 × e × α   = eval_bwd v t
         ρ1 × ρ2        = splitAt (length δ) ρ1ρ2
         ρ1' × δ' × α'  = closeDefs_bwd ρ2 (ρ1 × δ) in
     (ρ1 ∨ ρ1') × Expr (α ∨ α') (LetRec δ' e) × (α ∨ α')
eval_bwd _ _ = error absurd
