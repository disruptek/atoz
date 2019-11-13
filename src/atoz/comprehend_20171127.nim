
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDetectDominantLanguage_593727 = ref object of OpenApiRestCall_593389
proc url_BatchDetectDominantLanguage_593729(protocol: Scheme; host: string;
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

proc validate_BatchDetectDominantLanguage_593728(path: JsonNode; query: JsonNode;
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
  var valid_593854 = header.getOrDefault("X-Amz-Target")
  valid_593854 = validateParameter(valid_593854, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectDominantLanguage"))
  if valid_593854 != nil:
    section.add "X-Amz-Target", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Signature")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Signature", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Content-Sha256", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Date")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Date", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Credential")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Credential", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Security-Token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Security-Token", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Algorithm")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Algorithm", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-SignedHeaders", valid_593861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593885: Call_BatchDetectDominantLanguage_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_BatchDetectDominantLanguage_593727; body: JsonNode): Recallable =
  ## batchDetectDominantLanguage
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_593957 = newJObject()
  if body != nil:
    body_593957 = body
  result = call_593956.call(nil, nil, nil, nil, body_593957)

var batchDetectDominantLanguage* = Call_BatchDetectDominantLanguage_593727(
    name: "batchDetectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectDominantLanguage",
    validator: validate_BatchDetectDominantLanguage_593728, base: "/",
    url: url_BatchDetectDominantLanguage_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectEntities_593996 = ref object of OpenApiRestCall_593389
proc url_BatchDetectEntities_593998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDetectEntities_593997(path: JsonNode; query: JsonNode;
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
  var valid_593999 = header.getOrDefault("X-Amz-Target")
  valid_593999 = validateParameter(valid_593999, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectEntities"))
  if valid_593999 != nil:
    section.add "X-Amz-Target", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Signature")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Signature", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Content-Sha256", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Date")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Date", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Credential")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Credential", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Security-Token")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Security-Token", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Algorithm")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Algorithm", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-SignedHeaders", valid_594006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594008: Call_BatchDetectEntities_593996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_BatchDetectEntities_593996; body: JsonNode): Recallable =
  ## batchDetectEntities
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ##   body: JObject (required)
  var body_594010 = newJObject()
  if body != nil:
    body_594010 = body
  result = call_594009.call(nil, nil, nil, nil, body_594010)

