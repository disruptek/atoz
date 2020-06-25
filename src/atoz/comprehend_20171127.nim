
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchDetectDominantLanguage_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchDetectDominantLanguage_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectDominantLanguage_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectDominantLanguage"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_BatchDetectDominantLanguage_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_BatchDetectDominantLanguage_21625779; body: JsonNode): Recallable =
  ## batchDetectDominantLanguage
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var batchDetectDominantLanguage* = Call_BatchDetectDominantLanguage_21625779(
    name: "batchDetectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectDominantLanguage",
    validator: validate_BatchDetectDominantLanguage_21625780, base: "/",
    makeUrl: url_BatchDetectDominantLanguage_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectEntities_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchDetectEntities_21626031(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectEntities_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectEntities"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_BatchDetectEntities_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchDetectEntities_21626029; body: JsonNode): Recallable =
  ## batchDetectEntities
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchDetectEntities* = Call_BatchDetectEntities_21626029(
    name: "batchDetectEntities", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectEntities",
    validator: validate_BatchDetectEntities_21626030, base: "/",
    makeUrl: url_BatchDetectEntities_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectKeyPhrases_21626044 = ref object of OpenApiRestCall_21625435
proc url_BatchDetectKeyPhrases_21626046(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectKeyPhrases_21626045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectKeyPhrases"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_BatchDetectKeyPhrases_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_BatchDetectKeyPhrases_21626044; body: JsonNode): Recallable =
  ## batchDetectKeyPhrases
  ## Detects the key noun phrases found in a batch of documents.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var batchDetectKeyPhrases* = Call_BatchDetectKeyPhrases_21626044(
    name: "batchDetectKeyPhrases", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectKeyPhrases",
    validator: validate_BatchDetectKeyPhrases_21626045, base: "/",
    makeUrl: url_BatchDetectKeyPhrases_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSentiment_21626059 = ref object of OpenApiRestCall_21625435
proc url_BatchDetectSentiment_21626061(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectSentiment_21626060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSentiment"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_BatchDetectSentiment_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_BatchDetectSentiment_21626059; body: JsonNode): Recallable =
  ## batchDetectSentiment
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var batchDetectSentiment* = Call_BatchDetectSentiment_21626059(
    name: "batchDetectSentiment", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSentiment",
    validator: validate_BatchDetectSentiment_21626060, base: "/",
    makeUrl: url_BatchDetectSentiment_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSyntax_21626074 = ref object of OpenApiRestCall_21625435
proc url_BatchDetectSyntax_21626076(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDetectSyntax_21626075(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSyntax"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_BatchDetectSyntax_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_BatchDetectSyntax_21626074; body: JsonNode): Recallable =
  ## batchDetectSyntax
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var batchDetectSyntax* = Call_BatchDetectSyntax_21626074(name: "batchDetectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSyntax",
    validator: validate_BatchDetectSyntax_21626075, base: "/",
    makeUrl: url_BatchDetectSyntax_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ClassifyDocument_21626089 = ref object of OpenApiRestCall_21625435
proc url_ClassifyDocument_21626091(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ClassifyDocument_21626090(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "Comprehend_20171127.ClassifyDocument"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_ClassifyDocument_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_ClassifyDocument_21626089; body: JsonNode): Recallable =
  ## classifyDocument
  ## Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var classifyDocument* = Call_ClassifyDocument_21626089(name: "classifyDocument",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ClassifyDocument",
    validator: validate_ClassifyDocument_21626090, base: "/",
    makeUrl: url_ClassifyDocument_21626091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentClassifier_21626104 = ref object of OpenApiRestCall_21625435
proc url_CreateDocumentClassifier_21626106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDocumentClassifier_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateDocumentClassifier"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_CreateDocumentClassifier_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CreateDocumentClassifier_21626104; body: JsonNode): Recallable =
  ## createDocumentClassifier
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var createDocumentClassifier* = Call_CreateDocumentClassifier_21626104(
    name: "createDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateDocumentClassifier",
    validator: validate_CreateDocumentClassifier_21626105, base: "/",
    makeUrl: url_CreateDocumentClassifier_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateEndpoint_21626121(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_21626120(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEndpoint"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_CreateEndpoint_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateEndpoint_21626119; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates a model-specific endpoint for synchronous inference for a previously trained custom model 
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createEndpoint* = Call_CreateEndpoint_21626119(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEndpoint",
    validator: validate_CreateEndpoint_21626120, base: "/",
    makeUrl: url_CreateEndpoint_21626121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEntityRecognizer_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateEntityRecognizer_21626136(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEntityRecognizer_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEntityRecognizer"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_CreateEntityRecognizer_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateEntityRecognizer_21626134; body: JsonNode): Recallable =
  ## createEntityRecognizer
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createEntityRecognizer* = Call_CreateEntityRecognizer_21626134(
    name: "createEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEntityRecognizer",
    validator: validate_CreateEntityRecognizer_21626135, base: "/",
    makeUrl: url_CreateEntityRecognizer_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentClassifier_21626149 = ref object of OpenApiRestCall_21625435
proc url_DeleteDocumentClassifier_21626151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDocumentClassifier_21626150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteDocumentClassifier"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626161: Call_DeleteDocumentClassifier_21626149;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_DeleteDocumentClassifier_21626149; body: JsonNode): Recallable =
  ## deleteDocumentClassifier
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var deleteDocumentClassifier* = Call_DeleteDocumentClassifier_21626149(
    name: "deleteDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteDocumentClassifier",
    validator: validate_DeleteDocumentClassifier_21626150, base: "/",
    makeUrl: url_DeleteDocumentClassifier_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_21626164 = ref object of OpenApiRestCall_21625435
proc url_DeleteEndpoint_21626166(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_21626165(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEndpoint"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_DeleteEndpoint_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_DeleteEndpoint_21626164; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var deleteEndpoint* = Call_DeleteEndpoint_21626164(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEndpoint",
    validator: validate_DeleteEndpoint_21626165, base: "/",
    makeUrl: url_DeleteEndpoint_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEntityRecognizer_21626179 = ref object of OpenApiRestCall_21625435
proc url_DeleteEntityRecognizer_21626181(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEntityRecognizer_21626180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEntityRecognizer"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_DeleteEntityRecognizer_21626179;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_DeleteEntityRecognizer_21626179; body: JsonNode): Recallable =
  ## deleteEntityRecognizer
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var deleteEntityRecognizer* = Call_DeleteEntityRecognizer_21626179(
    name: "deleteEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEntityRecognizer",
    validator: validate_DeleteEntityRecognizer_21626180, base: "/",
    makeUrl: url_DeleteEntityRecognizer_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassificationJob_21626194 = ref object of OpenApiRestCall_21625435
proc url_DescribeDocumentClassificationJob_21626196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentClassificationJob_21626195(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassificationJob"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_DescribeDocumentClassificationJob_21626194;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_DescribeDocumentClassificationJob_21626194;
          body: JsonNode): Recallable =
  ## describeDocumentClassificationJob
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var describeDocumentClassificationJob* = Call_DescribeDocumentClassificationJob_21626194(
    name: "describeDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassificationJob",
    validator: validate_DescribeDocumentClassificationJob_21626195, base: "/",
    makeUrl: url_DescribeDocumentClassificationJob_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassifier_21626209 = ref object of OpenApiRestCall_21625435
proc url_DescribeDocumentClassifier_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentClassifier_21626210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassifier"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_DescribeDocumentClassifier_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a document classifier.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_DescribeDocumentClassifier_21626209; body: JsonNode): Recallable =
  ## describeDocumentClassifier
  ## Gets the properties associated with a document classifier.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var describeDocumentClassifier* = Call_DescribeDocumentClassifier_21626209(
    name: "describeDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassifier",
    validator: validate_DescribeDocumentClassifier_21626210, base: "/",
    makeUrl: url_DescribeDocumentClassifier_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDominantLanguageDetectionJob_21626224 = ref object of OpenApiRestCall_21625435
proc url_DescribeDominantLanguageDetectionJob_21626226(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDominantLanguageDetectionJob_21626225(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDominantLanguageDetectionJob"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_DescribeDominantLanguageDetectionJob_21626224;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_DescribeDominantLanguageDetectionJob_21626224;
          body: JsonNode): Recallable =
  ## describeDominantLanguageDetectionJob
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var describeDominantLanguageDetectionJob* = Call_DescribeDominantLanguageDetectionJob_21626224(
    name: "describeDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDominantLanguageDetectionJob",
    validator: validate_DescribeDominantLanguageDetectionJob_21626225, base: "/",
    makeUrl: url_DescribeDominantLanguageDetectionJob_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_21626239 = ref object of OpenApiRestCall_21625435
proc url_DescribeEndpoint_21626241(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_21626240(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
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
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEndpoint"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_DescribeEndpoint_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DescribeEndpoint_21626239; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var describeEndpoint* = Call_DescribeEndpoint_21626239(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEndpoint",
    validator: validate_DescribeEndpoint_21626240, base: "/",
    makeUrl: url_DescribeEndpoint_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntitiesDetectionJob_21626254 = ref object of OpenApiRestCall_21625435
proc url_DescribeEntitiesDetectionJob_21626256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntitiesDetectionJob_21626255(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntitiesDetectionJob"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_DescribeEntitiesDetectionJob_21626254;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_DescribeEntitiesDetectionJob_21626254;
          body: JsonNode): Recallable =
  ## describeEntitiesDetectionJob
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var describeEntitiesDetectionJob* = Call_DescribeEntitiesDetectionJob_21626254(
    name: "describeEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntitiesDetectionJob",
    validator: validate_DescribeEntitiesDetectionJob_21626255, base: "/",
    makeUrl: url_DescribeEntitiesDetectionJob_21626256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityRecognizer_21626269 = ref object of OpenApiRestCall_21625435
proc url_DescribeEntityRecognizer_21626271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntityRecognizer_21626270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntityRecognizer"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DescribeEntityRecognizer_21626269;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DescribeEntityRecognizer_21626269; body: JsonNode): Recallable =
  ## describeEntityRecognizer
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var describeEntityRecognizer* = Call_DescribeEntityRecognizer_21626269(
    name: "describeEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntityRecognizer",
    validator: validate_DescribeEntityRecognizer_21626270, base: "/",
    makeUrl: url_DescribeEntityRecognizer_21626271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKeyPhrasesDetectionJob_21626284 = ref object of OpenApiRestCall_21625435
proc url_DescribeKeyPhrasesDetectionJob_21626286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeKeyPhrasesDetectionJob_21626285(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DescribeKeyPhrasesDetectionJob_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DescribeKeyPhrasesDetectionJob_21626284;
          body: JsonNode): Recallable =
  ## describeKeyPhrasesDetectionJob
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var describeKeyPhrasesDetectionJob* = Call_DescribeKeyPhrasesDetectionJob_21626284(
    name: "describeKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeKeyPhrasesDetectionJob",
    validator: validate_DescribeKeyPhrasesDetectionJob_21626285, base: "/",
    makeUrl: url_DescribeKeyPhrasesDetectionJob_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSentimentDetectionJob_21626299 = ref object of OpenApiRestCall_21625435
proc url_DescribeSentimentDetectionJob_21626301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSentimentDetectionJob_21626300(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeSentimentDetectionJob"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_DescribeSentimentDetectionJob_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DescribeSentimentDetectionJob_21626299;
          body: JsonNode): Recallable =
  ## describeSentimentDetectionJob
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var describeSentimentDetectionJob* = Call_DescribeSentimentDetectionJob_21626299(
    name: "describeSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeSentimentDetectionJob",
    validator: validate_DescribeSentimentDetectionJob_21626300, base: "/",
    makeUrl: url_DescribeSentimentDetectionJob_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTopicsDetectionJob_21626314 = ref object of OpenApiRestCall_21625435
proc url_DescribeTopicsDetectionJob_21626316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTopicsDetectionJob_21626315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeTopicsDetectionJob"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_DescribeTopicsDetectionJob_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DescribeTopicsDetectionJob_21626314; body: JsonNode): Recallable =
  ## describeTopicsDetectionJob
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var describeTopicsDetectionJob* = Call_DescribeTopicsDetectionJob_21626314(
    name: "describeTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeTopicsDetectionJob",
    validator: validate_DescribeTopicsDetectionJob_21626315, base: "/",
    makeUrl: url_DescribeTopicsDetectionJob_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectDominantLanguage_21626329 = ref object of OpenApiRestCall_21625435
proc url_DetectDominantLanguage_21626331(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectDominantLanguage_21626330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectDominantLanguage"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_DetectDominantLanguage_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DetectDominantLanguage_21626329; body: JsonNode): Recallable =
  ## detectDominantLanguage
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var detectDominantLanguage* = Call_DetectDominantLanguage_21626329(
    name: "detectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectDominantLanguage",
    validator: validate_DetectDominantLanguage_21626330, base: "/",
    makeUrl: url_DetectDominantLanguage_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectEntities_21626344 = ref object of OpenApiRestCall_21625435
proc url_DetectEntities_21626346(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectEntities_21626345(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectEntities"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_DetectEntities_21626344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_DetectEntities_21626344; body: JsonNode): Recallable =
  ## detectEntities
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var detectEntities* = Call_DetectEntities_21626344(name: "detectEntities",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectEntities",
    validator: validate_DetectEntities_21626345, base: "/",
    makeUrl: url_DetectEntities_21626346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectKeyPhrases_21626359 = ref object of OpenApiRestCall_21625435
proc url_DetectKeyPhrases_21626361(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectKeyPhrases_21626360(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectKeyPhrases"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626371: Call_DetectKeyPhrases_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detects the key noun phrases found in the text. 
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DetectKeyPhrases_21626359; body: JsonNode): Recallable =
  ## detectKeyPhrases
  ## Detects the key noun phrases found in the text. 
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var detectKeyPhrases* = Call_DetectKeyPhrases_21626359(name: "detectKeyPhrases",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectKeyPhrases",
    validator: validate_DetectKeyPhrases_21626360, base: "/",
    makeUrl: url_DetectKeyPhrases_21626361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSentiment_21626374 = ref object of OpenApiRestCall_21625435
proc url_DetectSentiment_21626376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectSentiment_21626375(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSentiment"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_DetectSentiment_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DetectSentiment_21626374; body: JsonNode): Recallable =
  ## detectSentiment
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var detectSentiment* = Call_DetectSentiment_21626374(name: "detectSentiment",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSentiment",
    validator: validate_DetectSentiment_21626375, base: "/",
    makeUrl: url_DetectSentiment_21626376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSyntax_21626389 = ref object of OpenApiRestCall_21625435
proc url_DetectSyntax_21626391(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectSyntax_21626390(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSyntax"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_DetectSyntax_21626389; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_DetectSyntax_21626389; body: JsonNode): Recallable =
  ## detectSyntax
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var detectSyntax* = Call_DetectSyntax_21626389(name: "detectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSyntax",
    validator: validate_DetectSyntax_21626390, base: "/", makeUrl: url_DetectSyntax_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassificationJobs_21626404 = ref object of OpenApiRestCall_21625435
proc url_ListDocumentClassificationJobs_21626406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentClassificationJobs_21626405(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626407 = query.getOrDefault("NextToken")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "NextToken", valid_21626407
  var valid_21626408 = query.getOrDefault("MaxResults")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "MaxResults", valid_21626408
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
  var valid_21626409 = header.getOrDefault("X-Amz-Date")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Date", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Security-Token", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Target")
  valid_21626411 = validateParameter(valid_21626411, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassificationJobs"))
  if valid_21626411 != nil:
    section.add "X-Amz-Target", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Algorithm", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Signature")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Signature", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Credential")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Credential", valid_21626416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626418: Call_ListDocumentClassificationJobs_21626404;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  let valid = call_21626418.validator(path, query, header, formData, body, _)
  let scheme = call_21626418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626418.makeUrl(scheme.get, call_21626418.host, call_21626418.base,
                               call_21626418.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626418, uri, valid, _)

proc call*(call_21626419: Call_ListDocumentClassificationJobs_21626404;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassificationJobs
  ## Gets a list of the documentation classification jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626421 = newJObject()
  var body_21626422 = newJObject()
  add(query_21626421, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626422 = body
  add(query_21626421, "MaxResults", newJString(MaxResults))
  result = call_21626419.call(nil, query_21626421, nil, nil, body_21626422)

var listDocumentClassificationJobs* = Call_ListDocumentClassificationJobs_21626404(
    name: "listDocumentClassificationJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassificationJobs",
    validator: validate_ListDocumentClassificationJobs_21626405, base: "/",
    makeUrl: url_ListDocumentClassificationJobs_21626406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassifiers_21626426 = ref object of OpenApiRestCall_21625435
proc url_ListDocumentClassifiers_21626428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentClassifiers_21626427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626429 = query.getOrDefault("NextToken")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "NextToken", valid_21626429
  var valid_21626430 = query.getOrDefault("MaxResults")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "MaxResults", valid_21626430
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
  var valid_21626431 = header.getOrDefault("X-Amz-Date")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Date", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Security-Token", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Target")
  valid_21626433 = validateParameter(valid_21626433, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassifiers"))
  if valid_21626433 != nil:
    section.add "X-Amz-Target", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Algorithm", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Signature")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Signature", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Credential")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Credential", valid_21626438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626440: Call_ListDocumentClassifiers_21626426;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the document classifiers that you have created.
  ## 
  let valid = call_21626440.validator(path, query, header, formData, body, _)
  let scheme = call_21626440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626440.makeUrl(scheme.get, call_21626440.host, call_21626440.base,
                               call_21626440.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626440, uri, valid, _)

proc call*(call_21626441: Call_ListDocumentClassifiers_21626426; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassifiers
  ## Gets a list of the document classifiers that you have created.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626442 = newJObject()
  var body_21626443 = newJObject()
  add(query_21626442, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626443 = body
  add(query_21626442, "MaxResults", newJString(MaxResults))
  result = call_21626441.call(nil, query_21626442, nil, nil, body_21626443)

var listDocumentClassifiers* = Call_ListDocumentClassifiers_21626426(
    name: "listDocumentClassifiers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassifiers",
    validator: validate_ListDocumentClassifiers_21626427, base: "/",
    makeUrl: url_ListDocumentClassifiers_21626428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDominantLanguageDetectionJobs_21626444 = ref object of OpenApiRestCall_21625435
proc url_ListDominantLanguageDetectionJobs_21626446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDominantLanguageDetectionJobs_21626445(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626447 = query.getOrDefault("NextToken")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "NextToken", valid_21626447
  var valid_21626448 = query.getOrDefault("MaxResults")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "MaxResults", valid_21626448
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
  var valid_21626449 = header.getOrDefault("X-Amz-Date")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Date", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Security-Token", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Target")
  valid_21626451 = validateParameter(valid_21626451, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDominantLanguageDetectionJobs"))
  if valid_21626451 != nil:
    section.add "X-Amz-Target", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Algorithm", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Signature")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Signature", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Credential")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Credential", valid_21626456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626458: Call_ListDominantLanguageDetectionJobs_21626444;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  let valid = call_21626458.validator(path, query, header, formData, body, _)
  let scheme = call_21626458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626458.makeUrl(scheme.get, call_21626458.host, call_21626458.base,
                               call_21626458.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626458, uri, valid, _)

proc call*(call_21626459: Call_ListDominantLanguageDetectionJobs_21626444;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDominantLanguageDetectionJobs
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626460 = newJObject()
  var body_21626461 = newJObject()
  add(query_21626460, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626461 = body
  add(query_21626460, "MaxResults", newJString(MaxResults))
  result = call_21626459.call(nil, query_21626460, nil, nil, body_21626461)

var listDominantLanguageDetectionJobs* = Call_ListDominantLanguageDetectionJobs_21626444(
    name: "listDominantLanguageDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.ListDominantLanguageDetectionJobs",
    validator: validate_ListDominantLanguageDetectionJobs_21626445, base: "/",
    makeUrl: url_ListDominantLanguageDetectionJobs_21626446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_21626462 = ref object of OpenApiRestCall_21625435
proc url_ListEndpoints_21626464(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_21626463(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a list of all existing endpoints that you've created.
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
  var valid_21626465 = header.getOrDefault("X-Amz-Date")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Date", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Security-Token", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Target")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEndpoints"))
  if valid_21626467 != nil:
    section.add "X-Amz-Target", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Algorithm", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Signature")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Signature", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Credential")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Credential", valid_21626472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626474: Call_ListEndpoints_21626462; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of all existing endpoints that you've created.
  ## 
  let valid = call_21626474.validator(path, query, header, formData, body, _)
  let scheme = call_21626474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626474.makeUrl(scheme.get, call_21626474.host, call_21626474.base,
                               call_21626474.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626474, uri, valid, _)

proc call*(call_21626475: Call_ListEndpoints_21626462; body: JsonNode): Recallable =
  ## listEndpoints
  ## Gets a list of all existing endpoints that you've created.
  ##   body: JObject (required)
  var body_21626476 = newJObject()
  if body != nil:
    body_21626476 = body
  result = call_21626475.call(nil, nil, nil, nil, body_21626476)

var listEndpoints* = Call_ListEndpoints_21626462(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEndpoints",
    validator: validate_ListEndpoints_21626463, base: "/",
    makeUrl: url_ListEndpoints_21626464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitiesDetectionJobs_21626477 = ref object of OpenApiRestCall_21625435
proc url_ListEntitiesDetectionJobs_21626479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntitiesDetectionJobs_21626478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626480 = query.getOrDefault("NextToken")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "NextToken", valid_21626480
  var valid_21626481 = query.getOrDefault("MaxResults")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "MaxResults", valid_21626481
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
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntitiesDetectionJobs"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626491: Call_ListEntitiesDetectionJobs_21626477;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_ListEntitiesDetectionJobs_21626477; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntitiesDetectionJobs
  ## Gets a list of the entity detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626493 = newJObject()
  var body_21626494 = newJObject()
  add(query_21626493, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626494 = body
  add(query_21626493, "MaxResults", newJString(MaxResults))
  result = call_21626492.call(nil, query_21626493, nil, nil, body_21626494)

var listEntitiesDetectionJobs* = Call_ListEntitiesDetectionJobs_21626477(
    name: "listEntitiesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntitiesDetectionJobs",
    validator: validate_ListEntitiesDetectionJobs_21626478, base: "/",
    makeUrl: url_ListEntitiesDetectionJobs_21626479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntityRecognizers_21626495 = ref object of OpenApiRestCall_21625435
proc url_ListEntityRecognizers_21626497(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntityRecognizers_21626496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626498 = query.getOrDefault("NextToken")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "NextToken", valid_21626498
  var valid_21626499 = query.getOrDefault("MaxResults")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "MaxResults", valid_21626499
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
  var valid_21626500 = header.getOrDefault("X-Amz-Date")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Date", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Security-Token", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Target")
  valid_21626502 = validateParameter(valid_21626502, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntityRecognizers"))
  if valid_21626502 != nil:
    section.add "X-Amz-Target", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Algorithm", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Signature")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Signature", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Credential")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Credential", valid_21626507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626509: Call_ListEntityRecognizers_21626495;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  let valid = call_21626509.validator(path, query, header, formData, body, _)
  let scheme = call_21626509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626509.makeUrl(scheme.get, call_21626509.host, call_21626509.base,
                               call_21626509.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626509, uri, valid, _)

proc call*(call_21626510: Call_ListEntityRecognizers_21626495; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntityRecognizers
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626511 = newJObject()
  var body_21626512 = newJObject()
  add(query_21626511, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626512 = body
  add(query_21626511, "MaxResults", newJString(MaxResults))
  result = call_21626510.call(nil, query_21626511, nil, nil, body_21626512)

var listEntityRecognizers* = Call_ListEntityRecognizers_21626495(
    name: "listEntityRecognizers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntityRecognizers",
    validator: validate_ListEntityRecognizers_21626496, base: "/",
    makeUrl: url_ListEntityRecognizers_21626497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPhrasesDetectionJobs_21626513 = ref object of OpenApiRestCall_21625435
proc url_ListKeyPhrasesDetectionJobs_21626515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKeyPhrasesDetectionJobs_21626514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626516 = query.getOrDefault("NextToken")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "NextToken", valid_21626516
  var valid_21626517 = query.getOrDefault("MaxResults")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "MaxResults", valid_21626517
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
  var valid_21626518 = header.getOrDefault("X-Amz-Date")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Date", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Security-Token", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Target")
  valid_21626520 = validateParameter(valid_21626520, JString, required = true, default = newJString(
      "Comprehend_20171127.ListKeyPhrasesDetectionJobs"))
  if valid_21626520 != nil:
    section.add "X-Amz-Target", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Algorithm", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Signature")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Signature", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Credential")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Credential", valid_21626525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626527: Call_ListKeyPhrasesDetectionJobs_21626513;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  let valid = call_21626527.validator(path, query, header, formData, body, _)
  let scheme = call_21626527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626527.makeUrl(scheme.get, call_21626527.host, call_21626527.base,
                               call_21626527.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626527, uri, valid, _)

proc call*(call_21626528: Call_ListKeyPhrasesDetectionJobs_21626513;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listKeyPhrasesDetectionJobs
  ## Get a list of key phrase detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626529 = newJObject()
  var body_21626530 = newJObject()
  add(query_21626529, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626530 = body
  add(query_21626529, "MaxResults", newJString(MaxResults))
  result = call_21626528.call(nil, query_21626529, nil, nil, body_21626530)

var listKeyPhrasesDetectionJobs* = Call_ListKeyPhrasesDetectionJobs_21626513(
    name: "listKeyPhrasesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListKeyPhrasesDetectionJobs",
    validator: validate_ListKeyPhrasesDetectionJobs_21626514, base: "/",
    makeUrl: url_ListKeyPhrasesDetectionJobs_21626515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSentimentDetectionJobs_21626531 = ref object of OpenApiRestCall_21625435
proc url_ListSentimentDetectionJobs_21626533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSentimentDetectionJobs_21626532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626534 = query.getOrDefault("NextToken")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "NextToken", valid_21626534
  var valid_21626535 = query.getOrDefault("MaxResults")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "MaxResults", valid_21626535
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
  var valid_21626536 = header.getOrDefault("X-Amz-Date")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Date", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Security-Token", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Target")
  valid_21626538 = validateParameter(valid_21626538, JString, required = true, default = newJString(
      "Comprehend_20171127.ListSentimentDetectionJobs"))
  if valid_21626538 != nil:
    section.add "X-Amz-Target", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Algorithm", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Signature")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Signature", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Credential")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Credential", valid_21626543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626545: Call_ListSentimentDetectionJobs_21626531;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  let valid = call_21626545.validator(path, query, header, formData, body, _)
  let scheme = call_21626545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626545.makeUrl(scheme.get, call_21626545.host, call_21626545.base,
                               call_21626545.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626545, uri, valid, _)

proc call*(call_21626546: Call_ListSentimentDetectionJobs_21626531; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSentimentDetectionJobs
  ## Gets a list of sentiment detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626547 = newJObject()
  var body_21626548 = newJObject()
  add(query_21626547, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626548 = body
  add(query_21626547, "MaxResults", newJString(MaxResults))
  result = call_21626546.call(nil, query_21626547, nil, nil, body_21626548)

var listSentimentDetectionJobs* = Call_ListSentimentDetectionJobs_21626531(
    name: "listSentimentDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListSentimentDetectionJobs",
    validator: validate_ListSentimentDetectionJobs_21626532, base: "/",
    makeUrl: url_ListSentimentDetectionJobs_21626533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626549 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626551(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626552 = header.getOrDefault("X-Amz-Date")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Date", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Security-Token", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Target")
  valid_21626554 = validateParameter(valid_21626554, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTagsForResource"))
  if valid_21626554 != nil:
    section.add "X-Amz-Target", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Algorithm", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Signature")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Signature", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Credential")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Credential", valid_21626559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626561: Call_ListTagsForResource_21626549; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  let valid = call_21626561.validator(path, query, header, formData, body, _)
  let scheme = call_21626561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626561.makeUrl(scheme.get, call_21626561.host, call_21626561.base,
                               call_21626561.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626561, uri, valid, _)

proc call*(call_21626562: Call_ListTagsForResource_21626549; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_21626563 = newJObject()
  if body != nil:
    body_21626563 = body
  result = call_21626562.call(nil, nil, nil, nil, body_21626563)

var listTagsForResource* = Call_ListTagsForResource_21626549(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTagsForResource",
    validator: validate_ListTagsForResource_21626550, base: "/",
    makeUrl: url_ListTagsForResource_21626551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTopicsDetectionJobs_21626564 = ref object of OpenApiRestCall_21625435
proc url_ListTopicsDetectionJobs_21626566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTopicsDetectionJobs_21626565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626567 = query.getOrDefault("NextToken")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "NextToken", valid_21626567
  var valid_21626568 = query.getOrDefault("MaxResults")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "MaxResults", valid_21626568
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
  var valid_21626569 = header.getOrDefault("X-Amz-Date")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Date", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Security-Token", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Target")
  valid_21626571 = validateParameter(valid_21626571, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTopicsDetectionJobs"))
  if valid_21626571 != nil:
    section.add "X-Amz-Target", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Algorithm", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Signature")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Signature", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Credential")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Credential", valid_21626576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626578: Call_ListTopicsDetectionJobs_21626564;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  let valid = call_21626578.validator(path, query, header, formData, body, _)
  let scheme = call_21626578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626578.makeUrl(scheme.get, call_21626578.host, call_21626578.base,
                               call_21626578.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626578, uri, valid, _)

proc call*(call_21626579: Call_ListTopicsDetectionJobs_21626564; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTopicsDetectionJobs
  ## Gets a list of the topic detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626580 = newJObject()
  var body_21626581 = newJObject()
  add(query_21626580, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626581 = body
  add(query_21626580, "MaxResults", newJString(MaxResults))
  result = call_21626579.call(nil, query_21626580, nil, nil, body_21626581)

var listTopicsDetectionJobs* = Call_ListTopicsDetectionJobs_21626564(
    name: "listTopicsDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTopicsDetectionJobs",
    validator: validate_ListTopicsDetectionJobs_21626565, base: "/",
    makeUrl: url_ListTopicsDetectionJobs_21626566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDocumentClassificationJob_21626582 = ref object of OpenApiRestCall_21625435
proc url_StartDocumentClassificationJob_21626584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDocumentClassificationJob_21626583(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626585 = header.getOrDefault("X-Amz-Date")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Date", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Security-Token", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Target")
  valid_21626587 = validateParameter(valid_21626587, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDocumentClassificationJob"))
  if valid_21626587 != nil:
    section.add "X-Amz-Target", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Algorithm", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Signature")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Signature", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Credential")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Credential", valid_21626592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626594: Call_StartDocumentClassificationJob_21626582;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  let valid = call_21626594.validator(path, query, header, formData, body, _)
  let scheme = call_21626594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626594.makeUrl(scheme.get, call_21626594.host, call_21626594.base,
                               call_21626594.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626594, uri, valid, _)

proc call*(call_21626595: Call_StartDocumentClassificationJob_21626582;
          body: JsonNode): Recallable =
  ## startDocumentClassificationJob
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ##   body: JObject (required)
  var body_21626596 = newJObject()
  if body != nil:
    body_21626596 = body
  result = call_21626595.call(nil, nil, nil, nil, body_21626596)

var startDocumentClassificationJob* = Call_StartDocumentClassificationJob_21626582(
    name: "startDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartDocumentClassificationJob",
    validator: validate_StartDocumentClassificationJob_21626583, base: "/",
    makeUrl: url_StartDocumentClassificationJob_21626584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDominantLanguageDetectionJob_21626597 = ref object of OpenApiRestCall_21625435
proc url_StartDominantLanguageDetectionJob_21626599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDominantLanguageDetectionJob_21626598(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626600 = header.getOrDefault("X-Amz-Date")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Date", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Security-Token", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Target")
  valid_21626602 = validateParameter(valid_21626602, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDominantLanguageDetectionJob"))
  if valid_21626602 != nil:
    section.add "X-Amz-Target", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Algorithm", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Signature")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Signature", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Credential")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Credential", valid_21626607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626609: Call_StartDominantLanguageDetectionJob_21626597;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_21626609.validator(path, query, header, formData, body, _)
  let scheme = call_21626609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626609.makeUrl(scheme.get, call_21626609.host, call_21626609.base,
                               call_21626609.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626609, uri, valid, _)

proc call*(call_21626610: Call_StartDominantLanguageDetectionJob_21626597;
          body: JsonNode): Recallable =
  ## startDominantLanguageDetectionJob
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_21626611 = newJObject()
  if body != nil:
    body_21626611 = body
  result = call_21626610.call(nil, nil, nil, nil, body_21626611)

var startDominantLanguageDetectionJob* = Call_StartDominantLanguageDetectionJob_21626597(
    name: "startDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StartDominantLanguageDetectionJob",
    validator: validate_StartDominantLanguageDetectionJob_21626598, base: "/",
    makeUrl: url_StartDominantLanguageDetectionJob_21626599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartEntitiesDetectionJob_21626612 = ref object of OpenApiRestCall_21625435
proc url_StartEntitiesDetectionJob_21626614(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartEntitiesDetectionJob_21626613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626615 = header.getOrDefault("X-Amz-Date")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Date", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Security-Token", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Target")
  valid_21626617 = validateParameter(valid_21626617, JString, required = true, default = newJString(
      "Comprehend_20171127.StartEntitiesDetectionJob"))
  if valid_21626617 != nil:
    section.add "X-Amz-Target", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Algorithm", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Signature")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Signature", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Credential")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Credential", valid_21626622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626624: Call_StartEntitiesDetectionJob_21626612;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  let valid = call_21626624.validator(path, query, header, formData, body, _)
  let scheme = call_21626624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626624.makeUrl(scheme.get, call_21626624.host, call_21626624.base,
                               call_21626624.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626624, uri, valid, _)

proc call*(call_21626625: Call_StartEntitiesDetectionJob_21626612; body: JsonNode): Recallable =
  ## startEntitiesDetectionJob
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ##   body: JObject (required)
  var body_21626626 = newJObject()
  if body != nil:
    body_21626626 = body
  result = call_21626625.call(nil, nil, nil, nil, body_21626626)

var startEntitiesDetectionJob* = Call_StartEntitiesDetectionJob_21626612(
    name: "startEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartEntitiesDetectionJob",
    validator: validate_StartEntitiesDetectionJob_21626613, base: "/",
    makeUrl: url_StartEntitiesDetectionJob_21626614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartKeyPhrasesDetectionJob_21626627 = ref object of OpenApiRestCall_21625435
proc url_StartKeyPhrasesDetectionJob_21626629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartKeyPhrasesDetectionJob_21626628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626630 = header.getOrDefault("X-Amz-Date")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Date", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Security-Token", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Target")
  valid_21626632 = validateParameter(valid_21626632, JString, required = true, default = newJString(
      "Comprehend_20171127.StartKeyPhrasesDetectionJob"))
  if valid_21626632 != nil:
    section.add "X-Amz-Target", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626639: Call_StartKeyPhrasesDetectionJob_21626627;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_21626639.validator(path, query, header, formData, body, _)
  let scheme = call_21626639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626639.makeUrl(scheme.get, call_21626639.host, call_21626639.base,
                               call_21626639.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626639, uri, valid, _)

proc call*(call_21626640: Call_StartKeyPhrasesDetectionJob_21626627; body: JsonNode): Recallable =
  ## startKeyPhrasesDetectionJob
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_21626641 = newJObject()
  if body != nil:
    body_21626641 = body
  result = call_21626640.call(nil, nil, nil, nil, body_21626641)

var startKeyPhrasesDetectionJob* = Call_StartKeyPhrasesDetectionJob_21626627(
    name: "startKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartKeyPhrasesDetectionJob",
    validator: validate_StartKeyPhrasesDetectionJob_21626628, base: "/",
    makeUrl: url_StartKeyPhrasesDetectionJob_21626629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSentimentDetectionJob_21626642 = ref object of OpenApiRestCall_21625435
proc url_StartSentimentDetectionJob_21626644(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSentimentDetectionJob_21626643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626645 = header.getOrDefault("X-Amz-Date")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Date", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Security-Token", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Target")
  valid_21626647 = validateParameter(valid_21626647, JString, required = true, default = newJString(
      "Comprehend_20171127.StartSentimentDetectionJob"))
  if valid_21626647 != nil:
    section.add "X-Amz-Target", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Algorithm", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Signature")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Signature", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Credential")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Credential", valid_21626652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626654: Call_StartSentimentDetectionJob_21626642;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  let valid = call_21626654.validator(path, query, header, formData, body, _)
  let scheme = call_21626654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626654.makeUrl(scheme.get, call_21626654.host, call_21626654.base,
                               call_21626654.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626654, uri, valid, _)

proc call*(call_21626655: Call_StartSentimentDetectionJob_21626642; body: JsonNode): Recallable =
  ## startSentimentDetectionJob
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_21626656 = newJObject()
  if body != nil:
    body_21626656 = body
  result = call_21626655.call(nil, nil, nil, nil, body_21626656)

var startSentimentDetectionJob* = Call_StartSentimentDetectionJob_21626642(
    name: "startSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartSentimentDetectionJob",
    validator: validate_StartSentimentDetectionJob_21626643, base: "/",
    makeUrl: url_StartSentimentDetectionJob_21626644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTopicsDetectionJob_21626657 = ref object of OpenApiRestCall_21625435
proc url_StartTopicsDetectionJob_21626659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTopicsDetectionJob_21626658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626660 = header.getOrDefault("X-Amz-Date")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Date", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Security-Token", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Target")
  valid_21626662 = validateParameter(valid_21626662, JString, required = true, default = newJString(
      "Comprehend_20171127.StartTopicsDetectionJob"))
  if valid_21626662 != nil:
    section.add "X-Amz-Target", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Algorithm", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Signature")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Signature", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Credential")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Credential", valid_21626667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626669: Call_StartTopicsDetectionJob_21626657;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  let valid = call_21626669.validator(path, query, header, formData, body, _)
  let scheme = call_21626669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626669.makeUrl(scheme.get, call_21626669.host, call_21626669.base,
                               call_21626669.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626669, uri, valid, _)

proc call*(call_21626670: Call_StartTopicsDetectionJob_21626657; body: JsonNode): Recallable =
  ## startTopicsDetectionJob
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ##   body: JObject (required)
  var body_21626671 = newJObject()
  if body != nil:
    body_21626671 = body
  result = call_21626670.call(nil, nil, nil, nil, body_21626671)

var startTopicsDetectionJob* = Call_StartTopicsDetectionJob_21626657(
    name: "startTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartTopicsDetectionJob",
    validator: validate_StartTopicsDetectionJob_21626658, base: "/",
    makeUrl: url_StartTopicsDetectionJob_21626659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDominantLanguageDetectionJob_21626672 = ref object of OpenApiRestCall_21625435
proc url_StopDominantLanguageDetectionJob_21626674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDominantLanguageDetectionJob_21626673(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626675 = header.getOrDefault("X-Amz-Date")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Date", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Security-Token", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Target")
  valid_21626677 = validateParameter(valid_21626677, JString, required = true, default = newJString(
      "Comprehend_20171127.StopDominantLanguageDetectionJob"))
  if valid_21626677 != nil:
    section.add "X-Amz-Target", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Algorithm", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Signature")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Signature", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Credential")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Credential", valid_21626682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626684: Call_StopDominantLanguageDetectionJob_21626672;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_21626684.validator(path, query, header, formData, body, _)
  let scheme = call_21626684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626684.makeUrl(scheme.get, call_21626684.host, call_21626684.base,
                               call_21626684.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626684, uri, valid, _)

proc call*(call_21626685: Call_StopDominantLanguageDetectionJob_21626672;
          body: JsonNode): Recallable =
  ## stopDominantLanguageDetectionJob
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_21626686 = newJObject()
  if body != nil:
    body_21626686 = body
  result = call_21626685.call(nil, nil, nil, nil, body_21626686)

var stopDominantLanguageDetectionJob* = Call_StopDominantLanguageDetectionJob_21626672(
    name: "stopDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StopDominantLanguageDetectionJob",
    validator: validate_StopDominantLanguageDetectionJob_21626673, base: "/",
    makeUrl: url_StopDominantLanguageDetectionJob_21626674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopEntitiesDetectionJob_21626687 = ref object of OpenApiRestCall_21625435
proc url_StopEntitiesDetectionJob_21626689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopEntitiesDetectionJob_21626688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626690 = header.getOrDefault("X-Amz-Date")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Date", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Security-Token", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Target")
  valid_21626692 = validateParameter(valid_21626692, JString, required = true, default = newJString(
      "Comprehend_20171127.StopEntitiesDetectionJob"))
  if valid_21626692 != nil:
    section.add "X-Amz-Target", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Algorithm", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Signature")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Signature", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Credential")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Credential", valid_21626697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626699: Call_StopEntitiesDetectionJob_21626687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_21626699.validator(path, query, header, formData, body, _)
  let scheme = call_21626699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626699.makeUrl(scheme.get, call_21626699.host, call_21626699.base,
                               call_21626699.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626699, uri, valid, _)

proc call*(call_21626700: Call_StopEntitiesDetectionJob_21626687; body: JsonNode): Recallable =
  ## stopEntitiesDetectionJob
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_21626701 = newJObject()
  if body != nil:
    body_21626701 = body
  result = call_21626700.call(nil, nil, nil, nil, body_21626701)

var stopEntitiesDetectionJob* = Call_StopEntitiesDetectionJob_21626687(
    name: "stopEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopEntitiesDetectionJob",
    validator: validate_StopEntitiesDetectionJob_21626688, base: "/",
    makeUrl: url_StopEntitiesDetectionJob_21626689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopKeyPhrasesDetectionJob_21626702 = ref object of OpenApiRestCall_21625435
proc url_StopKeyPhrasesDetectionJob_21626704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopKeyPhrasesDetectionJob_21626703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626705 = header.getOrDefault("X-Amz-Date")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Date", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Security-Token", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Target")
  valid_21626707 = validateParameter(valid_21626707, JString, required = true, default = newJString(
      "Comprehend_20171127.StopKeyPhrasesDetectionJob"))
  if valid_21626707 != nil:
    section.add "X-Amz-Target", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Algorithm", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Signature")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Signature", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Credential")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Credential", valid_21626712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626714: Call_StopKeyPhrasesDetectionJob_21626702;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_21626714.validator(path, query, header, formData, body, _)
  let scheme = call_21626714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626714.makeUrl(scheme.get, call_21626714.host, call_21626714.base,
                               call_21626714.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626714, uri, valid, _)

proc call*(call_21626715: Call_StopKeyPhrasesDetectionJob_21626702; body: JsonNode): Recallable =
  ## stopKeyPhrasesDetectionJob
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_21626716 = newJObject()
  if body != nil:
    body_21626716 = body
  result = call_21626715.call(nil, nil, nil, nil, body_21626716)

var stopKeyPhrasesDetectionJob* = Call_StopKeyPhrasesDetectionJob_21626702(
    name: "stopKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopKeyPhrasesDetectionJob",
    validator: validate_StopKeyPhrasesDetectionJob_21626703, base: "/",
    makeUrl: url_StopKeyPhrasesDetectionJob_21626704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopSentimentDetectionJob_21626717 = ref object of OpenApiRestCall_21625435
proc url_StopSentimentDetectionJob_21626719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopSentimentDetectionJob_21626718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626720 = header.getOrDefault("X-Amz-Date")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Date", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Security-Token", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Target")
  valid_21626722 = validateParameter(valid_21626722, JString, required = true, default = newJString(
      "Comprehend_20171127.StopSentimentDetectionJob"))
  if valid_21626722 != nil:
    section.add "X-Amz-Target", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Algorithm", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Signature")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Signature", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Credential")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Credential", valid_21626727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626729: Call_StopSentimentDetectionJob_21626717;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_21626729.validator(path, query, header, formData, body, _)
  let scheme = call_21626729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626729.makeUrl(scheme.get, call_21626729.host, call_21626729.base,
                               call_21626729.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626729, uri, valid, _)

proc call*(call_21626730: Call_StopSentimentDetectionJob_21626717; body: JsonNode): Recallable =
  ## stopSentimentDetectionJob
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_21626731 = newJObject()
  if body != nil:
    body_21626731 = body
  result = call_21626730.call(nil, nil, nil, nil, body_21626731)

var stopSentimentDetectionJob* = Call_StopSentimentDetectionJob_21626717(
    name: "stopSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopSentimentDetectionJob",
    validator: validate_StopSentimentDetectionJob_21626718, base: "/",
    makeUrl: url_StopSentimentDetectionJob_21626719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingDocumentClassifier_21626732 = ref object of OpenApiRestCall_21625435
proc url_StopTrainingDocumentClassifier_21626734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingDocumentClassifier_21626733(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626735 = header.getOrDefault("X-Amz-Date")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Date", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Security-Token", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Target")
  valid_21626737 = validateParameter(valid_21626737, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingDocumentClassifier"))
  if valid_21626737 != nil:
    section.add "X-Amz-Target", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Algorithm", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Signature")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Signature", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Credential")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Credential", valid_21626742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626744: Call_StopTrainingDocumentClassifier_21626732;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  let valid = call_21626744.validator(path, query, header, formData, body, _)
  let scheme = call_21626744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626744.makeUrl(scheme.get, call_21626744.host, call_21626744.base,
                               call_21626744.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626744, uri, valid, _)

proc call*(call_21626745: Call_StopTrainingDocumentClassifier_21626732;
          body: JsonNode): Recallable =
  ## stopTrainingDocumentClassifier
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ##   body: JObject (required)
  var body_21626746 = newJObject()
  if body != nil:
    body_21626746 = body
  result = call_21626745.call(nil, nil, nil, nil, body_21626746)

var stopTrainingDocumentClassifier* = Call_StopTrainingDocumentClassifier_21626732(
    name: "stopTrainingDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingDocumentClassifier",
    validator: validate_StopTrainingDocumentClassifier_21626733, base: "/",
    makeUrl: url_StopTrainingDocumentClassifier_21626734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingEntityRecognizer_21626747 = ref object of OpenApiRestCall_21625435
proc url_StopTrainingEntityRecognizer_21626749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingEntityRecognizer_21626748(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626750 = header.getOrDefault("X-Amz-Date")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Date", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Security-Token", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Target")
  valid_21626752 = validateParameter(valid_21626752, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingEntityRecognizer"))
  if valid_21626752 != nil:
    section.add "X-Amz-Target", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Algorithm", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Signature")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Signature", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Credential")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Credential", valid_21626757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626759: Call_StopTrainingEntityRecognizer_21626747;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  let valid = call_21626759.validator(path, query, header, formData, body, _)
  let scheme = call_21626759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626759.makeUrl(scheme.get, call_21626759.host, call_21626759.base,
                               call_21626759.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626759, uri, valid, _)

proc call*(call_21626760: Call_StopTrainingEntityRecognizer_21626747;
          body: JsonNode): Recallable =
  ## stopTrainingEntityRecognizer
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ##   body: JObject (required)
  var body_21626761 = newJObject()
  if body != nil:
    body_21626761 = body
  result = call_21626760.call(nil, nil, nil, nil, body_21626761)

var stopTrainingEntityRecognizer* = Call_StopTrainingEntityRecognizer_21626747(
    name: "stopTrainingEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingEntityRecognizer",
    validator: validate_StopTrainingEntityRecognizer_21626748, base: "/",
    makeUrl: url_StopTrainingEntityRecognizer_21626749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626762 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626764(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626763(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626765 = header.getOrDefault("X-Amz-Date")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Date", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Security-Token", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Target")
  valid_21626767 = validateParameter(valid_21626767, JString, required = true, default = newJString(
      "Comprehend_20171127.TagResource"))
  if valid_21626767 != nil:
    section.add "X-Amz-Target", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Algorithm", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Signature")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Signature", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Credential")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Credential", valid_21626772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626774: Call_TagResource_21626762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  let valid = call_21626774.validator(path, query, header, formData, body, _)
  let scheme = call_21626774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626774.makeUrl(scheme.get, call_21626774.host, call_21626774.base,
                               call_21626774.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626774, uri, valid, _)

proc call*(call_21626775: Call_TagResource_21626762; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ##   body: JObject (required)
  var body_21626776 = newJObject()
  if body != nil:
    body_21626776 = body
  result = call_21626775.call(nil, nil, nil, nil, body_21626776)

var tagResource* = Call_TagResource_21626762(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.TagResource",
    validator: validate_TagResource_21626763, base: "/", makeUrl: url_TagResource_21626764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626777 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626779(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626778(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626780 = header.getOrDefault("X-Amz-Date")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Date", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Security-Token", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Target")
  valid_21626782 = validateParameter(valid_21626782, JString, required = true, default = newJString(
      "Comprehend_20171127.UntagResource"))
  if valid_21626782 != nil:
    section.add "X-Amz-Target", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Algorithm", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Signature")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Signature", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Credential")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Credential", valid_21626787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626789: Call_UntagResource_21626777; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  let valid = call_21626789.validator(path, query, header, formData, body, _)
  let scheme = call_21626789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626789.makeUrl(scheme.get, call_21626789.host, call_21626789.base,
                               call_21626789.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626789, uri, valid, _)

proc call*(call_21626790: Call_UntagResource_21626777; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_21626791 = newJObject()
  if body != nil:
    body_21626791 = body
  result = call_21626790.call(nil, nil, nil, nil, body_21626791)

var untagResource* = Call_UntagResource_21626777(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UntagResource",
    validator: validate_UntagResource_21626778, base: "/",
    makeUrl: url_UntagResource_21626779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_21626792 = ref object of OpenApiRestCall_21625435
proc url_UpdateEndpoint_21626794(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_21626793(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates information about the specified endpoint.
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
  var valid_21626795 = header.getOrDefault("X-Amz-Date")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Date", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Security-Token", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Target")
  valid_21626797 = validateParameter(valid_21626797, JString, required = true, default = newJString(
      "Comprehend_20171127.UpdateEndpoint"))
  if valid_21626797 != nil:
    section.add "X-Amz-Target", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Algorithm", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Signature")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Signature", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Credential")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Credential", valid_21626802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626804: Call_UpdateEndpoint_21626792; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about the specified endpoint.
  ## 
  let valid = call_21626804.validator(path, query, header, formData, body, _)
  let scheme = call_21626804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626804.makeUrl(scheme.get, call_21626804.host, call_21626804.base,
                               call_21626804.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626804, uri, valid, _)

proc call*(call_21626805: Call_UpdateEndpoint_21626792; body: JsonNode): Recallable =
  ## updateEndpoint
  ## Updates information about the specified endpoint.
  ##   body: JObject (required)
  var body_21626806 = newJObject()
  if body != nil:
    body_21626806 = body
  result = call_21626805.call(nil, nil, nil, nil, body_21626806)

var updateEndpoint* = Call_UpdateEndpoint_21626792(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UpdateEndpoint",
    validator: validate_UpdateEndpoint_21626793, base: "/",
    makeUrl: url_UpdateEndpoint_21626794, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}