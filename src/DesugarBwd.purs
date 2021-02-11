module DesugarBwd where

import Prelude hiding (absurd)
import Data.Function (on)
import Data.List (List(..), (:), zip)
import Data.List.NonEmpty (NonEmptyList(..), groupBy, toList, appendFoldable, reverse)
import Data.Map (fromFoldable)
import Data.NonEmpty ((:|))
import Data.Traversable (traverse)
import Data.Tuple (uncurry, fst, snd)
import Bindings (Binding, Bindings(..), (↦), (:+:))
import DataType (cPair, cCons, cNil, cTrue, cFalse)
import Expr (Cont(..), Elim(..))
import Expr (Expr(..), VarDef(..)) as E
import Pretty (render, pretty)
import SExpr (Expr(..), ListRest(..), Patt(..), Pattern(..), ListPatternRest(..), Qualifier(..), VarDef(..))
import Lattice (𝔹, (∧))
import Util (MayFail, type (×), (×), (≞), (≜), absurd, mustLookup, lookupE, error)

qualTrue :: 𝔹 -> Qualifier 𝔹
qualTrue α = Guard α (Constr α cTrue Nil)

snil :: 𝔹 -> Expr 𝔹
snil α = Constr α cNil Nil

class DesugarBwd a b where
   desugarBwd :: a -> b -> MayFail b

instance desugarBwdVarDef  :: DesugarBwd (E.VarDef Boolean) (VarDef Boolean) where
   desugarBwd (E.VarDef σ e) (VarDef π s) = VarDef π <$> desugarBwd e s

