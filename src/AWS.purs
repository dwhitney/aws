module AWS where

import Prelude

import AWS.SignatureV4.Functions as SignatureV4
import AWS.SignatureV4.Types (Body(..))
import Control.Alt ((<|>))
import Data.Either (Either(..))
import Data.Foldable as A
import Data.JSDate as JSDate
import Data.Maybe (Maybe(..))
import Data.String as S
import Data.String.Regex as R
import Data.String.Regex.Flags as Flags
import Data.String.Regex.Unsafe (unsafeRegex)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.AVar (AVar)
import Effect.Aff.AVar as AVar
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect.Class (liftEffect)
import Foreign.Object (Object)
import Foreign.Object as O
import Global.Unsafe (unsafeEncodeURIComponent, unsafeStringify)
import Milkis as M
import Milkis.Impl (FetchImpl)
import Milkis.Impl.Node (nodeFetch)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Run (AFF, Run, SProxy(..))
import Run as Run
import Run.Except (EXCEPT)
import Run.Except as Except
import Run.Reader (READER)
import Run.Reader as Reader
import Run.Streaming (YIELD)
import Simple.JSON (class ReadForeign, class WriteForeign, readImpl, readJSON, writeJSON)
import Tortellini (parsellIni)
import AWS.Utils (liftEither, runLiftEither)



type Credentials =
  { accessKeyId :: String
  , secretAccessKey :: String
  , sessionToken :: Maybe String
  }

type RequestParams =
  { method :: String
  , headers :: Object String
  , hostname :: String
  , path :: String
  }

type AWSContext =
  { fetchImpl :: FetchImpl
  , credentials :: AVar Credentials
  , region :: String
  , identity_pool_id :: String
  }

newtype AWSError = AWSError { type :: String, message :: String }

instance showAWSError :: Show AWSError where show (AWSError e) = show e

instance readForeignAWSError :: ReadForeign AWSError where
  readImpl f = do
    (tmp :: { "__type" :: String }) <- readImpl f
    pure $ AWSError { type : tmp."__type", message : unsafeStringify f }

type AWS r a = Run(aff :: AFF, aws :: EXCEPT AWSError, awsreader :: READER AWSContext | r) a
type Stream r a = Run(aff :: AFF, awsreader :: READER AWSContext, yield :: YIELD a, aws :: EXCEPT AWSError | r) Unit

type CredentialsINI =
  { default ::
      { region :: String
      , aws_access_key_id :: String
      , aws_secret_access_key :: String
      }
  }

type SignatureParams =
  ( path :: String
  , method :: String
  , body :: String
  , host :: String
  , headers :: Object String
  , service :: String
  , region :: String
  )

newtype Service = Service String
newtype Region = Region String
newtype Version = Version String
newtype Action = Action String

_aws :: SProxy "aws"
_aws = SProxy

_awsreader :: SProxy "awsreader"
_awsreader = SProxy

credentials :: ∀ r . AWS r Credentials
credentials = do
  ctx <- Reader.askAt _awsreader
  Run.liftAff $ AVar.read ctx.credentials

defaultContext :: Aff AWSContext
defaultContext = do
  creds  <- AVar.new =<< (envCredentials <|> credentialsFromINI)
  pure { fetchImpl : nodeFetch, credentials : creds, region: "us-east-1", identity_pool_id : "" }

credentialsFromINI :: Aff Credentials
credentialsFromINI = do
  home  <- liftEffect homedir
  str   <- FS.readTextFile UTF8 (home <> "/.aws/credentials")
  (creds :: CredentialsINI) <- liftEither $ parsellIni str
  pure { accessKeyId : creds.default.aws_access_key_id, secretAccessKey : creds.default.aws_secret_access_key, sessionToken : Nothing }

fetchImpl :: ∀ r . AWS r FetchImpl
fetchImpl = do
  ctx <- Reader.askAt _awsreader
  pure ctx.fetchImpl

request :: ∀ r i o
  . WriteForeign i
  => ReadForeign o
  => Region
  -> Service
  -> Version
  -> Action
  -> i
  -> AWS r o
request (Region region) (Service service) (Version version) (Action action) input = do
  impl  <- fetchImpl
  creds <- credentials
  let body = writeJSON input
  req   <- makeRequest creds body
  let queryString = "?" <> (A.intercalate "&"
        $ map (\(Tuple k v) -> (unsafeEncodeURIComponent k) <> "=" <> (unsafeEncodeURIComponent v))
        $ (O.toUnfoldable req.query :: Array (Tuple String String)))
  let url = M.URL $ A.fold [ "https://", req.hostname, req.path ]
      opts = { method: M.postMethod, body, headers : req.headers }
  response <- Run.liftAff $ (M.fetch impl) url opts
  json <- Run.liftAff $ M.text response
  parseResponse json
  where
    makeRequest creds body = Run.liftAff do
      now <- JSDate.now # liftEffect
      iso <- JSDate.toISOString now # liftEffect
      let regex = unsafeRegex "[:-]" Flags.global
          regex2 = unsafeRegex "\\..*" Flags.global
          longDate = R.replace regex "" $ R.replace regex2 "Z" iso
          shortDate = S.take 8 longDate
          versionShort = S.take 8 $ R.replace regex version ""
          args = { longDate, shortDate, region, service, applyChecksum: false, credentials: creds }
          req =
            { protocol: "https:"
            , method: "POST"
            , hostname: (service <> "." <> region <> ".amazonaws.com")
            , port: 443
            , path: "/"
            , query: O.empty -- O.fromHomogeneous { "Action": action, "Version": version }
            , headers: O.fromHomogeneous
                          { "Content-Type": "application/x-amz-json-1.0"
                          , "X-Amz-Target": action
                          , "User-Agent": "GraphadoClient"
                          }
            , body: Body body
            }
      liftEffect $ SignatureV4.sign args req



parseResponse :: ∀ r o
  .  ReadForeign o
  => String
  -> AWS r o
parseResponse str = case readJSON str of
    Left _ -> runLiftEither $ readJSON str
    Right e -> Except.rethrowAt _aws $ Left e

envCredentials :: Aff Credentials
envCredentials = fromEffectFnAff $ _envCredentials Nothing Just

foreign import data AWSClient :: Type
foreign import _envCredentials :: Maybe Credentials -> (Credentials -> Maybe Credentials) -> EffectFnAff Credentials
foreign import homedir :: Effect String

