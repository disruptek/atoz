
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchDetectDominantLanguage_600768 = ref object of OpenApiRestCall_600426
proc url_BatchDetectDominantLanguage_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDetectDominantLanguage_600769(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectDominantLanguage"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_BatchDetectDominantLanguage_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_BatchDetectDominantLanguage_600768; body: JsonNode): Recallable =
  ## batchDetectDominantLanguage
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var batchDetectDominantLanguage* = Call_BatchDetectDominantLanguage_600768(
    name: "batchDetectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectDominantLanguage",
    validator: validate_BatchDetectDominantLanguage_600769, base: "/",
    url: url_BatchDetectDominantLanguage_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectEntities_601037 = ref object of OpenApiRestCall_600426
proc url_BatchDetectEntities_601039(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDetectEntities_601038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectEntities"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchDetectEntities_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchDetectEntities_601037; body: JsonNode): Recallable =
  ## batchDetectEntities
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchDetectEntities* = Call_BatchDetectEntities_601037(
    name: "batchDetectEntities", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectEntities",
    validator: validate_BatchDetectEntities_601038, base: "/",
    url: url_BatchDetectEntities_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectKeyPhrases_601052 = ref object of OpenApiRestCall_600426
proc url_BatchDetectKeyPhrases_601054(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDetectKeyPhrases_601053(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectKeyPhrases"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_BatchDetectKeyPhrases_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_BatchDetectKeyPhrases_601052; body: JsonNode): Recallable =
  ## batchDetectKeyPhrases
  ## Detects the key noun phrases found in a batch of documents.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var batchDetectKeyPhrases* = Call_BatchDetectKeyPhrases_601052(
    name: "batchDetectKeyPhrases", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectKeyPhrases",
    validator: validate_BatchDetectKeyPhrases_601053, base: "/",
    url: url_BatchDetectKeyPhrases_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSentiment_601067 = ref object of OpenApiRestCall_600426
proc url_BatchDetectSentiment_601069(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDetectSentiment_601068(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSentiment"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_BatchDetectSentiment_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_BatchDetectSentiment_601067; body: JsonNode): Recallable =
  ## batchDetectSentiment
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var batchDetectSentiment* = Call_BatchDetectSentiment_601067(
    name: "batchDetectSentiment", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSentiment",
    validator: validate_BatchDetectSentiment_601068, base: "/",
    url: url_BatchDetectSentiment_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSyntax_601082 = ref object of OpenApiRestCall_600426
proc url_BatchDetectSyntax_601084(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDetectSyntax_601083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSyntax"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_BatchDetectSyntax_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_BatchDetectSyntax_601082; body: JsonNode): Recallable =
  ## batchDetectSyntax
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var batchDetectSyntax* = Call_BatchDetectSyntax_601082(name: "batchDetectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSyntax",
    validator: validate_BatchDetectSyntax_601083, base: "/",
    url: url_BatchDetectSyntax_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentClassifier_601097 = ref object of OpenApiRestCall_600426
proc url_CreateDocumentClassifier_601099(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDocumentClassifier_601098(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateDocumentClassifier"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_CreateDocumentClassifier_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_CreateDocumentClassifier_601097; body: JsonNode): Recallable =
  ## createDocumentClassifier
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var createDocumentClassifier* = Call_CreateDocumentClassifier_601097(
    name: "createDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateDocumentClassifier",
    validator: validate_CreateDocumentClassifier_601098, base: "/",
    url: url_CreateDocumentClassifier_601099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEntityRecognizer_601112 = ref object of OpenApiRestCall_600426
proc url_CreateEntityRecognizer_601114(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEntityRecognizer_601113(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEntityRecognizer"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_CreateEntityRecognizer_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_CreateEntityRecognizer_601112; body: JsonNode): Recallable =
  ## createEntityRecognizer
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var createEntityRecognizer* = Call_CreateEntityRecognizer_601112(
    name: "createEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEntityRecognizer",
    validator: validate_CreateEntityRecognizer_601113, base: "/",
    url: url_CreateEntityRecognizer_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentClassifier_601127 = ref object of OpenApiRestCall_600426
proc url_DeleteDocumentClassifier_601129(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDocumentClassifier_601128(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteDocumentClassifier"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeleteDocumentClassifier_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeleteDocumentClassifier_601127; body: JsonNode): Recallable =
  ## deleteDocumentClassifier
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deleteDocumentClassifier* = Call_DeleteDocumentClassifier_601127(
    name: "deleteDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteDocumentClassifier",
    validator: validate_DeleteDocumentClassifier_601128, base: "/",
    url: url_DeleteDocumentClassifier_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEntityRecognizer_601142 = ref object of OpenApiRestCall_600426
proc url_DeleteEntityRecognizer_601144(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEntityRecognizer_601143(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEntityRecognizer"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DeleteEntityRecognizer_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DeleteEntityRecognizer_601142; body: JsonNode): Recallable =
  ## deleteEntityRecognizer
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var deleteEntityRecognizer* = Call_DeleteEntityRecognizer_601142(
    name: "deleteEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEntityRecognizer",
    validator: validate_DeleteEntityRecognizer_601143, base: "/",
    url: url_DeleteEntityRecognizer_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassificationJob_601157 = ref object of OpenApiRestCall_600426
proc url_DescribeDocumentClassificationJob_601159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocumentClassificationJob_601158(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassificationJob"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DescribeDocumentClassificationJob_601157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DescribeDocumentClassificationJob_601157;
          body: JsonNode): Recallable =
  ## describeDocumentClassificationJob
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var describeDocumentClassificationJob* = Call_DescribeDocumentClassificationJob_601157(
    name: "describeDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassificationJob",
    validator: validate_DescribeDocumentClassificationJob_601158, base: "/",
    url: url_DescribeDocumentClassificationJob_601159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassifier_601172 = ref object of OpenApiRestCall_600426
proc url_DescribeDocumentClassifier_601174(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocumentClassifier_601173(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassifier"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_DescribeDocumentClassifier_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a document classifier.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DescribeDocumentClassifier_601172; body: JsonNode): Recallable =
  ## describeDocumentClassifier
  ## Gets the properties associated with a document classifier.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var describeDocumentClassifier* = Call_DescribeDocumentClassifier_601172(
    name: "describeDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassifier",
    validator: validate_DescribeDocumentClassifier_601173, base: "/",
    url: url_DescribeDocumentClassifier_601174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDominantLanguageDetectionJob_601187 = ref object of OpenApiRestCall_600426
proc url_DescribeDominantLanguageDetectionJob_601189(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDominantLanguageDetectionJob_601188(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDominantLanguageDetectionJob"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_DescribeDominantLanguageDetectionJob_601187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_DescribeDominantLanguageDetectionJob_601187;
          body: JsonNode): Recallable =
  ## describeDominantLanguageDetectionJob
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var describeDominantLanguageDetectionJob* = Call_DescribeDominantLanguageDetectionJob_601187(
    name: "describeDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDominantLanguageDetectionJob",
    validator: validate_DescribeDominantLanguageDetectionJob_601188, base: "/",
    url: url_DescribeDominantLanguageDetectionJob_601189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntitiesDetectionJob_601202 = ref object of OpenApiRestCall_600426
proc url_DescribeEntitiesDetectionJob_601204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEntitiesDetectionJob_601203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntitiesDetectionJob"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_DescribeEntitiesDetectionJob_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_DescribeEntitiesDetectionJob_601202; body: JsonNode): Recallable =
  ## describeEntitiesDetectionJob
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var describeEntitiesDetectionJob* = Call_DescribeEntitiesDetectionJob_601202(
    name: "describeEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntitiesDetectionJob",
    validator: validate_DescribeEntitiesDetectionJob_601203, base: "/",
    url: url_DescribeEntitiesDetectionJob_601204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityRecognizer_601217 = ref object of OpenApiRestCall_600426
proc url_DescribeEntityRecognizer_601219(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEntityRecognizer_601218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntityRecognizer"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_DescribeEntityRecognizer_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_DescribeEntityRecognizer_601217; body: JsonNode): Recallable =
  ## describeEntityRecognizer
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var describeEntityRecognizer* = Call_DescribeEntityRecognizer_601217(
    name: "describeEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntityRecognizer",
    validator: validate_DescribeEntityRecognizer_601218, base: "/",
    url: url_DescribeEntityRecognizer_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKeyPhrasesDetectionJob_601232 = ref object of OpenApiRestCall_600426
proc url_DescribeKeyPhrasesDetectionJob_601234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeKeyPhrasesDetectionJob_601233(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_DescribeKeyPhrasesDetectionJob_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DescribeKeyPhrasesDetectionJob_601232; body: JsonNode): Recallable =
  ## describeKeyPhrasesDetectionJob
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var describeKeyPhrasesDetectionJob* = Call_DescribeKeyPhrasesDetectionJob_601232(
    name: "describeKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeKeyPhrasesDetectionJob",
    validator: validate_DescribeKeyPhrasesDetectionJob_601233, base: "/",
    url: url_DescribeKeyPhrasesDetectionJob_601234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSentimentDetectionJob_601247 = ref object of OpenApiRestCall_600426
proc url_DescribeSentimentDetectionJob_601249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSentimentDetectionJob_601248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeSentimentDetectionJob"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_DescribeSentimentDetectionJob_601247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_DescribeSentimentDetectionJob_601247; body: JsonNode): Recallable =
  ## describeSentimentDetectionJob
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var describeSentimentDetectionJob* = Call_DescribeSentimentDetectionJob_601247(
    name: "describeSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeSentimentDetectionJob",
    validator: validate_DescribeSentimentDetectionJob_601248, base: "/",
    url: url_DescribeSentimentDetectionJob_601249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTopicsDetectionJob_601262 = ref object of OpenApiRestCall_600426
proc url_DescribeTopicsDetectionJob_601264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTopicsDetectionJob_601263(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeTopicsDetectionJob"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_DescribeTopicsDetectionJob_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_DescribeTopicsDetectionJob_601262; body: JsonNode): Recallable =
  ## describeTopicsDetectionJob
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var describeTopicsDetectionJob* = Call_DescribeTopicsDetectionJob_601262(
    name: "describeTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeTopicsDetectionJob",
    validator: validate_DescribeTopicsDetectionJob_601263, base: "/",
    url: url_DescribeTopicsDetectionJob_601264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectDominantLanguage_601277 = ref object of OpenApiRestCall_600426
proc url_DetectDominantLanguage_601279(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetectDominantLanguage_601278(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectDominantLanguage"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_DetectDominantLanguage_601277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_DetectDominantLanguage_601277; body: JsonNode): Recallable =
  ## detectDominantLanguage
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var detectDominantLanguage* = Call_DetectDominantLanguage_601277(
    name: "detectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectDominantLanguage",
    validator: validate_DetectDominantLanguage_601278, base: "/",
    url: url_DetectDominantLanguage_601279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectEntities_601292 = ref object of OpenApiRestCall_600426
proc url_DetectEntities_601294(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetectEntities_601293(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectEntities"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_DetectEntities_601292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_DetectEntities_601292; body: JsonNode): Recallable =
  ## detectEntities
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var detectEntities* = Call_DetectEntities_601292(name: "detectEntities",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectEntities",
    validator: validate_DetectEntities_601293, base: "/", url: url_DetectEntities_601294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectKeyPhrases_601307 = ref object of OpenApiRestCall_600426
proc url_DetectKeyPhrases_601309(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetectKeyPhrases_601308(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601312 = header.getOrDefault("X-Amz-Target")
  valid_601312 = validateParameter(valid_601312, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectKeyPhrases"))
  if valid_601312 != nil:
    section.add "X-Amz-Target", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Content-Sha256", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Algorithm")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Algorithm", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Signature")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Signature", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-SignedHeaders", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Credential")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Credential", valid_601317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_DetectKeyPhrases_601307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in the text. 
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_DetectKeyPhrases_601307; body: JsonNode): Recallable =
  ## detectKeyPhrases
  ## Detects the key noun phrases found in the text. 
  ##   body: JObject (required)
  var body_601321 = newJObject()
  if body != nil:
    body_601321 = body
  result = call_601320.call(nil, nil, nil, nil, body_601321)

var detectKeyPhrases* = Call_DetectKeyPhrases_601307(name: "detectKeyPhrases",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectKeyPhrases",
    validator: validate_DetectKeyPhrases_601308, base: "/",
    url: url_DetectKeyPhrases_601309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSentiment_601322 = ref object of OpenApiRestCall_600426
proc url_DetectSentiment_601324(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetectSentiment_601323(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSentiment"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_DetectSentiment_601322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_DetectSentiment_601322; body: JsonNode): Recallable =
  ## detectSentiment
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var detectSentiment* = Call_DetectSentiment_601322(name: "detectSentiment",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSentiment",
    validator: validate_DetectSentiment_601323, base: "/", url: url_DetectSentiment_601324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSyntax_601337 = ref object of OpenApiRestCall_600426
proc url_DetectSyntax_601339(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetectSyntax_601338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSyntax"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_DetectSyntax_601337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_DetectSyntax_601337; body: JsonNode): Recallable =
  ## detectSyntax
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var detectSyntax* = Call_DetectSyntax_601337(name: "detectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSyntax",
    validator: validate_DetectSyntax_601338, base: "/", url: url_DetectSyntax_601339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassificationJobs_601352 = ref object of OpenApiRestCall_600426
proc url_ListDocumentClassificationJobs_601354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocumentClassificationJobs_601353(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601355 = query.getOrDefault("NextToken")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "NextToken", valid_601355
  var valid_601356 = query.getOrDefault("MaxResults")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "MaxResults", valid_601356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601359 = header.getOrDefault("X-Amz-Target")
  valid_601359 = validateParameter(valid_601359, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassificationJobs"))
  if valid_601359 != nil:
    section.add "X-Amz-Target", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Content-Sha256", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Algorithm")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Algorithm", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Signature")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Signature", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-SignedHeaders", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Credential")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Credential", valid_601364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_ListDocumentClassificationJobs_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"))
  result = hook(call_601366, url, valid)

proc call*(call_601367: Call_ListDocumentClassificationJobs_601352; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassificationJobs
  ## Gets a list of the documentation classification jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601368 = newJObject()
  var body_601369 = newJObject()
  add(query_601368, "NextToken", newJString(NextToken))
  if body != nil:
    body_601369 = body
  add(query_601368, "MaxResults", newJString(MaxResults))
  result = call_601367.call(nil, query_601368, nil, nil, body_601369)

var listDocumentClassificationJobs* = Call_ListDocumentClassificationJobs_601352(
    name: "listDocumentClassificationJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassificationJobs",
    validator: validate_ListDocumentClassificationJobs_601353, base: "/",
    url: url_ListDocumentClassificationJobs_601354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassifiers_601371 = ref object of OpenApiRestCall_600426
proc url_ListDocumentClassifiers_601373(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocumentClassifiers_601372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the document classifiers that you have created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601374 = query.getOrDefault("NextToken")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "NextToken", valid_601374
  var valid_601375 = query.getOrDefault("MaxResults")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "MaxResults", valid_601375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601376 = header.getOrDefault("X-Amz-Date")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Date", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Security-Token")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Security-Token", valid_601377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601378 = header.getOrDefault("X-Amz-Target")
  valid_601378 = validateParameter(valid_601378, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassifiers"))
  if valid_601378 != nil:
    section.add "X-Amz-Target", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601385: Call_ListDocumentClassifiers_601371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the document classifiers that you have created.
  ## 
  let valid = call_601385.validator(path, query, header, formData, body)
  let scheme = call_601385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601385.url(scheme.get, call_601385.host, call_601385.base,
                         call_601385.route, valid.getOrDefault("path"))
  result = hook(call_601385, url, valid)

proc call*(call_601386: Call_ListDocumentClassifiers_601371; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassifiers
  ## Gets a list of the document classifiers that you have created.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601387 = newJObject()
  var body_601388 = newJObject()
  add(query_601387, "NextToken", newJString(NextToken))
  if body != nil:
    body_601388 = body
  add(query_601387, "MaxResults", newJString(MaxResults))
  result = call_601386.call(nil, query_601387, nil, nil, body_601388)

var listDocumentClassifiers* = Call_ListDocumentClassifiers_601371(
    name: "listDocumentClassifiers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassifiers",
    validator: validate_ListDocumentClassifiers_601372, base: "/",
    url: url_ListDocumentClassifiers_601373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDominantLanguageDetectionJobs_601389 = ref object of OpenApiRestCall_600426
proc url_ListDominantLanguageDetectionJobs_601391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDominantLanguageDetectionJobs_601390(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601392 = query.getOrDefault("NextToken")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "NextToken", valid_601392
  var valid_601393 = query.getOrDefault("MaxResults")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "MaxResults", valid_601393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601394 = header.getOrDefault("X-Amz-Date")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Date", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Security-Token")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Security-Token", valid_601395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601396 = header.getOrDefault("X-Amz-Target")
  valid_601396 = validateParameter(valid_601396, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDominantLanguageDetectionJobs"))
  if valid_601396 != nil:
    section.add "X-Amz-Target", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Content-Sha256", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Algorithm")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Algorithm", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Signature")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Signature", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-SignedHeaders", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Credential")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Credential", valid_601401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601403: Call_ListDominantLanguageDetectionJobs_601389;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  let valid = call_601403.validator(path, query, header, formData, body)
  let scheme = call_601403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601403.url(scheme.get, call_601403.host, call_601403.base,
                         call_601403.route, valid.getOrDefault("path"))
  result = hook(call_601403, url, valid)

proc call*(call_601404: Call_ListDominantLanguageDetectionJobs_601389;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDominantLanguageDetectionJobs
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601405 = newJObject()
  var body_601406 = newJObject()
  add(query_601405, "NextToken", newJString(NextToken))
  if body != nil:
    body_601406 = body
  add(query_601405, "MaxResults", newJString(MaxResults))
  result = call_601404.call(nil, query_601405, nil, nil, body_601406)

var listDominantLanguageDetectionJobs* = Call_ListDominantLanguageDetectionJobs_601389(
    name: "listDominantLanguageDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.ListDominantLanguageDetectionJobs",
    validator: validate_ListDominantLanguageDetectionJobs_601390, base: "/",
    url: url_ListDominantLanguageDetectionJobs_601391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitiesDetectionJobs_601407 = ref object of OpenApiRestCall_600426
proc url_ListEntitiesDetectionJobs_601409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEntitiesDetectionJobs_601408(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601410 = query.getOrDefault("NextToken")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "NextToken", valid_601410
  var valid_601411 = query.getOrDefault("MaxResults")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "MaxResults", valid_601411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601412 = header.getOrDefault("X-Amz-Date")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Date", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Security-Token")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Security-Token", valid_601413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601414 = header.getOrDefault("X-Amz-Target")
  valid_601414 = validateParameter(valid_601414, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntitiesDetectionJobs"))
  if valid_601414 != nil:
    section.add "X-Amz-Target", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Content-Sha256", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Algorithm")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Algorithm", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Signature")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Signature", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-SignedHeaders", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Credential")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Credential", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601421: Call_ListEntitiesDetectionJobs_601407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  let valid = call_601421.validator(path, query, header, formData, body)
  let scheme = call_601421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601421.url(scheme.get, call_601421.host, call_601421.base,
                         call_601421.route, valid.getOrDefault("path"))
  result = hook(call_601421, url, valid)

proc call*(call_601422: Call_ListEntitiesDetectionJobs_601407; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntitiesDetectionJobs
  ## Gets a list of the entity detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601423 = newJObject()
  var body_601424 = newJObject()
  add(query_601423, "NextToken", newJString(NextToken))
  if body != nil:
    body_601424 = body
  add(query_601423, "MaxResults", newJString(MaxResults))
  result = call_601422.call(nil, query_601423, nil, nil, body_601424)

var listEntitiesDetectionJobs* = Call_ListEntitiesDetectionJobs_601407(
    name: "listEntitiesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntitiesDetectionJobs",
    validator: validate_ListEntitiesDetectionJobs_601408, base: "/",
    url: url_ListEntitiesDetectionJobs_601409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntityRecognizers_601425 = ref object of OpenApiRestCall_600426
proc url_ListEntityRecognizers_601427(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEntityRecognizers_601426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601428 = query.getOrDefault("NextToken")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "NextToken", valid_601428
  var valid_601429 = query.getOrDefault("MaxResults")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "MaxResults", valid_601429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601430 = header.getOrDefault("X-Amz-Date")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Date", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Security-Token")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Security-Token", valid_601431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601432 = header.getOrDefault("X-Amz-Target")
  valid_601432 = validateParameter(valid_601432, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntityRecognizers"))
  if valid_601432 != nil:
    section.add "X-Amz-Target", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Content-Sha256", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Algorithm")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Algorithm", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Signature")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Signature", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-SignedHeaders", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Credential")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Credential", valid_601437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_ListEntityRecognizers_601425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_ListEntityRecognizers_601425; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntityRecognizers
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601441 = newJObject()
  var body_601442 = newJObject()
  add(query_601441, "NextToken", newJString(NextToken))
  if body != nil:
    body_601442 = body
  add(query_601441, "MaxResults", newJString(MaxResults))
  result = call_601440.call(nil, query_601441, nil, nil, body_601442)

var listEntityRecognizers* = Call_ListEntityRecognizers_601425(
    name: "listEntityRecognizers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntityRecognizers",
    validator: validate_ListEntityRecognizers_601426, base: "/",
    url: url_ListEntityRecognizers_601427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPhrasesDetectionJobs_601443 = ref object of OpenApiRestCall_600426
proc url_ListKeyPhrasesDetectionJobs_601445(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListKeyPhrasesDetectionJobs_601444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601446 = query.getOrDefault("NextToken")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "NextToken", valid_601446
  var valid_601447 = query.getOrDefault("MaxResults")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "MaxResults", valid_601447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601448 = header.getOrDefault("X-Amz-Date")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Date", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Security-Token")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Security-Token", valid_601449
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601450 = header.getOrDefault("X-Amz-Target")
  valid_601450 = validateParameter(valid_601450, JString, required = true, default = newJString(
      "Comprehend_20171127.ListKeyPhrasesDetectionJobs"))
  if valid_601450 != nil:
    section.add "X-Amz-Target", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Content-Sha256", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Algorithm")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Algorithm", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Signature")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Signature", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-SignedHeaders", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Credential")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Credential", valid_601455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601457: Call_ListKeyPhrasesDetectionJobs_601443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  let valid = call_601457.validator(path, query, header, formData, body)
  let scheme = call_601457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601457.url(scheme.get, call_601457.host, call_601457.base,
                         call_601457.route, valid.getOrDefault("path"))
  result = hook(call_601457, url, valid)

proc call*(call_601458: Call_ListKeyPhrasesDetectionJobs_601443; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listKeyPhrasesDetectionJobs
  ## Get a list of key phrase detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601459 = newJObject()
  var body_601460 = newJObject()
  add(query_601459, "NextToken", newJString(NextToken))
  if body != nil:
    body_601460 = body
  add(query_601459, "MaxResults", newJString(MaxResults))
  result = call_601458.call(nil, query_601459, nil, nil, body_601460)

var listKeyPhrasesDetectionJobs* = Call_ListKeyPhrasesDetectionJobs_601443(
    name: "listKeyPhrasesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListKeyPhrasesDetectionJobs",
    validator: validate_ListKeyPhrasesDetectionJobs_601444, base: "/",
    url: url_ListKeyPhrasesDetectionJobs_601445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSentimentDetectionJobs_601461 = ref object of OpenApiRestCall_600426
proc url_ListSentimentDetectionJobs_601463(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSentimentDetectionJobs_601462(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601464 = query.getOrDefault("NextToken")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "NextToken", valid_601464
  var valid_601465 = query.getOrDefault("MaxResults")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "MaxResults", valid_601465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601466 = header.getOrDefault("X-Amz-Date")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Date", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Security-Token")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Security-Token", valid_601467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601468 = header.getOrDefault("X-Amz-Target")
  valid_601468 = validateParameter(valid_601468, JString, required = true, default = newJString(
      "Comprehend_20171127.ListSentimentDetectionJobs"))
  if valid_601468 != nil:
    section.add "X-Amz-Target", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Content-Sha256", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Algorithm")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Algorithm", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Signature")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Signature", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-SignedHeaders", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Credential")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Credential", valid_601473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601475: Call_ListSentimentDetectionJobs_601461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  let valid = call_601475.validator(path, query, header, formData, body)
  let scheme = call_601475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601475.url(scheme.get, call_601475.host, call_601475.base,
                         call_601475.route, valid.getOrDefault("path"))
  result = hook(call_601475, url, valid)

proc call*(call_601476: Call_ListSentimentDetectionJobs_601461; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSentimentDetectionJobs
  ## Gets a list of sentiment detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601477 = newJObject()
  var body_601478 = newJObject()
  add(query_601477, "NextToken", newJString(NextToken))
  if body != nil:
    body_601478 = body
  add(query_601477, "MaxResults", newJString(MaxResults))
  result = call_601476.call(nil, query_601477, nil, nil, body_601478)

var listSentimentDetectionJobs* = Call_ListSentimentDetectionJobs_601461(
    name: "listSentimentDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListSentimentDetectionJobs",
    validator: validate_ListSentimentDetectionJobs_601462, base: "/",
    url: url_ListSentimentDetectionJobs_601463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601479 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601481(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601480(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601482 = header.getOrDefault("X-Amz-Date")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Date", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Security-Token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Security-Token", valid_601483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601484 = header.getOrDefault("X-Amz-Target")
  valid_601484 = validateParameter(valid_601484, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTagsForResource"))
  if valid_601484 != nil:
    section.add "X-Amz-Target", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_ListTagsForResource_601479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_ListTagsForResource_601479; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_601493 = newJObject()
  if body != nil:
    body_601493 = body
  result = call_601492.call(nil, nil, nil, nil, body_601493)

var listTagsForResource* = Call_ListTagsForResource_601479(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTagsForResource",
    validator: validate_ListTagsForResource_601480, base: "/",
    url: url_ListTagsForResource_601481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTopicsDetectionJobs_601494 = ref object of OpenApiRestCall_600426
proc url_ListTopicsDetectionJobs_601496(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTopicsDetectionJobs_601495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601497 = query.getOrDefault("NextToken")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "NextToken", valid_601497
  var valid_601498 = query.getOrDefault("MaxResults")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "MaxResults", valid_601498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601499 = header.getOrDefault("X-Amz-Date")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Date", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Security-Token")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Security-Token", valid_601500
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601501 = header.getOrDefault("X-Amz-Target")
  valid_601501 = validateParameter(valid_601501, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTopicsDetectionJobs"))
  if valid_601501 != nil:
    section.add "X-Amz-Target", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Content-Sha256", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Algorithm")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Algorithm", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Signature")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Signature", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-SignedHeaders", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Credential")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Credential", valid_601506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601508: Call_ListTopicsDetectionJobs_601494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  let valid = call_601508.validator(path, query, header, formData, body)
  let scheme = call_601508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601508.url(scheme.get, call_601508.host, call_601508.base,
                         call_601508.route, valid.getOrDefault("path"))
  result = hook(call_601508, url, valid)

proc call*(call_601509: Call_ListTopicsDetectionJobs_601494; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTopicsDetectionJobs
  ## Gets a list of the topic detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601510 = newJObject()
  var body_601511 = newJObject()
  add(query_601510, "NextToken", newJString(NextToken))
  if body != nil:
    body_601511 = body
  add(query_601510, "MaxResults", newJString(MaxResults))
  result = call_601509.call(nil, query_601510, nil, nil, body_601511)

var listTopicsDetectionJobs* = Call_ListTopicsDetectionJobs_601494(
    name: "listTopicsDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTopicsDetectionJobs",
    validator: validate_ListTopicsDetectionJobs_601495, base: "/",
    url: url_ListTopicsDetectionJobs_601496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDocumentClassificationJob_601512 = ref object of OpenApiRestCall_600426
proc url_StartDocumentClassificationJob_601514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartDocumentClassificationJob_601513(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601515 = header.getOrDefault("X-Amz-Date")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Date", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Security-Token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Security-Token", valid_601516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601517 = header.getOrDefault("X-Amz-Target")
  valid_601517 = validateParameter(valid_601517, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDocumentClassificationJob"))
  if valid_601517 != nil:
    section.add "X-Amz-Target", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Content-Sha256", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Algorithm")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Algorithm", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Signature")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Signature", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-SignedHeaders", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Credential")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Credential", valid_601522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601524: Call_StartDocumentClassificationJob_601512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  let valid = call_601524.validator(path, query, header, formData, body)
  let scheme = call_601524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601524.url(scheme.get, call_601524.host, call_601524.base,
                         call_601524.route, valid.getOrDefault("path"))
  result = hook(call_601524, url, valid)

proc call*(call_601525: Call_StartDocumentClassificationJob_601512; body: JsonNode): Recallable =
  ## startDocumentClassificationJob
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ##   body: JObject (required)
  var body_601526 = newJObject()
  if body != nil:
    body_601526 = body
  result = call_601525.call(nil, nil, nil, nil, body_601526)

var startDocumentClassificationJob* = Call_StartDocumentClassificationJob_601512(
    name: "startDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartDocumentClassificationJob",
    validator: validate_StartDocumentClassificationJob_601513, base: "/",
    url: url_StartDocumentClassificationJob_601514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDominantLanguageDetectionJob_601527 = ref object of OpenApiRestCall_600426
proc url_StartDominantLanguageDetectionJob_601529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartDominantLanguageDetectionJob_601528(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601530 = header.getOrDefault("X-Amz-Date")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Date", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Security-Token")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Security-Token", valid_601531
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601532 = header.getOrDefault("X-Amz-Target")
  valid_601532 = validateParameter(valid_601532, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDominantLanguageDetectionJob"))
  if valid_601532 != nil:
    section.add "X-Amz-Target", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Content-Sha256", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Algorithm")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Algorithm", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Signature")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Signature", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-SignedHeaders", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Credential")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Credential", valid_601537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601539: Call_StartDominantLanguageDetectionJob_601527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_601539.validator(path, query, header, formData, body)
  let scheme = call_601539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601539.url(scheme.get, call_601539.host, call_601539.base,
                         call_601539.route, valid.getOrDefault("path"))
  result = hook(call_601539, url, valid)

proc call*(call_601540: Call_StartDominantLanguageDetectionJob_601527;
          body: JsonNode): Recallable =
  ## startDominantLanguageDetectionJob
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_601541 = newJObject()
  if body != nil:
    body_601541 = body
  result = call_601540.call(nil, nil, nil, nil, body_601541)

var startDominantLanguageDetectionJob* = Call_StartDominantLanguageDetectionJob_601527(
    name: "startDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StartDominantLanguageDetectionJob",
    validator: validate_StartDominantLanguageDetectionJob_601528, base: "/",
    url: url_StartDominantLanguageDetectionJob_601529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartEntitiesDetectionJob_601542 = ref object of OpenApiRestCall_600426
proc url_StartEntitiesDetectionJob_601544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartEntitiesDetectionJob_601543(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601545 = header.getOrDefault("X-Amz-Date")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Date", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Security-Token")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Security-Token", valid_601546
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601547 = header.getOrDefault("X-Amz-Target")
  valid_601547 = validateParameter(valid_601547, JString, required = true, default = newJString(
      "Comprehend_20171127.StartEntitiesDetectionJob"))
  if valid_601547 != nil:
    section.add "X-Amz-Target", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Content-Sha256", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Algorithm")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Algorithm", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Signature")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Signature", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-SignedHeaders", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Credential")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Credential", valid_601552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601554: Call_StartEntitiesDetectionJob_601542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  let valid = call_601554.validator(path, query, header, formData, body)
  let scheme = call_601554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601554.url(scheme.get, call_601554.host, call_601554.base,
                         call_601554.route, valid.getOrDefault("path"))
  result = hook(call_601554, url, valid)

proc call*(call_601555: Call_StartEntitiesDetectionJob_601542; body: JsonNode): Recallable =
  ## startEntitiesDetectionJob
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ##   body: JObject (required)
  var body_601556 = newJObject()
  if body != nil:
    body_601556 = body
  result = call_601555.call(nil, nil, nil, nil, body_601556)

var startEntitiesDetectionJob* = Call_StartEntitiesDetectionJob_601542(
    name: "startEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartEntitiesDetectionJob",
    validator: validate_StartEntitiesDetectionJob_601543, base: "/",
    url: url_StartEntitiesDetectionJob_601544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartKeyPhrasesDetectionJob_601557 = ref object of OpenApiRestCall_600426
proc url_StartKeyPhrasesDetectionJob_601559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartKeyPhrasesDetectionJob_601558(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601560 = header.getOrDefault("X-Amz-Date")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Date", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Security-Token")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Security-Token", valid_601561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601562 = header.getOrDefault("X-Amz-Target")
  valid_601562 = validateParameter(valid_601562, JString, required = true, default = newJString(
      "Comprehend_20171127.StartKeyPhrasesDetectionJob"))
  if valid_601562 != nil:
    section.add "X-Amz-Target", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Content-Sha256", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Algorithm")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Algorithm", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Signature")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Signature", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-SignedHeaders", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Credential")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Credential", valid_601567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601569: Call_StartKeyPhrasesDetectionJob_601557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_601569.validator(path, query, header, formData, body)
  let scheme = call_601569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601569.url(scheme.get, call_601569.host, call_601569.base,
                         call_601569.route, valid.getOrDefault("path"))
  result = hook(call_601569, url, valid)

proc call*(call_601570: Call_StartKeyPhrasesDetectionJob_601557; body: JsonNode): Recallable =
  ## startKeyPhrasesDetectionJob
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_601571 = newJObject()
  if body != nil:
    body_601571 = body
  result = call_601570.call(nil, nil, nil, nil, body_601571)

var startKeyPhrasesDetectionJob* = Call_StartKeyPhrasesDetectionJob_601557(
    name: "startKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartKeyPhrasesDetectionJob",
    validator: validate_StartKeyPhrasesDetectionJob_601558, base: "/",
    url: url_StartKeyPhrasesDetectionJob_601559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSentimentDetectionJob_601572 = ref object of OpenApiRestCall_600426
proc url_StartSentimentDetectionJob_601574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartSentimentDetectionJob_601573(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601575 = header.getOrDefault("X-Amz-Date")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Date", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Security-Token")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Security-Token", valid_601576
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601577 = header.getOrDefault("X-Amz-Target")
  valid_601577 = validateParameter(valid_601577, JString, required = true, default = newJString(
      "Comprehend_20171127.StartSentimentDetectionJob"))
  if valid_601577 != nil:
    section.add "X-Amz-Target", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Content-Sha256", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Algorithm")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Algorithm", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Signature")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Signature", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-SignedHeaders", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Credential")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Credential", valid_601582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601584: Call_StartSentimentDetectionJob_601572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  let valid = call_601584.validator(path, query, header, formData, body)
  let scheme = call_601584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601584.url(scheme.get, call_601584.host, call_601584.base,
                         call_601584.route, valid.getOrDefault("path"))
  result = hook(call_601584, url, valid)

proc call*(call_601585: Call_StartSentimentDetectionJob_601572; body: JsonNode): Recallable =
  ## startSentimentDetectionJob
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_601586 = newJObject()
  if body != nil:
    body_601586 = body
  result = call_601585.call(nil, nil, nil, nil, body_601586)

var startSentimentDetectionJob* = Call_StartSentimentDetectionJob_601572(
    name: "startSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartSentimentDetectionJob",
    validator: validate_StartSentimentDetectionJob_601573, base: "/",
    url: url_StartSentimentDetectionJob_601574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTopicsDetectionJob_601587 = ref object of OpenApiRestCall_600426
proc url_StartTopicsDetectionJob_601589(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartTopicsDetectionJob_601588(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601590 = header.getOrDefault("X-Amz-Date")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Date", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Security-Token")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Security-Token", valid_601591
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601592 = header.getOrDefault("X-Amz-Target")
  valid_601592 = validateParameter(valid_601592, JString, required = true, default = newJString(
      "Comprehend_20171127.StartTopicsDetectionJob"))
  if valid_601592 != nil:
    section.add "X-Amz-Target", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Content-Sha256", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Algorithm")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Algorithm", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Signature")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Signature", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-SignedHeaders", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Credential")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Credential", valid_601597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601599: Call_StartTopicsDetectionJob_601587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  let valid = call_601599.validator(path, query, header, formData, body)
  let scheme = call_601599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601599.url(scheme.get, call_601599.host, call_601599.base,
                         call_601599.route, valid.getOrDefault("path"))
  result = hook(call_601599, url, valid)

proc call*(call_601600: Call_StartTopicsDetectionJob_601587; body: JsonNode): Recallable =
  ## startTopicsDetectionJob
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ##   body: JObject (required)
  var body_601601 = newJObject()
  if body != nil:
    body_601601 = body
  result = call_601600.call(nil, nil, nil, nil, body_601601)

var startTopicsDetectionJob* = Call_StartTopicsDetectionJob_601587(
    name: "startTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartTopicsDetectionJob",
    validator: validate_StartTopicsDetectionJob_601588, base: "/",
    url: url_StartTopicsDetectionJob_601589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDominantLanguageDetectionJob_601602 = ref object of OpenApiRestCall_600426
proc url_StopDominantLanguageDetectionJob_601604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopDominantLanguageDetectionJob_601603(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601605 = header.getOrDefault("X-Amz-Date")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Date", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Security-Token")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Security-Token", valid_601606
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601607 = header.getOrDefault("X-Amz-Target")
  valid_601607 = validateParameter(valid_601607, JString, required = true, default = newJString(
      "Comprehend_20171127.StopDominantLanguageDetectionJob"))
  if valid_601607 != nil:
    section.add "X-Amz-Target", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Content-Sha256", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Algorithm")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Algorithm", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Signature")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Signature", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-SignedHeaders", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Credential")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Credential", valid_601612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601614: Call_StopDominantLanguageDetectionJob_601602;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_601614.validator(path, query, header, formData, body)
  let scheme = call_601614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601614.url(scheme.get, call_601614.host, call_601614.base,
                         call_601614.route, valid.getOrDefault("path"))
  result = hook(call_601614, url, valid)

proc call*(call_601615: Call_StopDominantLanguageDetectionJob_601602;
          body: JsonNode): Recallable =
  ## stopDominantLanguageDetectionJob
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_601616 = newJObject()
  if body != nil:
    body_601616 = body
  result = call_601615.call(nil, nil, nil, nil, body_601616)

var stopDominantLanguageDetectionJob* = Call_StopDominantLanguageDetectionJob_601602(
    name: "stopDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StopDominantLanguageDetectionJob",
    validator: validate_StopDominantLanguageDetectionJob_601603, base: "/",
    url: url_StopDominantLanguageDetectionJob_601604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopEntitiesDetectionJob_601617 = ref object of OpenApiRestCall_600426
proc url_StopEntitiesDetectionJob_601619(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopEntitiesDetectionJob_601618(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601620 = header.getOrDefault("X-Amz-Date")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Date", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Security-Token")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Security-Token", valid_601621
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601622 = header.getOrDefault("X-Amz-Target")
  valid_601622 = validateParameter(valid_601622, JString, required = true, default = newJString(
      "Comprehend_20171127.StopEntitiesDetectionJob"))
  if valid_601622 != nil:
    section.add "X-Amz-Target", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Content-Sha256", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Algorithm")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Algorithm", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Signature")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Signature", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-SignedHeaders", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Credential")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Credential", valid_601627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601629: Call_StopEntitiesDetectionJob_601617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_601629.validator(path, query, header, formData, body)
  let scheme = call_601629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601629.url(scheme.get, call_601629.host, call_601629.base,
                         call_601629.route, valid.getOrDefault("path"))
  result = hook(call_601629, url, valid)

proc call*(call_601630: Call_StopEntitiesDetectionJob_601617; body: JsonNode): Recallable =
  ## stopEntitiesDetectionJob
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_601631 = newJObject()
  if body != nil:
    body_601631 = body
  result = call_601630.call(nil, nil, nil, nil, body_601631)

var stopEntitiesDetectionJob* = Call_StopEntitiesDetectionJob_601617(
    name: "stopEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopEntitiesDetectionJob",
    validator: validate_StopEntitiesDetectionJob_601618, base: "/",
    url: url_StopEntitiesDetectionJob_601619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopKeyPhrasesDetectionJob_601632 = ref object of OpenApiRestCall_600426
proc url_StopKeyPhrasesDetectionJob_601634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopKeyPhrasesDetectionJob_601633(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601635 = header.getOrDefault("X-Amz-Date")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Date", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Security-Token")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Security-Token", valid_601636
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601637 = header.getOrDefault("X-Amz-Target")
  valid_601637 = validateParameter(valid_601637, JString, required = true, default = newJString(
      "Comprehend_20171127.StopKeyPhrasesDetectionJob"))
  if valid_601637 != nil:
    section.add "X-Amz-Target", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Content-Sha256", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Algorithm")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Algorithm", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Signature")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Signature", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-SignedHeaders", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Credential")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Credential", valid_601642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601644: Call_StopKeyPhrasesDetectionJob_601632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_601644.validator(path, query, header, formData, body)
  let scheme = call_601644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601644.url(scheme.get, call_601644.host, call_601644.base,
                         call_601644.route, valid.getOrDefault("path"))
  result = hook(call_601644, url, valid)

proc call*(call_601645: Call_StopKeyPhrasesDetectionJob_601632; body: JsonNode): Recallable =
  ## stopKeyPhrasesDetectionJob
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_601646 = newJObject()
  if body != nil:
    body_601646 = body
  result = call_601645.call(nil, nil, nil, nil, body_601646)

var stopKeyPhrasesDetectionJob* = Call_StopKeyPhrasesDetectionJob_601632(
    name: "stopKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopKeyPhrasesDetectionJob",
    validator: validate_StopKeyPhrasesDetectionJob_601633, base: "/",
    url: url_StopKeyPhrasesDetectionJob_601634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopSentimentDetectionJob_601647 = ref object of OpenApiRestCall_600426
proc url_StopSentimentDetectionJob_601649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopSentimentDetectionJob_601648(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601650 = header.getOrDefault("X-Amz-Date")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Date", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Security-Token")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Security-Token", valid_601651
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601652 = header.getOrDefault("X-Amz-Target")
  valid_601652 = validateParameter(valid_601652, JString, required = true, default = newJString(
      "Comprehend_20171127.StopSentimentDetectionJob"))
  if valid_601652 != nil:
    section.add "X-Amz-Target", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Content-Sha256", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Algorithm")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Algorithm", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Signature")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Signature", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-SignedHeaders", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Credential")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Credential", valid_601657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601659: Call_StopSentimentDetectionJob_601647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_601659.validator(path, query, header, formData, body)
  let scheme = call_601659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601659.url(scheme.get, call_601659.host, call_601659.base,
                         call_601659.route, valid.getOrDefault("path"))
  result = hook(call_601659, url, valid)

proc call*(call_601660: Call_StopSentimentDetectionJob_601647; body: JsonNode): Recallable =
  ## stopSentimentDetectionJob
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_601661 = newJObject()
  if body != nil:
    body_601661 = body
  result = call_601660.call(nil, nil, nil, nil, body_601661)

var stopSentimentDetectionJob* = Call_StopSentimentDetectionJob_601647(
    name: "stopSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopSentimentDetectionJob",
    validator: validate_StopSentimentDetectionJob_601648, base: "/",
    url: url_StopSentimentDetectionJob_601649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingDocumentClassifier_601662 = ref object of OpenApiRestCall_600426
proc url_StopTrainingDocumentClassifier_601664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTrainingDocumentClassifier_601663(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601665 = header.getOrDefault("X-Amz-Date")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Date", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Security-Token")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Security-Token", valid_601666
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601667 = header.getOrDefault("X-Amz-Target")
  valid_601667 = validateParameter(valid_601667, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingDocumentClassifier"))
  if valid_601667 != nil:
    section.add "X-Amz-Target", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Content-Sha256", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Algorithm")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Algorithm", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Signature")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Signature", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-SignedHeaders", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Credential")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Credential", valid_601672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601674: Call_StopTrainingDocumentClassifier_601662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  let valid = call_601674.validator(path, query, header, formData, body)
  let scheme = call_601674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601674.url(scheme.get, call_601674.host, call_601674.base,
                         call_601674.route, valid.getOrDefault("path"))
  result = hook(call_601674, url, valid)

proc call*(call_601675: Call_StopTrainingDocumentClassifier_601662; body: JsonNode): Recallable =
  ## stopTrainingDocumentClassifier
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ##   body: JObject (required)
  var body_601676 = newJObject()
  if body != nil:
    body_601676 = body
  result = call_601675.call(nil, nil, nil, nil, body_601676)

var stopTrainingDocumentClassifier* = Call_StopTrainingDocumentClassifier_601662(
    name: "stopTrainingDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingDocumentClassifier",
    validator: validate_StopTrainingDocumentClassifier_601663, base: "/",
    url: url_StopTrainingDocumentClassifier_601664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingEntityRecognizer_601677 = ref object of OpenApiRestCall_600426
proc url_StopTrainingEntityRecognizer_601679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTrainingEntityRecognizer_601678(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601680 = header.getOrDefault("X-Amz-Date")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Date", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Security-Token")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Security-Token", valid_601681
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601682 = header.getOrDefault("X-Amz-Target")
  valid_601682 = validateParameter(valid_601682, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingEntityRecognizer"))
  if valid_601682 != nil:
    section.add "X-Amz-Target", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Content-Sha256", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Algorithm")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Algorithm", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Signature")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Signature", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-SignedHeaders", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Credential")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Credential", valid_601687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601689: Call_StopTrainingEntityRecognizer_601677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  let valid = call_601689.validator(path, query, header, formData, body)
  let scheme = call_601689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601689.url(scheme.get, call_601689.host, call_601689.base,
                         call_601689.route, valid.getOrDefault("path"))
  result = hook(call_601689, url, valid)

proc call*(call_601690: Call_StopTrainingEntityRecognizer_601677; body: JsonNode): Recallable =
  ## stopTrainingEntityRecognizer
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ##   body: JObject (required)
  var body_601691 = newJObject()
  if body != nil:
    body_601691 = body
  result = call_601690.call(nil, nil, nil, nil, body_601691)

var stopTrainingEntityRecognizer* = Call_StopTrainingEntityRecognizer_601677(
    name: "stopTrainingEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingEntityRecognizer",
    validator: validate_StopTrainingEntityRecognizer_601678, base: "/",
    url: url_StopTrainingEntityRecognizer_601679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601692 = ref object of OpenApiRestCall_600426
proc url_TagResource_601694(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601693(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601695 = header.getOrDefault("X-Amz-Date")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Date", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Security-Token")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Security-Token", valid_601696
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601697 = header.getOrDefault("X-Amz-Target")
  valid_601697 = validateParameter(valid_601697, JString, required = true, default = newJString(
      "Comprehend_20171127.TagResource"))
  if valid_601697 != nil:
    section.add "X-Amz-Target", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Content-Sha256", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Algorithm")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Algorithm", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Signature")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Signature", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-SignedHeaders", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Credential")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Credential", valid_601702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601704: Call_TagResource_601692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  let valid = call_601704.validator(path, query, header, formData, body)
  let scheme = call_601704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601704.url(scheme.get, call_601704.host, call_601704.base,
                         call_601704.route, valid.getOrDefault("path"))
  result = hook(call_601704, url, valid)

proc call*(call_601705: Call_TagResource_601692; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ##   body: JObject (required)
  var body_601706 = newJObject()
  if body != nil:
    body_601706 = body
  result = call_601705.call(nil, nil, nil, nil, body_601706)

var tagResource* = Call_TagResource_601692(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.TagResource",
                                        validator: validate_TagResource_601693,
                                        base: "/", url: url_TagResource_601694,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601707 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601708(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601710 = header.getOrDefault("X-Amz-Date")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Date", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Security-Token")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Security-Token", valid_601711
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601712 = header.getOrDefault("X-Amz-Target")
  valid_601712 = validateParameter(valid_601712, JString, required = true, default = newJString(
      "Comprehend_20171127.UntagResource"))
  if valid_601712 != nil:
    section.add "X-Amz-Target", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Content-Sha256", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Algorithm")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Algorithm", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Signature")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Signature", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-SignedHeaders", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Credential")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Credential", valid_601717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601719: Call_UntagResource_601707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  let valid = call_601719.validator(path, query, header, formData, body)
  let scheme = call_601719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601719.url(scheme.get, call_601719.host, call_601719.base,
                         call_601719.route, valid.getOrDefault("path"))
  result = hook(call_601719, url, valid)

proc call*(call_601720: Call_UntagResource_601707; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_601721 = newJObject()
  if body != nil:
    body_601721 = body
  result = call_601720.call(nil, nil, nil, nil, body_601721)

var untagResource* = Call_UntagResource_601707(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UntagResource",
    validator: validate_UntagResource_601708, base: "/", url: url_UntagResource_601709,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
