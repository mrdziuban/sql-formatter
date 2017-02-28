module Test.Main where

import Prelude (Unit)
import Control.Monad.Aff.AVar (AVAR)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Test.Unit.Console (TESTOUTPUT)
import Test.Unit.Main (runTest)

import Test.SQLFormatter as SQLFormatter

main :: forall a. Eff (console :: CONSOLE, testOutput :: TESTOUTPUT, avar :: AVAR | a) Unit
main = runTest SQLFormatter.main
