module Fwd where

import Prelude ((<>), ($))
import Data.Maybe (Maybe(..))
import Data.Semiring ((+))
import Expr


fwd_match :: Val -> Elim -> Match -> Maybe (T3 Env Expr Availability)
fwd_match val σ ξ
 = case val, σ, ξ of 
    _, ElimVar x t expr, MatchVar mx
        ->  Just $ T3 (EnvNil :∈: T2 x val) expr Top
    ValTrue, ElimBool (BranchTrue expr1) (BranchFalse expr2), MatchTrue
        ->  Just $ T3 EnvNil expr1 Top
    ValBottom, ElimBool (BranchTrue expr1) (BranchFalse expr2), MatchTrue
        ->  Just $ T3 EnvNil expr1 Bottom
    ValFalse, ElimBool (BranchTrue expr1) (BranchFalse expr2), MatchFalse
        ->  Just $ T3 EnvNil expr2 Top
    ValBottom, ElimBool (BranchTrue expr1) (BranchFalse expr2), MatchFalse
        ->  Just $ T3 EnvNil expr2 Bottom
    ValPair x' y', ElimPair x _ y _ expr, MatchPair mx my 
        ->  let ρ' = (EnvNil :∈: T2 y y' :∈: T2 x x')
            in  Just $ T3 ρ' expr Top
    ValPair_Del x' y', ElimPair x _ y _ expr, MatchPair mx my
        ->  let ρ' = (EnvNil :∈: T2 y y' :∈: T2 x x')
            in  Just $ T3 ρ' expr Bottom
    ValNil, ElimList (BranchNil _ expr2) (BranchCons x xs _ expr1), MatchNil
        ->  Just $ T3 EnvNil expr2 Top
    ValBottom, ElimList (BranchNil _ expr2) (BranchCons x xs _ expr1), MatchNil
        ->  Just $ T3 EnvNil expr2 Bottom       
    ValCons v vs, ElimList (BranchNil _ expr2) (BranchCons x xs _ expr1), MatchCons mx mxs
        ->  let ρ' = (EnvNil :∈: T2 xs vs :∈: T2 x v)
            in  Just $ T3 ρ' expr1 Top
    ValCons_Del v vs, ElimList (BranchNil _ expr2) (BranchCons x xs _ expr1), MatchCons mx mxs
        ->  let ρ' = (EnvNil :∈: T2 xs vs :∈: T2 x v)
            in  Just $ T3 ρ' expr1 Bottom
    _,_,_ ->  Nothing




fwd :: Partial => Expr -> Trace  -> Availability -> Env -> Val
fwd (ExprBottom) TraceBottom α ρ = ValBottom
fwd (ExprVar x) t α ρ
 = case findVarVal x ρ of
    Just val -> val
    _        -> ValFailure ("variable " <> x <> " not found")
fwd ExprTrue TraceTrue Top  ρ                    = ValTrue
fwd ExprTrue TraceTrue Bottom  ρ                 = ValBottom
fwd ExprFalse TraceFalse Top ρ                   = ValFalse
fwd ExprFalse TraceFalse Bottom ρ                = ValBottom
fwd (ExprNum n) (TraceNum tn) Top ρ              = ValNum n
fwd (ExprNum n) (TraceNum tn) Bottom ρ           = ValBottom
fwd (ExprPair e1 e2) (TracePair te1 te2) Top  ρ  = ValPair (fwd e1 te1 Top ρ) (fwd e2 te2 Top ρ)
fwd (ExprPair e1 e2) (TracePair te1 te2) Bottom ρ       = ValPair_Del (fwd e1 te1 Bottom ρ) (fwd e2 te2 Bottom ρ)
fwd (ExprPair_Del e1 e2) (TracePair te1 te2) α ρ = ValPair_Del (fwd e1 te1 α ρ) (fwd e2 te2 α ρ)
fwd ExprNil TraceNil α ρ                = ValNil
fwd (ExprCons e es) (TraceCons te tes) Top ρ      = ValCons (fwd e te Top ρ) (fwd es tes Top ρ)
fwd (ExprCons e es) (TraceCons te tes) Bottom ρ   = ValCons_Del (fwd e te Bottom ρ) (fwd es tes Bottom ρ)
fwd (ExprCons_Del e es) (TraceCons te tes) α ρ    = ValCons_Del (fwd e te α ρ) (fwd es tes α ρ)
fwd (ExprLetrec fun σ e) (TraceLetrec x tσ te) α ρ = fwd e te α (ρ :∈: T2 fun (ValClosure ρ fun σ))
fwd (ExprApp e e') (TraceApp te te' m tu) α ρ
 = case fwd e te α ρ  of
     ValClosure ρ' fun σ
        -> case fwd_match (fwd e' te' α ρ) σ m of
                Just (T3 ρ'' e''  α') -> fwd e'' tu α' (concEnv ρ' ρ'' :∈: T2 fun (ValClosure ρ' fun σ))
                Nothing               -> ValFailure "Match not found"
     _  -> ValFailure "Applied expression e in e e' does not fwd to closure"
fwd (ExprAdd e1 e2) (TraceAdd te1 te2) Bottom ρ   = ValBottom
fwd (ExprAdd e1 e2) (TraceAdd te1 te2) Top ρ
 = let v1 = fwd e1 te1 Top  ρ
       v2 = fwd e2 te2 Top  ρ
   in  case v1, v2 of
          (ValNum n1), (ValNum n2) -> ValNum (n1 + n2)
          ValBottom,  _            -> ValBottom 
          _,          ValBottom    -> ValBottom
          _,          _            -> ValFailure "Arithemetic type error: e1 or/and e2 do not fwd to ints"
fwd (ExprLet x e1 e2) (TraceLet tx te1 te2) α ρ
 = let v1  = fwd e1 te1 α ρ
       ρ'  = (ρ :∈: T2 x v1)
   in  fwd e2 te2 α ρ'
fwd (ExprLet_Body x e1 e2) (TraceLet tx te1 te2) α ρ = fwd e2 te2 α (ρ :∈: T2 x ValBottom)
fwd (ExprMatch e σ) (TraceMatch te m tu) α ρ
 = case fwd_match (fwd e te α ρ) σ m of
    Nothing            -> ValFailure "Match not found"
    Just (T3 ρ' e' α') -> fwd e' tu α' (concEnv ρ ρ')


