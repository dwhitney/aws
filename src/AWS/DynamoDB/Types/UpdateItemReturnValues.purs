module AWS.DynamoDB.Types.UpdateItemReturnValues where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Simple.JSON (class WriteForeign, writeImpl)

data UpdateItemReturnValues = NONE | ALL_OLD | UPDATED_OLD | ALL_NEW | UPDATED_NEW

derive instance eqRCC :: Eq UpdateItemReturnValues
derive instance ordRCC :: Ord UpdateItemReturnValues 
derive instance genRCC :: Generic UpdateItemReturnValues _

instance showReturnedConsumedCapacity :: Show UpdateItemReturnValues where
  show = genericShow

instance writeForeignUpdateItemReturnValues :: WriteForeign UpdateItemReturnValues where
  writeImpl = writeImpl <<< show