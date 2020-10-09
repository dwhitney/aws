module AWS.SignatureV4.Constants where

import Prelude

import Data.String (toLower)
import Data.String.Regex (Regex)
import Data.String.Regex.Flags as Flags
import Data.String.Regex.Unsafe (unsafeRegex)

algorithm_query_param :: String
algorithm_query_param = "X-Amz-Algorithm"

credential_query_param :: String
credential_query_param = "X-Amz-Credential"

amz_date_query_param  :: String
amz_date_query_param = "X-Amz-Date"

signed_headers_query_param  :: String
signed_headers_query_param = "X-Amz-SignedHeaders"

expires_query_param  :: String
expires_query_param = "X-Amz-Expires"

signature_query_param  :: String
signature_query_param = "X-Amz-Signature"

token_query_param  :: String
token_query_param = "X-Amz-Security-Token"
  
auth_header :: String
auth_header = "authorization"

amz_date_header  :: String
amz_date_header = toLower $ amz_date_query_param

date_header  :: String
date_header = "date"

generated_headers  :: Array String
generated_headers = [auth_header, amz_date_header, date_header]

signature_header  :: String
signature_header = toLower $ signature_query_param

sha256_header  :: String
sha256_header = "x-amz-content-sha256"

token_header  :: String
token_header = toLower $ token_query_param

host_header  :: String
host_header = "host"

always_unsignable_headers :: Array String
always_unsignable_headers = 
  [ "authorization"
  , "cache-control"
  , "connection"
  , "expect"
  , "from"
  , "keep-alive"
  , "max-forwards"
  , "pragma"
  , "referer"
  , "te"
  , "trailer"
  , "transfer-encoding"
  , "upgrade"
  , "user-agent"
  , "x-amzn-trace-id"
  ]

proxy_header_pattern :: Regex
proxy_header_pattern = unsafeRegex "^proxy-" Flags.noFlags

sec_header_pattern :: Regex
sec_header_pattern = unsafeRegex "^sec-" Flags.noFlags

unsignable_patterns :: Array Regex
unsignable_patterns = [unsafeRegex "^proxy-" Flags.ignoreCase, unsafeRegex "^sec-" Flags.ignoreCase]

algorithm_identifier :: String
algorithm_identifier = "AWS4-HMAC-SHA256"

unsigned_payload :: String
unsigned_payload = "UNSIGNED-PAYLOAD"

max_cache_size :: Int
max_cache_size = 50

key_type_identifier :: String
key_type_identifier = "aws4_request"

max_presigned_ttl :: Int
max_presigned_ttl = 60 * 60 * 24 * 7


