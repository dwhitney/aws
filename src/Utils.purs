module Utils where

import Prelude

import Data.Array as A
import Data.Bifunctor (lmap)
import Data.DateTime.Instant (unInstant)
import Data.Either (Either(..))
import Data.Foldable (intercalate)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect.Aff (Aff, Error, error)
import Effect.Aff as Aff
import Effect.Class (liftEffect)
import Effect.Console as Console
import Effect.Now (now)
import Foreign (MultipleErrors, renderForeignError)
import Run (AFF, Run)
import Run as Run
import Run.Streaming.Prelude as S

liftMaybe :: ∀ a . String -> Maybe a -> Aff a
liftMaybe msg Nothing = Aff.throwError $ Aff.error msg
liftMaybe _ (Just a) = pure a

liftEither :: ∀ e a . Show e => Either e a -> Aff a
liftEither (Left e) = Aff.throwError $ Aff.error $ show e
liftEither (Right a) = pure a

runLiftEither :: ∀ r e a . Show e => Either e a -> Run(aff :: AFF | r) a
runLiftEither = Run.liftAff <<< liftEither

timeAff :: ∀ a. String -> Aff a -> Aff a
timeAff msg aff = do
  begin <- liftEffect $ now
  a     <- aff
  end   <- liftEffect $ now
  liftEffect $ Console.log (msg <> ": " <> (show ((toNumber end) - (toNumber begin))))
  pure a
  where
    toNumber = unInstant >>> unwrap

multipleErrorsToError :: MultipleErrors -> Error
multipleErrorsToError multiple =
  error $ intercalate "\n" (map renderForeignError multiple)

liftMultipleErrors :: ∀ a. Either MultipleErrors a -> Aff a
liftMultipleErrors multiple = liftEither $ lmap multipleErrorsToError multiple

affLog :: ∀ m . Show m => m -> Aff Unit
affLog m = liftEffect $ Console.log $ show m

affErrorLog :: ∀ m . Show m => m -> Aff Unit
affErrorLog m = liftEffect $ Console.error $ show m

runLog :: ∀ r m . Show m => m -> Run(aff :: AFF | r) Unit
runLog = Run.liftAff <<< affLog

runErrorLog :: ∀ r m . Show m => m -> Run(aff :: AFF | r) Unit
runErrorLog = Run.liftAff <<< affErrorLog

toArray ∷ ∀ r x. Run (S.Producer x r) Unit → Run r (Array x)
toArray = S.fold A.snoc [] identity

