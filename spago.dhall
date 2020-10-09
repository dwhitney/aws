{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "my-project"
, dependencies =
  [ "avar"
  , "console"
  , "crypto"
  , "effect"
  , "foreign"
  , "js-date"
  , "milkis"
  , "node-fs-aff"
  , "psci-support"
  , "run"
  , "run-streaming"
  , "simple-json"
  , "spec"
  , "tortellini"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
