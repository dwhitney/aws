module AWS.Cognito where

import Prelude

import AWS (AWS, _awsreader)
import Data.Either (Either(..))
import Data.UUID as UUID
import Effect.Aff (Error, error)
import Effect.Aff as Aff
import Effect.Class (liftEffect)
import Milkis as M
import Run as Run
import Run.Reader as Reader
import Simple.JSON (read, writeJSON)
import Utils (runErrorLog, runLiftEither)

cognitoUrl :: String
cognitoUrl = "https://cognito-identity.us-east-1.amazonaws.com/"

type API =
  { getId :: String
  , getOpenIdToken :: String
  }

newtype IdentityId = IdentityId String
newtype Token = Token String
type IdentityIdResponse = { "IdentityId" :: String }
type TokenResponse = { "IdentityId" :: String, "Token" :: String }

data Cognito = Unauthenticated IdentityId Token

api :: API
api = 
  { getId : "AWSCognitoIdentityService.GetId"
  , getOpenIdToken  : "AWSCognitoIdentityService.GetOpenIdToken"
  }

unauthenticated :: ∀ r. AWS r Cognito
unauthenticated = do
  id <- getId >>= runLiftEither 
  token <- (getToken id) >>= runLiftEither
  pure $ Unauthenticated id token

getId :: ∀ r. AWS r (Either Error IdentityId)
getId = do
  ctx <- Reader.askAt _awsreader
  let fetchImpl = ctx.fetchImpl
      identity_pool_id = ctx.identity_pool_id
  uuid        <- UUID.genUUID <#> UUID.toString # liftEffect # Run.liftAff
  let request = { "IdentityPoolId" : identity_pool_id }
      options = { method : M.postMethod
                , body : writeJSON request
                , headers : M.makeHeaders 
                    { "X-Amz-Target": api.getId
                    , "Content-Type": "application/x-amz-json-1.1"
                    }
                }
  either     <- Run.liftAff $ Aff.attempt $ M.fetch fetchImpl (M.URL cognitoUrl) options >>= M.json
  case either of
    Left e -> do
      runErrorLog "Error fetching IdentityId from Cognito"
      runErrorLog e
      pure $ Left $ error $ ("Error fetching IdentityId from Cognito: " <> (show e))
    Right json -> case (read json) of
        Left e -> do
          runErrorLog "Error fetching decoding IdentityId"
          runErrorLog e
          pure $ Left $ error $ ("Error decodeing IdentityId: " <> (show e))
        Right (rec :: IdentityIdResponse) -> pure $ Right $ IdentityId rec."IdentityId"


getToken :: ∀ r. IdentityId -> AWS r (Either Error Token)
getToken (IdentityId id) = do
  ctx <- Reader.askAt _awsreader
  let { fetchImpl, region, identity_pool_id } = ctx
  uuid        <- UUID.genUUID <#> UUID.toString # liftEffect # Run.liftAff
  let request = { "IdentityId" : id }
      options = { method : M.postMethod
                , body : writeJSON request
                , headers : M.makeHeaders 
                    { "X-Amz-Target": api.getOpenIdToken
                    , "Content-Type": "application/x-amz-json-1.1"
                    }
                }
  either     <- Run.liftAff $ Aff.attempt $ M.fetch fetchImpl (M.URL cognitoUrl) options >>= M.json
  case either of
    Left e -> do
      runErrorLog "Error fetching IdentityId from Cognito"
      runErrorLog e
      pure $ Left $ error $ ("Error fetching IdentityId from Cognito: " <> (show e))
    Right json -> case (read json) of
        Left e -> do
          runErrorLog "Error fetching decoding IdentityId"
          runErrorLog e
          pure $ Left $ error $ ("Error decodeing IdentityId: " <> (show e))
        Right (rec :: TokenResponse) -> pure $ Right $ Token rec."Token"
