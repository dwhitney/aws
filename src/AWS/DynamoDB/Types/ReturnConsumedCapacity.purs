module AWS.DynamoDB.Types.ReturnConsumedCapacity where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Simple.JSON (class WriteForeign, writeImpl)

data ReturnConsumedCapacity = INDEXES | TOTAL | NONE

derive instance eqRCC :: Eq ReturnConsumedCapacity
derive instance ordRCC :: Ord ReturnConsumedCapacity
derive instance genRCC :: Generic ReturnConsumedCapacity _

instance showReturnedConsumedCapacity :: Show ReturnConsumedCapacity where
  show = genericShow

instance writeForeignReturnConsumedCapacity :: WriteForeign ReturnConsumedCapacity where
  writeImpl = writeImpl <<< show
