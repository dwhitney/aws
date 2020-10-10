module AWS.DynamoDB.Types.ReturnValues where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Simple.JSON (class WriteForeign, writeImpl)

data ReturnValues = NONE | ALL_OLD 

derive instance eqRCC :: Eq ReturnValues
derive instance ordRCC :: Ord ReturnValues 
derive instance genRCC :: Generic ReturnValues _

instance showReturnedConsumedCapacity :: Show ReturnValues where
  show = genericShow

instance writeForeignReturnValues :: WriteForeign ReturnValues where
  writeImpl = writeImpl <<< show