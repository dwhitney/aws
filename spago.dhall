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
  , "foreign-generic"
  , "js-date"
  , "milkis"
  , "node-fs-aff"
  , "profunctor-lenses"
  , "psci-support"
  , "run"
  , "run-streaming"
  , "simple-json"
  , "spec"
  , "tortellini"
  , "uuid"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
