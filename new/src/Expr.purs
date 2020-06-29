module Expr where

import Prelude hiding (top)
import Data.Either (Either)
import Data.List (List, zipWith)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Data.Traversable (sequence)
import Bindings (Var)
import DataType (Ctr)
import Lattice (class Selectable, Selected, mapα, maybeZipWithα)
import Util ((≟), error)
import Debug.Trace (trace) as T

trace s a = T.trace  s $ \_-> a

data Def = Def Elim Expr -- elim has codomain unit
data RecDef = RecDef Var Elim
type RecDefs = List RecDef

data RawExpr =
   Var Var |
   Op Var |
   Int Int |
   Str String |
   Constr Ctr (List Expr) |
   Lambda Elim |
   App Expr Expr |
   BinaryApp Expr Var Expr |
   MatchAs Expr Elim |
   Let Def Expr |
   LetRec RecDefs Expr

data Expr = Expr Selected RawExpr

expr :: RawExpr -> Expr
expr = Expr false


reverseArgs :: Cont -> Cont
reverseArgs (Body e) = (Body e)
reverseArgs (Arg n (ElimVar x k))
   = let k' = reverseArgs k
     in  case k' of (Arg n' (ElimVar x' k'')) -> (Arg n (ElimVar x' (Arg n' (ElimVar x k''))))
                    (Body e) -> (Arg n (ElimVar x (Body e)))
                    _ -> (Arg n (ElimVar x k))
reverseArgs c = c

-- Continuation of an eliminator.
data Cont = None | Body Expr | Arg Int Elim

body :: Cont -> Expr
body (Body e) = e
body _ = error "Expression expected"

instance selectableCont :: Selectable Cont where
   mapα f None  = None
   mapα f (Body e)  = Body $ mapα f e
   mapα f (Arg n σ)  = Arg n $ mapα f σ

   maybeZipWithα f (Body e) (Body e')     = Body <$> maybeZipWithα f e e'
   maybeZipWithα f (Arg n σ) (Arg m σ')   = Arg <$> n ≟ m <*> maybeZipWithα f σ σ'
   maybeZipWithα _ _ _                    = Just None

data Elim =
   ElimVar Var Cont |
   ElimConstr (Map Ctr Cont)

instance elim2Selectable :: Selectable Elim where
   mapα f (ElimVar x κ)    = ElimVar x $ mapα f κ
   mapα f (ElimConstr κs)  = ElimConstr $ map (mapα f) κs

   maybeZipWithα f (ElimVar x κ) (ElimVar x' κ')
      = ElimVar <$> x ≟ x' <*> maybeZipWithα f κ κ'
   maybeZipWithα f (ElimConstr κs) (ElimConstr κs')   = ElimConstr <$> maybeZipWithα f κs κs'
   maybeZipWithα _ _ _                                = Just $ ElimVar "x" None --Nothing

data Module = Module (List (Either Def RecDefs))

instance defSelectable :: Selectable Def where
   mapα f (Def σ e)                       = Def (mapα f σ) (mapα f e)
   maybeZipWithα f (Def σ e) (Def σ' e')  = Def <$> maybeZipWithα f σ σ' <*> maybeZipWithα f e e'

instance recDefSelectable :: Selectable RecDef where
   mapα f (RecDef x σ)                          = RecDef x (mapα f σ)
   maybeZipWithα f (RecDef x σ) (RecDef x' σ')  = RecDef <$> x ≟ x' <*> maybeZipWithα f σ σ'

instance exprSelectable :: Selectable Expr where
   mapα f (Expr α r)                         = Expr (f α) $ mapα f r
   maybeZipWithα f (Expr α r) (Expr α' r')   = Expr <$> pure (f α α') <*> maybeZipWithα f r r'

instance rawExprSelectable :: Selectable RawExpr where
   mapα _ (Var x)             = Var x
   mapα _ (Op φ)              = Op φ
   mapα _ (Int n)             = Int n
   mapα _ (Str str)           = Str str
   mapα f (Constr c es)       = Constr c $ map (mapα f) es
   mapα f (Lambda σ)          = Lambda (mapα f σ)
   mapα f (App e e')          = App (mapα f e) (mapα f e')
   mapα f (BinaryApp e op e') = BinaryApp (mapα f e) op (mapα f e')
   mapα f (MatchAs e σ)       = MatchAs (mapα f e) (mapα f σ)
   mapα f (Let def e)         = Let (mapα f def) (mapα f e)
   mapα f (LetRec δ e)        = LetRec (map (mapα f) δ) (mapα f e)

   maybeZipWithα _ (Var x) (Var x')                = Var <$> x ≟ x'
   maybeZipWithα _ (Op op) (Op op')                = Op <$> op ≟ op'
   maybeZipWithα _ (Int n) (Int n')                = Int <$> n ≟ n'
   maybeZipWithα _ (Str s) (Var s')                = Str <$> s ≟ s'
   maybeZipWithα f (Constr c es) (Constr c' es')
      = Constr <$> c ≟ c' <*> sequence (zipWith (maybeZipWithα f) es' es')
   maybeZipWithα f (App e1 e2) (App e1' e2')
      = App <$>  maybeZipWithα f e1 e1' <*> maybeZipWithα f e2 e2'
   maybeZipWithα f (BinaryApp e1 op e2) (BinaryApp e1' op' e2')
      = BinaryApp <$> maybeZipWithα f e1 e1' <*> op ≟ op' <*> maybeZipWithα f e2 e2'
   maybeZipWithα f (Lambda σ) (Lambda σ')
      = Lambda <$> maybeZipWithα f σ σ'
   maybeZipWithα f (MatchAs e σ) (MatchAs e' σ')
      = MatchAs <$> maybeZipWithα f e e' <*> maybeZipWithα f σ σ'
   maybeZipWithα f (Let def e) (Let def' e')
      = Let <$> maybeZipWithα f def def' <*> maybeZipWithα f e e'
   maybeZipWithα f (LetRec δ e) (LetRec δ' e')
      = LetRec <$> maybeZipWithα f δ δ' <*>  maybeZipWithα f e e'
   maybeZipWithα _ _ _                             = Nothing

