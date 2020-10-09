module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.AWS.SignatureV4.FunctionsSpec as SignatureV4
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = launchAff_ do
  runSpec [ consoleReporter ] do
    SignatureV4.spec
    pure unit
