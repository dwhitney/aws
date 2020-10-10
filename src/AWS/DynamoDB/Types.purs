module AWS.DynamoDB.Types where

import Prelude

import AWS.DynamoDB.Types.ReturnConsumedCapacity (ReturnConsumedCapacity)
import AWS.DynamoDB.Types.ReturnItemCollectionMetrics (ReturnItemCollectionMetrics)
import AWS.DynamoDB.Types.ReturnValues (ReturnValues)
import AWS.DynamoDB.Types.UpdateItemReturnValues (UpdateItemReturnValues)
import Control.Alt ((<|>))
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Foreign (Foreign, ForeignError(..), fail)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Foreign.Object (Object)
import Simple.JSON (class ReadForeign, class WriteForeign, read', writeImpl)

newtype TableName = TableName String

type StreamRecords = { "Records" :: Array StreamEvent }

type StreamEventRecord r = 
  { eventID :: String
  , eventVersion :: String
  , eventSource :: String
  , awsRegion :: String
  , dynamodb :: DynamoDBItem r
  , eventSourceARN :: String
  }

type DynamoDBItem r =
  { "ApproximateCreationDateTime" :: Number
  , "SequenceNumber" :: String
  , "SizeBytes" :: Number
  , "StreamViewType" :: String
  , "Keys" :: Object AttributeValue
  | r
  }

type InsertItem = StreamEventRecord ("NewImage" :: Object AttributeValue)
type ModifyItem = StreamEventRecord ("NewImage" :: Object AttributeValue, "OldImage" :: Object AttributeValue)
type RemoveItem = StreamEventRecord ("OldImage" :: Object AttributeValue)

data StreamEvent
  = Insert InsertItem
  | Modify ModifyItem
  | Remove RemoveItem

data TransactItem
  = Put PutItemInput
  | Update UpdateItemInput

data WriteItemRequest
  = DeleteRequest (Object AttributeValue)
  | PutRequest (Object AttributeValue)

derive instance genWriteItemRequest :: Generic WriteItemRequest _
derive instance eqWriteItemRequest :: Eq WriteItemRequest
instance showWriteItemRequest :: Show WriteItemRequest where show = genericShow
instance writeForeignWriteItemRequest :: WriteForeign WriteItemRequest
  where 
    writeImpl (PutRequest item) = writeImpl { "PutRequest" : { "Item" : item } }
    writeImpl (DeleteRequest key) = writeImpl { "DeleteRequest" : { "Key" : key } }

data AttributeValue
  = B String 
  | BS (Array String)
  | BOOL Boolean
  | L (Array AttributeValue)
  | M (Object AttributeValue)
  | N String
  | NS (Array String)
  | NULL 
  | S String
  | SS (Array String)

data Select = ALL_ATTRIBUTES | ALL_PROJECTED_ATTRIBUTES | SPECIFIC_ATTRIBUTES | COUNT

type CapacityUnits = { "CapacityUnits" :: Number }

type ConsumedCapacity = 
  { "CapacityUnits" :: Number
  , "GlobalSecondaryIndexes" :: Object CapacityUnits
  , "LocalSecondaryIndexes" :: Object CapacityUnits
  , "Table" :: CapacityUnits
  , "TableName" :: String
  }

type ItemCollectionMetrics = 
  { "ItemCollectionKey" :: Maybe (Object AttributeValue)
  , "SizeEstimateRangeGB" :: Maybe (Array Number) 
  }

type BatchWriteItem =
  { "RequestItems"                :: Object (Array WriteItemRequest)
  , "ReturnConsumedCapacity"      :: Maybe ReturnConsumedCapacity 
  }

type BatchWriteItemOutput =
  { "ConsumedCapacity"            :: Maybe ConsumedCapacity
  , "UnprocessedKeys"             :: Maybe (Object (Array (Object (Object (AttributeValue)))))
  }

type PutItemInput =  
  { "TableName"                   :: TableName
  , "Item"                        :: Object AttributeValue
  , "ReturnValues"                :: Maybe ReturnValues
  , "ConditionExpression"         :: Maybe String
  , "ExpressionAttributeNames"    :: Maybe (Object String)
  , "ExpressionAttributeValues"   :: Maybe (Object AttributeValue)
  , "ReturnConsumedCapacity"      :: Maybe ReturnConsumedCapacity
  , "ReturnItemCollectionMetrics" :: Maybe ReturnItemCollectionMetrics
  }

type GetItemInput = 
  { "TableName"                   :: TableName
  , "Key"                         :: Object AttributeValue
  , "ConsistentRead"              :: Maybe Boolean
  , "ProjectionExpression"        :: Maybe String
  , "ExpressionAttributeNames"    :: Maybe (Object String)
  , "ReturnConsumedCapacity"      :: Maybe ReturnConsumedCapacity 
  }

type RequestItems =
  { "ConsistentRead"              :: Maybe Boolean
  , "Keys"                        :: Array (Object AttributeValue)
  , "ProjectionExpression"        :: Maybe String
  , "ExpressionAttributeNames"    :: Maybe (Object String)
  }

type BatchGetItem =
  { "RequestItems"                :: Object RequestItems
  , "ReturnConsumedCapacity"      :: Maybe ReturnConsumedCapacity 
  }

type BatchGetItemOutput =
  { "ConsumedCapacity"  :: Maybe ConsumedCapacity
  , "Responses"         :: Object (Array (Object AttributeValue))
  , "UnprocessedKeys"   :: Object RequestItems
  }

type GetItemOutput = 
  { "Item"             :: Maybe (Object AttributeValue)
  , "ConsumedCapacity" :: Maybe ConsumedCapacity
  }

type UpdateItemInput = 
  { "TableName"                   :: TableName
  , "Key"                         :: Object AttributeValue
  , "UpdateExpression"            :: Maybe String
  , "ConditionExpression"         :: Maybe String
  , "ReturnValues"                :: Maybe UpdateItemReturnValues
  , "ExpressionAttributeNames"    :: Maybe (Object String)
  , "ExpressionAttributeValues"   :: Maybe (Object AttributeValue)
  , "ReturnConsumedCapacity"      :: Maybe ReturnConsumedCapacity 
  , "ReturnItemCollectionMetrics" :: Maybe ReturnItemCollectionMetrics
  }

type UpdateItemOutput = 
  { "Attributes"            :: Maybe (Object AttributeValue) 
  , "ConsumedCapacity"      :: Maybe ConsumedCapacity
  , "ItemCollectionMetrics" :: Maybe ItemCollectionMetrics
  }

type QueryInput = 
  { "TableName"                 :: TableName
  , "ConsistentRead"            :: Maybe Boolean
  , "ExclusiveStartKey"         :: Maybe (Object AttributeValue)
  , "ExpressionAttributeNames"  :: Maybe (Object String)
  , "ExpressionAttributeValues" :: Maybe (Object AttributeValue)
  , "FilterExpression"          :: Maybe String
  , "IndexName"                 :: Maybe String
  , "KeyConditionExpression"    :: Maybe String
  , "Limit"                     :: Maybe Int
  , "ProjectionExpression"      :: Maybe String
  , "ReturnConsumedCapacity"    :: Maybe ReturnConsumedCapacity 
  , "ScanIndexForward"          :: Maybe Boolean
  , "Select"                    :: Maybe Select
  }

type QueryOutput = 
  { "ConsumedCapacity" :: Maybe ConsumedCapacity
  , "Count" :: Int
  , "Items" :: Array (Object AttributeValue)
  , "LastEvaluatedKey" :: Maybe (Object AttributeValue)
  , "ScannedCount" :: Int 
  }

type PutItemOutput = 
  { "Attributes"            :: Maybe (Object AttributeValue) 
  , "ConsumedCapacity"      :: Maybe ConsumedCapacity
  , "ItemCollectionMetrics" :: Maybe ItemCollectionMetrics
  }

type TransactWriteItemsInput =
  { "ClientRequestToken" :: Maybe String
  , "ReturnConsumedCapacity"    :: Maybe ReturnConsumedCapacity 
  , "ReturnItemCollectionMetrics" :: Maybe ReturnItemCollectionMetrics
  , "TransactItems" :: Array Foreign
  }

type TransactWriteItemsOutput =
  { "ConsumedCapacity"      :: Maybe ConsumedCapacity
  , "ItemCollectionMetrics" :: Maybe ItemCollectionMetrics
  }

instance showTableName :: Show TableName where
  show (TableName name) = name

instance showAttributeValue :: Show AttributeValue where
  show (B str) = str
  show (BS array) = show array
  show (BOOL b) = show b
  show (L array) = show array
  show (M obj) = show obj
  show (N str) = str 
  show (NS array) = show array
  show NULL  = "null" 
  show (S str) = str
  show (SS array) = show array

instance attributeValueWriteForeign :: WriteForeign AttributeValue where
  writeImpl (B blob)    = writeImpl { "B" : writeImpl blob  }
  writeImpl (BS blobs)  = writeImpl { "BS" : writeImpl blobs  }
  writeImpl (BOOL bool) = writeImpl { "BOOL" : bool }
  writeImpl (L array)   = writeImpl { "L" : writeImpl array }
  writeImpl (M obj)     = writeImpl { "M" : writeImpl obj } 
  writeImpl (N num)     = writeImpl { "N" : num }
  writeImpl (NS nums)   = writeImpl { "NS" : writeImpl nums }
  writeImpl (NULL)      = writeImpl { "NULL" : true } 
  writeImpl (S str)     = writeImpl { "S" : str }
  writeImpl (SS strs)   = writeImpl { "SS" : writeImpl strs }

instance attributeValueRightForeign :: ReadForeign AttributeValue where
  readImpl value = 
    ((read' value) <#> \(rec :: { "B" :: String }) -> B rec."B") <|>
    ((read' value) <#> \(rec :: { "BS" :: Array String }) -> BS rec."BS") <|>
    ((read' value) <#> \(rec :: { "BOOL" :: Boolean }) -> BOOL rec."BOOL") <|>
    ((read' value) <#> \(rec :: { "L" :: (Array AttributeValue)}) -> L rec."L") <|>
    ((read' value) <#> \(rec :: { "M" :: (Object AttributeValue) }) -> M rec."M") <|>
    ((read' value) <#> \(rec :: { "N" :: String }) -> N rec."N") <|>
    ((read' value) <#> \(rec :: { "NS" :: (Array String) }) -> NS rec."NS") <|>
    ((read' value) <#> \(rec :: { "NULL" :: Boolean }) -> NULL) <|>
    ((read' value) <#> \(rec :: { "S" :: String }) -> S rec."S") <|>
    ((read' value) <#> \(rec :: { "SS" :: (Array String) }) -> SS rec."SS") <|>
    (fail $ ForeignError "Couldn't read the attribute value")

derive instance tableNameNT :: Newtype TableName _
derive instance genTableName :: Generic TableName _
derive instance eqTableName :: Eq TableName
derive instance ordTableName :: Ord TableName
instance genTNDecode :: ReadForeign TableName where readImpl = genericDecode (defaultOptions { unwrapSingleConstructors = true })
instance genTNEncode :: WriteForeign TableName where writeImpl = genericEncode (defaultOptions { unwrapSingleConstructors = true }) 

derive instance genTransactItem :: Generic TransactItem _
instance showTransactItem :: Show TransactItem where show = genericShow
instance genTransactItemEncode :: WriteForeign TransactItem 
  where 
    writeImpl (Put item) = writeImpl { "Put" : item }
    writeImpl (Update item) = writeImpl { "Update" : item }

derive instance eqAttributeValue :: Eq AttributeValue

derive instance genSelect :: Generic Select _
derive instance eqSelect :: Eq Select
derive instance ordSelect :: Ord Select
instance showSelect :: Show Select where show = genericShow
instance genSelEncode :: WriteForeign Select where writeImpl = writeImpl <<< show

instance streamEventReadForeign :: ReadForeign StreamEvent where
  readImpl f =  ((read' f) <#> Modify) <|> 
                ((read' f) <#> Insert) <|>
                ((read' f) <#> Remove)
