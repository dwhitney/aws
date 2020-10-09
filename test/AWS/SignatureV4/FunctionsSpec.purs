module Test.AWS.SignatureV4.FunctionsSpec where

import Prelude

import AWS.SignatureV4.Constants (always_unsignable_headers, amz_date_header, auth_header, date_header, host_header, unsigned_payload)
import AWS.SignatureV4.Functions (Args, createScope, getCanonicalHeaders, getCanonicalQuery, getCanonicalRequest, getPayloadHash, getPreparedRequest, getSigningKey, getStringToSign, moveHeadersToQuery, sign)
import AWS.SignatureV4.Types (Body(..), PreparedRequest(..), Request)
import Data.Foldable as A
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.String (toUpper)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Foreign.Object as O
import Node.Buffer as Buffer
import Node.Encoding (Encoding(..))
import Test.AWS.SignatureV4.Fixtures (TestCase, testCases)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual)

minimalRequest :: Request
minimalRequest = 
  { port : 443
  , method: "POST"
  , hostname: "foo.us-bar-1.amazonaws.com"
  , protocol: "https"
  , path: "/"
  , headers: O.singleton "host" "foo.us-bar-1.amazonaws.com"
  , query : O.empty
  , body : None
  }

minimalArgs :: Args
minimalArgs = do
  let shortDate = "20120215"
      longDate = shortDate
      region = "us-east-1"
      service = "iam"
      credentials = { accessKeyId: "foo", secretAccessKey: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", sessionToken : Nothing }
  { shortDate, longDate, region, service, credentials, applyChecksum : true }


spec :: Spec Unit
spec = do

  describe "createScope" do
    it "should create a scoped identifier for the credentials used" do
      let credentials = { accessKeyId: "foo", secretAccessKey: "bar", sessionToken : Nothing }
          scope = createScope { shortDate : "date", longDate : "longDate",  region : "region", service : "service", credentials, applyChecksum : true }
      scope `shouldEqual` "date/region/service/aws4_request"

  describe "getSigningKey" do
    it "should produce the correct sequence of signature keys from the docs" do
      -- | https://docs.aws.amazon.com/general/latest/gr/signature-v4-examples.html#signature-v4-examples-other
      let shortDate = "20120215"
          longDate = shortDate
          region = "us-east-1"
          service = "iam"
          credentials = { accessKeyId: "foo", secretAccessKey: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", sessionToken : Nothing }
      buffer  <- getSigningKey { shortDate, longDate, region, service, credentials, applyChecksum : true } # liftEffect
      key <- Buffer.toString Hex buffer # liftEffect
      key `shouldEqual` "f4780e2d9f65fa895f9c67b32ce1baf0b0d8a43505a000a1a9e090d414db404d" 

    it "should return a buffer containing a signing key derived from the provided credentials, date, region, and service" do
      let credentials = { accessKeyId: "foo", secretAccessKey: "bar", sessionToken : Nothing }
          shortDate = "19700101"
          longDate = shortDate
          region = "us-foo-1"
          service = "bar"
      buffer  <- getSigningKey { shortDate, longDate, region, service, credentials, applyChecksum : true } # liftEffect
      key <- Buffer.toString Hex buffer # liftEffect
      key `shouldEqual` "b7c34d23320b5cd909500c889eac033a33c93f5a4bf67f71988a58f299e62e0a" 

  describe "getPreparedRequest" do
    it "should ignore previously set authorization, date, and x-amz-date headers" do
      let headers = O.empty 
            # O.insert auth_header "foo"
            # O.insert amz_date_header "bar"
            # O.insert date_header "baz"
          request = minimalRequest { headers = headers }
      PreparedRequest prepared <- liftEffect $ getPreparedRequest minimalArgs request
      (O.lookup auth_header prepared.headers) `shouldEqual` Nothing
      (O.lookup amz_date_header prepared.headers) `shouldNotEqual` (Just "bar")
      (O.lookup date_header prepared.headers) `shouldNotEqual` (Just "baz")

    it "should ignore previously set authorization, date, and x-amz-date headers regardless of case" do
      let headers = O.empty 
            # O.insert (toUpper auth_header) "foo"
            # O.insert (toUpper amz_date_header) "bar"
            # O.insert (toUpper date_header) "baz"
          request = minimalRequest { headers = headers }
      PreparedRequest prepared <- liftEffect $ getPreparedRequest minimalArgs request
      (O.lookup (toUpper auth_header) prepared.headers) `shouldEqual` Nothing
      (O.lookup (toUpper amz_date_header) prepared.headers) `shouldEqual` Nothing
      (O.lookup (toUpper date_header) prepared.headers) `shouldEqual` Nothing

    it "should set the 'Host' header if it's not present" do
      let headers = O.empty 
          request = minimalRequest { headers = headers }
      PreparedRequest prepared <- liftEffect $ getPreparedRequest minimalArgs request
      (O.lookup host_header prepared.headers) `shouldEqual` (Just request.hostname)

  describe "moveHeadersToQuery" do
    it "should hoist 'x-amz-' headers to the querystring" do
      let headers = O.fromHomogeneous 
                      { "Host": "www.example.com"
                      , "X-Amz-Website-Redirect-Location": "/index.html"
                      , "Foo": "bar"
                      , fizz : "buzz"
                      , "SNAP": "crackle, pop"
                      , "X-Amz-Storage-Class": "STANDARD_IA"
                      }
          request = moveHeadersToQuery $ minimalRequest { headers = headers }
          expectedQuery = O.fromHomogeneous
                      { "X-Amz-Website-Redirect-Location": "/index.html"
                      , "X-Amz-Storage-Class": "STANDARD_IA"
                      }

          expectedHeaders = O.fromHomogeneous
                      { "Host": "www.example.com"
                      , "Foo": "bar"
                      , fizz: "buzz"
                      , "SNAP": "crackle, pop"
                      }
      request.query `shouldEqual` expectedQuery 
      request.headers `shouldEqual` expectedHeaders

    it "should not overwrite existing query values with different keys" do
      let headers = O.fromHomogeneous
            { "Host": "www.example.com"
            , "X-Amz-Website-Redirect-Location": "/index.html"
            , "Foo": "bar"
            , fizz: "buzz"
            , "SNAP": "crackle, pop"
            , "X-Amz-Storage-Class": "STANDARD_IA"
            }
          query = O.fromHomogeneous
            { "Foo": "buzz"
            , fizz: "bar"
            , "X-Amz-Storage-Class": "REDUCED_REDUNDANCY"
            }
          request = moveHeadersToQuery $ minimalRequest { headers = headers, query = query }
          expectedQuery = O.fromHomogeneous
              { "Foo": "buzz"
              , fizz: "bar"
              , "X-Amz-Website-Redirect-Location": "/index.html"
              , "X-Amz-Storage-Class": "STANDARD_IA"
              }
      request.query `shouldEqual` expectedQuery
            
  describe "getCononicalHeaders" do
    it "should downcase all headers" do
      let headers = O.fromHomogeneous
              { fOo: "bar"
              , "BaZ": "QUUX"
              , "HoSt": "foo.us-east-1.amazonaws.com"
              }
      prepared <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest { headers = headers }
      let canonicalHeaders = unwrap (getCanonicalHeaders prepared)
      (O.lookup "fOo" canonicalHeaders) `shouldEqual` Nothing
      (O.lookup "foo" canonicalHeaders) `shouldEqual` (Just "bar")
      (O.lookup "BaZ" canonicalHeaders) `shouldEqual` Nothing
      (O.lookup "baz" canonicalHeaders) `shouldEqual` (Just "QUUX")
      (O.lookup "HoSt" canonicalHeaders) `shouldEqual` Nothing
      (O.lookup "host" canonicalHeaders) `shouldEqual` (Just "foo.us-east-1.amazonaws.com")


    it "should remove all unsignable headers" do
      let headers = O.fromHomogeneous
              { host: "foo.us-east-1.amazonaws.com"
              , foo: "bar" 
              , "authorization" : "asdf"
              , "cache-control" : "asdf"
              , "connection" : "asdf"
              , "expect" : "asdf"
              , "from" : "asdf"
              , "keep-alive" : "asdf"
              , "max-forwards" : "asdf"
              , "pragma" : "asdf"
              , "referer" : "asdf"
              , "te" : "asdf"
              , "trailer" : "asdf"
              , "transfer-encoding" : "asdf"
              , "upgrade" : "asdf"
              , "user-agent" : "asdf"
              , "x-amzn-trace-id" : "asdf"
              }
      prepared <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest { headers = headers }
      let canonicalHeaders = unwrap $ getCanonicalHeaders prepared 
          keys = A.all (flip A.notElem always_unsignable_headers) $ O.keys canonicalHeaders
      keys `shouldEqual` true
 
  describe "getPayloadHash" do
    it "an empty body results in the correct hash" do
      prepared <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest
      let canonicalHeaders = getCanonicalHeaders prepared
      payloadHash <- liftEffect $ getPayloadHash (unwrap prepared).body
      payloadHash `shouldEqual` "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    
    it "should return the hex-encoded hash of a string body" do
      let request =  minimalRequest { body = Body "foo" }
      preparedRequest <- liftEffect $ getPreparedRequest minimalArgs request
      let canonicalHeaders = getCanonicalHeaders preparedRequest 
      payloadHash <- liftEffect $ getPayloadHash (unwrap preparedRequest).body
      payloadHash `shouldEqual` "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"

    it "should return the unsigned_payload if the body is a stream" do
      let request = minimalRequest { body = Stream }
      preparedRequest <- liftEffect $ getPreparedRequest minimalArgs request
      let canonicalHeaders = getCanonicalHeaders preparedRequest
      payloadHash <- liftEffect $ getPayloadHash (unwrap preparedRequest).body
      payloadHash `shouldEqual` unsigned_payload

  describe "getCanonicalQuery" do
    it "should return an empty string for requests with no querystring" do
      request <- liftEffect $ getPreparedRequest minimalArgs minimalRequest 
      let canonicalQuery = getCanonicalQuery request
      canonicalQuery `shouldEqual` ""
 

    it "should serialize simple key => value pairs" do
      request <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest { query = O.fromHomogeneous { fizz : "buzz", foo : "bar" } }
      let canonicalQuery = getCanonicalQuery request
      canonicalQuery `shouldEqual` "fizz=buzz&foo=bar"
        
    it "should URI-encode keys and values" do
      request <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest { query = O.fromHomogeneous { "🐎": "🦄", "💩": "☃️" } }
      let canonicalQuery = getCanonicalQuery request
      canonicalQuery `shouldEqual` "%F0%9F%90%8E=%F0%9F%A6%84&%F0%9F%92%A9=%E2%98%83%EF%B8%8F"

    it "should omit the x-amz-signature parameter, regardless of case" do
      request <- liftEffect $ getPreparedRequest minimalArgs $ minimalRequest { query = O.fromHomogeneous {
          "x-amz-signature": "foo",
          "X-Amz-Signature": "bar",
          fizz: "buzz"
          }}
      let canonicalQuery = getCanonicalQuery request
      canonicalQuery `shouldEqual` "fizz=buzz"

  describe "canonicalReqest" do
    it "should create a canonical request" do
      let request  =  
            { protocol : "https"
            , method : "GET"
            , hostname : "iam.amazonaws.com"
            , port : 443
            , path : "/"
            , query : O.fromHomogeneous { "Action" : "ListUsers", "Version" : "2010-05-08" }
            , headers : O.fromHomogeneous { "Content-Type" : "application/x-www-form-urlencoded; charset=utf-8" }
            , body : None
            }

          credentials = { accessKeyId: "foo", secretAccessKey: "bar", sessionToken : Nothing }
          args =
            { shortDate : "20150830"
            , longDate : "20150830T123600Z"
            , region : "us-east-1"
            , service : "iam"
            , applyChecksum : false 
            , credentials
            }
      preparedRequest <- liftEffect $ getPreparedRequest args request
      canonicalRequest <- liftEffect $ getCanonicalRequest args preparedRequest
      let expected ="""GET
/
Action=ListUsers&Version=2010-05-08
content-type:application/x-www-form-urlencoded; charset=utf-8
host:iam.amazonaws.com
x-amz-date:20150830T123600Z

content-type;host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"""
      (unwrap canonicalRequest) `shouldEqual` expected

    it "should create a StringToSign" do

      let request  =  
            { protocol : "https"
            , method : "GET"
            , hostname : "iam.amazonaws.com"
            , port : 443
            , path : "/"
            , query : O.fromHomogeneous { "Action" : "ListUsers", "Version" : "2010-05-08" }
            , headers : O.fromHomogeneous { "Content-Type" : "application/x-www-form-urlencoded; charset=utf-8" }
            , body : None
            }

          credentials = { accessKeyId: "foo", secretAccessKey: "bar", sessionToken : Nothing }
          args =
            { shortDate : "20150830"
            , longDate : "20150830T123600Z"
            , region : "us-east-1"
            , service : "iam"
            , applyChecksum : false
            , credentials
            }
      preparedRequest <- liftEffect $ getPreparedRequest args request
      canonicalRequest <- liftEffect $ getCanonicalRequest args preparedRequest
      sts <- getStringToSign args canonicalRequest # liftEffect
      let expected = """AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/iam/aws4_request
f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59"""
      (unwrap sts) `shouldEqual` expected

  describe "sign" do
    it "should sign requests without bodies" do
      let request  =  
            { protocol : "https"
            , method : "GET"
            , hostname : "example.amazonaws.com"
            , port : 443
            , path : "/"
            , query : O.fromHomogeneous { "Param1": "value1", "Param2": "value2" }
            , headers : O.empty
            , body : None
            }

          credentials = { accessKeyId: "AKIDEXAMPLE", secretAccessKey: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", sessionToken : Nothing }
          args =
            { shortDate : "20150830"
            , longDate : "20150830T123600Z"
            , region : "us-east-1"
            , service : "service"
            , applyChecksum : false
            , credentials
            }
      signed <- sign args request # liftEffect
      let auth = O.lookup auth_header signed.headers      
      auth `shouldEqual` (Just "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500")

    it "should correctly sign all of the test cases" do
      let credentials = { accessKeyId: "AKIDEXAMPLE", secretAccessKey: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", sessionToken : Nothing }
      let args =
            { shortDate : "20150830"
            , longDate : "20150830T123600Z"
            , region : "us-east-1"
            , service : "service"
            , applyChecksum : false
            , credentials
            }
      A.traverse_ (handlTestCase args) testCases

handlTestCase :: Args -> TestCase -> Aff Unit
handlTestCase args { name, request, authorization } = do
  signed <- sign args request # liftEffect
  let auth = O.lookup auth_header signed.headers      
  if auth == (Just authorization) 
    then pure unit 
    else do
      let str = A.intercalate "\n" [ name, A.fold auth, authorization ]
      (log str) # liftEffect
  auth `shouldEqual` (Just authorization) 
