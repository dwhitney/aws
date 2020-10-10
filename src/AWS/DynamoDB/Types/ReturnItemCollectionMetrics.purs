module AWS.DynamoDB.Types.ReturnItemCollectionMetrics where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Simple.JSON (class WriteForeign, writeImpl)

data ReturnItemCollectionMetrics = SIZE | NONE

derive instance eqRCC :: Eq ReturnItemCollectionMetrics
derive instance ordRCC :: Ord ReturnItemCollectionMetrics
derive instance genRCC :: Generic ReturnItemCollectionMetrics _

instance showReturnedConsumedCapacity :: Show ReturnItemCollectionMetrics where
  show = genericShow

instance writeForeignReturnItemCollectionMetrics :: WriteForeign ReturnItemCollectionMetrics where
  writeImpl = writeImpl <<< show