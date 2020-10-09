module AWS.SignatureV4.Types where

import Prelude

import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Foreign.Object (Object)

newtype CanonicalHeaders = CanonicalHeaders (Object String)
newtype CanonicalQuery = CanonicalQuery (Object String)
newtype CanonicalRequest = CanonicalRequest String
newtype StringToSign = StringToSign String

newtype PreparedRequest = PreparedRequest Request

derive instance ntCH :: Newtype CanonicalHeaders _
derive instance ntCQ :: Newtype CanonicalQuery _
derive instance ntCR :: Newtype CanonicalRequest _
derive instance ntStS :: Newtype StringToSign _
derive instance ntPR :: Newtype PreparedRequest _

derive instance eqCanonicalHeaders :: Eq CanonicalHeaders
instance showCanonicalHeaders :: Show CanonicalHeaders where show (CanonicalHeaders headers) = show headers

data Body = Body String | None | Stream
instance showBody :: Show Body where 
  show (Body str) = str
  show None = ""
  show Stream = "<stream>"

type Credentials =
  { accessKeyId :: String
  , secretAccessKey :: String
  , sessionToken :: Maybe String
  }

type Request = 
  { protocol :: String
  , method :: String
  , hostname :: String
  , port :: Int
  , path :: String
  , query :: Object String
  , headers :: Object String
  , body :: Body
  }

