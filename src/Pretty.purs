module Pretty (class Pretty, pretty, module P) where

import Prelude hiding (absurd, between)
import Data.List (List(..), (:), fromFoldable)
import Data.List.NonEmpty (NonEmptyList(..))
import Data.Map (toUnfoldable)
import Data.NonEmpty ((:|))
import Data.String (Pattern(..), contains) as Data.String
import Text.Pretty (Doc, atop, beside, hcat, render, text, vcat)
import Text.Pretty (render) as P
import Bindings (Binding, Bindings(..), (:+:), (↦))
import DataType (Ctr, cCons, cNil, cPair)
import Expr (Cont(..), Elim(..), varAnon)
import Expr (Expr(..), RawExpr(..), VarDef(..), expr) as E
import SExpr (Expr(..), ListPatternRest(..), ListRest(..), Patt(..), Pattern(..), Qualifier(..), RawExpr(..), VarDef(..), expr)
import Expl (RawExpl(..), VarDef(..)) as T
import Expl (Expl(..), Match(..), RawExpl)
import Lattice (class BoundedJoinSemilattice)
import Util (Endo, type (×), (×), absurd, error, intersperse)
import Val (Primitive, Val)
import Val (Val(..)) as V

infixl 5 beside as :<>:

between :: Doc -> Doc -> Endo Doc
between l r doc = l :<>: doc :<>: r

brackets :: Endo Doc
brackets = between (text "[") (text "]")

comma :: Doc
comma = text "," :<>: space

space :: Doc
space = text " "

tab :: Doc
tab = text "   "

operator :: String -> Doc
operator = text >>> between space space

parens :: Endo Doc
parens = between (text "(") (text ")")

null :: Doc
null = text ""

hole :: Doc
hole = text "□"

class ToList a where
   toList :: a -> List a

