module App.View.ScatterPlot where

import Prelude

import App.Util (class Reflect, Handler, Renderer, Sel, from, get_intOrNumber, record)
import App.Util.Selector (constrArg, field, listElement)
import Data.Maybe (Maybe)
import DataType (cScatterPlot, f_caption, f_colour, f_data, f_x, f_xlabel, f_y, f_ylabel)
import Dict (Dict, get)
import Lattice (neg)
import Primitive (string, unpack)
import Test.Util (Selector)
import Unsafe.Coerce (unsafeCoerce)
import Util (type (×), definitely', (!))
import Val (Val)
import Web.Event.Event (target)
import Web.Event.Internal.Types (EventTarget)

newtype ScatterPlot = ScatterPlot
   { caption :: String × Sel
   , data :: Array ScatterRecord
   , xlabel :: String × Sel
   , ylabel :: String × Sel
   }

newtype ScatterRecord = ScatterRecord
   { x :: Number × Sel
   , y :: Number × Sel
   , c :: String × Sel
   }

foreign import drawScatterPlot :: Renderer ScatterPlot

instance Reflect (Dict (Val Sel)) ScatterRecord where
   from r = ScatterRecord
      { x: get_intOrNumber f_x r
      , y: get_intOrNumber f_y r
      , c: unpack string $ get f_colour r
      }

instance Reflect (Dict (Val Sel)) ScatterPlot where
   from r = ScatterPlot
      { caption: unpack string (get f_caption r)
      , data: record from <$> from (get f_data r)
      , xlabel: unpack string (get f_xlabel r)
      , ylabel: unpack string (get f_ylabel r)
      }

scatterPlotHandler :: Handler
scatterPlotHandler ev = toggleDot $ unsafeDotIndex $ target ev
   where
   toggleDot :: Int -> Selector Val
   toggleDot i =
      constrArg cScatterPlot 0
         $ field f_data
         $ listElement i
         $ neg

   unsafeDotIndex :: Maybe EventTarget -> Int
   unsafeDotIndex tgt_opt = (unsafeCoerce (definitely' tgt_opt)).__data__ ! 0