instance desugarBwdVarDefs :: DesugarBwd (E.Expr Boolean)
                                         (NonEmptyList (VarDef Boolean) × Expr Boolean) where
   desugarBwd (E.Let (E.VarDef σ e1) e2)
              (NonEmptyList (VarDef π s1 :| Nil) × s2) = do
              s1' <- desugarBwd e1 s1
              s2' <- desugarBwd e2 s2
              pure $ NonEmptyList (VarDef π s1' :| Nil) × s2'
   desugarBwd (E.Let (E.VarDef σ e1) e2)
              (NonEmptyList (VarDef π s1 :| d : ds) × s2) = do
              s1' <- desugarBwd e1 s1
              NonEmptyList (d' :| ds') × s2' <- desugarBwd e2 (NonEmptyList (d :| ds) × s2)
              pure $ NonEmptyList (VarDef π s1' :| d' : ds') × s2'
   desugarBwd _ (_ × _) = error absurd

concatNonEmpty :: forall a. NonEmptyList (NonEmptyList a) -> NonEmptyList a
concatNonEmpty (NonEmptyList (x :| x' : xs)) = appendFoldable x (concatNonEmpty (NonEmptyList (x' :| xs)))
concatNonEmpty (NonEmptyList (x :| Nil))     = x

{-                 →                        →           -}
{-                                            →         -}
{- let [f ↦ σ] ↘ (f c)         [f ↦ σ] ↘ (f, (p, s))    -}
instance desugarBwdRecDefs :: DesugarBwd (Bindings Elim Boolean)
                                         (NonEmptyList (String × ((NonEmptyList Pattern) × (Expr Boolean)))) where
   desugarBwd fσs fπes = concatNonEmpty <$> zipRecDefs fσs fπess --error "Desugar bwd for RecDefs not implemented"
      where
      fπess  = reverse $ (groupBy (eq `on` fst) fπes ::
               NonEmptyList (NonEmptyList (String × ((NonEmptyList Pattern) × (Expr Boolean)))))

      -- f a -> g b -> (a -> b -> b) -> (g b)
      zipRecDefs :: Bindings Elim 𝔹
                  -> NonEmptyList (NonEmptyList (String × ((NonEmptyList Pattern) × (Expr 𝔹))))
                  -> MayFail (NonEmptyList (NonEmptyList (String × ((NonEmptyList Pattern) × (Expr 𝔹)))))
      zipRecDefs (ρ :+: f ↦ σ) (NonEmptyList (fπes1 :| fπes2 : fπes_rest)) = do
         fπes1' <- fromRecDef (f ↦ σ) fπes1
         fπess' <- toList <$> zipRecDefs ρ (NonEmptyList (fπes2 :| fπes_rest))
         pure $ NonEmptyList (fπes1' :| fπess')
      zipRecDefs (Empty :+: f ↦ σ) (NonEmptyList (fπes1 :| Nil)) = do
         fπes1'  <- fromRecDef (f ↦ σ) fπes1
         pure $ NonEmptyList (fπes1' :| Nil)
      zipRecDefs ρ fπs = error absurd

      -- backward slice the eliminator (containing different possible pattern matches of the f)
      -- and the set of branches (for each pattern match of f)
      --          →       →
      -- f ↦ σ, (f c) ↘ (f c)
      fromRecDef :: Binding Elim 𝔹
                  -> NonEmptyList (String × (NonEmptyList Pattern × Expr 𝔹))
                  -> MayFail (NonEmptyList (String × (NonEmptyList Pattern × Expr 𝔹)))
      fromRecDef (f ↦ σ) fπs@(NonEmptyList ((f' × (πs × e)) :| fπs')) =
         map ((×) f) <$> desugarBwd σ (snd <$> fπs)

instance desugarBwdExpr :: DesugarBwd (E.Expr Boolean) (Expr Boolean) where
   desugarBwd (E.Var x)             (Var x')          = pure $ Var (x ≜ x')
   desugarBwd (E.Op op)             (Op op')          = pure $ Op (op ≜ op')
   desugarBwd (E.Int α n)           (Int _ n')        = pure $ Int α (n ≜ n')
   desugarBwd (E.Float α n)         (Float _ n')      = pure $ Float α (n ≜ n')
   desugarBwd (E.Str α s)           (Str _ s')        = pure $ Str α (s ≜ s')
   desugarBwd (E.Constr α c es)     (Constr _ c' es') =
      Constr α (c ≜ c') <$> traverse (uncurry desugarBwd) (zip es es')
   desugarBwd (E.Matrix α e (x × y) e') (Matrix _ s (x' × y') s') =
      Matrix α <$> desugarBwd e s <@> (x ≜ x') × (y ≜ y') <*> desugarBwd e' s'
   desugarBwd (E.Lambda σ)          (Lambda bs)       = Lambda <$> desugarBwd σ bs
   desugarBwd (E.App e1 e2)         (App s1 s2)       = App <$> desugarBwd e1 s1 <*> desugarBwd e2 s2
   desugarBwd (E.App (E.Lambda σ) e) (MatchAs s bs)   = MatchAs <$> desugarBwd e s <*> desugarBwd σ bs
   desugarBwd (E.App (E.Lambda (ElimConstr m)) e1) (IfElse s1 s2 s3) = do
      e2 <- liftM1 asExpr $ lookupE cTrue m
      e3 <- liftM1 asExpr $ lookupE cFalse m
      IfElse <$> desugarBwd e1 s1 <*> desugarBwd e2 s2 <*> desugarBwd e3 s3
   desugarBwd (E.BinaryApp e1 x e2) (BinaryApp s1 x' s2) =
      BinaryApp <$> desugarBwd e1 s1 <@> x ≜ x' <*> desugarBwd e2 s2
   desugarBwd (E.Constr α c Nil)    (ListEmpty _) | c == cNil =
      pure $ ListEmpty α
   desugarBwd (E.Constr α c (e : e' : Nil)) (ListNonEmpty _ s l) | c == cCons =
      ListNonEmpty α <$> desugarBwd e s <*> desugarBwd e' l
   -- | List-enum
   desugarBwd (E.App (E.App (E.Var "enumFromTo") e1) e2) (ListEnum s1 s2) =
      ListEnum <$> desugarBwd e1 s1 <*> desugarBwd e2 s2
   -- | List-comp-done
   desugarBwd (E.Constr α2 c (e : (E.Constr α1 c' Nil) : Nil))
              (ListComp _ s_body (NonEmptyList (Guard _ (Constr _ c'' Nil) :| Nil)))
      | c == cCons , c' == cNil, c'' == cTrue =
      ListComp (α1 ∧ α2) <$> desugarBwd e s_body
                         <*> pure (NonEmptyList (Guard (α1 ∧ α2) (Constr (α1 ∧ α2) cTrue Nil) :| Nil))
   -- | List-comp-qual
   desugarBwd e (ListComp α s_body (NonEmptyList (q :| Nil))) = do
      sListComp <- desugarBwd e (ListComp α s_body (NonEmptyList (q :| qualTrue true : Nil)))
      case sListComp of
         ListComp α2 s_body' (NonEmptyList (q' :| (Guard α1 (Constr _ c Nil)) : Nil))
         | c == cTrue
            -> pure $ ListComp (α1 ∧ α2) s_body' (NonEmptyList (q' :| Nil))
         sListComp'
            -> error $ "desugarBwd for List-comp-qual failed: \n" <>
                       render (pretty sListComp')
   -- | List-comp-guard
   desugarBwd (E.App (E.Lambda (ElimConstr m)) e1)
              (ListComp α s1 (NonEmptyList ((Guard _ s2) :| q : qs))) = do
      e2          <- liftM1 asExpr $ lookupE cTrue  m
      e3          <- liftM1 asExpr $ lookupE cFalse m
      s2'         <- desugarBwd e1 s2
      sListComp   <- desugarBwd e2 (ListComp α s1 (NonEmptyList (q :| qs)))
      sNil        <- desugarBwd e3 (snil true)
      case sListComp, sNil of
         ListComp α3 s1' (NonEmptyList (q' :| qs')), Constr α4 c Nil | c == cNil ->
            pure $ ListComp (α3 ∧ α4) s1' (NonEmptyList (Guard (α3 ∧ α4) s2' :| q' : qs'))
         _, _ -> error absurd
   -- | List-comp-decl
   desugarBwd (E.App (E.Lambda σ) e)
              (ListComp α s2 (NonEmptyList ((Declaration _ (VarDef π s1)) :| q : qs))) = do
      (_ × sListComp)  <- desugarBwd σ (NonEmptyList (π :| Nil) × (ListComp α s2 (NonEmptyList (q :| qs))))
      s1'  <- desugarBwd e s1
      case sListComp of
         ListComp α3 s2' (NonEmptyList (q' :| qs')) ->
            pure $ ListComp α3 s2' (NonEmptyList ((Declaration α3 (VarDef π s1')) :| q' : qs'))
         _ -> error absurd
   -- | List-comp-gen
   desugarBwd (E.App (E.App (E.Var "concatMap") (E.Lambda σ)) e1)
              (ListComp α s2 (NonEmptyList ((Generator _ p s1) :| q : qs))) = do
      s1'        <- desugarBwd e1 s1
      σ'         <- pure $ asElim $ untotalise (Arg σ) (Pattern p : Nil)
      e2         <- liftM1 asExpr (desugarPatternBwd σ' p)
      sListComp  <- desugarBwd e2 (ListComp α s2 (NonEmptyList (q :| qs)))
      case sListComp of
         ListComp α4 s2' (NonEmptyList (q' :| qs')) ->
            pure $ ListComp α4 s2' (NonEmptyList ((Generator α4 p s1) :| q' : qs'))
         _ -> error absurd
   -- | Let
   desugarBwd (E.Let d e) (Let ds s) = do
      ds' × s' <- desugarBwd (E.Let d e) (ds × s)
      pure $ Let ds' s'
   -- | LetRec (recursive function)
   desugarBwd (E.LetRec fπs e) (LetRec fπs' s) = LetRec <$> desugarBwd fπs fπs' <*> desugarBwd e s
   desugarBwd (E.Hole) s = error "todo"

   desugarBwd e s = error $ "desugarBwd match not found: " <> render (pretty e) <> "\n" <> render (pretty s)

asElim :: Cont 𝔹 -> Elim 𝔹
asElim (Arg σ) =  σ
asElim _ = error "Eliminator expected"

asExpr :: Cont 𝔹 -> E.Expr 𝔹
asExpr (Body e) =  e
asExpr _ = error "Expression expected"

{- e, l ↘ l -}
instance desugarBwdListRest :: DesugarBwd (E.Expr Boolean) (ListRest Boolean) where
   desugarBwd (E.Constr α c Nil) (End _) | c == cNil =
      pure $ End α
   desugarBwd (E.Constr α c (e : e' : Nil)) (Next _ s l) | c == cCons =
      Next α <$> desugarBwd e s <*> desugarBwd e' l
   desugarBwd (E.Hole) s = error "todo"
   desugarBwd e l = error $ "desugarBwdListRest (e, l) match not found: \n" <>
                            render (pretty e) <> "\n" <>
                            render (pretty l)

class DesugarPatternBwd a where
   desugarPatternBwd :: Elim Boolean -> a -> MayFail (Cont Boolean)

{-    →     -}
{- σ, p ↘ κ -}
instance desugarPatternBwdPatterns :: DesugarPatternBwd (NonEmptyList Pattern) where
   desugarPatternBwd σ (NonEmptyList (π :| Nil)) = desugarPatternBwd σ π
   desugarPatternBwd σ (NonEmptyList (π :| π' : πs)) = do
      test <- desugarPatternBwd σ π
      σ' <- liftM1 asElim $ desugarPatternBwd σ π
      desugarPatternBwd σ' (NonEmptyList (π' :| πs))

{- σ, p ↘ κ -}
instance desugarPatternBwdPattern :: DesugarPatternBwd Pattern where
   desugarPatternBwd (ElimVar x κ)  (PVar x') = (x ≞ x') *> pure κ
   desugarPatternBwd (ElimConstr m) (PConstr c Nil) | c == cTrue = lookupE cTrue m
   desugarPatternBwd (ElimConstr m) (PConstr c Nil) | c == cFalse = lookupE cFalse m
   desugarPatternBwd (ElimConstr m) (PConstr c Nil) | c == cNil = lookupE cNil m
   desugarPatternBwd (ElimConstr m) (PConstr ctr (π:π':_))
      | ctr == cCons || ctr == cPair = do
          σ  <- liftM1 asElim $ lookupE ctr m
          σ' <- liftM1 asElim $ desugarPatternBwd σ π
          desugarPatternBwd σ' π'
   desugarPatternBwd (ElimConstr m) (PListEmpty) = lookupE cNil m
   desugarPatternBwd σ (PListNonEmpty π o)  = do
      σ' <- liftM1 asElim $ desugarPatternBwd σ π
      desugarPatternBwd σ' o
   desugarPatternBwd σ π = error absurd

{- σ, o ↘ κ -}
instance desugarPatternBwdListPatternRest :: DesugarPatternBwd ListPatternRest where
   desugarPatternBwd (ElimConstr m) PEnd        = lookupE cCons m
   desugarPatternBwd (ElimConstr m) (PNext π o) = do
      σ  <- liftM1 asElim $ lookupE cCons m
      σ' <- liftM1 asElim $ desugarPatternBwd σ π
      desugarPatternBwd σ' o
   desugarPatternBwd σ l = error $ "desugarPatternBwdListPatternRest (σ, l) match not found: \n" <>
                                   render (pretty σ) <> "\n" <>
                                   render (pretty l)
{- σ, c ↘ c -}
instance desugarBwdBranch :: DesugarBwd (Elim Boolean) (NonEmptyList Pattern × Expr Boolean) where
   desugarBwd σ (πs × s) = do
      e  <- liftM1 asExpr $ desugarPatternBwd σ πs
      s' <- desugarBwd e s
      pure $ πs × s'

instance desugarBwdBranchUncurried :: DesugarBwd (Elim Boolean) (Pattern × Expr Boolean) where
   desugarBwd σ (πs × s) = do
      e  <- liftM1 asExpr $ desugarPatternBwd σ πs
      s' <- desugarBwd e s
      pure $ πs × s'

{-    →   → -}
{- σ, c ↘ c -}
instance desugarBwdBranches :: DesugarBwd (Elim Boolean) (NonEmptyList (NonEmptyList Pattern × Expr Boolean)) where
   desugarBwd σ (NonEmptyList (b1 :| b2 : bs)) = do
      b'  <- desugarBwd σ b1
      bs' <- desugarBwd σ (NonEmptyList (b2 :| bs))
      pure $ NonEmptyList (b' :| (toList bs'))
   desugarBwd σ (NonEmptyList (b :| Nil)) = do
      b' <- desugarBwd σ b
      pure $ NonEmptyList (b' :| Nil)

instance desugarBwdBranchesUncurried :: DesugarBwd (Elim Boolean) (NonEmptyList (Pattern × Expr Boolean)) where
   desugarBwd σ (NonEmptyList (b1 :| b2 : bs)) = do
      b'  <- desugarBwd σ b1
      bs' <- desugarBwd σ (NonEmptyList (b2 :| bs))
      pure $ NonEmptyList (b' :| (toList bs'))
   desugarBwd σ (NonEmptyList (b :| Nil)) = do
      b' <- desugarBwd σ b
      pure $ NonEmptyList (b' :| Nil)

{-              →      -}
{- untotalise κ π ↗ κ' -}
untotalise :: Cont 𝔹 -> List Patt -> Cont 𝔹
untotalise κ Nil = κ
untotalise (Arg σ) (p : ps) =
   case σ, p of
      ElimVar x κ, Pattern (PVar x') ->
         if x == x' then Arg (ElimVar x (untotalise κ ps))
         else error $ "untotalise: patterns don't match " <> render (pretty x) <> " & " <> render (pretty x')
      ElimConstr m, Pattern (PConstr ctr arg_patts) ->
         let κ  = mustLookup ctr m
             κ' = untotalise κ (map Pattern arg_patts <> ps)
         in Arg $ ElimConstr (fromFoldable [ctr × κ'])
      ElimConstr m, Pattern (PListEmpty) ->
         let κ  = mustLookup cNil m
             κ' = untotalise κ ps
         in  Arg $ ElimConstr (fromFoldable [cNil × κ'])
      ElimConstr m, Pattern (PListNonEmpty p' o) ->
         let κ  = mustLookup cCons m
             κ' = untotalise κ (Pattern p' : ListPatternRest o : ps)
         in  Arg $ ElimConstr (fromFoldable [cCons × κ'])
      ElimConstr m, ListPatternRest (PEnd) ->
         let κ  = mustLookup cNil m
             κ' = untotalise κ ps
         in  Arg $ ElimConstr (fromFoldable [cNil × κ'])
      ElimConstr m, ListPatternRest (PNext p' o) ->
         let κ  = mustLookup cCons m
             κ' = untotalise κ (Pattern p' : ListPatternRest o : ps)
         in  Arg $ ElimConstr (fromFoldable [cCons × κ'])
      σ', p' -> error absurd
untotalise κ π = error absurd
