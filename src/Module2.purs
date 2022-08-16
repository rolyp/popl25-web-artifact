module Module2 where

import Prelude
import Affjax.Web (defaultRequest, printError, request)
import Affjax.ResponseFormat (string)
import Data.Bifunctor (bimap)
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Data.Map (singleton)
import Effect.Aff (Aff)
import Parsing (runParser)
import Bindings2 (Var)
import DesugarFwd2 (desugarFwd, desugarModuleFwd)
import Eval2 (eval, eval_module)
import Lattice2 (𝔹)
import Parse2 (module_, program)
import Primitive.Defs2 (primitives)
import SExpr2 (Expr) as S
import Util2 (MayFail, type (×), (×), error, successful)
import Util.Parse2 (SParser)
import Val2 (Env2, SingletonEnv)

-- Mainly serve as documentation
newtype File = File String
newtype Folder = Folder String

derive newtype instance Show File
derive newtype instance Semigroup File
derive newtype instance Monoid File

-- For Wrattler integration. Should not end in "/".
resourceServerUrl :: String
resourceServerUrl = "."

loadFile :: Folder -> File -> Aff String
loadFile (Folder folder) (File file) = do
   let url = resourceServerUrl <> "/" <> folder <> "/" <> file <> ".fld"
   result <- request (defaultRequest { url = url, method = Left GET, responseFormat = string })
   case result of
      Left err -> error (printError err)
      Right response -> pure response.body

parse :: forall t . String -> SParser t -> MayFail t
parse src = runParser src >>> show `bimap` identity

loadModule :: File -> Env2 𝔹 -> Aff (Env2 𝔹)
loadModule file γ = do
   src <- loadFile (Folder "fluid/lib") file
   pure (successful (parse src module_ >>= desugarModuleFwd >>= eval_module γ))

parseProgram :: Folder -> File -> Aff (S.Expr 𝔹)
parseProgram folder file = loadFile folder file <#> (successful <<< flip parse program)

open :: File -> Aff (S.Expr 𝔹)
open = parseProgram (Folder "fluid/example")

defaultImports :: Aff (Env2 𝔹)
defaultImports =
   loadModule (File "prelude") primitives >>= loadModule (File "graphics") >>= loadModule (File "convolution")

openWithDefaultImports :: File -> Aff (Env2 𝔹 × S.Expr 𝔹)
openWithDefaultImports file = do
   γ <- defaultImports
   open file <#> (γ × _)

-- Return ambient environment used to load dataset along with new binding.
openDatasetAs :: File -> Var -> Aff (Env2 𝔹 × SingletonEnv 𝔹)
openDatasetAs file x = do
   s <- parseProgram (Folder "fluid") file
   γ <- defaultImports
   let _ × v = successful (desugarFwd s >>= eval γ)
   pure (γ × singleton x v)
