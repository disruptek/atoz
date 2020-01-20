
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Comprehend
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Comprehend is an AWS service for gaining insight into the content of documents. Use these actions to determine the topics contained in your documents, the topics they discuss, the predominant sentiment expressed in them, the predominant language used, and more.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/comprehend/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "comprehend.ap-northeast-1.amazonaws.com", "ap-southeast-1": "comprehend.ap-southeast-1.amazonaws.com",
                           "us-west-2": "comprehend.us-west-2.amazonaws.com",
                           "eu-west-2": "comprehend.eu-west-2.amazonaws.com", "ap-northeast-3": "comprehend.ap-northeast-3.amazonaws.com", "eu-central-1": "comprehend.eu-central-1.amazonaws.com",
                           "us-east-2": "comprehend.us-east-2.amazonaws.com",
                           "us-east-1": "comprehend.us-east-1.amazonaws.com", "cn-northwest-1": "comprehend.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "comprehend.ap-south-1.amazonaws.com",
                           "eu-north-1": "comprehend.eu-north-1.amazonaws.com", "ap-northeast-2": "comprehend.ap-northeast-2.amazonaws.com",
                           "us-west-1": "comprehend.us-west-1.amazonaws.com", "us-gov-east-1": "comprehend.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "comprehend.eu-west-3.amazonaws.com", "cn-north-1": "comprehend.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "comprehend.sa-east-1.amazonaws.com",
                           "eu-west-1": "comprehend.eu-west-1.amazonaws.com", "us-gov-west-1": "comprehend.us-gov-west-1.amazonaws.com", "ap-southeast-2": "comprehend.ap-southeast-2.amazonaws.com", "ca-central-1": "comprehend.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "comprehend.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "comprehend.ap-southeast-1.amazonaws.com",
      "us-west-2": "comprehend.us-west-2.amazonaws.com",
      "eu-west-2": "comprehend.eu-west-2.amazonaws.com",
      "ap-northeast-3": "comprehend.ap-northeast-3.amazonaws.com",
      "eu-central-1": "comprehend.eu-central-1.amazonaws.com",
      "us-east-2": "comprehend.us-east-2.amazonaws.com",
      "us-east-1": "comprehend.us-east-1.amazonaws.com",
      "cn-northwest-1": "comprehend.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "comprehend.ap-south-1.amazonaws.com",
      "eu-north-1": "comprehend.eu-north-1.amazonaws.com",
      "ap-northeast-2": "comprehend.ap-northeast-2.amazonaws.com",
      "us-west-1": "comprehend.us-west-1.amazonaws.com",
      "us-gov-east-1": "comprehend.us-gov-east-1.amazonaws.com",
      "eu-west-3": "comprehend.eu-west-3.amazonaws.com",
      "cn-north-1": "comprehend.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "comprehend.sa-east-1.amazonaws.com",
      "eu-west-1": "comprehend.eu-west-1.amazonaws.com",
      "us-gov-west-1": "comprehend.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "comprehend.ap-southeast-2.amazonaws.com",
      "ca-central-1": "comprehend.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "comprehend"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDetectDominantLanguage_605927 = ref object of OpenApiRestCall_605589
