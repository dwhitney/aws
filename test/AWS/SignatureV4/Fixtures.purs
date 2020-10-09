module Test.AWS.SignatureV4.Fixtures where

import AWS.SignatureV4.Types (Body(..), Request)
import Foreign.Object as O

type TestCase = 
  { name :: String
  , request :: Request
  , authorization :: String
  }

testCases :: Array TestCase
testCases = [
  {
    name: "get-header-key-duplicate",
    request: {
      protocol: "https:",
      method: "GET",
      port: 443,
      body : None,
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "value2,value2,value1",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;x-amz-date, Signature=c9d5ea9f3f72853aea855b47ea873832890dbdd183b4468f858259531a5138ea"
  },
  {
    name: "get-header-value-multiline",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      query : O.empty,
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "value1,value2,value3",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;x-amz-date, Signature=ba17b383a53190154eb5fa66a1b836cc297cc0a3d70a5d00705980573d8ff790"
  },
  {
    name: "get-header-value-order",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "GET",
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "value4,value1,value3,value2",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;x-amz-date, Signature=08c7e5a9acfcfeb3ab6b2185e75ce8b1deb5e634ec47601a50643f830c755c01"
  },
  {
    name: "get-header-value-trim",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "value1",
        "my-header2": "\"a   b   c\"",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;my-header2;x-amz-date, Signature=acc3ed3afb60bb290fc8d2dd0098b9911fcaa05412b367055dee359757a9c736"
  },
  {
    name: "get-unreserved",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      query : O.empty,
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path:
        "/-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=07ef7494c76fa4850883e2b006601f940f8a34d404d0cfa977f52a65bbf5f24f"
  },
  {
    name: "get-utf8",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/ሴ",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=8318018e0b0f223aa2bbf98705b62bb787dc9c0e678f255a891fd03141be5d85"
  },
  {
    name: "get-vanilla",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31"
  },
  {
    name: "get-vanilla-empty-query-key",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "Param1": "value1"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=a67d582fa61cc504c4bae71f336f98b97f1ea3c7a6bfe1b6e45aec72011b9aeb"
  },
  {
    name: "get-vanilla-query",
    request: {
      protocol: "https:",
      port: 443,
      query : O.empty,
      body : None,
      method: "GET",
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31"
  },
  {
    name: "get-vanilla-query-order-key-case",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "Param2": "value2",
        "Param1": "value1"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500"
  },
  {
    name: "get-vanilla-query-unreserved",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz":
          "-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=9c3e54bfcdf0b19771a7f523ee5669cdf59bc7cc0884027167c21bb143a40197"
  },
  {
    name: "get-vanilla-utf8-query",
    request: {
      protocol: "https:",
      port: 443,
      method: "GET",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "ሴ": "bar"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=2cdec8eed098649ff3a119c94853b13c643bcf08f8b0a1d91e12c9027818dd04"
  },
  {
    name: "post-header-key-case",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "POST",
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5da7c1a2acd57cee7505fc6676e4e544621c30862966e37dddb68e92efbe5d6b"
  },
  {
    name: "post-header-key-sort",
    request: {
      protocol: "https:",
      port: 443,
      method: "POST",
      body : None,
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "value1",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;x-amz-date, Signature=c5410059b04c1ee005303aed430f6e6645f61f4dc9e1461ec8f8916fdf18852c"
  },
  {
    name: "post-header-value-case",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "POST",
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "my-header1": "VALUE1",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;my-header1;x-amz-date, Signature=cdbc9802e29d2942e5e10b5bccfdd67c5f22c7c4e8ae67b53629efa58b974b7d"
  },
  {
    name: "post-vanilla",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "POST",
      query : O.empty,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5da7c1a2acd57cee7505fc6676e4e544621c30862966e37dddb68e92efbe5d6b"
  },
  {
    name: "post-vanilla-empty-query-value",
    request: {
      protocol: "https:",
      port: 443,
      method: "POST",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "Param1": "value1"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=28038455d6de14eafc1f9222cf5aa6f1a96197d7deb8263271d420d138af7f11"
  },
  {
    name: "post-vanilla-query",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "POST",
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "Param1": "value1"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=28038455d6de14eafc1f9222cf5aa6f1a96197d7deb8263271d420d138af7f11"
  },
  {
    name: "post-vanilla-query-nonunreserved",
    request: {
      protocol: "https:",
      port: 443,
      method: "POST",
      body : None,
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        "@#$%^": "",
        "+": "/,?><`\";:\\|][{}"
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=66c82657c86e26fb25238d0e69f011edc4c6df5ae71119d7cb98ed9b87393c1e"
  },
  {
    name: "post-vanilla-query-space",
    request: {
      protocol: "https:",
      port: 443,
      body : None,
      method: "POST",
      headers: O.fromHomogeneous {
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      path: "/",
      query: O.fromHomogeneous {
        p: ""
      },
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=e71688addb58a26418614085fb730ba3faa623b461c17f48f2fbdb9361b94a9b"
  },
  {
    name: "post-x-www-form-urlencoded",
    request: {
      protocol: "https:",
      port: 443,
      method: "POST",
      query : O.empty,
      headers: O.fromHomogeneous {
        "content-type": "application/x-www-form-urlencoded",
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      body: Body "Param1=value1",
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=ff11897932ad3f4e8b18135d722051e5ac45fc38421b1da7b9d196a0fe09473a"
  },
  {
    name: "post-x-www-form-urlencoded-parameters",
    request: {
      protocol: "https:",
      port: 443,
      method: "POST",
      query : O.empty,
      headers: O.fromHomogeneous {
        "content-type": "application/x-www-form-urlencoded; charset=utf8",
        host: "example.amazonaws.com",
        "x-amz-date": "20150830T123600Z"
      },
      body: Body "Param1=value1",
      path: "/",
      hostname: "example.amazonaws.com"
    },
    authorization:
      "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=1a72ec8f64bd914b0e42e42607c7fbce7fb2c7465f63e3092b3b0d39fa77a6fe"
  }
]