var batchDetectEntities* = Call_BatchDetectEntities_593996(
    name: "batchDetectEntities", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectEntities",
    validator: validate_BatchDetectEntities_593997, base: "/",
    url: url_BatchDetectEntities_593998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectKeyPhrases_594011 = ref object of OpenApiRestCall_593389
proc url_BatchDetectKeyPhrases_594013(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDetectKeyPhrases_594012(path: JsonNode; query: JsonNode;
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
  var valid_594014 = header.getOrDefault("X-Amz-Target")
  valid_594014 = validateParameter(valid_594014, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectKeyPhrases"))
  if valid_594014 != nil:
    section.add "X-Amz-Target", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Signature")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Signature", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Content-Sha256", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Date")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Date", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Credential")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Credential", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Algorithm")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Algorithm", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-SignedHeaders", valid_594021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594023: Call_BatchDetectKeyPhrases_594011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_BatchDetectKeyPhrases_594011; body: JsonNode): Recallable =
  ## batchDetectKeyPhrases
  ## Detects the key noun phrases found in a batch of documents.
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var batchDetectKeyPhrases* = Call_BatchDetectKeyPhrases_594011(
    name: "batchDetectKeyPhrases", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectKeyPhrases",
    validator: validate_BatchDetectKeyPhrases_594012, base: "/",
    url: url_BatchDetectKeyPhrases_594013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSentiment_594026 = ref object of OpenApiRestCall_593389
proc url_BatchDetectSentiment_594028(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDetectSentiment_594027(path: JsonNode; query: JsonNode;
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
  var valid_594029 = header.getOrDefault("X-Amz-Target")
  valid_594029 = validateParameter(valid_594029, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSentiment"))
  if valid_594029 != nil:
    section.add "X-Amz-Target", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Signature")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Signature", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Content-Sha256", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Credential")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Credential", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_BatchDetectSentiment_594026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_BatchDetectSentiment_594026; body: JsonNode): Recallable =
  ## batchDetectSentiment
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var batchDetectSentiment* = Call_BatchDetectSentiment_594026(
    name: "batchDetectSentiment", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSentiment",
    validator: validate_BatchDetectSentiment_594027, base: "/",
    url: url_BatchDetectSentiment_594028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSyntax_594041 = ref object of OpenApiRestCall_593389
proc url_BatchDetectSyntax_594043(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDetectSyntax_594042(path: JsonNode; query: JsonNode;
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
  var valid_594044 = header.getOrDefault("X-Amz-Target")
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSyntax"))
  if valid_594044 != nil:
    section.add "X-Amz-Target", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_BatchDetectSyntax_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_BatchDetectSyntax_594041; body: JsonNode): Recallable =
  ## batchDetectSyntax
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var batchDetectSyntax* = Call_BatchDetectSyntax_594041(name: "batchDetectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSyntax",
    validator: validate_BatchDetectSyntax_594042, base: "/",
    url: url_BatchDetectSyntax_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentClassifier_594056 = ref object of OpenApiRestCall_593389
proc url_CreateDocumentClassifier_594058(protocol: Scheme; host: string;
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

proc validate_CreateDocumentClassifier_594057(path: JsonNode; query: JsonNode;
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
  var valid_594059 = header.getOrDefault("X-Amz-Target")
  valid_594059 = validateParameter(valid_594059, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateDocumentClassifier"))
  if valid_594059 != nil:
    section.add "X-Amz-Target", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Content-Sha256", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Credential")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Credential", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594068: Call_CreateDocumentClassifier_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_CreateDocumentClassifier_594056; body: JsonNode): Recallable =
  ## createDocumentClassifier
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ##   body: JObject (required)
  var body_594070 = newJObject()
  if body != nil:
    body_594070 = body
  result = call_594069.call(nil, nil, nil, nil, body_594070)

var createDocumentClassifier* = Call_CreateDocumentClassifier_594056(
    name: "createDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateDocumentClassifier",
    validator: validate_CreateDocumentClassifier_594057, base: "/",
    url: url_CreateDocumentClassifier_594058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEntityRecognizer_594071 = ref object of OpenApiRestCall_593389
proc url_CreateEntityRecognizer_594073(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEntityRecognizer_594072(path: JsonNode; query: JsonNode;
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
  var valid_594074 = header.getOrDefault("X-Amz-Target")
  valid_594074 = validateParameter(valid_594074, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEntityRecognizer"))
  if valid_594074 != nil:
    section.add "X-Amz-Target", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Credential")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Credential", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_CreateEntityRecognizer_594071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_CreateEntityRecognizer_594071; body: JsonNode): Recallable =
  ## createEntityRecognizer
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ##   body: JObject (required)
  var body_594085 = newJObject()
  if body != nil:
    body_594085 = body
  result = call_594084.call(nil, nil, nil, nil, body_594085)

var createEntityRecognizer* = Call_CreateEntityRecognizer_594071(
    name: "createEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEntityRecognizer",
    validator: validate_CreateEntityRecognizer_594072, base: "/",
    url: url_CreateEntityRecognizer_594073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentClassifier_594086 = ref object of OpenApiRestCall_593389
proc url_DeleteDocumentClassifier_594088(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentClassifier_594087(path: JsonNode; query: JsonNode;
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
  var valid_594089 = header.getOrDefault("X-Amz-Target")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteDocumentClassifier"))
  if valid_594089 != nil:
    section.add "X-Amz-Target", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_DeleteDocumentClassifier_594086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_DeleteDocumentClassifier_594086; body: JsonNode): Recallable =
  ## deleteDocumentClassifier
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_594100 = newJObject()
  if body != nil:
    body_594100 = body
  result = call_594099.call(nil, nil, nil, nil, body_594100)

var deleteDocumentClassifier* = Call_DeleteDocumentClassifier_594086(
    name: "deleteDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteDocumentClassifier",
    validator: validate_DeleteDocumentClassifier_594087, base: "/",
    url: url_DeleteDocumentClassifier_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEntityRecognizer_594101 = ref object of OpenApiRestCall_593389
proc url_DeleteEntityRecognizer_594103(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEntityRecognizer_594102(path: JsonNode; query: JsonNode;
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
  var valid_594104 = header.getOrDefault("X-Amz-Target")
  valid_594104 = validateParameter(valid_594104, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEntityRecognizer"))
  if valid_594104 != nil:
    section.add "X-Amz-Target", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Signature")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Signature", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Content-Sha256", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Date")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Date", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Credential")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Credential", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_DeleteEntityRecognizer_594101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_DeleteEntityRecognizer_594101; body: JsonNode): Recallable =
  ## deleteEntityRecognizer
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_594115 = newJObject()
  if body != nil:
    body_594115 = body
  result = call_594114.call(nil, nil, nil, nil, body_594115)

var deleteEntityRecognizer* = Call_DeleteEntityRecognizer_594101(
    name: "deleteEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEntityRecognizer",
    validator: validate_DeleteEntityRecognizer_594102, base: "/",
    url: url_DeleteEntityRecognizer_594103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassificationJob_594116 = ref object of OpenApiRestCall_593389
proc url_DescribeDocumentClassificationJob_594118(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentClassificationJob_594117(path: JsonNode;
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
  var valid_594119 = header.getOrDefault("X-Amz-Target")
  valid_594119 = validateParameter(valid_594119, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassificationJob"))
  if valid_594119 != nil:
    section.add "X-Amz-Target", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Signature")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Signature", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594128: Call_DescribeDocumentClassificationJob_594116;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  let valid = call_594128.validator(path, query, header, formData, body)
  let scheme = call_594128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594128.url(scheme.get, call_594128.host, call_594128.base,
                         call_594128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594128, url, valid)

proc call*(call_594129: Call_DescribeDocumentClassificationJob_594116;
          body: JsonNode): Recallable =
  ## describeDocumentClassificationJob
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ##   body: JObject (required)
  var body_594130 = newJObject()
  if body != nil:
    body_594130 = body
  result = call_594129.call(nil, nil, nil, nil, body_594130)

var describeDocumentClassificationJob* = Call_DescribeDocumentClassificationJob_594116(
    name: "describeDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassificationJob",
    validator: validate_DescribeDocumentClassificationJob_594117, base: "/",
    url: url_DescribeDocumentClassificationJob_594118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassifier_594131 = ref object of OpenApiRestCall_593389
proc url_DescribeDocumentClassifier_594133(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentClassifier_594132(path: JsonNode; query: JsonNode;
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
  var valid_594134 = header.getOrDefault("X-Amz-Target")
  valid_594134 = validateParameter(valid_594134, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassifier"))
  if valid_594134 != nil:
    section.add "X-Amz-Target", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Credential")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Credential", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Security-Token")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Security-Token", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_DescribeDocumentClassifier_594131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a document classifier.
  ## 
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_DescribeDocumentClassifier_594131; body: JsonNode): Recallable =
  ## describeDocumentClassifier
  ## Gets the properties associated with a document classifier.
  ##   body: JObject (required)
  var body_594145 = newJObject()
  if body != nil:
    body_594145 = body
  result = call_594144.call(nil, nil, nil, nil, body_594145)

var describeDocumentClassifier* = Call_DescribeDocumentClassifier_594131(
    name: "describeDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassifier",
    validator: validate_DescribeDocumentClassifier_594132, base: "/",
    url: url_DescribeDocumentClassifier_594133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDominantLanguageDetectionJob_594146 = ref object of OpenApiRestCall_593389
proc url_DescribeDominantLanguageDetectionJob_594148(protocol: Scheme;
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

proc validate_DescribeDominantLanguageDetectionJob_594147(path: JsonNode;
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
  var valid_594149 = header.getOrDefault("X-Amz-Target")
  valid_594149 = validateParameter(valid_594149, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDominantLanguageDetectionJob"))
  if valid_594149 != nil:
    section.add "X-Amz-Target", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Content-Sha256", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Security-Token")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Security-Token", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_DescribeDominantLanguageDetectionJob_594146;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_DescribeDominantLanguageDetectionJob_594146;
          body: JsonNode): Recallable =
  ## describeDominantLanguageDetectionJob
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_594160 = newJObject()
  if body != nil:
    body_594160 = body
  result = call_594159.call(nil, nil, nil, nil, body_594160)

var describeDominantLanguageDetectionJob* = Call_DescribeDominantLanguageDetectionJob_594146(
    name: "describeDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDominantLanguageDetectionJob",
    validator: validate_DescribeDominantLanguageDetectionJob_594147, base: "/",
    url: url_DescribeDominantLanguageDetectionJob_594148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntitiesDetectionJob_594161 = ref object of OpenApiRestCall_593389
proc url_DescribeEntitiesDetectionJob_594163(protocol: Scheme; host: string;
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

proc validate_DescribeEntitiesDetectionJob_594162(path: JsonNode; query: JsonNode;
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
  var valid_594164 = header.getOrDefault("X-Amz-Target")
  valid_594164 = validateParameter(valid_594164, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntitiesDetectionJob"))
  if valid_594164 != nil:
    section.add "X-Amz-Target", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_DescribeEntitiesDetectionJob_594161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_DescribeEntitiesDetectionJob_594161; body: JsonNode): Recallable =
  ## describeEntitiesDetectionJob
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_594175 = newJObject()
  if body != nil:
    body_594175 = body
  result = call_594174.call(nil, nil, nil, nil, body_594175)

var describeEntitiesDetectionJob* = Call_DescribeEntitiesDetectionJob_594161(
    name: "describeEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntitiesDetectionJob",
    validator: validate_DescribeEntitiesDetectionJob_594162, base: "/",
    url: url_DescribeEntitiesDetectionJob_594163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityRecognizer_594176 = ref object of OpenApiRestCall_593389
proc url_DescribeEntityRecognizer_594178(protocol: Scheme; host: string;
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

proc validate_DescribeEntityRecognizer_594177(path: JsonNode; query: JsonNode;
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
  var valid_594179 = header.getOrDefault("X-Amz-Target")
  valid_594179 = validateParameter(valid_594179, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntityRecognizer"))
  if valid_594179 != nil:
    section.add "X-Amz-Target", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594188: Call_DescribeEntityRecognizer_594176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  let valid = call_594188.validator(path, query, header, formData, body)
  let scheme = call_594188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594188.url(scheme.get, call_594188.host, call_594188.base,
                         call_594188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594188, url, valid)

proc call*(call_594189: Call_DescribeEntityRecognizer_594176; body: JsonNode): Recallable =
  ## describeEntityRecognizer
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ##   body: JObject (required)
  var body_594190 = newJObject()
  if body != nil:
    body_594190 = body
  result = call_594189.call(nil, nil, nil, nil, body_594190)

var describeEntityRecognizer* = Call_DescribeEntityRecognizer_594176(
    name: "describeEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntityRecognizer",
    validator: validate_DescribeEntityRecognizer_594177, base: "/",
    url: url_DescribeEntityRecognizer_594178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKeyPhrasesDetectionJob_594191 = ref object of OpenApiRestCall_593389
proc url_DescribeKeyPhrasesDetectionJob_594193(protocol: Scheme; host: string;
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

proc validate_DescribeKeyPhrasesDetectionJob_594192(path: JsonNode;
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
  var valid_594194 = header.getOrDefault("X-Amz-Target")
  valid_594194 = validateParameter(valid_594194, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"))
  if valid_594194 != nil:
    section.add "X-Amz-Target", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Content-Sha256", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_DescribeKeyPhrasesDetectionJob_594191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_DescribeKeyPhrasesDetectionJob_594191; body: JsonNode): Recallable =
  ## describeKeyPhrasesDetectionJob
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_594205 = newJObject()
  if body != nil:
    body_594205 = body
  result = call_594204.call(nil, nil, nil, nil, body_594205)

var describeKeyPhrasesDetectionJob* = Call_DescribeKeyPhrasesDetectionJob_594191(
    name: "describeKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeKeyPhrasesDetectionJob",
    validator: validate_DescribeKeyPhrasesDetectionJob_594192, base: "/",
    url: url_DescribeKeyPhrasesDetectionJob_594193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSentimentDetectionJob_594206 = ref object of OpenApiRestCall_593389
proc url_DescribeSentimentDetectionJob_594208(protocol: Scheme; host: string;
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

proc validate_DescribeSentimentDetectionJob_594207(path: JsonNode; query: JsonNode;
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
  var valid_594209 = header.getOrDefault("X-Amz-Target")
  valid_594209 = validateParameter(valid_594209, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeSentimentDetectionJob"))
  if valid_594209 != nil:
    section.add "X-Amz-Target", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-SignedHeaders", valid_594216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594218: Call_DescribeSentimentDetectionJob_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_594218.validator(path, query, header, formData, body)
  let scheme = call_594218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594218.url(scheme.get, call_594218.host, call_594218.base,
                         call_594218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594218, url, valid)

proc call*(call_594219: Call_DescribeSentimentDetectionJob_594206; body: JsonNode): Recallable =
  ## describeSentimentDetectionJob
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_594220 = newJObject()
  if body != nil:
    body_594220 = body
  result = call_594219.call(nil, nil, nil, nil, body_594220)

var describeSentimentDetectionJob* = Call_DescribeSentimentDetectionJob_594206(
    name: "describeSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeSentimentDetectionJob",
    validator: validate_DescribeSentimentDetectionJob_594207, base: "/",
    url: url_DescribeSentimentDetectionJob_594208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTopicsDetectionJob_594221 = ref object of OpenApiRestCall_593389
proc url_DescribeTopicsDetectionJob_594223(protocol: Scheme; host: string;
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

proc validate_DescribeTopicsDetectionJob_594222(path: JsonNode; query: JsonNode;
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
  var valid_594224 = header.getOrDefault("X-Amz-Target")
  valid_594224 = validateParameter(valid_594224, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeTopicsDetectionJob"))
  if valid_594224 != nil:
    section.add "X-Amz-Target", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Security-Token")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Security-Token", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_DescribeTopicsDetectionJob_594221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_DescribeTopicsDetectionJob_594221; body: JsonNode): Recallable =
  ## describeTopicsDetectionJob
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_594235 = newJObject()
  if body != nil:
    body_594235 = body
  result = call_594234.call(nil, nil, nil, nil, body_594235)

var describeTopicsDetectionJob* = Call_DescribeTopicsDetectionJob_594221(
    name: "describeTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeTopicsDetectionJob",
    validator: validate_DescribeTopicsDetectionJob_594222, base: "/",
    url: url_DescribeTopicsDetectionJob_594223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectDominantLanguage_594236 = ref object of OpenApiRestCall_593389
proc url_DetectDominantLanguage_594238(protocol: Scheme; host: string; base: string;
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

proc validate_DetectDominantLanguage_594237(path: JsonNode; query: JsonNode;
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
  var valid_594239 = header.getOrDefault("X-Amz-Target")
  valid_594239 = validateParameter(valid_594239, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectDominantLanguage"))
  if valid_594239 != nil:
    section.add "X-Amz-Target", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_DetectDominantLanguage_594236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_DetectDominantLanguage_594236; body: JsonNode): Recallable =
  ## detectDominantLanguage
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_594250 = newJObject()
  if body != nil:
    body_594250 = body
  result = call_594249.call(nil, nil, nil, nil, body_594250)

var detectDominantLanguage* = Call_DetectDominantLanguage_594236(
    name: "detectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectDominantLanguage",
    validator: validate_DetectDominantLanguage_594237, base: "/",
    url: url_DetectDominantLanguage_594238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectEntities_594251 = ref object of OpenApiRestCall_593389
proc url_DetectEntities_594253(protocol: Scheme; host: string; base: string;
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

proc validate_DetectEntities_594252(path: JsonNode; query: JsonNode;
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
  var valid_594254 = header.getOrDefault("X-Amz-Target")
  valid_594254 = validateParameter(valid_594254, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectEntities"))
  if valid_594254 != nil:
    section.add "X-Amz-Target", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_DetectEntities_594251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_DetectEntities_594251; body: JsonNode): Recallable =
  ## detectEntities
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ##   body: JObject (required)
  var body_594265 = newJObject()
  if body != nil:
    body_594265 = body
  result = call_594264.call(nil, nil, nil, nil, body_594265)

var detectEntities* = Call_DetectEntities_594251(name: "detectEntities",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectEntities",
    validator: validate_DetectEntities_594252, base: "/", url: url_DetectEntities_594253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectKeyPhrases_594266 = ref object of OpenApiRestCall_593389
proc url_DetectKeyPhrases_594268(protocol: Scheme; host: string; base: string;
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

proc validate_DetectKeyPhrases_594267(path: JsonNode; query: JsonNode;
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
  var valid_594269 = header.getOrDefault("X-Amz-Target")
  valid_594269 = validateParameter(valid_594269, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectKeyPhrases"))
  if valid_594269 != nil:
    section.add "X-Amz-Target", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Signature")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Signature", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Content-Sha256", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Credential")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Credential", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Security-Token")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Security-Token", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-SignedHeaders", valid_594276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594278: Call_DetectKeyPhrases_594266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in the text. 
  ## 
  let valid = call_594278.validator(path, query, header, formData, body)
  let scheme = call_594278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594278.url(scheme.get, call_594278.host, call_594278.base,
                         call_594278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594278, url, valid)

proc call*(call_594279: Call_DetectKeyPhrases_594266; body: JsonNode): Recallable =
  ## detectKeyPhrases
  ## Detects the key noun phrases found in the text. 
  ##   body: JObject (required)
  var body_594280 = newJObject()
  if body != nil:
    body_594280 = body
  result = call_594279.call(nil, nil, nil, nil, body_594280)

var detectKeyPhrases* = Call_DetectKeyPhrases_594266(name: "detectKeyPhrases",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectKeyPhrases",
    validator: validate_DetectKeyPhrases_594267, base: "/",
    url: url_DetectKeyPhrases_594268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSentiment_594281 = ref object of OpenApiRestCall_593389
proc url_DetectSentiment_594283(protocol: Scheme; host: string; base: string;
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

proc validate_DetectSentiment_594282(path: JsonNode; query: JsonNode;
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
  var valid_594284 = header.getOrDefault("X-Amz-Target")
  valid_594284 = validateParameter(valid_594284, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSentiment"))
  if valid_594284 != nil:
    section.add "X-Amz-Target", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Content-Sha256", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Credential")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Credential", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Security-Token")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Security-Token", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_DetectSentiment_594281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_DetectSentiment_594281; body: JsonNode): Recallable =
  ## detectSentiment
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ##   body: JObject (required)
  var body_594295 = newJObject()
  if body != nil:
    body_594295 = body
  result = call_594294.call(nil, nil, nil, nil, body_594295)

var detectSentiment* = Call_DetectSentiment_594281(name: "detectSentiment",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSentiment",
    validator: validate_DetectSentiment_594282, base: "/", url: url_DetectSentiment_594283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSyntax_594296 = ref object of OpenApiRestCall_593389
proc url_DetectSyntax_594298(protocol: Scheme; host: string; base: string;
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

proc validate_DetectSyntax_594297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594299 = header.getOrDefault("X-Amz-Target")
  valid_594299 = validateParameter(valid_594299, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSyntax"))
  if valid_594299 != nil:
    section.add "X-Amz-Target", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Signature")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Signature", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Content-Sha256", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Date")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Date", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Credential")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Credential", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Security-Token")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Security-Token", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-SignedHeaders", valid_594306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594308: Call_DetectSyntax_594296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  let valid = call_594308.validator(path, query, header, formData, body)
  let scheme = call_594308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594308.url(scheme.get, call_594308.host, call_594308.base,
                         call_594308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594308, url, valid)

proc call*(call_594309: Call_DetectSyntax_594296; body: JsonNode): Recallable =
  ## detectSyntax
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_594310 = newJObject()
  if body != nil:
    body_594310 = body
  result = call_594309.call(nil, nil, nil, nil, body_594310)

var detectSyntax* = Call_DetectSyntax_594296(name: "detectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSyntax",
    validator: validate_DetectSyntax_594297, base: "/", url: url_DetectSyntax_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassificationJobs_594311 = ref object of OpenApiRestCall_593389
proc url_ListDocumentClassificationJobs_594313(protocol: Scheme; host: string;
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

proc validate_ListDocumentClassificationJobs_594312(path: JsonNode;
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
  var valid_594314 = query.getOrDefault("MaxResults")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "MaxResults", valid_594314
  var valid_594315 = query.getOrDefault("NextToken")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "NextToken", valid_594315
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
  var valid_594316 = header.getOrDefault("X-Amz-Target")
  valid_594316 = validateParameter(valid_594316, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassificationJobs"))
  if valid_594316 != nil:
    section.add "X-Amz-Target", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Signature")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Signature", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Content-Sha256", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Date")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Date", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Credential")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Credential", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Security-Token")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Security-Token", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Algorithm")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Algorithm", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-SignedHeaders", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_ListDocumentClassificationJobs_594311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_ListDocumentClassificationJobs_594311; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocumentClassificationJobs
  ## Gets a list of the documentation classification jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594327 = newJObject()
  var body_594328 = newJObject()
  add(query_594327, "MaxResults", newJString(MaxResults))
  add(query_594327, "NextToken", newJString(NextToken))
  if body != nil:
    body_594328 = body
  result = call_594326.call(nil, query_594327, nil, nil, body_594328)

var listDocumentClassificationJobs* = Call_ListDocumentClassificationJobs_594311(
    name: "listDocumentClassificationJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassificationJobs",
    validator: validate_ListDocumentClassificationJobs_594312, base: "/",
    url: url_ListDocumentClassificationJobs_594313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassifiers_594330 = ref object of OpenApiRestCall_593389
proc url_ListDocumentClassifiers_594332(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocumentClassifiers_594331(path: JsonNode; query: JsonNode;
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
  var valid_594333 = query.getOrDefault("MaxResults")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "MaxResults", valid_594333
  var valid_594334 = query.getOrDefault("NextToken")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "NextToken", valid_594334
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
  var valid_594335 = header.getOrDefault("X-Amz-Target")
  valid_594335 = validateParameter(valid_594335, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassifiers"))
  if valid_594335 != nil:
    section.add "X-Amz-Target", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Content-Sha256", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Date")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Date", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Credential")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Credential", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Security-Token")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Security-Token", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Algorithm")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Algorithm", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-SignedHeaders", valid_594342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594344: Call_ListDocumentClassifiers_594330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the document classifiers that you have created.
  ## 
  let valid = call_594344.validator(path, query, header, formData, body)
  let scheme = call_594344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594344.url(scheme.get, call_594344.host, call_594344.base,
                         call_594344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594344, url, valid)

proc call*(call_594345: Call_ListDocumentClassifiers_594330; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocumentClassifiers
  ## Gets a list of the document classifiers that you have created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594346 = newJObject()
  var body_594347 = newJObject()
  add(query_594346, "MaxResults", newJString(MaxResults))
  add(query_594346, "NextToken", newJString(NextToken))
  if body != nil:
    body_594347 = body
  result = call_594345.call(nil, query_594346, nil, nil, body_594347)

var listDocumentClassifiers* = Call_ListDocumentClassifiers_594330(
    name: "listDocumentClassifiers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassifiers",
    validator: validate_ListDocumentClassifiers_594331, base: "/",
    url: url_ListDocumentClassifiers_594332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDominantLanguageDetectionJobs_594348 = ref object of OpenApiRestCall_593389
proc url_ListDominantLanguageDetectionJobs_594350(protocol: Scheme; host: string;
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

proc validate_ListDominantLanguageDetectionJobs_594349(path: JsonNode;
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
  var valid_594351 = query.getOrDefault("MaxResults")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "MaxResults", valid_594351
  var valid_594352 = query.getOrDefault("NextToken")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "NextToken", valid_594352
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
  var valid_594353 = header.getOrDefault("X-Amz-Target")
  valid_594353 = validateParameter(valid_594353, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDominantLanguageDetectionJobs"))
  if valid_594353 != nil:
    section.add "X-Amz-Target", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Signature")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Signature", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Content-Sha256", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Date")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Date", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Credential")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Credential", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Security-Token")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Security-Token", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Algorithm")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Algorithm", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-SignedHeaders", valid_594360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594362: Call_ListDominantLanguageDetectionJobs_594348;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  let valid = call_594362.validator(path, query, header, formData, body)
  let scheme = call_594362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594362.url(scheme.get, call_594362.host, call_594362.base,
                         call_594362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594362, url, valid)

proc call*(call_594363: Call_ListDominantLanguageDetectionJobs_594348;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDominantLanguageDetectionJobs
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594364 = newJObject()
  var body_594365 = newJObject()
  add(query_594364, "MaxResults", newJString(MaxResults))
  add(query_594364, "NextToken", newJString(NextToken))
  if body != nil:
    body_594365 = body
  result = call_594363.call(nil, query_594364, nil, nil, body_594365)

var listDominantLanguageDetectionJobs* = Call_ListDominantLanguageDetectionJobs_594348(
    name: "listDominantLanguageDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.ListDominantLanguageDetectionJobs",
    validator: validate_ListDominantLanguageDetectionJobs_594349, base: "/",
    url: url_ListDominantLanguageDetectionJobs_594350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitiesDetectionJobs_594366 = ref object of OpenApiRestCall_593389
proc url_ListEntitiesDetectionJobs_594368(protocol: Scheme; host: string;
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

proc validate_ListEntitiesDetectionJobs_594367(path: JsonNode; query: JsonNode;
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
  var valid_594369 = query.getOrDefault("MaxResults")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "MaxResults", valid_594369
  var valid_594370 = query.getOrDefault("NextToken")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "NextToken", valid_594370
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
  var valid_594371 = header.getOrDefault("X-Amz-Target")
  valid_594371 = validateParameter(valid_594371, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntitiesDetectionJobs"))
  if valid_594371 != nil:
    section.add "X-Amz-Target", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-Content-Sha256", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Date")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Date", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-Credential")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Credential", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Security-Token")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Security-Token", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Algorithm")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Algorithm", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-SignedHeaders", valid_594378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594380: Call_ListEntitiesDetectionJobs_594366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  let valid = call_594380.validator(path, query, header, formData, body)
  let scheme = call_594380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594380.url(scheme.get, call_594380.host, call_594380.base,
                         call_594380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594380, url, valid)

proc call*(call_594381: Call_ListEntitiesDetectionJobs_594366; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntitiesDetectionJobs
  ## Gets a list of the entity detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594382 = newJObject()
  var body_594383 = newJObject()
  add(query_594382, "MaxResults", newJString(MaxResults))
  add(query_594382, "NextToken", newJString(NextToken))
  if body != nil:
    body_594383 = body
  result = call_594381.call(nil, query_594382, nil, nil, body_594383)

var listEntitiesDetectionJobs* = Call_ListEntitiesDetectionJobs_594366(
    name: "listEntitiesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntitiesDetectionJobs",
    validator: validate_ListEntitiesDetectionJobs_594367, base: "/",
    url: url_ListEntitiesDetectionJobs_594368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntityRecognizers_594384 = ref object of OpenApiRestCall_593389
proc url_ListEntityRecognizers_594386(protocol: Scheme; host: string; base: string;
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

proc validate_ListEntityRecognizers_594385(path: JsonNode; query: JsonNode;
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
  var valid_594387 = query.getOrDefault("MaxResults")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "MaxResults", valid_594387
  var valid_594388 = query.getOrDefault("NextToken")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "NextToken", valid_594388
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
  var valid_594389 = header.getOrDefault("X-Amz-Target")
  valid_594389 = validateParameter(valid_594389, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntityRecognizers"))
  if valid_594389 != nil:
    section.add "X-Amz-Target", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Signature")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Signature", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Content-Sha256", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Date")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Date", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Credential")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Credential", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Security-Token")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Security-Token", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-SignedHeaders", valid_594396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594398: Call_ListEntityRecognizers_594384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  let valid = call_594398.validator(path, query, header, formData, body)
  let scheme = call_594398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594398.url(scheme.get, call_594398.host, call_594398.base,
                         call_594398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594398, url, valid)

proc call*(call_594399: Call_ListEntityRecognizers_594384; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntityRecognizers
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594400 = newJObject()
  var body_594401 = newJObject()
  add(query_594400, "MaxResults", newJString(MaxResults))
  add(query_594400, "NextToken", newJString(NextToken))
  if body != nil:
    body_594401 = body
  result = call_594399.call(nil, query_594400, nil, nil, body_594401)

var listEntityRecognizers* = Call_ListEntityRecognizers_594384(
    name: "listEntityRecognizers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntityRecognizers",
    validator: validate_ListEntityRecognizers_594385, base: "/",
    url: url_ListEntityRecognizers_594386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPhrasesDetectionJobs_594402 = ref object of OpenApiRestCall_593389
proc url_ListKeyPhrasesDetectionJobs_594404(protocol: Scheme; host: string;
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

proc validate_ListKeyPhrasesDetectionJobs_594403(path: JsonNode; query: JsonNode;
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
  var valid_594405 = query.getOrDefault("MaxResults")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "MaxResults", valid_594405
  var valid_594406 = query.getOrDefault("NextToken")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "NextToken", valid_594406
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
  var valid_594407 = header.getOrDefault("X-Amz-Target")
  valid_594407 = validateParameter(valid_594407, JString, required = true, default = newJString(
      "Comprehend_20171127.ListKeyPhrasesDetectionJobs"))
  if valid_594407 != nil:
    section.add "X-Amz-Target", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Signature")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Signature", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Date")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Date", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Credential")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Credential", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Security-Token")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Security-Token", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Algorithm")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Algorithm", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-SignedHeaders", valid_594414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_ListKeyPhrasesDetectionJobs_594402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_ListKeyPhrasesDetectionJobs_594402; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listKeyPhrasesDetectionJobs
  ## Get a list of key phrase detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594418 = newJObject()
  var body_594419 = newJObject()
  add(query_594418, "MaxResults", newJString(MaxResults))
  add(query_594418, "NextToken", newJString(NextToken))
  if body != nil:
    body_594419 = body
  result = call_594417.call(nil, query_594418, nil, nil, body_594419)

var listKeyPhrasesDetectionJobs* = Call_ListKeyPhrasesDetectionJobs_594402(
    name: "listKeyPhrasesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListKeyPhrasesDetectionJobs",
    validator: validate_ListKeyPhrasesDetectionJobs_594403, base: "/",
    url: url_ListKeyPhrasesDetectionJobs_594404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSentimentDetectionJobs_594420 = ref object of OpenApiRestCall_593389
proc url_ListSentimentDetectionJobs_594422(protocol: Scheme; host: string;
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

proc validate_ListSentimentDetectionJobs_594421(path: JsonNode; query: JsonNode;
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
  var valid_594423 = query.getOrDefault("MaxResults")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "MaxResults", valid_594423
  var valid_594424 = query.getOrDefault("NextToken")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "NextToken", valid_594424
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
  var valid_594425 = header.getOrDefault("X-Amz-Target")
  valid_594425 = validateParameter(valid_594425, JString, required = true, default = newJString(
      "Comprehend_20171127.ListSentimentDetectionJobs"))
  if valid_594425 != nil:
    section.add "X-Amz-Target", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Date")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Date", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Credential")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Credential", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Security-Token")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Security-Token", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Algorithm")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Algorithm", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-SignedHeaders", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_ListSentimentDetectionJobs_594420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_ListSentimentDetectionJobs_594420; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSentimentDetectionJobs
  ## Gets a list of sentiment detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594436 = newJObject()
  var body_594437 = newJObject()
  add(query_594436, "MaxResults", newJString(MaxResults))
  add(query_594436, "NextToken", newJString(NextToken))
  if body != nil:
    body_594437 = body
  result = call_594435.call(nil, query_594436, nil, nil, body_594437)

var listSentimentDetectionJobs* = Call_ListSentimentDetectionJobs_594420(
    name: "listSentimentDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListSentimentDetectionJobs",
    validator: validate_ListSentimentDetectionJobs_594421, base: "/",
    url: url_ListSentimentDetectionJobs_594422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594438 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594440(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594439(path: JsonNode; query: JsonNode;
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
  var valid_594441 = header.getOrDefault("X-Amz-Target")
  valid_594441 = validateParameter(valid_594441, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTagsForResource"))
  if valid_594441 != nil:
    section.add "X-Amz-Target", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Signature")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Signature", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Date")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Date", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Credential")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Credential", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Security-Token")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Security-Token", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Algorithm")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Algorithm", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-SignedHeaders", valid_594448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594450: Call_ListTagsForResource_594438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  let valid = call_594450.validator(path, query, header, formData, body)
  let scheme = call_594450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594450.url(scheme.get, call_594450.host, call_594450.base,
                         call_594450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594450, url, valid)

proc call*(call_594451: Call_ListTagsForResource_594438; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_594452 = newJObject()
  if body != nil:
    body_594452 = body
  result = call_594451.call(nil, nil, nil, nil, body_594452)

var listTagsForResource* = Call_ListTagsForResource_594438(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTagsForResource",
    validator: validate_ListTagsForResource_594439, base: "/",
    url: url_ListTagsForResource_594440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTopicsDetectionJobs_594453 = ref object of OpenApiRestCall_593389
proc url_ListTopicsDetectionJobs_594455(protocol: Scheme; host: string; base: string;
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

proc validate_ListTopicsDetectionJobs_594454(path: JsonNode; query: JsonNode;
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
  var valid_594456 = query.getOrDefault("MaxResults")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "MaxResults", valid_594456
  var valid_594457 = query.getOrDefault("NextToken")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "NextToken", valid_594457
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
  var valid_594458 = header.getOrDefault("X-Amz-Target")
  valid_594458 = validateParameter(valid_594458, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTopicsDetectionJobs"))
  if valid_594458 != nil:
    section.add "X-Amz-Target", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Signature")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Signature", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Content-Sha256", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Date")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Date", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Security-Token")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Security-Token", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Algorithm")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Algorithm", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-SignedHeaders", valid_594465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594467: Call_ListTopicsDetectionJobs_594453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  let valid = call_594467.validator(path, query, header, formData, body)
  let scheme = call_594467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594467.url(scheme.get, call_594467.host, call_594467.base,
                         call_594467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594467, url, valid)

proc call*(call_594468: Call_ListTopicsDetectionJobs_594453; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTopicsDetectionJobs
  ## Gets a list of the topic detection jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594469 = newJObject()
  var body_594470 = newJObject()
  add(query_594469, "MaxResults", newJString(MaxResults))
  add(query_594469, "NextToken", newJString(NextToken))
  if body != nil:
    body_594470 = body
  result = call_594468.call(nil, query_594469, nil, nil, body_594470)

var listTopicsDetectionJobs* = Call_ListTopicsDetectionJobs_594453(
    name: "listTopicsDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTopicsDetectionJobs",
    validator: validate_ListTopicsDetectionJobs_594454, base: "/",
    url: url_ListTopicsDetectionJobs_594455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDocumentClassificationJob_594471 = ref object of OpenApiRestCall_593389
proc url_StartDocumentClassificationJob_594473(protocol: Scheme; host: string;
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

proc validate_StartDocumentClassificationJob_594472(path: JsonNode;
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
  var valid_594474 = header.getOrDefault("X-Amz-Target")
  valid_594474 = validateParameter(valid_594474, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDocumentClassificationJob"))
  if valid_594474 != nil:
    section.add "X-Amz-Target", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Signature")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Signature", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Content-Sha256", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Date")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Date", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Credential")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Credential", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Security-Token")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Security-Token", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Algorithm")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Algorithm", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-SignedHeaders", valid_594481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594483: Call_StartDocumentClassificationJob_594471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  let valid = call_594483.validator(path, query, header, formData, body)
  let scheme = call_594483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594483.url(scheme.get, call_594483.host, call_594483.base,
                         call_594483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594483, url, valid)

proc call*(call_594484: Call_StartDocumentClassificationJob_594471; body: JsonNode): Recallable =
  ## startDocumentClassificationJob
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ##   body: JObject (required)
  var body_594485 = newJObject()
  if body != nil:
    body_594485 = body
  result = call_594484.call(nil, nil, nil, nil, body_594485)

var startDocumentClassificationJob* = Call_StartDocumentClassificationJob_594471(
    name: "startDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartDocumentClassificationJob",
    validator: validate_StartDocumentClassificationJob_594472, base: "/",
    url: url_StartDocumentClassificationJob_594473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDominantLanguageDetectionJob_594486 = ref object of OpenApiRestCall_593389
proc url_StartDominantLanguageDetectionJob_594488(protocol: Scheme; host: string;
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

proc validate_StartDominantLanguageDetectionJob_594487(path: JsonNode;
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
  var valid_594489 = header.getOrDefault("X-Amz-Target")
  valid_594489 = validateParameter(valid_594489, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDominantLanguageDetectionJob"))
  if valid_594489 != nil:
    section.add "X-Amz-Target", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Signature")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Signature", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Content-Sha256", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Date")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Date", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Credential")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Credential", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Security-Token")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Security-Token", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Algorithm")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Algorithm", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-SignedHeaders", valid_594496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594498: Call_StartDominantLanguageDetectionJob_594486;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_594498.validator(path, query, header, formData, body)
  let scheme = call_594498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594498.url(scheme.get, call_594498.host, call_594498.base,
                         call_594498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594498, url, valid)

proc call*(call_594499: Call_StartDominantLanguageDetectionJob_594486;
          body: JsonNode): Recallable =
  ## startDominantLanguageDetectionJob
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_594500 = newJObject()
  if body != nil:
    body_594500 = body
  result = call_594499.call(nil, nil, nil, nil, body_594500)

var startDominantLanguageDetectionJob* = Call_StartDominantLanguageDetectionJob_594486(
    name: "startDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StartDominantLanguageDetectionJob",
    validator: validate_StartDominantLanguageDetectionJob_594487, base: "/",
    url: url_StartDominantLanguageDetectionJob_594488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartEntitiesDetectionJob_594501 = ref object of OpenApiRestCall_593389
proc url_StartEntitiesDetectionJob_594503(protocol: Scheme; host: string;
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

proc validate_StartEntitiesDetectionJob_594502(path: JsonNode; query: JsonNode;
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
  var valid_594504 = header.getOrDefault("X-Amz-Target")
  valid_594504 = validateParameter(valid_594504, JString, required = true, default = newJString(
      "Comprehend_20171127.StartEntitiesDetectionJob"))
  if valid_594504 != nil:
    section.add "X-Amz-Target", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Signature")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Signature", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Content-Sha256", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Date")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Date", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Credential")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Credential", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Security-Token")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Security-Token", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Algorithm")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Algorithm", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-SignedHeaders", valid_594511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594513: Call_StartEntitiesDetectionJob_594501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  let valid = call_594513.validator(path, query, header, formData, body)
  let scheme = call_594513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594513.url(scheme.get, call_594513.host, call_594513.base,
                         call_594513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594513, url, valid)

proc call*(call_594514: Call_StartEntitiesDetectionJob_594501; body: JsonNode): Recallable =
  ## startEntitiesDetectionJob
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ##   body: JObject (required)
  var body_594515 = newJObject()
  if body != nil:
    body_594515 = body
  result = call_594514.call(nil, nil, nil, nil, body_594515)

var startEntitiesDetectionJob* = Call_StartEntitiesDetectionJob_594501(
    name: "startEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartEntitiesDetectionJob",
    validator: validate_StartEntitiesDetectionJob_594502, base: "/",
    url: url_StartEntitiesDetectionJob_594503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartKeyPhrasesDetectionJob_594516 = ref object of OpenApiRestCall_593389
proc url_StartKeyPhrasesDetectionJob_594518(protocol: Scheme; host: string;
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

proc validate_StartKeyPhrasesDetectionJob_594517(path: JsonNode; query: JsonNode;
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
  var valid_594519 = header.getOrDefault("X-Amz-Target")
  valid_594519 = validateParameter(valid_594519, JString, required = true, default = newJString(
      "Comprehend_20171127.StartKeyPhrasesDetectionJob"))
  if valid_594519 != nil:
    section.add "X-Amz-Target", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Signature")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Signature", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Content-Sha256", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Date")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Date", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Credential")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Credential", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Security-Token")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Security-Token", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Algorithm")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Algorithm", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-SignedHeaders", valid_594526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594528: Call_StartKeyPhrasesDetectionJob_594516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_594528.validator(path, query, header, formData, body)
  let scheme = call_594528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594528.url(scheme.get, call_594528.host, call_594528.base,
                         call_594528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594528, url, valid)

proc call*(call_594529: Call_StartKeyPhrasesDetectionJob_594516; body: JsonNode): Recallable =
  ## startKeyPhrasesDetectionJob
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_594530 = newJObject()
  if body != nil:
    body_594530 = body
  result = call_594529.call(nil, nil, nil, nil, body_594530)

var startKeyPhrasesDetectionJob* = Call_StartKeyPhrasesDetectionJob_594516(
    name: "startKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartKeyPhrasesDetectionJob",
    validator: validate_StartKeyPhrasesDetectionJob_594517, base: "/",
    url: url_StartKeyPhrasesDetectionJob_594518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSentimentDetectionJob_594531 = ref object of OpenApiRestCall_593389
proc url_StartSentimentDetectionJob_594533(protocol: Scheme; host: string;
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

proc validate_StartSentimentDetectionJob_594532(path: JsonNode; query: JsonNode;
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
  var valid_594534 = header.getOrDefault("X-Amz-Target")
  valid_594534 = validateParameter(valid_594534, JString, required = true, default = newJString(
      "Comprehend_20171127.StartSentimentDetectionJob"))
  if valid_594534 != nil:
    section.add "X-Amz-Target", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Signature")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Signature", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Content-Sha256", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Date")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Date", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Credential")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Credential", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Security-Token")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Security-Token", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Algorithm")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Algorithm", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-SignedHeaders", valid_594541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594543: Call_StartSentimentDetectionJob_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  let valid = call_594543.validator(path, query, header, formData, body)
  let scheme = call_594543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594543.url(scheme.get, call_594543.host, call_594543.base,
                         call_594543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594543, url, valid)

proc call*(call_594544: Call_StartSentimentDetectionJob_594531; body: JsonNode): Recallable =
  ## startSentimentDetectionJob
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_594545 = newJObject()
  if body != nil:
    body_594545 = body
  result = call_594544.call(nil, nil, nil, nil, body_594545)

var startSentimentDetectionJob* = Call_StartSentimentDetectionJob_594531(
    name: "startSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartSentimentDetectionJob",
    validator: validate_StartSentimentDetectionJob_594532, base: "/",
    url: url_StartSentimentDetectionJob_594533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTopicsDetectionJob_594546 = ref object of OpenApiRestCall_593389
proc url_StartTopicsDetectionJob_594548(protocol: Scheme; host: string; base: string;
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

proc validate_StartTopicsDetectionJob_594547(path: JsonNode; query: JsonNode;
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
  var valid_594549 = header.getOrDefault("X-Amz-Target")
  valid_594549 = validateParameter(valid_594549, JString, required = true, default = newJString(
      "Comprehend_20171127.StartTopicsDetectionJob"))
  if valid_594549 != nil:
    section.add "X-Amz-Target", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Signature")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Signature", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Content-Sha256", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Date")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Date", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Credential")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Credential", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Security-Token")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Security-Token", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Algorithm")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Algorithm", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-SignedHeaders", valid_594556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594558: Call_StartTopicsDetectionJob_594546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  let valid = call_594558.validator(path, query, header, formData, body)
  let scheme = call_594558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594558.url(scheme.get, call_594558.host, call_594558.base,
                         call_594558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594558, url, valid)

proc call*(call_594559: Call_StartTopicsDetectionJob_594546; body: JsonNode): Recallable =
  ## startTopicsDetectionJob
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ##   body: JObject (required)
  var body_594560 = newJObject()
  if body != nil:
    body_594560 = body
  result = call_594559.call(nil, nil, nil, nil, body_594560)

var startTopicsDetectionJob* = Call_StartTopicsDetectionJob_594546(
    name: "startTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartTopicsDetectionJob",
    validator: validate_StartTopicsDetectionJob_594547, base: "/",
    url: url_StartTopicsDetectionJob_594548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDominantLanguageDetectionJob_594561 = ref object of OpenApiRestCall_593389
proc url_StopDominantLanguageDetectionJob_594563(protocol: Scheme; host: string;
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

proc validate_StopDominantLanguageDetectionJob_594562(path: JsonNode;
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
  var valid_594564 = header.getOrDefault("X-Amz-Target")
  valid_594564 = validateParameter(valid_594564, JString, required = true, default = newJString(
      "Comprehend_20171127.StopDominantLanguageDetectionJob"))
  if valid_594564 != nil:
    section.add "X-Amz-Target", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Signature")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Signature", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Content-Sha256", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Credential")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Credential", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Security-Token")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Security-Token", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Algorithm")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Algorithm", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-SignedHeaders", valid_594571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594573: Call_StopDominantLanguageDetectionJob_594561;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_594573.validator(path, query, header, formData, body)
  let scheme = call_594573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594573.url(scheme.get, call_594573.host, call_594573.base,
                         call_594573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594573, url, valid)

proc call*(call_594574: Call_StopDominantLanguageDetectionJob_594561;
          body: JsonNode): Recallable =
  ## stopDominantLanguageDetectionJob
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_594575 = newJObject()
  if body != nil:
    body_594575 = body
  result = call_594574.call(nil, nil, nil, nil, body_594575)

var stopDominantLanguageDetectionJob* = Call_StopDominantLanguageDetectionJob_594561(
    name: "stopDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StopDominantLanguageDetectionJob",
    validator: validate_StopDominantLanguageDetectionJob_594562, base: "/",
    url: url_StopDominantLanguageDetectionJob_594563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopEntitiesDetectionJob_594576 = ref object of OpenApiRestCall_593389
proc url_StopEntitiesDetectionJob_594578(protocol: Scheme; host: string;
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

proc validate_StopEntitiesDetectionJob_594577(path: JsonNode; query: JsonNode;
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
  var valid_594579 = header.getOrDefault("X-Amz-Target")
  valid_594579 = validateParameter(valid_594579, JString, required = true, default = newJString(
      "Comprehend_20171127.StopEntitiesDetectionJob"))
  if valid_594579 != nil:
    section.add "X-Amz-Target", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Signature")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Signature", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Content-Sha256", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Date")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Date", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Credential")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Credential", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-Security-Token")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-Security-Token", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-Algorithm")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Algorithm", valid_594585
  var valid_594586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-SignedHeaders", valid_594586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594588: Call_StopEntitiesDetectionJob_594576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_594588.validator(path, query, header, formData, body)
  let scheme = call_594588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594588.url(scheme.get, call_594588.host, call_594588.base,
                         call_594588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594588, url, valid)

proc call*(call_594589: Call_StopEntitiesDetectionJob_594576; body: JsonNode): Recallable =
  ## stopEntitiesDetectionJob
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_594590 = newJObject()
  if body != nil:
    body_594590 = body
  result = call_594589.call(nil, nil, nil, nil, body_594590)

var stopEntitiesDetectionJob* = Call_StopEntitiesDetectionJob_594576(
    name: "stopEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopEntitiesDetectionJob",
    validator: validate_StopEntitiesDetectionJob_594577, base: "/",
    url: url_StopEntitiesDetectionJob_594578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopKeyPhrasesDetectionJob_594591 = ref object of OpenApiRestCall_593389
proc url_StopKeyPhrasesDetectionJob_594593(protocol: Scheme; host: string;
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

proc validate_StopKeyPhrasesDetectionJob_594592(path: JsonNode; query: JsonNode;
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
  var valid_594594 = header.getOrDefault("X-Amz-Target")
  valid_594594 = validateParameter(valid_594594, JString, required = true, default = newJString(
      "Comprehend_20171127.StopKeyPhrasesDetectionJob"))
  if valid_594594 != nil:
    section.add "X-Amz-Target", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Signature")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Signature", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Content-Sha256", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Date")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Date", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Credential")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Credential", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Security-Token")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Security-Token", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Algorithm")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Algorithm", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-SignedHeaders", valid_594601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594603: Call_StopKeyPhrasesDetectionJob_594591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_594603.validator(path, query, header, formData, body)
  let scheme = call_594603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594603.url(scheme.get, call_594603.host, call_594603.base,
                         call_594603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594603, url, valid)

proc call*(call_594604: Call_StopKeyPhrasesDetectionJob_594591; body: JsonNode): Recallable =
  ## stopKeyPhrasesDetectionJob
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_594605 = newJObject()
  if body != nil:
    body_594605 = body
  result = call_594604.call(nil, nil, nil, nil, body_594605)

var stopKeyPhrasesDetectionJob* = Call_StopKeyPhrasesDetectionJob_594591(
    name: "stopKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopKeyPhrasesDetectionJob",
    validator: validate_StopKeyPhrasesDetectionJob_594592, base: "/",
    url: url_StopKeyPhrasesDetectionJob_594593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopSentimentDetectionJob_594606 = ref object of OpenApiRestCall_593389
proc url_StopSentimentDetectionJob_594608(protocol: Scheme; host: string;
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

proc validate_StopSentimentDetectionJob_594607(path: JsonNode; query: JsonNode;
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
  var valid_594609 = header.getOrDefault("X-Amz-Target")
  valid_594609 = validateParameter(valid_594609, JString, required = true, default = newJString(
      "Comprehend_20171127.StopSentimentDetectionJob"))
  if valid_594609 != nil:
    section.add "X-Amz-Target", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Signature")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Signature", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Content-Sha256", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Date")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Date", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Credential")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Credential", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Security-Token")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Security-Token", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Algorithm")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Algorithm", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-SignedHeaders", valid_594616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594618: Call_StopSentimentDetectionJob_594606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_594618.validator(path, query, header, formData, body)
  let scheme = call_594618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594618.url(scheme.get, call_594618.host, call_594618.base,
                         call_594618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594618, url, valid)

proc call*(call_594619: Call_StopSentimentDetectionJob_594606; body: JsonNode): Recallable =
  ## stopSentimentDetectionJob
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_594620 = newJObject()
  if body != nil:
    body_594620 = body
  result = call_594619.call(nil, nil, nil, nil, body_594620)

var stopSentimentDetectionJob* = Call_StopSentimentDetectionJob_594606(
    name: "stopSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopSentimentDetectionJob",
    validator: validate_StopSentimentDetectionJob_594607, base: "/",
    url: url_StopSentimentDetectionJob_594608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingDocumentClassifier_594621 = ref object of OpenApiRestCall_593389
proc url_StopTrainingDocumentClassifier_594623(protocol: Scheme; host: string;
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

proc validate_StopTrainingDocumentClassifier_594622(path: JsonNode;
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
  var valid_594624 = header.getOrDefault("X-Amz-Target")
  valid_594624 = validateParameter(valid_594624, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingDocumentClassifier"))
  if valid_594624 != nil:
    section.add "X-Amz-Target", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Signature")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Signature", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Content-Sha256", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Date")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Date", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Credential")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Credential", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Security-Token")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Security-Token", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Algorithm")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Algorithm", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-SignedHeaders", valid_594631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594633: Call_StopTrainingDocumentClassifier_594621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  let valid = call_594633.validator(path, query, header, formData, body)
  let scheme = call_594633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594633.url(scheme.get, call_594633.host, call_594633.base,
                         call_594633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594633, url, valid)

proc call*(call_594634: Call_StopTrainingDocumentClassifier_594621; body: JsonNode): Recallable =
  ## stopTrainingDocumentClassifier
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ##   body: JObject (required)
  var body_594635 = newJObject()
  if body != nil:
    body_594635 = body
  result = call_594634.call(nil, nil, nil, nil, body_594635)

var stopTrainingDocumentClassifier* = Call_StopTrainingDocumentClassifier_594621(
    name: "stopTrainingDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingDocumentClassifier",
    validator: validate_StopTrainingDocumentClassifier_594622, base: "/",
    url: url_StopTrainingDocumentClassifier_594623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingEntityRecognizer_594636 = ref object of OpenApiRestCall_593389
proc url_StopTrainingEntityRecognizer_594638(protocol: Scheme; host: string;
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

proc validate_StopTrainingEntityRecognizer_594637(path: JsonNode; query: JsonNode;
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
  var valid_594639 = header.getOrDefault("X-Amz-Target")
  valid_594639 = validateParameter(valid_594639, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingEntityRecognizer"))
  if valid_594639 != nil:
    section.add "X-Amz-Target", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Signature")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Signature", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Content-Sha256", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Date")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Date", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Credential")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Credential", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Security-Token")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Security-Token", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Algorithm")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Algorithm", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-SignedHeaders", valid_594646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594648: Call_StopTrainingEntityRecognizer_594636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  let valid = call_594648.validator(path, query, header, formData, body)
  let scheme = call_594648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594648.url(scheme.get, call_594648.host, call_594648.base,
                         call_594648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594648, url, valid)

proc call*(call_594649: Call_StopTrainingEntityRecognizer_594636; body: JsonNode): Recallable =
  ## stopTrainingEntityRecognizer
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ##   body: JObject (required)
  var body_594650 = newJObject()
  if body != nil:
    body_594650 = body
  result = call_594649.call(nil, nil, nil, nil, body_594650)

var stopTrainingEntityRecognizer* = Call_StopTrainingEntityRecognizer_594636(
    name: "stopTrainingEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingEntityRecognizer",
    validator: validate_StopTrainingEntityRecognizer_594637, base: "/",
    url: url_StopTrainingEntityRecognizer_594638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594651 = ref object of OpenApiRestCall_593389
proc url_TagResource_594653(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594652(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594654 = header.getOrDefault("X-Amz-Target")
  valid_594654 = validateParameter(valid_594654, JString, required = true, default = newJString(
      "Comprehend_20171127.TagResource"))
  if valid_594654 != nil:
    section.add "X-Amz-Target", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Signature")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Signature", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Content-Sha256", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Date")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Date", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Credential")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Credential", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Security-Token")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Security-Token", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Algorithm")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Algorithm", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-SignedHeaders", valid_594661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594663: Call_TagResource_594651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  let valid = call_594663.validator(path, query, header, formData, body)
  let scheme = call_594663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594663.url(scheme.get, call_594663.host, call_594663.base,
                         call_594663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594663, url, valid)

proc call*(call_594664: Call_TagResource_594651; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ##   body: JObject (required)
  var body_594665 = newJObject()
  if body != nil:
    body_594665 = body
  result = call_594664.call(nil, nil, nil, nil, body_594665)

var tagResource* = Call_TagResource_594651(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.TagResource",
                                        validator: validate_TagResource_594652,
                                        base: "/", url: url_TagResource_594653,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594666 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594668(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594667(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594669 = header.getOrDefault("X-Amz-Target")
  valid_594669 = validateParameter(valid_594669, JString, required = true, default = newJString(
      "Comprehend_20171127.UntagResource"))
  if valid_594669 != nil:
    section.add "X-Amz-Target", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Signature")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Signature", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Content-Sha256", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Date")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Date", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Credential")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Credential", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Security-Token")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Security-Token", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Algorithm")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Algorithm", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-SignedHeaders", valid_594676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594678: Call_UntagResource_594666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  let valid = call_594678.validator(path, query, header, formData, body)
  let scheme = call_594678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594678.url(scheme.get, call_594678.host, call_594678.base,
                         call_594678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594678, url, valid)

proc call*(call_594679: Call_UntagResource_594666; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_594680 = newJObject()
  if body != nil:
    body_594680 = body
  result = call_594679.call(nil, nil, nil, nil, body_594680)

var untagResource* = Call_UntagResource_594666(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UntagResource",
    validator: validate_UntagResource_594667, base: "/", url: url_UntagResource_594668,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