proc url_BatchDetectDominantLanguage_605929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectDominantLanguage_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectDominantLanguage"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_BatchDetectDominantLanguage_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_BatchDetectDominantLanguage_605927; body: JsonNode): Recallable =
  ## batchDetectDominantLanguage
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var batchDetectDominantLanguage* = Call_BatchDetectDominantLanguage_605927(
    name: "batchDetectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectDominantLanguage",
    validator: validate_BatchDetectDominantLanguage_605928, base: "/",
    url: url_BatchDetectDominantLanguage_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectEntities_606196 = ref object of OpenApiRestCall_605589
proc url_BatchDetectEntities_606198(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectEntities_606197(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectEntities"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_BatchDetectEntities_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_BatchDetectEntities_606196; body: JsonNode): Recallable =
  ## batchDetectEntities
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var batchDetectEntities* = Call_BatchDetectEntities_606196(
    name: "batchDetectEntities", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectEntities",
    validator: validate_BatchDetectEntities_606197, base: "/",
    url: url_BatchDetectEntities_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectKeyPhrases_606211 = ref object of OpenApiRestCall_605589
proc url_BatchDetectKeyPhrases_606213(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectKeyPhrases_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectKeyPhrases"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_BatchDetectKeyPhrases_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_BatchDetectKeyPhrases_606211; body: JsonNode): Recallable =
  ## batchDetectKeyPhrases
  ## Detects the key noun phrases found in a batch of documents.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var batchDetectKeyPhrases* = Call_BatchDetectKeyPhrases_606211(
    name: "batchDetectKeyPhrases", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectKeyPhrases",
    validator: validate_BatchDetectKeyPhrases_606212, base: "/",
    url: url_BatchDetectKeyPhrases_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSentiment_606226 = ref object of OpenApiRestCall_605589
proc url_BatchDetectSentiment_606228(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectSentiment_606227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSentiment"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_BatchDetectSentiment_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_BatchDetectSentiment_606226; body: JsonNode): Recallable =
  ## batchDetectSentiment
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var batchDetectSentiment* = Call_BatchDetectSentiment_606226(
    name: "batchDetectSentiment", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSentiment",
    validator: validate_BatchDetectSentiment_606227, base: "/",
    url: url_BatchDetectSentiment_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSyntax_606241 = ref object of OpenApiRestCall_605589
proc url_BatchDetectSyntax_606243(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectSyntax_606242(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSyntax"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_BatchDetectSyntax_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_BatchDetectSyntax_606241; body: JsonNode): Recallable =
  ## batchDetectSyntax
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var batchDetectSyntax* = Call_BatchDetectSyntax_606241(name: "batchDetectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSyntax",
    validator: validate_BatchDetectSyntax_606242, base: "/",
    url: url_BatchDetectSyntax_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ClassifyDocument_606256 = ref object of OpenApiRestCall_605589
proc url_ClassifyDocument_606258(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ClassifyDocument_606257(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "Comprehend_20171127.ClassifyDocument"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_ClassifyDocument_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_ClassifyDocument_606256; body: JsonNode): Recallable =
  ## classifyDocument
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var classifyDocument* = Call_ClassifyDocument_606256(name: "classifyDocument",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ClassifyDocument",
    validator: validate_ClassifyDocument_606257, base: "/",
    url: url_ClassifyDocument_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentClassifier_606271 = ref object of OpenApiRestCall_605589
proc url_CreateDocumentClassifier_606273(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDocumentClassifier_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateDocumentClassifier"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_CreateDocumentClassifier_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_CreateDocumentClassifier_606271; body: JsonNode): Recallable =
  ## createDocumentClassifier
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var createDocumentClassifier* = Call_CreateDocumentClassifier_606271(
    name: "createDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateDocumentClassifier",
    validator: validate_CreateDocumentClassifier_606272, base: "/",
    url: url_CreateDocumentClassifier_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_606286 = ref object of OpenApiRestCall_605589
proc url_CreateEndpoint_606288(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_606287(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEndpoint"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_CreateEndpoint_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_CreateEndpoint_606286; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var createEndpoint* = Call_CreateEndpoint_606286(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEndpoint",
    validator: validate_CreateEndpoint_606287, base: "/", url: url_CreateEndpoint_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEntityRecognizer_606301 = ref object of OpenApiRestCall_605589
proc url_CreateEntityRecognizer_606303(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEntityRecognizer_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEntityRecognizer"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_CreateEntityRecognizer_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateEntityRecognizer_606301; body: JsonNode): Recallable =
  ## createEntityRecognizer
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createEntityRecognizer* = Call_CreateEntityRecognizer_606301(
    name: "createEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEntityRecognizer",
    validator: validate_CreateEntityRecognizer_606302, base: "/",
    url: url_CreateEntityRecognizer_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentClassifier_606316 = ref object of OpenApiRestCall_605589
proc url_DeleteDocumentClassifier_606318(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDocumentClassifier_606317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteDocumentClassifier"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DeleteDocumentClassifier_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DeleteDocumentClassifier_606316; body: JsonNode): Recallable =
  ## deleteDocumentClassifier
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var deleteDocumentClassifier* = Call_DeleteDocumentClassifier_606316(
    name: "deleteDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteDocumentClassifier",
    validator: validate_DeleteDocumentClassifier_606317, base: "/",
    url: url_DeleteDocumentClassifier_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_606331 = ref object of OpenApiRestCall_605589
proc url_DeleteEndpoint_606333(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_606332(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEndpoint"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DeleteEndpoint_606331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DeleteEndpoint_606331; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var deleteEndpoint* = Call_DeleteEndpoint_606331(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEndpoint",
    validator: validate_DeleteEndpoint_606332, base: "/", url: url_DeleteEndpoint_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEntityRecognizer_606346 = ref object of OpenApiRestCall_605589
proc url_DeleteEntityRecognizer_606348(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEntityRecognizer_606347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEntityRecognizer"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_DeleteEntityRecognizer_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_DeleteEntityRecognizer_606346; body: JsonNode): Recallable =
  ## deleteEntityRecognizer
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var deleteEntityRecognizer* = Call_DeleteEntityRecognizer_606346(
    name: "deleteEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEntityRecognizer",
    validator: validate_DeleteEntityRecognizer_606347, base: "/",
    url: url_DeleteEntityRecognizer_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassificationJob_606361 = ref object of OpenApiRestCall_605589
proc url_DescribeDocumentClassificationJob_606363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentClassificationJob_606362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassificationJob"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_DescribeDocumentClassificationJob_606361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_DescribeDocumentClassificationJob_606361;
          body: JsonNode): Recallable =
  ## describeDocumentClassificationJob
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var describeDocumentClassificationJob* = Call_DescribeDocumentClassificationJob_606361(
    name: "describeDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassificationJob",
    validator: validate_DescribeDocumentClassificationJob_606362, base: "/",
    url: url_DescribeDocumentClassificationJob_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassifier_606376 = ref object of OpenApiRestCall_605589
proc url_DescribeDocumentClassifier_606378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentClassifier_606377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a document classifier.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassifier"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_DescribeDocumentClassifier_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a document classifier.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_DescribeDocumentClassifier_606376; body: JsonNode): Recallable =
  ## describeDocumentClassifier
  ## Gets the properties associated with a document classifier.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var describeDocumentClassifier* = Call_DescribeDocumentClassifier_606376(
    name: "describeDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassifier",
    validator: validate_DescribeDocumentClassifier_606377, base: "/",
    url: url_DescribeDocumentClassifier_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDominantLanguageDetectionJob_606391 = ref object of OpenApiRestCall_605589
proc url_DescribeDominantLanguageDetectionJob_606393(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDominantLanguageDetectionJob_606392(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDominantLanguageDetectionJob"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_DescribeDominantLanguageDetectionJob_606391;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_DescribeDominantLanguageDetectionJob_606391;
          body: JsonNode): Recallable =
  ## describeDominantLanguageDetectionJob
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var describeDominantLanguageDetectionJob* = Call_DescribeDominantLanguageDetectionJob_606391(
    name: "describeDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDominantLanguageDetectionJob",
    validator: validate_DescribeDominantLanguageDetectionJob_606392, base: "/",
    url: url_DescribeDominantLanguageDetectionJob_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_606406 = ref object of OpenApiRestCall_605589
proc url_DescribeEndpoint_606408(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_606407(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEndpoint"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_DescribeEndpoint_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_DescribeEndpoint_606406; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var describeEndpoint* = Call_DescribeEndpoint_606406(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEndpoint",
    validator: validate_DescribeEndpoint_606407, base: "/",
    url: url_DescribeEndpoint_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntitiesDetectionJob_606421 = ref object of OpenApiRestCall_605589
proc url_DescribeEntitiesDetectionJob_606423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntitiesDetectionJob_606422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntitiesDetectionJob"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_DescribeEntitiesDetectionJob_606421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_DescribeEntitiesDetectionJob_606421; body: JsonNode): Recallable =
  ## describeEntitiesDetectionJob
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var describeEntitiesDetectionJob* = Call_DescribeEntitiesDetectionJob_606421(
    name: "describeEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntitiesDetectionJob",
    validator: validate_DescribeEntitiesDetectionJob_606422, base: "/",
    url: url_DescribeEntitiesDetectionJob_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityRecognizer_606436 = ref object of OpenApiRestCall_605589
proc url_DescribeEntityRecognizer_606438(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntityRecognizer_606437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntityRecognizer"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_DescribeEntityRecognizer_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_DescribeEntityRecognizer_606436; body: JsonNode): Recallable =
  ## describeEntityRecognizer
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var describeEntityRecognizer* = Call_DescribeEntityRecognizer_606436(
    name: "describeEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntityRecognizer",
    validator: validate_DescribeEntityRecognizer_606437, base: "/",
    url: url_DescribeEntityRecognizer_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKeyPhrasesDetectionJob_606451 = ref object of OpenApiRestCall_605589
proc url_DescribeKeyPhrasesDetectionJob_606453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeKeyPhrasesDetectionJob_606452(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_DescribeKeyPhrasesDetectionJob_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_DescribeKeyPhrasesDetectionJob_606451; body: JsonNode): Recallable =
  ## describeKeyPhrasesDetectionJob
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var describeKeyPhrasesDetectionJob* = Call_DescribeKeyPhrasesDetectionJob_606451(
    name: "describeKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeKeyPhrasesDetectionJob",
    validator: validate_DescribeKeyPhrasesDetectionJob_606452, base: "/",
    url: url_DescribeKeyPhrasesDetectionJob_606453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSentimentDetectionJob_606466 = ref object of OpenApiRestCall_605589
proc url_DescribeSentimentDetectionJob_606468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSentimentDetectionJob_606467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeSentimentDetectionJob"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_DescribeSentimentDetectionJob_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_DescribeSentimentDetectionJob_606466; body: JsonNode): Recallable =
  ## describeSentimentDetectionJob
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var describeSentimentDetectionJob* = Call_DescribeSentimentDetectionJob_606466(
    name: "describeSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeSentimentDetectionJob",
    validator: validate_DescribeSentimentDetectionJob_606467, base: "/",
    url: url_DescribeSentimentDetectionJob_606468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTopicsDetectionJob_606481 = ref object of OpenApiRestCall_605589
proc url_DescribeTopicsDetectionJob_606483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTopicsDetectionJob_606482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeTopicsDetectionJob"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_DescribeTopicsDetectionJob_606481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_DescribeTopicsDetectionJob_606481; body: JsonNode): Recallable =
  ## describeTopicsDetectionJob
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var describeTopicsDetectionJob* = Call_DescribeTopicsDetectionJob_606481(
    name: "describeTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeTopicsDetectionJob",
    validator: validate_DescribeTopicsDetectionJob_606482, base: "/",
    url: url_DescribeTopicsDetectionJob_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectDominantLanguage_606496 = ref object of OpenApiRestCall_605589
proc url_DetectDominantLanguage_606498(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectDominantLanguage_606497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectDominantLanguage"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_DetectDominantLanguage_606496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_DetectDominantLanguage_606496; body: JsonNode): Recallable =
  ## detectDominantLanguage
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var detectDominantLanguage* = Call_DetectDominantLanguage_606496(
    name: "detectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectDominantLanguage",
    validator: validate_DetectDominantLanguage_606497, base: "/",
    url: url_DetectDominantLanguage_606498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectEntities_606511 = ref object of OpenApiRestCall_605589
proc url_DetectEntities_606513(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectEntities_606512(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectEntities"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_DetectEntities_606511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_DetectEntities_606511; body: JsonNode): Recallable =
  ## detectEntities
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var detectEntities* = Call_DetectEntities_606511(name: "detectEntities",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectEntities",
    validator: validate_DetectEntities_606512, base: "/", url: url_DetectEntities_606513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectKeyPhrases_606526 = ref object of OpenApiRestCall_605589
proc url_DetectKeyPhrases_606528(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectKeyPhrases_606527(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Detects the key noun phrases found in the text. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectKeyPhrases"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DetectKeyPhrases_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in the text. 
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DetectKeyPhrases_606526; body: JsonNode): Recallable =
  ## detectKeyPhrases
  ## Detects the key noun phrases found in the text. 
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var detectKeyPhrases* = Call_DetectKeyPhrases_606526(name: "detectKeyPhrases",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectKeyPhrases",
    validator: validate_DetectKeyPhrases_606527, base: "/",
    url: url_DetectKeyPhrases_606528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSentiment_606541 = ref object of OpenApiRestCall_605589
proc url_DetectSentiment_606543(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectSentiment_606542(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSentiment"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_DetectSentiment_606541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_DetectSentiment_606541; body: JsonNode): Recallable =
  ## detectSentiment
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var detectSentiment* = Call_DetectSentiment_606541(name: "detectSentiment",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSentiment",
    validator: validate_DetectSentiment_606542, base: "/", url: url_DetectSentiment_606543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSyntax_606556 = ref object of OpenApiRestCall_605589
proc url_DetectSyntax_606558(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectSyntax_606557(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSyntax"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_DetectSyntax_606556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_DetectSyntax_606556; body: JsonNode): Recallable =
  ## detectSyntax
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var detectSyntax* = Call_DetectSyntax_606556(name: "detectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSyntax",
    validator: validate_DetectSyntax_606557, base: "/", url: url_DetectSyntax_606558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassificationJobs_606571 = ref object of OpenApiRestCall_605589
proc url_ListDocumentClassificationJobs_606573(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentClassificationJobs_606572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606574 = query.getOrDefault("MaxResults")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "MaxResults", valid_606574
  var valid_606575 = query.getOrDefault("NextToken")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "NextToken", valid_606575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606576 = header.getOrDefault("X-Amz-Target")
  valid_606576 = validateParameter(valid_606576, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassificationJobs"))
  if valid_606576 != nil:
    section.add "X-Amz-Target", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Signature")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Signature", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Content-Sha256", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Date")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Date", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Credential")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Credential", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Security-Token")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Security-Token", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Algorithm")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Algorithm", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-SignedHeaders", valid_606583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606585: Call_ListDocumentClassificationJobs_606571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  let valid = call_606585.validator(path, query, header, formData, body)
  let scheme = call_606585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606585.url(scheme.get, call_606585.host, call_606585.base,
                         call_606585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606585, url, valid)

proc call*(call_606586: Call_ListDocumentClassificationJobs_606571; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocumentClassificationJobs
  ## Gets a list of the documentation classification jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606587 = newJObject()
  var body_606588 = newJObject()
  add(query_606587, "MaxResults", newJString(MaxResults))
  add(query_606587, "NextToken", newJString(NextToken))
  if body != nil:
    body_606588 = body
  result = call_606586.call(nil, query_606587, nil, nil, body_606588)

var listDocumentClassificationJobs* = Call_ListDocumentClassificationJobs_606571(
    name: "listDocumentClassificationJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassificationJobs",
    validator: validate_ListDocumentClassificationJobs_606572, base: "/",
    url: url_ListDocumentClassificationJobs_606573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassifiers_606590 = ref object of OpenApiRestCall_605589
proc url_ListDocumentClassifiers_606592(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentClassifiers_606591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the document classifiers that you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606593 = query.getOrDefault("MaxResults")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "MaxResults", valid_606593
  var valid_606594 = query.getOrDefault("NextToken")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "NextToken", valid_606594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606595 = header.getOrDefault("X-Amz-Target")
  valid_606595 = validateParameter(valid_606595, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassifiers"))
  if valid_606595 != nil:
    section.add "X-Amz-Target", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Signature")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Signature", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Content-Sha256", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Date")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Date", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Credential")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Credential", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Security-Token")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Security-Token", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Algorithm")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Algorithm", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-SignedHeaders", valid_606602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606604: Call_ListDocumentClassifiers_606590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the document classifiers that you have created.
  ## 
  let valid = call_606604.validator(path, query, header, formData, body)
  let scheme = call_606604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606604.url(scheme.get, call_606604.host, call_606604.base,
                         call_606604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606604, url, valid)

proc call*(call_606605: Call_ListDocumentClassifiers_606590; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocumentClassifiers
  ## Gets a list of the document classifiers that you have created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606606 = newJObject()
  var body_606607 = newJObject()
  add(query_606606, "MaxResults", newJString(MaxResults))
  add(query_606606, "NextToken", newJString(NextToken))
  if body != nil:
    body_606607 = body
  result = call_606605.call(nil, query_606606, nil, nil, body_606607)

var listDocumentClassifiers* = Call_ListDocumentClassifiers_606590(
    name: "listDocumentClassifiers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassifiers",
    validator: validate_ListDocumentClassifiers_606591, base: "/",
    url: url_ListDocumentClassifiers_606592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDominantLanguageDetectionJobs_606608 = ref object of OpenApiRestCall_605589
proc url_ListDominantLanguageDetectionJobs_606610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDominantLanguageDetectionJobs_606609(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606611 = query.getOrDefault("MaxResults")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "MaxResults", valid_606611
  var valid_606612 = query.getOrDefault("NextToken")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "NextToken", valid_606612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606613 = header.getOrDefault("X-Amz-Target")
  valid_606613 = validateParameter(valid_606613, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDominantLanguageDetectionJobs"))
  if valid_606613 != nil:
    section.add "X-Amz-Target", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Signature")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Signature", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Content-Sha256", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Date")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Date", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Credential")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Credential", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Security-Token")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Security-Token", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Algorithm")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Algorithm", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-SignedHeaders", valid_606620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606622: Call_ListDominantLanguageDetectionJobs_606608;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  let valid = call_606622.validator(path, query, header, formData, body)
  let scheme = call_606622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606622.url(scheme.get, call_606622.host, call_606622.base,
                         call_606622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606622, url, valid)

proc call*(call_606623: Call_ListDominantLanguageDetectionJobs_606608;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDominantLanguageDetectionJobs
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606624 = newJObject()
  var body_606625 = newJObject()
  add(query_606624, "MaxResults", newJString(MaxResults))
  add(query_606624, "NextToken", newJString(NextToken))
  if body != nil:
    body_606625 = body
  result = call_606623.call(nil, query_606624, nil, nil, body_606625)

var listDominantLanguageDetectionJobs* = Call_ListDominantLanguageDetectionJobs_606608(
    name: "listDominantLanguageDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.ListDominantLanguageDetectionJobs",
    validator: validate_ListDominantLanguageDetectionJobs_606609, base: "/",
    url: url_ListDominantLanguageDetectionJobs_606610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_606626 = ref object of OpenApiRestCall_605589
proc url_ListEndpoints_606628(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_606627(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of all existing endpoints that you've created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606629 = header.getOrDefault("X-Amz-Target")
  valid_606629 = validateParameter(valid_606629, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEndpoints"))
  if valid_606629 != nil:
    section.add "X-Amz-Target", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Signature")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Signature", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Content-Sha256", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Date")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Date", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Credential")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Credential", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Security-Token")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Security-Token", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Algorithm")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Algorithm", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-SignedHeaders", valid_606636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606638: Call_ListEndpoints_606626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all existing endpoints that you've created.
  ## 
  let valid = call_606638.validator(path, query, header, formData, body)
  let scheme = call_606638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606638.url(scheme.get, call_606638.host, call_606638.base,
                         call_606638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606638, url, valid)

proc call*(call_606639: Call_ListEndpoints_606626; body: JsonNode): Recallable =
  ## listEndpoints
  ## Gets a list of all existing endpoints that you've created.
  ##   body: JObject (required)
  var body_606640 = newJObject()
  if body != nil:
    body_606640 = body
  result = call_606639.call(nil, nil, nil, nil, body_606640)

var listEndpoints* = Call_ListEndpoints_606626(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEndpoints",
    validator: validate_ListEndpoints_606627, base: "/", url: url_ListEndpoints_606628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitiesDetectionJobs_606641 = ref object of OpenApiRestCall_605589
proc url_ListEntitiesDetectionJobs_606643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntitiesDetectionJobs_606642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606644 = query.getOrDefault("MaxResults")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "MaxResults", valid_606644
  var valid_606645 = query.getOrDefault("NextToken")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "NextToken", valid_606645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606646 = header.getOrDefault("X-Amz-Target")
  valid_606646 = validateParameter(valid_606646, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntitiesDetectionJobs"))
  if valid_606646 != nil:
    section.add "X-Amz-Target", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Signature")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Signature", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Content-Sha256", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Date")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Date", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Credential")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Credential", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Security-Token")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Security-Token", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Algorithm")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Algorithm", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-SignedHeaders", valid_606653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606655: Call_ListEntitiesDetectionJobs_606641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  let valid = call_606655.validator(path, query, header, formData, body)
  let scheme = call_606655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606655.url(scheme.get, call_606655.host, call_606655.base,
                         call_606655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606655, url, valid)

proc call*(call_606656: Call_ListEntitiesDetectionJobs_606641; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntitiesDetectionJobs
  ## Gets a list of the entity detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606657 = newJObject()
  var body_606658 = newJObject()
  add(query_606657, "MaxResults", newJString(MaxResults))
  add(query_606657, "NextToken", newJString(NextToken))
  if body != nil:
    body_606658 = body
  result = call_606656.call(nil, query_606657, nil, nil, body_606658)

var listEntitiesDetectionJobs* = Call_ListEntitiesDetectionJobs_606641(
    name: "listEntitiesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntitiesDetectionJobs",
    validator: validate_ListEntitiesDetectionJobs_606642, base: "/",
    url: url_ListEntitiesDetectionJobs_606643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntityRecognizers_606659 = ref object of OpenApiRestCall_605589
proc url_ListEntityRecognizers_606661(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntityRecognizers_606660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606662 = query.getOrDefault("MaxResults")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "MaxResults", valid_606662
  var valid_606663 = query.getOrDefault("NextToken")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "NextToken", valid_606663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606664 = header.getOrDefault("X-Amz-Target")
  valid_606664 = validateParameter(valid_606664, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntityRecognizers"))
  if valid_606664 != nil:
    section.add "X-Amz-Target", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606673: Call_ListEntityRecognizers_606659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  let valid = call_606673.validator(path, query, header, formData, body)
  let scheme = call_606673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606673.url(scheme.get, call_606673.host, call_606673.base,
                         call_606673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606673, url, valid)

proc call*(call_606674: Call_ListEntityRecognizers_606659; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntityRecognizers
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606675 = newJObject()
  var body_606676 = newJObject()
  add(query_606675, "MaxResults", newJString(MaxResults))
  add(query_606675, "NextToken", newJString(NextToken))
  if body != nil:
    body_606676 = body
  result = call_606674.call(nil, query_606675, nil, nil, body_606676)

var listEntityRecognizers* = Call_ListEntityRecognizers_606659(
    name: "listEntityRecognizers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntityRecognizers",
    validator: validate_ListEntityRecognizers_606660, base: "/",
    url: url_ListEntityRecognizers_606661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPhrasesDetectionJobs_606677 = ref object of OpenApiRestCall_605589
proc url_ListKeyPhrasesDetectionJobs_606679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKeyPhrasesDetectionJobs_606678(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606680 = query.getOrDefault("MaxResults")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "MaxResults", valid_606680
  var valid_606681 = query.getOrDefault("NextToken")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "NextToken", valid_606681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606682 = header.getOrDefault("X-Amz-Target")
  valid_606682 = validateParameter(valid_606682, JString, required = true, default = newJString(
      "Comprehend_20171127.ListKeyPhrasesDetectionJobs"))
  if valid_606682 != nil:
    section.add "X-Amz-Target", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Signature")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Signature", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Content-Sha256", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Date")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Date", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Credential")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Credential", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Security-Token")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Security-Token", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Algorithm")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Algorithm", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-SignedHeaders", valid_606689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606691: Call_ListKeyPhrasesDetectionJobs_606677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  let valid = call_606691.validator(path, query, header, formData, body)
  let scheme = call_606691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606691.url(scheme.get, call_606691.host, call_606691.base,
                         call_606691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606691, url, valid)

proc call*(call_606692: Call_ListKeyPhrasesDetectionJobs_606677; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listKeyPhrasesDetectionJobs
  ## Get a list of key phrase detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606693 = newJObject()
  var body_606694 = newJObject()
  add(query_606693, "MaxResults", newJString(MaxResults))
  add(query_606693, "NextToken", newJString(NextToken))
  if body != nil:
    body_606694 = body
  result = call_606692.call(nil, query_606693, nil, nil, body_606694)

var listKeyPhrasesDetectionJobs* = Call_ListKeyPhrasesDetectionJobs_606677(
    name: "listKeyPhrasesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListKeyPhrasesDetectionJobs",
    validator: validate_ListKeyPhrasesDetectionJobs_606678, base: "/",
    url: url_ListKeyPhrasesDetectionJobs_606679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSentimentDetectionJobs_606695 = ref object of OpenApiRestCall_605589
proc url_ListSentimentDetectionJobs_606697(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSentimentDetectionJobs_606696(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606698 = query.getOrDefault("MaxResults")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "MaxResults", valid_606698
  var valid_606699 = query.getOrDefault("NextToken")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "NextToken", valid_606699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606700 = header.getOrDefault("X-Amz-Target")
  valid_606700 = validateParameter(valid_606700, JString, required = true, default = newJString(
      "Comprehend_20171127.ListSentimentDetectionJobs"))
  if valid_606700 != nil:
    section.add "X-Amz-Target", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Signature")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Signature", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Content-Sha256", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Date")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Date", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Credential")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Credential", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Security-Token")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Security-Token", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Algorithm")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Algorithm", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-SignedHeaders", valid_606707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606709: Call_ListSentimentDetectionJobs_606695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  let valid = call_606709.validator(path, query, header, formData, body)
  let scheme = call_606709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606709.url(scheme.get, call_606709.host, call_606709.base,
                         call_606709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606709, url, valid)

proc call*(call_606710: Call_ListSentimentDetectionJobs_606695; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSentimentDetectionJobs
  ## Gets a list of sentiment detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606711 = newJObject()
  var body_606712 = newJObject()
  add(query_606711, "MaxResults", newJString(MaxResults))
  add(query_606711, "NextToken", newJString(NextToken))
  if body != nil:
    body_606712 = body
  result = call_606710.call(nil, query_606711, nil, nil, body_606712)

var listSentimentDetectionJobs* = Call_ListSentimentDetectionJobs_606695(
    name: "listSentimentDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListSentimentDetectionJobs",
    validator: validate_ListSentimentDetectionJobs_606696, base: "/",
    url: url_ListSentimentDetectionJobs_606697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606713 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606715(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_606714(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606716 = header.getOrDefault("X-Amz-Target")
  valid_606716 = validateParameter(valid_606716, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTagsForResource"))
  if valid_606716 != nil:
    section.add "X-Amz-Target", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Signature")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Signature", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Content-Sha256", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Date")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Date", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Credential")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Credential", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Security-Token")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Security-Token", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Algorithm")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Algorithm", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-SignedHeaders", valid_606723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606725: Call_ListTagsForResource_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  let valid = call_606725.validator(path, query, header, formData, body)
  let scheme = call_606725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606725.url(scheme.get, call_606725.host, call_606725.base,
                         call_606725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606725, url, valid)

proc call*(call_606726: Call_ListTagsForResource_606713; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_606727 = newJObject()
  if body != nil:
    body_606727 = body
  result = call_606726.call(nil, nil, nil, nil, body_606727)

var listTagsForResource* = Call_ListTagsForResource_606713(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTagsForResource",
    validator: validate_ListTagsForResource_606714, base: "/",
    url: url_ListTagsForResource_606715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTopicsDetectionJobs_606728 = ref object of OpenApiRestCall_605589
proc url_ListTopicsDetectionJobs_606730(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTopicsDetectionJobs_606729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606731 = query.getOrDefault("MaxResults")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "MaxResults", valid_606731
  var valid_606732 = query.getOrDefault("NextToken")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "NextToken", valid_606732
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606733 = header.getOrDefault("X-Amz-Target")
  valid_606733 = validateParameter(valid_606733, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTopicsDetectionJobs"))
  if valid_606733 != nil:
    section.add "X-Amz-Target", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Signature")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Signature", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Content-Sha256", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Date")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Date", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Credential")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Credential", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Security-Token")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Security-Token", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Algorithm")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Algorithm", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-SignedHeaders", valid_606740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606742: Call_ListTopicsDetectionJobs_606728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  let valid = call_606742.validator(path, query, header, formData, body)
  let scheme = call_606742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606742.url(scheme.get, call_606742.host, call_606742.base,
                         call_606742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606742, url, valid)

proc call*(call_606743: Call_ListTopicsDetectionJobs_606728; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTopicsDetectionJobs
  ## Gets a list of the topic detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606744 = newJObject()
  var body_606745 = newJObject()
  add(query_606744, "MaxResults", newJString(MaxResults))
  add(query_606744, "NextToken", newJString(NextToken))
  if body != nil:
    body_606745 = body
  result = call_606743.call(nil, query_606744, nil, nil, body_606745)

var listTopicsDetectionJobs* = Call_ListTopicsDetectionJobs_606728(
    name: "listTopicsDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTopicsDetectionJobs",
    validator: validate_ListTopicsDetectionJobs_606729, base: "/",
    url: url_ListTopicsDetectionJobs_606730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDocumentClassificationJob_606746 = ref object of OpenApiRestCall_605589
proc url_StartDocumentClassificationJob_606748(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDocumentClassificationJob_606747(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606749 = header.getOrDefault("X-Amz-Target")
  valid_606749 = validateParameter(valid_606749, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDocumentClassificationJob"))
  if valid_606749 != nil:
    section.add "X-Amz-Target", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Signature")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Signature", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Content-Sha256", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Date")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Date", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Credential")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Credential", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Security-Token")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Security-Token", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Algorithm")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Algorithm", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-SignedHeaders", valid_606756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606758: Call_StartDocumentClassificationJob_606746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  let valid = call_606758.validator(path, query, header, formData, body)
  let scheme = call_606758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606758.url(scheme.get, call_606758.host, call_606758.base,
                         call_606758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606758, url, valid)

proc call*(call_606759: Call_StartDocumentClassificationJob_606746; body: JsonNode): Recallable =
  ## startDocumentClassificationJob
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ##   body: JObject (required)
  var body_606760 = newJObject()
  if body != nil:
    body_606760 = body
  result = call_606759.call(nil, nil, nil, nil, body_606760)

var startDocumentClassificationJob* = Call_StartDocumentClassificationJob_606746(
    name: "startDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartDocumentClassificationJob",
    validator: validate_StartDocumentClassificationJob_606747, base: "/",
    url: url_StartDocumentClassificationJob_606748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDominantLanguageDetectionJob_606761 = ref object of OpenApiRestCall_605589
proc url_StartDominantLanguageDetectionJob_606763(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDominantLanguageDetectionJob_606762(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606764 = header.getOrDefault("X-Amz-Target")
  valid_606764 = validateParameter(valid_606764, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDominantLanguageDetectionJob"))
  if valid_606764 != nil:
    section.add "X-Amz-Target", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Signature")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Signature", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Content-Sha256", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Date")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Date", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Credential")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Credential", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Security-Token")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Security-Token", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Algorithm")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Algorithm", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-SignedHeaders", valid_606771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606773: Call_StartDominantLanguageDetectionJob_606761;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_606773.validator(path, query, header, formData, body)
  let scheme = call_606773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606773.url(scheme.get, call_606773.host, call_606773.base,
                         call_606773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606773, url, valid)

proc call*(call_606774: Call_StartDominantLanguageDetectionJob_606761;
          body: JsonNode): Recallable =
  ## startDominantLanguageDetectionJob
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_606775 = newJObject()
  if body != nil:
    body_606775 = body
  result = call_606774.call(nil, nil, nil, nil, body_606775)

var startDominantLanguageDetectionJob* = Call_StartDominantLanguageDetectionJob_606761(
    name: "startDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StartDominantLanguageDetectionJob",
    validator: validate_StartDominantLanguageDetectionJob_606762, base: "/",
    url: url_StartDominantLanguageDetectionJob_606763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartEntitiesDetectionJob_606776 = ref object of OpenApiRestCall_605589
proc url_StartEntitiesDetectionJob_606778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartEntitiesDetectionJob_606777(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606779 = header.getOrDefault("X-Amz-Target")
  valid_606779 = validateParameter(valid_606779, JString, required = true, default = newJString(
      "Comprehend_20171127.StartEntitiesDetectionJob"))
  if valid_606779 != nil:
    section.add "X-Amz-Target", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Signature")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Signature", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Content-Sha256", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Date")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Date", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Credential")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Credential", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Security-Token")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Security-Token", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Algorithm")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Algorithm", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-SignedHeaders", valid_606786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606788: Call_StartEntitiesDetectionJob_606776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  let valid = call_606788.validator(path, query, header, formData, body)
  let scheme = call_606788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606788.url(scheme.get, call_606788.host, call_606788.base,
                         call_606788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606788, url, valid)

proc call*(call_606789: Call_StartEntitiesDetectionJob_606776; body: JsonNode): Recallable =
  ## startEntitiesDetectionJob
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ##   body: JObject (required)
  var body_606790 = newJObject()
  if body != nil:
    body_606790 = body
  result = call_606789.call(nil, nil, nil, nil, body_606790)

var startEntitiesDetectionJob* = Call_StartEntitiesDetectionJob_606776(
    name: "startEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartEntitiesDetectionJob",
    validator: validate_StartEntitiesDetectionJob_606777, base: "/",
    url: url_StartEntitiesDetectionJob_606778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartKeyPhrasesDetectionJob_606791 = ref object of OpenApiRestCall_605589
proc url_StartKeyPhrasesDetectionJob_606793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartKeyPhrasesDetectionJob_606792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606794 = header.getOrDefault("X-Amz-Target")
  valid_606794 = validateParameter(valid_606794, JString, required = true, default = newJString(
      "Comprehend_20171127.StartKeyPhrasesDetectionJob"))
  if valid_606794 != nil:
    section.add "X-Amz-Target", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Signature")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Signature", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Content-Sha256", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Date")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Date", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Credential")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Credential", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Security-Token")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Security-Token", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Algorithm")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Algorithm", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-SignedHeaders", valid_606801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606803: Call_StartKeyPhrasesDetectionJob_606791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_606803.validator(path, query, header, formData, body)
  let scheme = call_606803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606803.url(scheme.get, call_606803.host, call_606803.base,
                         call_606803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606803, url, valid)

proc call*(call_606804: Call_StartKeyPhrasesDetectionJob_606791; body: JsonNode): Recallable =
  ## startKeyPhrasesDetectionJob
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_606805 = newJObject()
  if body != nil:
    body_606805 = body
  result = call_606804.call(nil, nil, nil, nil, body_606805)

var startKeyPhrasesDetectionJob* = Call_StartKeyPhrasesDetectionJob_606791(
    name: "startKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartKeyPhrasesDetectionJob",
    validator: validate_StartKeyPhrasesDetectionJob_606792, base: "/",
    url: url_StartKeyPhrasesDetectionJob_606793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSentimentDetectionJob_606806 = ref object of OpenApiRestCall_605589
proc url_StartSentimentDetectionJob_606808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSentimentDetectionJob_606807(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606809 = header.getOrDefault("X-Amz-Target")
  valid_606809 = validateParameter(valid_606809, JString, required = true, default = newJString(
      "Comprehend_20171127.StartSentimentDetectionJob"))
  if valid_606809 != nil:
    section.add "X-Amz-Target", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Signature")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Signature", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Content-Sha256", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Date")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Date", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Credential")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Credential", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Security-Token")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Security-Token", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Algorithm")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Algorithm", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-SignedHeaders", valid_606816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_StartSentimentDetectionJob_606806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_StartSentimentDetectionJob_606806; body: JsonNode): Recallable =
  ## startSentimentDetectionJob
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_606820 = newJObject()
  if body != nil:
    body_606820 = body
  result = call_606819.call(nil, nil, nil, nil, body_606820)

var startSentimentDetectionJob* = Call_StartSentimentDetectionJob_606806(
    name: "startSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartSentimentDetectionJob",
    validator: validate_StartSentimentDetectionJob_606807, base: "/",
    url: url_StartSentimentDetectionJob_606808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTopicsDetectionJob_606821 = ref object of OpenApiRestCall_605589
proc url_StartTopicsDetectionJob_606823(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTopicsDetectionJob_606822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606824 = header.getOrDefault("X-Amz-Target")
  valid_606824 = validateParameter(valid_606824, JString, required = true, default = newJString(
      "Comprehend_20171127.StartTopicsDetectionJob"))
  if valid_606824 != nil:
    section.add "X-Amz-Target", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Signature")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Signature", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Content-Sha256", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Date")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Date", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Credential")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Credential", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Security-Token")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Security-Token", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Algorithm")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Algorithm", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-SignedHeaders", valid_606831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606833: Call_StartTopicsDetectionJob_606821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  let valid = call_606833.validator(path, query, header, formData, body)
  let scheme = call_606833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606833.url(scheme.get, call_606833.host, call_606833.base,
                         call_606833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606833, url, valid)

proc call*(call_606834: Call_StartTopicsDetectionJob_606821; body: JsonNode): Recallable =
  ## startTopicsDetectionJob
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ##   body: JObject (required)
  var body_606835 = newJObject()
  if body != nil:
    body_606835 = body
  result = call_606834.call(nil, nil, nil, nil, body_606835)

var startTopicsDetectionJob* = Call_StartTopicsDetectionJob_606821(
    name: "startTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartTopicsDetectionJob",
    validator: validate_StartTopicsDetectionJob_606822, base: "/",
    url: url_StartTopicsDetectionJob_606823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDominantLanguageDetectionJob_606836 = ref object of OpenApiRestCall_605589
proc url_StopDominantLanguageDetectionJob_606838(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDominantLanguageDetectionJob_606837(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606839 = header.getOrDefault("X-Amz-Target")
  valid_606839 = validateParameter(valid_606839, JString, required = true, default = newJString(
      "Comprehend_20171127.StopDominantLanguageDetectionJob"))
  if valid_606839 != nil:
    section.add "X-Amz-Target", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Signature")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Signature", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Content-Sha256", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Date")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Date", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Credential")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Credential", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Security-Token")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Security-Token", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Algorithm")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Algorithm", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-SignedHeaders", valid_606846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606848: Call_StopDominantLanguageDetectionJob_606836;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_StopDominantLanguageDetectionJob_606836;
          body: JsonNode): Recallable =
  ## stopDominantLanguageDetectionJob
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_606850 = newJObject()
  if body != nil:
    body_606850 = body
  result = call_606849.call(nil, nil, nil, nil, body_606850)

var stopDominantLanguageDetectionJob* = Call_StopDominantLanguageDetectionJob_606836(
    name: "stopDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StopDominantLanguageDetectionJob",
    validator: validate_StopDominantLanguageDetectionJob_606837, base: "/",
    url: url_StopDominantLanguageDetectionJob_606838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopEntitiesDetectionJob_606851 = ref object of OpenApiRestCall_605589
proc url_StopEntitiesDetectionJob_606853(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopEntitiesDetectionJob_606852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606854 = header.getOrDefault("X-Amz-Target")
  valid_606854 = validateParameter(valid_606854, JString, required = true, default = newJString(
      "Comprehend_20171127.StopEntitiesDetectionJob"))
  if valid_606854 != nil:
    section.add "X-Amz-Target", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Signature")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Signature", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Content-Sha256", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Date")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Date", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Credential")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Credential", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Security-Token")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Security-Token", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Algorithm")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Algorithm", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-SignedHeaders", valid_606861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606863: Call_StopEntitiesDetectionJob_606851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_606863.validator(path, query, header, formData, body)
  let scheme = call_606863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606863.url(scheme.get, call_606863.host, call_606863.base,
                         call_606863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606863, url, valid)

proc call*(call_606864: Call_StopEntitiesDetectionJob_606851; body: JsonNode): Recallable =
  ## stopEntitiesDetectionJob
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_606865 = newJObject()
  if body != nil:
    body_606865 = body
  result = call_606864.call(nil, nil, nil, nil, body_606865)

var stopEntitiesDetectionJob* = Call_StopEntitiesDetectionJob_606851(
    name: "stopEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopEntitiesDetectionJob",
    validator: validate_StopEntitiesDetectionJob_606852, base: "/",
    url: url_StopEntitiesDetectionJob_606853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopKeyPhrasesDetectionJob_606866 = ref object of OpenApiRestCall_605589
proc url_StopKeyPhrasesDetectionJob_606868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopKeyPhrasesDetectionJob_606867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606869 = header.getOrDefault("X-Amz-Target")
  valid_606869 = validateParameter(valid_606869, JString, required = true, default = newJString(
      "Comprehend_20171127.StopKeyPhrasesDetectionJob"))
  if valid_606869 != nil:
    section.add "X-Amz-Target", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Signature")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Signature", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Content-Sha256", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Date")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Date", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Credential")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Credential", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Security-Token")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Security-Token", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Algorithm")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Algorithm", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-SignedHeaders", valid_606876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606878: Call_StopKeyPhrasesDetectionJob_606866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_606878.validator(path, query, header, formData, body)
  let scheme = call_606878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606878.url(scheme.get, call_606878.host, call_606878.base,
                         call_606878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606878, url, valid)

proc call*(call_606879: Call_StopKeyPhrasesDetectionJob_606866; body: JsonNode): Recallable =
  ## stopKeyPhrasesDetectionJob
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_606880 = newJObject()
  if body != nil:
    body_606880 = body
  result = call_606879.call(nil, nil, nil, nil, body_606880)

var stopKeyPhrasesDetectionJob* = Call_StopKeyPhrasesDetectionJob_606866(
    name: "stopKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopKeyPhrasesDetectionJob",
    validator: validate_StopKeyPhrasesDetectionJob_606867, base: "/",
    url: url_StopKeyPhrasesDetectionJob_606868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopSentimentDetectionJob_606881 = ref object of OpenApiRestCall_605589
proc url_StopSentimentDetectionJob_606883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopSentimentDetectionJob_606882(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606884 = header.getOrDefault("X-Amz-Target")
  valid_606884 = validateParameter(valid_606884, JString, required = true, default = newJString(
      "Comprehend_20171127.StopSentimentDetectionJob"))
  if valid_606884 != nil:
    section.add "X-Amz-Target", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Signature")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Signature", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Content-Sha256", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Date")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Date", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Credential")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Credential", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Security-Token")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Security-Token", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Algorithm")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Algorithm", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-SignedHeaders", valid_606891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606893: Call_StopSentimentDetectionJob_606881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_606893.validator(path, query, header, formData, body)
  let scheme = call_606893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606893.url(scheme.get, call_606893.host, call_606893.base,
                         call_606893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606893, url, valid)

proc call*(call_606894: Call_StopSentimentDetectionJob_606881; body: JsonNode): Recallable =
  ## stopSentimentDetectionJob
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_606895 = newJObject()
  if body != nil:
    body_606895 = body
  result = call_606894.call(nil, nil, nil, nil, body_606895)

var stopSentimentDetectionJob* = Call_StopSentimentDetectionJob_606881(
    name: "stopSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopSentimentDetectionJob",
    validator: validate_StopSentimentDetectionJob_606882, base: "/",
    url: url_StopSentimentDetectionJob_606883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingDocumentClassifier_606896 = ref object of OpenApiRestCall_605589
proc url_StopTrainingDocumentClassifier_606898(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingDocumentClassifier_606897(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606899 = header.getOrDefault("X-Amz-Target")
  valid_606899 = validateParameter(valid_606899, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingDocumentClassifier"))
  if valid_606899 != nil:
    section.add "X-Amz-Target", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Signature")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Signature", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Content-Sha256", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Date")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Date", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Credential")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Credential", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Security-Token")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Security-Token", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Algorithm")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Algorithm", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-SignedHeaders", valid_606906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606908: Call_StopTrainingDocumentClassifier_606896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  let valid = call_606908.validator(path, query, header, formData, body)
  let scheme = call_606908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606908.url(scheme.get, call_606908.host, call_606908.base,
                         call_606908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606908, url, valid)

proc call*(call_606909: Call_StopTrainingDocumentClassifier_606896; body: JsonNode): Recallable =
  ## stopTrainingDocumentClassifier
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ##   body: JObject (required)
  var body_606910 = newJObject()
  if body != nil:
    body_606910 = body
  result = call_606909.call(nil, nil, nil, nil, body_606910)

var stopTrainingDocumentClassifier* = Call_StopTrainingDocumentClassifier_606896(
    name: "stopTrainingDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingDocumentClassifier",
    validator: validate_StopTrainingDocumentClassifier_606897, base: "/",
    url: url_StopTrainingDocumentClassifier_606898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingEntityRecognizer_606911 = ref object of OpenApiRestCall_605589
proc url_StopTrainingEntityRecognizer_606913(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingEntityRecognizer_606912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606914 = header.getOrDefault("X-Amz-Target")
  valid_606914 = validateParameter(valid_606914, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingEntityRecognizer"))
  if valid_606914 != nil:
    section.add "X-Amz-Target", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Signature")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Signature", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Content-Sha256", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Date")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Date", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Credential")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Credential", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Security-Token")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Security-Token", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Algorithm")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Algorithm", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-SignedHeaders", valid_606921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606923: Call_StopTrainingEntityRecognizer_606911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  let valid = call_606923.validator(path, query, header, formData, body)
  let scheme = call_606923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606923.url(scheme.get, call_606923.host, call_606923.base,
                         call_606923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606923, url, valid)

proc call*(call_606924: Call_StopTrainingEntityRecognizer_606911; body: JsonNode): Recallable =
  ## stopTrainingEntityRecognizer
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ##   body: JObject (required)
  var body_606925 = newJObject()
  if body != nil:
    body_606925 = body
  result = call_606924.call(nil, nil, nil, nil, body_606925)

var stopTrainingEntityRecognizer* = Call_StopTrainingEntityRecognizer_606911(
    name: "stopTrainingEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingEntityRecognizer",
    validator: validate_StopTrainingEntityRecognizer_606912, base: "/",
    url: url_StopTrainingEntityRecognizer_606913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606926 = ref object of OpenApiRestCall_605589
proc url_TagResource_606928(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_606927(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606929 = header.getOrDefault("X-Amz-Target")
  valid_606929 = validateParameter(valid_606929, JString, required = true, default = newJString(
      "Comprehend_20171127.TagResource"))
  if valid_606929 != nil:
    section.add "X-Amz-Target", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Signature")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Signature", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Content-Sha256", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Date")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Date", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Credential")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Credential", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Security-Token")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Security-Token", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Algorithm")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Algorithm", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-SignedHeaders", valid_606936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606938: Call_TagResource_606926; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  let valid = call_606938.validator(path, query, header, formData, body)
  let scheme = call_606938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606938.url(scheme.get, call_606938.host, call_606938.base,
                         call_606938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606938, url, valid)

proc call*(call_606939: Call_TagResource_606926; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ##   body: JObject (required)
  var body_606940 = newJObject()
  if body != nil:
    body_606940 = body
  result = call_606939.call(nil, nil, nil, nil, body_606940)

var tagResource* = Call_TagResource_606926(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.TagResource",
                                        validator: validate_TagResource_606927,
                                        base: "/", url: url_TagResource_606928,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606941 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606943(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_606942(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606944 = header.getOrDefault("X-Amz-Target")
  valid_606944 = validateParameter(valid_606944, JString, required = true, default = newJString(
      "Comprehend_20171127.UntagResource"))
  if valid_606944 != nil:
    section.add "X-Amz-Target", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Signature")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Signature", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Content-Sha256", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Date")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Date", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Credential")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Credential", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Security-Token")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Security-Token", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Algorithm")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Algorithm", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-SignedHeaders", valid_606951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606953: Call_UntagResource_606941; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  let valid = call_606953.validator(path, query, header, formData, body)
  let scheme = call_606953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606953.url(scheme.get, call_606953.host, call_606953.base,
                         call_606953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606953, url, valid)

proc call*(call_606954: Call_UntagResource_606941; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_606955 = newJObject()
  if body != nil:
    body_606955 = body
  result = call_606954.call(nil, nil, nil, nil, body_606955)

var untagResource* = Call_UntagResource_606941(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UntagResource",
    validator: validate_UntagResource_606942, base: "/", url: url_UntagResource_606943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_606956 = ref object of OpenApiRestCall_605589
proc url_UpdateEndpoint_606958(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_606957(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates information about the specified endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606959 = header.getOrDefault("X-Amz-Target")
  valid_606959 = validateParameter(valid_606959, JString, required = true, default = newJString(
      "Comprehend_20171127.UpdateEndpoint"))
  if valid_606959 != nil:
    section.add "X-Amz-Target", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Signature")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Signature", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Content-Sha256", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Date")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Date", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Credential")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Credential", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Security-Token")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Security-Token", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Algorithm")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Algorithm", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-SignedHeaders", valid_606966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606968: Call_UpdateEndpoint_606956; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the specified endpoint.
  ## 
  let valid = call_606968.validator(path, query, header, formData, body)
  let scheme = call_606968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606968.url(scheme.get, call_606968.host, call_606968.base,
                         call_606968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606968, url, valid)

proc call*(call_606969: Call_UpdateEndpoint_606956; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Updates information about the specified endpoint.
  ##   body: JObject (required)
  var body_606970 = newJObject()
  if body != nil:
    body_606970 = body
  result = call_606969.call(nil, nil, nil, nil, body_606970)

var updateEndpoint* = Call_UpdateEndpoint_606956(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UpdateEndpoint",
    validator: validate_UpdateEndpoint_606957, base: "/", url: url_UpdateEndpoint_606958,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
