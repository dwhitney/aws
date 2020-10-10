module AWS.DynamoDB.Function where

import Prelude

import AWS (AWS, Action(..), Region(..), Service(..), Version(..))
import AWS as AWS
import AWS.DynamoDB.Types (AttributeValue, BatchGetItem, BatchGetItemOutput, BatchWriteItem, BatchWriteItemOutput, GetItemInput, GetItemOutput, PutItemInput, PutItemOutput, QueryInput, QueryOutput, TableName(..), TransactItem, TransactWriteItemsInput, UpdateItemInput, UpdateItemOutput, WriteItemRequest, TransactWriteItemsOutput)
import Data.Array as Array
import Data.Array.NonEmpty (toArray)
import Data.Array.NonEmpty as NEA
import Data.Lens (_1, over, traversed)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..), snd)
import Foreign.Object (Object)
import Foreign.Object as O
import Foreign.Object as Object
import Run.Streaming.Prelude as S
import Simple.JSON (class ReadForeign, class WriteForeign, writeImpl)

version :: Version
version = Version "2012-08-10"

service :: Service
service = Service "dynamodb"

request :: ∀ r i o 
  .  WriteForeign i
  => ReadForeign o
  => Action
  -> i 
  -> AWS r o
request action input = AWS.request (Region "us-east-1") service version action input

putItemInput :: TableName -> Object AttributeValue -> PutItemInput
putItemInput tableName item = 
  { "TableName"                   : tableName
  , "Item"                        : item
  , "ReturnValues"                : Nothing
  , "ConditionExpression"         : Nothing
  , "ExpressionAttributeNames"    : Nothing
  , "ExpressionAttributeValues"   : Nothing
  , "ReturnConsumedCapacity"      : Nothing
  , "ReturnItemCollectionMetrics" : Nothing
  }

putItem :: ∀ r . PutItemInput -> AWS r PutItemOutput
putItem = request (Action "DynamoDB_20120810.PutItem")

getItemInput :: TableName -> Object AttributeValue -> GetItemInput
getItemInput tableName key =
  { "TableName"                   : tableName
  , "Key"                         : key
  , "ConsistentRead"              : Nothing
  , "ProjectionExpression"        : Nothing
  , "ExpressionAttributeNames"    : Nothing
  , "ReturnConsumedCapacity"      : Nothing
  }

getItem :: ∀ r . GetItemInput -> AWS r GetItemOutput
getItem = request (Action "DynamoDB_20120810.GetItem")

batchGetItemInput :: Array (Tuple TableName (Object AttributeValue)) -> BatchGetItem
batchGetItemInput batch = do 
  let groups = (Array.groupBy (\(Tuple t1 _) (Tuple t2 _) -> t1 == t2) batch) 
      requestItems = O.fromFoldable $ groups <#> (\g -> do
        let (Tuple (TableName tableName) _) = NEA.head g
        let ks = toArray $ map snd g
            items =  { "ConsistentRead" : Nothing, "Keys" : ks, "ProjectionExpression" : Nothing, "ExpressionAttributeNames" : Nothing }
        Tuple tableName items
  )
  { "RequestItems" : requestItems, "ReturnConsumedCapacity" : Nothing }


batchGetItem :: ∀ r . BatchGetItem -> AWS r BatchGetItemOutput
batchGetItem = request (Action "DynamoDB_20120810.BatchGetItem")


getItemStream :: ∀ r. Array (Tuple TableName (Object AttributeValue)) -> AWS.Stream r (Tuple TableName (Object AttributeValue))
getItemStream tuples = do
  let batches = map batchGetItemInput $ chunks 25 tuples
  go batches
  where
    go batches = fromMaybe (pure unit) $ (Array.head batches) <#> \batch -> do
      results <- batchGetItem batch
      let withTableNames = over (traversed <<< _1) TableName $ Object.toUnfoldable results."Responses"
          tupled = do 
            Tuple t objs  <- withTableNames
            objs <#> (Tuple t)
      (S.each tuples) >>= (const $ go $ Array.fold $ Array.tail batches)


queryStream :: ∀ r . QueryInput -> AWS.Stream r (Object AttributeValue)
queryStream input = do
  results <- query input
  S.each results."Items" >>= (const $ next results."LastEvaluatedKey")
  where
    next Nothing = pure unit
    next (Just key) = queryStream (input { "ExclusiveStartKey" = Just key })

writeItemStream :: ∀ r .  Array (Tuple TableName WriteItemRequest) -> AWS.Stream r BatchWriteItemOutput
writeItemStream items = S.each =<< (traverse batchWriteItem $ batchWriteItemInput items)

chunks :: ∀ a. Int -> Array a -> Array (Array a)
chunks _ [] = []
chunks n xs = pure (Array.take n xs) <> (chunks n $ Array.drop n xs) 

batchWriteItemInput :: Array (Tuple TableName WriteItemRequest) -> Array BatchWriteItem
batchWriteItemInput tuples = chunks 25 tuples <#> \chunk -> do
  let groups = Array.groupBy (\(Tuple t1 _) (Tuple t2 _) -> t1 == t2) chunk
      requestItems = O.fromFoldable $ groups <#> \g -> do
                      let (Tuple (TableName tableName) _) = NEA.head g
                      Tuple tableName $ toArray $ map snd g
  { "RequestItems" : requestItems, "ReturnConsumedCapacity" : Nothing }


batchWriteItem :: ∀ r . BatchWriteItem -> AWS r BatchWriteItemOutput
batchWriteItem = request (Action "DynamoDB_20120810.BatchWriteItem")

updateItemInput :: TableName -> Object AttributeValue -> UpdateItemInput
updateItemInput tableName key =
  { "TableName"                   : tableName
  , "Key"                         : key
  , "UpdateExpression"            : Nothing
  , "ConditionExpression"         : Nothing
  , "ReturnValues"                : Nothing
  , "ExpressionAttributeNames"    : Nothing
  , "ExpressionAttributeValues"   : Nothing
  , "ReturnConsumedCapacity"      : Nothing
  , "ReturnItemCollectionMetrics" : Nothing
  }

updateItem :: ∀ r . BatchWriteItem -> AWS r UpdateItemOutput
updateItem = request (Action "DynamoDB_20120810.UpdateItem")

queryInput :: TableName -> QueryInput
queryInput tableName =
  { "TableName"                 : tableName
  , "ConsistentRead"            : Nothing
  , "ExclusiveStartKey"         : Nothing
  , "ExpressionAttributeNames"  : Nothing
  , "ExpressionAttributeValues" : Nothing
  , "FilterExpression"          : Nothing
  , "IndexName"                 : Nothing
  , "KeyConditionExpression"    : Nothing
  , "Limit"                     : Nothing
  , "ProjectionExpression"      : Nothing
  , "ReturnConsumedCapacity"    : Nothing
  , "ScanIndexForward"          : Nothing
  , "Select"                    : Nothing
  }

query :: ∀ r . QueryInput -> AWS r QueryOutput
query = request (Action "DynamoDB_20120810.Query")

transactWriteItemsInput :: Array TransactItem -> TransactWriteItemsInput
transactWriteItemsInput items =
  { "ClientRequestToken" : Nothing
  , "ReturnConsumedCapacity" : Nothing
  , "ReturnItemCollectionMetrics" : Nothing
  , "TransactItems" : map writeImpl items
  }

transactWriteItems :: ∀ r . TransactWriteItemsInput -> AWS r TransactWriteItemsOutput
transactWriteItems = request (Action "DynamoDB_20120810.TransactWriteItems")