instance toListExpr :: BoundedJoinSemilattice a => ToList (E.Expr a)  where
   toList (E.Expr _ (E.Constr c (e : e' : Nil))) | c == cCons = e : toList e'
   toList (E.Expr _ (E.Constr c Nil)) | c == cNil             = Nil
   toList e                                                   = error $ "toListExpr - not a list: " <> render (pretty e)

instance toListVal :: BoundedJoinSemilattice a => ToList (Val a)  where
   toList (V.Constr _ c (v : v' : Nil)) | c == cCons  = v : toList v'
   toList (V.Constr _ c Nil)            | c == cNil   = Nil
   toList v                                           = error $ "toListVal - not a list: " <> render (pretty v)

class Pretty p where
   pretty :: p -> Doc

instance prettyBool :: Pretty Boolean where
   pretty = text <<< show

instance prettyBindings :: Pretty (t a) => Pretty (Bindings t a) where
   pretty (ρ :+: kv) = brackets $ pretty $ ρ :+: kv
   pretty Empty = text "[]"

instance prettyVoid :: Pretty Void where
   pretty _ = error absurd

instance prettyExpl :: BoundedJoinSemilattice a => Pretty (Expl a) where
   pretty (Expl _ t) = pretty t

instance prettyRawExpl :: BoundedJoinSemilattice a => Pretty (RawExpl a) where
   pretty T.Hole                          = hole
   pretty (T.Var x)                       = text x
   pretty (T.Op op)                       = text op
   pretty T.Int                           = text "int"
   pretty T.Float                         = text "float"
   pretty T.Str                           = text "str"
   pretty (T.Constr c ts)                 = prettyConstr c ts
   pretty (T.Matrix _ _ _)                = error "todo"
   pretty T.Lambda                        = text "fun"
   pretty (T.AppHole t)                   = text "App" :<>: parens (hole :<>: comma :<>: hole)
   pretty (T.App (t × _) t' ξ t'')        =
      text "App" :<>:
      parens (atop (text "t1: " :<>: pretty t :<>: comma)
                   (atop (text "t2: " :<>: pretty t' :<>: comma)
                         (atop (text "match: " :<>:  pretty ξ :<>: comma) (text "t3: " :<>: pretty t''))))
   pretty (T.AppOp tv tv')                = pretty tv :<>: space :<>: pretty tv'
   pretty (T.BinaryApp tv (op × _) tv')   =
      pretty tv :<>: space :<>: text op :<>: space :<>: pretty tv'
   pretty (T.Let (T.VarDef ξ t) t')       =
      atop (text "let " :<>: pretty ξ :<>: text " = " :<>: pretty t :<>: text " in")
           (pretty t')
   pretty (T.LetRec δ t)                  =
      atop (text "letrec " :<>: pretty δ)
           (text "in     " :<>: pretty t)

instance prettyMatch :: BoundedJoinSemilattice a => Pretty (Match a) where
   pretty (MatchConstr (c × ξs) κs) =
      text "ξ = " :<>:
      atop (text "Pattern:       " :<>: text (show c) :<>: operator "-> " :<>: vcat (map pretty ξs))
           (text "Continuations: " :<>: vcat (map pretty $ (toUnfoldable κs :: List _)))
   pretty (MatchVar x) = text "ξ = " :<>: text x
   pretty (MatchVarAnon x) = text "ξ = " :<>: text varAnon

instance prettyExplVal :: BoundedJoinSemilattice a => Pretty (Expl a × Val a) where
   pretty (t × v) = parens $ pretty t :<>: comma :<>: pretty v

instance prettyList :: Pretty a => Pretty (List a) where
   pretty xs = brackets $ hcat $ intersperse comma $ map pretty xs

instance prettyListRest :: BoundedJoinSemilattice a => Pretty (ListRest a) where
   pretty ListRestHole = hole
   pretty l = pretty $ listRestToExprs l

instance prettyListPatternRest :: Pretty (ListPatternRest) where
   pretty l = pretty $ listPatternRestToPatterns l

instance prettyExpr :: BoundedJoinSemilattice a => Pretty (E.Expr a) where
   pretty E.Hole     = hole
   pretty (E.Expr _ r) = pretty r

instance prettyCtr :: Pretty Ctr where
   pretty = show >>> text

-- Cheap hack to make progress on migrating some tests; need to revisit.
prettyParensOpt :: forall a . Pretty a => a -> Doc
prettyParensOpt x =
   let doc = pretty x in
   if Data.String.contains (Data.String.Pattern " ") $ render doc
   then parens doc
   else doc

prettyConstr :: forall a . Pretty a => Ctr -> List a -> Doc
prettyConstr c xs
   | c == cPair = case xs of
      x : y : Nil -> parens $ pretty x :<>: comma :<>: pretty y
      _           -> error absurd
   | c == cNil || c == cCons = pretty xs
   | otherwise = pretty c :<>: space :<>: hcat (intersperse space $ map prettyParensOpt xs)

instance prettyRawExpr :: BoundedJoinSemilattice a => Pretty (E.RawExpr a) where
   pretty (E.Int n)                 = text $ show n
   pretty (E.Float n)               = text $ show n
   pretty (E.Str str)               = text $ show str
   pretty (E.Var x)                 = text x
   pretty r@(E.Constr c es)
      | c == cNil || c == cCons     = pretty $ toList $ E.expr r
      | otherwise                   = prettyConstr c es
   pretty (E.Matrix _ _ _)            = error "todo"
   pretty (E.Op op)                 = parens $ text op
   pretty (E.Let (E.VarDef σ e) e')   =
      atop (text ("let ") :<>: pretty σ :<>: operator "=" :<>: pretty e :<>: text " in") (pretty e')
   pretty (E.LetRec δ e)            =
      atop (text "letrec " :<>: pretty δ) (text "in " :<>: pretty e)
   pretty (E.Lambda σ)              = text "fun " :<>: pretty σ
   pretty (E.App e e')              = pretty e :<>: space :<>: pretty e'
   pretty (E.BinaryApp e op e')     = pretty e :<>: operator op :<>: pretty e'

instance prettyBindingElim :: BoundedJoinSemilattice a => Pretty (Binding Elim a) where
   pretty (f ↦ σ) = text f :<>: operator "=" :<>: pretty σ

instance prettyBindingVal :: BoundedJoinSemilattice a => Pretty (Binding Val a) where
   pretty (x ↦ v) = text x :<>: text " ↦ " :<>: pretty v

instance prettyCont :: BoundedJoinSemilattice a => Pretty (Cont a) where
   pretty None          = text "⋆"
   pretty (Body e)      = pretty e
   pretty (Arg σ)       = pretty σ

instance prettyBranch :: BoundedJoinSemilattice a => Pretty (Ctr × Cont a) where
   pretty (c × κ) = text (show c) :<>: operator "->" :<>: pretty κ

instance prettyElim :: BoundedJoinSemilattice a => Pretty (Elim a) where
   pretty (ElimVar x κ)    = text x :<>: operator "->" :<>: pretty κ
   pretty (ElimConstr κs)  = hcat $ map (\x -> pretty x :<>: comma) $ (toUnfoldable κs :: List _)

instance prettyRawVal :: BoundedJoinSemilattice a => Pretty (Val a) where
   pretty V.Hole                 = hole
   pretty (V.Int _ n)            = text $ show n
   pretty (V.Float _ n)          = text $ show n
   pretty (V.Str _ str)          = text $ show str
   pretty u@(V.Constr _ c vs)
      | c == cNil || c == cCons  = pretty $ toList u
      | otherwise                = prettyConstr c vs
   pretty (V.Matrix _ vss _)       = hcat (pretty <$> fromFoldable (fromFoldable <$> vss))
   pretty (V.Closure ρ δ σ)      =
    text "Closure" :<>: text "(" :<>:
    (atop (atop (text "env: " :<>: pretty ρ) (text "defs: " :<>: pretty δ)) (text "elim: " :<>: pretty σ)) :<>: (text ")")
   pretty (V.Primitive _ op)     = parens $ pretty op

instance prettyPrimitive :: Pretty Primitive where
   pretty _ = text "<prim-op>"

-- Surface language

listRestToExprs :: forall a . ListRest a -> List (Expr a)
listRestToExprs (End _) = Nil
listRestToExprs (Next _ e l) = e : listRestToExprs l
listRestToExprs (ListRestHole) = Nil

listPatternRestToPatterns :: ListPatternRest -> List Pattern
listPatternRestToPatterns PEnd         = Nil
listPatternRestToPatterns (PNext π πs) = π : listPatternRestToPatterns πs

instance toListSExpr :: BoundedJoinSemilattice a => ToList (Expr a)  where
   toList (Expr _ (Constr c (e : e' : Nil))) | c == cCons = e : toList e'
   toList (Expr _ (Constr c Nil)) | c == cNil             = Nil
   toList (Expr _ (ListEmpty))                            = Nil
   toList (Expr _ (ListNonEmpty e l))                     = e : listRestToExprs l
   toList e                                               = error $ "toListSExpr - not a list: " <> render (pretty e)

instance prettyRawSExpr :: BoundedJoinSemilattice a => Pretty (RawExpr a) where
   pretty (Var x)                   = text x
   pretty (Op op)                   = parens $ text op
   pretty (Int n)                   = text $ show n
   pretty (Float n)                 = text $ show n
   pretty (Str str)                 = text $ show str
   pretty r@(Constr c es)
      | c == cNil || c == cCons     = pretty $ toList $ expr r
      | otherwise                   = prettyConstr c es
   pretty (Matrix _ _ _)            = error "todo"
   pretty (Lambda bs)               = text "λ " :<>: pretty bs
   pretty (App e e')                = pretty e :<>: space :<>: pretty e'
   pretty (BinaryApp e op e')       = pretty e :<>: operator op :<>: pretty e'
   pretty (MatchAs e bs)            = text "match " :<>: pretty e :<>: text " as " :<>: pretty bs
   pretty (IfElse e1 e2 e3)         = text "if " :<>: pretty e1 :<>: text " then " :<>: pretty e2 :<>: text " else " :<>: pretty e3
   pretty r@(ListEmpty)             = pretty $ toList $ expr r
   pretty r@(ListNonEmpty e l)      = pretty $ toList $ expr r
   pretty (ListEnum e e')           = brackets $ pretty e :<>: text " .. " :<>: pretty e'
   pretty (ListComp e qs)           = brackets $ pretty e :<>: text " | " :<>: pretty qs
   pretty (Let ds e)                = atop (text "let " :<>: pretty ds) (text "in " :<>: pretty e)
   pretty (LetRec fπs e)            = atop (text "letrec " :<>: pretty fπs) (text "in " :<>: pretty e)

instance prettyNonEmptyList :: Pretty a => Pretty (NonEmptyList a) where
   pretty (NonEmptyList (x :| Nil)) = pretty (x : Nil)
   pretty (NonEmptyList (x :| xs))  = pretty (x : xs)

instance prettyString :: Pretty String where
   pretty s = text s

instance prettyClause :: BoundedJoinSemilattice a => Pretty (String × (NonEmptyList Pattern × Expr a)) where
   pretty (x × b) = pretty x :<>: text " = " :<>: pretty b

instance prettySBranch :: BoundedJoinSemilattice a => Pretty (NonEmptyList Pattern × Expr a) where
   pretty (πs × e) = pretty πs :<>: text " -> " :<>: pretty e

instance prettySVarDef :: BoundedJoinSemilattice a => Pretty (VarDef a) where
   pretty (VarDef π e) = pretty π :<>: text " = " :<>: pretty e

instance prettyPatternExpr :: BoundedJoinSemilattice a => Pretty (Pattern × Expr a) where
   pretty (π × e) = pretty π :<>: text " -> " :<>: pretty e

instance prettyQualifier :: BoundedJoinSemilattice a => Pretty (Qualifier a) where
   pretty (QualifierHole)              = hole
   pretty (Guard _ e)                  = pretty e
   pretty (Generator _ π e)            = pretty π :<>: text " <- " :<>: pretty e
   pretty (Declaration _ (VarDef π e)) = text "let " :<>: pretty π :<>: text " = " :<>: pretty e

instance prettyPatt :: Pretty Patt where
   pretty (Pattern p)            = pretty p
   pretty (ListPatternRest p)    = pretty p

instance prettyPattern :: Pretty Pattern where
   pretty (PVar x)               = text x
   pretty (PConstr ctr πs)       = pretty ctr :<>: space :<>: pretty πs
   pretty (PListEmpty)           = text "[]"
   pretty (PListNonEmpty π πs)   = pretty $ π : listPatternRestToPatterns πs

instance prettySExpr :: BoundedJoinSemilattice a => Pretty (Expr a) where
   pretty (Hole)     = hole
   pretty (Expr _ r) = pretty r

prettyProgram :: E.Expr Boolean -> Doc
prettyProgram e = atop (pretty e) (text "")
