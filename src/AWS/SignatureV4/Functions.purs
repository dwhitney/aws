module AWS.SignatureV4.Functions where

import Prelude

import AWS.SignatureV4.Constants (algorithm_identifier, always_unsignable_headers, amz_date_header, auth_header, key_type_identifier, proxy_header_pattern, sec_header_pattern, sha256_header, signature_header, token_header, unsigned_payload)
import AWS.SignatureV4.Constants as C
import AWS.SignatureV4.Types (Body(..), CanonicalHeaders(..), CanonicalRequest(..), Credentials, PreparedRequest(..), Request, StringToSign(..))
import Data.Array as A
import Data.JSDate as JSDate
import Data.Maybe (Maybe(..), isNothing)
import Data.Newtype (unwrap)
import Data.String (toLower, toUpper)
import Data.String as S
import Data.String.Regex as R
import Data.String.Regex.Flags as Flags
import Data.String.Regex.Unsafe (unsafeRegex)
import Data.Tuple (Tuple(..), fst)
import Effect (Effect)
import Foreign.Object as O
import Global.Unsafe (unsafeEncodeURI, unsafeEncodeURIComponent)
import Node.Buffer (Buffer, toString)
import Node.Crypto.Hash (Algorithm(..))
import Node.Crypto.Hash as Hash
import Node.Crypto.Hmac (createHmac, digest, update)
import Node.Encoding (Encoding(..))
import Unsafe.Coerce (unsafeCoerce)

type Args =
  { shortDate :: String
  , longDate :: String
  , region :: String
  , service :: String
  , applyChecksum :: Boolean
  , credentials :: Credentials
  }

createScope :: Args -> String
createScope { shortDate, region, service } = A.intercalate "/" [ shortDate, region, service, key_type_identifier ]

getSigningKey :: Args -> Effect Buffer 
getSigningKey { shortDate, region, service, credentials: { secretAccessKey } } = do
  let kSecret = "AWS4" <> secretAccessKey
  kDate <- hmacIt kSecret shortDate
  kRegion <- hmacIt kDate region
  kService <- hmacIt kRegion service
  hmacIt kService key_type_identifier

hmacIt :: ∀ secret message . secret -> message -> Effect Buffer
hmacIt secret message = do
  hmac <- createHmac SHA256 (unsafeCoerce secret)
  digest =<< update hmac (unsafeCoerce message)

getPreparedRequest :: Args -> Request -> Effect PreparedRequest
getPreparedRequest args request = do
  let tuples = O.toUnfoldable request.headers
  let newHeaders = O.fromFoldable 
        $ A.filter (flip A.notElem C.generated_headers <<< toLower <<< fst)
        $ tuples 
      preparedHeaders = if isNothing $ A.find (\(Tuple k _) -> (toLower k) ==  C.host_header) tuples
                      then O.insert C.host_header request.hostname newHeaders
                      else newHeaders
      withDate = preparedHeaders # O.insert amz_date_header args.longDate
      withToken = case args.credentials.sessionToken of 
                    Nothing -> withDate
                    Just sessionToken -> O.insert token_header sessionToken withDate
  finalHeaders <- if args.applyChecksum && (not $ O.member sha256_header withToken)
                              then do
                                  payloadHash <- getPayloadHash request.body
                                  pure $ O.insert sha256_header payloadHash withToken
                              else pure $ withToken
  pure $ PreparedRequest (request { headers = finalHeaders })

getPayloadHash :: Body -> Effect String
getPayloadHash None = pure "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
getPayloadHash Stream = pure unsigned_payload
getPayloadHash (Body str) = Hash.hex SHA256 str

moveHeadersToQuery :: Request -> Request
moveHeadersToQuery request = do
  let tuples = A.partition (\(Tuple k _) -> "x-amz-" == (toLower $ S.take 6 k))
                  $ O.toUnfoldable request.headers 
      headers = O.fromFoldable tuples.no
      query = O.fromFoldable tuples.yes
  request { query = O.union query request.query, headers = headers }

getCanonicalHeaders :: PreparedRequest -> CanonicalHeaders
getCanonicalHeaders (PreparedRequest request) = CanonicalHeaders $ O.empty # O.foldMap (\k v obj -> do
  let key = toLower k
      value = S.trim $ R.replace (unsafeRegex "\\s+" Flags.global) " " v
  if (A.elem k always_unsignable_headers) || (R.test proxy_header_pattern key) || (R.test sec_header_pattern key)
    then obj
    else O.insert key value obj
  ) request.headers 

getCanonicalQuery :: PreparedRequest -> String
getCanonicalQuery (PreparedRequest request) = A.intercalate "&"
    $ map (\(Tuple k v) -> (unsafeEncodeURIComponent k) <> "=" <> (unsafeEncodeURIComponent v))
    $ A.sortWith fst
    $ A.filter (\(Tuple k _) -> (toLower k) /= signature_header)
    $ O.toUnfoldable request.query



getStringToSign :: Args -> CanonicalRequest -> Effect StringToSign
getStringToSign args (CanonicalRequest request) = do
  let scope = createScope args
  hashed <- Hash.hex SHA256 request 
  pure $ StringToSign $ A.intercalate "\n"
        [ algorithm_identifier
        , args.longDate
        , scope
        , hashed
        ]

sign :: Args -> Request -> Effect Request
sign args originalRequest = do
  let scope = createScope args
  preparedRequest <- getPreparedRequest args originalRequest
  let canonicalHeaders = getCanonicalHeaders preparedRequest
  canonicalRequest <- getCanonicalRequest args preparedRequest
  StringToSign stringToSign <- getStringToSign args canonicalRequest
  key <- getSigningKey args
  signature <- toString Hex =<< hmacIt key stringToSign
  let authHeaderValue = A.intercalate " " 
          [ algorithm_identifier
          , "Credential=" <> args.credentials.accessKeyId <> "/" <> scope <> ","
          , "SignedHeaders=" <> getCanonicalHeadersList canonicalHeaders <> ","
          , "Signature=" <> signature
          ]

      finalHeaders = O.insert auth_header authHeaderValue (unwrap preparedRequest).headers
  pure $ (unwrap preparedRequest) { headers = finalHeaders }

getCanonicalRequest :: Args -> PreparedRequest -> Effect CanonicalRequest 
getCanonicalRequest args preparedRequest@(PreparedRequest request) = do
  let headers = getCanonicalHeaders preparedRequest
  payloadHash <- getPayloadHash (unwrap preparedRequest).body
  let scope = createScope args
      canonicalHeaders = getCanonicalHeaders preparedRequest
      canonicalQuery = getCanonicalQuery preparedRequest
  let headerLine = A.intercalate "\n"
              $ map (\(Tuple k v) -> k <> ":" <> v)
              $ A.sortWith fst
              $ (O.toUnfoldable (unwrap canonicalHeaders) :: Array (Tuple String String))
  pure $ CanonicalRequest $ A.intercalate "\n"
      [ toUpper (unwrap preparedRequest).method
      , unsafeEncodeURI request.path
      , canonicalQuery
      , headerLine
      , ""
      , getCanonicalHeadersList headers
      , payloadHash
      ]


dates :: Effect { longDate :: String, shortDate :: String }
dates = do
  now <- JSDate.now >>= JSDate.toISOString
  let r = unsafeRegex "[\\-:]" Flags.global
      longDate = R.replace r now ""
      shortDate = S.take 8 longDate
  pure { longDate, shortDate }


getCanonicalHeadersList :: CanonicalHeaders -> String
getCanonicalHeadersList (CanonicalHeaders headers) = A.intercalate ";" $ A.sort $ O.keys headers

