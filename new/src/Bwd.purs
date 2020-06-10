module Bwd where

import Prelude (($), (<>), (==), append)
import Bindings (Bindings(..), (:+:), (↦), ε, find, Var)
import Expr (Elim(..), Expr(..), RawExpr(..))
import Selected
import Util (T3(..), absurd, error, todo, successful, (≟), (≜))
import Val (Env, Val(..), BinaryOp(..), UnaryOp(..))
import Val (RawVal(..)) as V
import Expl (Expl(..)) as T
import Expl (Expl, Match(..))
import Data.Tuple (Tuple(..))

bwd_env :: forall k . Env -> Match (Elim k) -> (Match k) -> Tuple Env Env
bwd_env ρ ξ ξ' = let ρ1 = bound_vars ρ ξ
                     ρ2 = bound_vars ρ ξ'
                 in  Tuple ρ1 ρ2

bound_vars :: forall k . Env -> Match k -> Env
bound_vars ρ (MatchVar x)     = ε :+: x ↦ successful (find x ρ)
bound_vars ρ (MatchTrue k)    = ε
bound_vars ρ (MatchFalse k)   = ε
bound_vars ρ (MatchPair ξ ξ') = append (bound_vars ρ ξ) (bound_vars ρ ξ')
bound_vars ρ (MatchNil k)     = ε
bound_vars ρ (MatchCons {nil: k, cons: Tuple ξ ξ'}) = append (bound_vars ρ ξ) (bound_vars ρ ξ')

match_bwd :: forall k . Lattice k => Env -> k -> Selected -> Match k -> Tuple Val (Elim k)
-- var
match_bwd (ε :+: x ↦ v) κ α (MatchVar x') = Tuple v (ElimVar (x ≜ x') κ)
-- true
match_bwd ε κ α (MatchTrue κ')  = Tuple (Val α V.True) (ElimBool { true: κ, false: bot κ' })
-- false
match_bwd ε κ α (MatchFalse κ') = Tuple (Val α V.False) (ElimBool { true: bot κ', false: κ })
-- pair
match_bwd ρ κ α (MatchPair ξ ξ') =
   let Tuple ρ1 ρ2 = bwd_env ρ ξ ξ'
       Tuple v' σ  = match_bwd ρ2 κ α ξ'
       Tuple v  τ  = match_bwd ρ1 σ α ξ
   in  Tuple (Val α (V.Pair v v')) (ElimPair τ)
-- nil
match_bwd ε κ α (MatchNil σ) = Tuple (Val α V.Nil) (ElimList {nil: κ, cons: bot σ})
-- cons
match_bwd ρ κ α (MatchCons { nil: κ', cons: Tuple ξ ξ'}) =
   let Tuple ρ1 ρ2 = bwd_env ρ ξ ξ'
       Tuple v' σ  = match_bwd ρ2 κ α ξ'
       Tuple v  τ  = match_bwd ρ1 σ α ξ
   in  Tuple (Val α (V.Cons v v')) (ElimList {nil: bot κ, cons: τ})
match_bwd _ _ _ _ = error absurd

eval_bwd :: Val -> Expl -> T3 Env Expr Selected
-- true
eval_bwd (Val α V.True ) T.True = T3 ε (Expr α True) α
-- false
eval_bwd (Val α V.False) T.False = T3 ε (Expr α False) α
-- pair
-- eval_bwd { α, u: V.Pair v1 v2} (T.Pair t1 t2) = ...
-- var
eval_bwd (Val α v) (T.Var x) = T3 (ε :+: x ↦ (Val α v)) (Expr α (Var x)) Bot
-- int
eval_bwd (Val α (V.Int n)) (T.Int tn) = T3 ε (Expr α (Int n)) α
-- op
eval_bwd (Val α (V.Binary (BinaryOp s bin))) (T.Op op)
   = T3 (ε :+: op ↦ (Val α (V.Binary (BinaryOp s bin)))) (Expr α (Op op)) Bot
eval_bwd (Val α (V.Unary (UnaryOp s una))) (T.Op op)
   = T3 (ε :+: op ↦ (Val α (V.Unary (UnaryOp s una)))) (Expr α (Op op)) Bot
-- nil
eval_bwd (Val α V.Nil) T.Nil = T3 ε (Expr α Nil) α
-- cons
eval_bwd (Val α (V.Cons u v)) (T.Cons tT uU)
   = let T3 ρ  e  α'  = eval_bwd u tT
         T3 ρ' e' α'' = eval_bwd v uU
     in  T3 (join ρ ρ') (Expr α (Cons e e')) (α ∨ α' ∨ α'')
-- apply
-- eval_bwd val (T.App t u match t') = ...
-- -- apply-prim
-- eval_bwd { α, n } (T.AppOp t u) = ...
-- -- binary-apply
-- eval_bwd { α, n } (T.BinaryApp t op u ) = ...
-- let
-- eval_bwd val (T.Let x t1 t2) = ...
-- -- let-rec
-- eval_bwd val (T.Letrec x t1 t2) = ...
eval_bwd _ _ = error absurd