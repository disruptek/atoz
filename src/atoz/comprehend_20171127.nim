
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_BatchDetectDominantLanguage_602803 = ref object of OpenApiRestCall_602466
proc url_BatchDetectDominantLanguage_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDetectDominantLanguage_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectDominantLanguage"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_BatchDetectDominantLanguage_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_BatchDetectDominantLanguage_602803; body: JsonNode): Recallable =
  ## batchDetectDominantLanguage
  ## Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var batchDetectDominantLanguage* = Call_BatchDetectDominantLanguage_602803(
    name: "batchDetectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectDominantLanguage",
    validator: validate_BatchDetectDominantLanguage_602804, base: "/",
    url: url_BatchDetectDominantLanguage_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectEntities_603072 = ref object of OpenApiRestCall_602466
proc url_BatchDetectEntities_603074(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDetectEntities_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectEntities"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchDetectEntities_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchDetectEntities_603072; body: JsonNode): Recallable =
  ## batchDetectEntities
  ## Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see <a>how-entities</a> 
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchDetectEntities* = Call_BatchDetectEntities_603072(
    name: "batchDetectEntities", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectEntities",
    validator: validate_BatchDetectEntities_603073, base: "/",
    url: url_BatchDetectEntities_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectKeyPhrases_603087 = ref object of OpenApiRestCall_602466
proc url_BatchDetectKeyPhrases_603089(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDetectKeyPhrases_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectKeyPhrases"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_BatchDetectKeyPhrases_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in a batch of documents.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_BatchDetectKeyPhrases_603087; body: JsonNode): Recallable =
  ## batchDetectKeyPhrases
  ## Detects the key noun phrases found in a batch of documents.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var batchDetectKeyPhrases* = Call_BatchDetectKeyPhrases_603087(
    name: "batchDetectKeyPhrases", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectKeyPhrases",
    validator: validate_BatchDetectKeyPhrases_603088, base: "/",
    url: url_BatchDetectKeyPhrases_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSentiment_603102 = ref object of OpenApiRestCall_602466
proc url_BatchDetectSentiment_603104(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDetectSentiment_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSentiment"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_BatchDetectSentiment_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_BatchDetectSentiment_603102; body: JsonNode): Recallable =
  ## batchDetectSentiment
  ## Inspects a batch of documents and returns an inference of the prevailing sentiment, <code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>, in each one.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var batchDetectSentiment* = Call_BatchDetectSentiment_603102(
    name: "batchDetectSentiment", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSentiment",
    validator: validate_BatchDetectSentiment_603103, base: "/",
    url: url_BatchDetectSentiment_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDetectSyntax_603117 = ref object of OpenApiRestCall_602466
proc url_BatchDetectSyntax_603119(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDetectSyntax_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "Comprehend_20171127.BatchDetectSyntax"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_BatchDetectSyntax_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_BatchDetectSyntax_603117; body: JsonNode): Recallable =
  ## batchDetectSyntax
  ## Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var batchDetectSyntax* = Call_BatchDetectSyntax_603117(name: "batchDetectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.BatchDetectSyntax",
    validator: validate_BatchDetectSyntax_603118, base: "/",
    url: url_BatchDetectSyntax_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentClassifier_603132 = ref object of OpenApiRestCall_602466
proc url_CreateDocumentClassifier_603134(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDocumentClassifier_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateDocumentClassifier"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateDocumentClassifier_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateDocumentClassifier_603132; body: JsonNode): Recallable =
  ## createDocumentClassifier
  ## Creates a new document classifier that you can use to categorize documents. To create a classifier you provide a set of training documents that labeled with the categories that you want to use. After the classifier is trained you can use it to categorize a set of labeled documents into the categories. For more information, see <a>how-document-classification</a>.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createDocumentClassifier* = Call_CreateDocumentClassifier_603132(
    name: "createDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateDocumentClassifier",
    validator: validate_CreateDocumentClassifier_603133, base: "/",
    url: url_CreateDocumentClassifier_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEntityRecognizer_603147 = ref object of OpenApiRestCall_602466
proc url_CreateEntityRecognizer_603149(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEntityRecognizer_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "Comprehend_20171127.CreateEntityRecognizer"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateEntityRecognizer_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateEntityRecognizer_603147; body: JsonNode): Recallable =
  ## createEntityRecognizer
  ## Creates an entity recognizer using submitted files. After your <code>CreateEntityRecognizer</code> request is submitted, you can check job status using the API. 
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createEntityRecognizer* = Call_CreateEntityRecognizer_603147(
    name: "createEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.CreateEntityRecognizer",
    validator: validate_CreateEntityRecognizer_603148, base: "/",
    url: url_CreateEntityRecognizer_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentClassifier_603162 = ref object of OpenApiRestCall_602466
proc url_DeleteDocumentClassifier_603164(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDocumentClassifier_603163(path: JsonNode; query: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteDocumentClassifier"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeleteDocumentClassifier_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeleteDocumentClassifier_603162; body: JsonNode): Recallable =
  ## deleteDocumentClassifier
  ## <p>Deletes a previously created document classifier</p> <p>Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deleteDocumentClassifier* = Call_DeleteDocumentClassifier_603162(
    name: "deleteDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteDocumentClassifier",
    validator: validate_DeleteDocumentClassifier_603163, base: "/",
    url: url_DeleteDocumentClassifier_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEntityRecognizer_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteEntityRecognizer_603179(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEntityRecognizer_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "Comprehend_20171127.DeleteEntityRecognizer"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteEntityRecognizer_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteEntityRecognizer_603177; body: JsonNode): Recallable =
  ## deleteEntityRecognizer
  ## <p>Deletes an entity recognizer.</p> <p>Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a <code>ResourceInUseException</code> will be returned.</p> <p>This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use. </p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteEntityRecognizer* = Call_DeleteEntityRecognizer_603177(
    name: "deleteEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DeleteEntityRecognizer",
    validator: validate_DeleteEntityRecognizer_603178, base: "/",
    url: url_DeleteEntityRecognizer_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassificationJob_603192 = ref object of OpenApiRestCall_602466
proc url_DescribeDocumentClassificationJob_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocumentClassificationJob_603193(path: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassificationJob"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DescribeDocumentClassificationJob_603192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DescribeDocumentClassificationJob_603192;
          body: JsonNode): Recallable =
  ## describeDocumentClassificationJob
  ## Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var describeDocumentClassificationJob* = Call_DescribeDocumentClassificationJob_603192(
    name: "describeDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassificationJob",
    validator: validate_DescribeDocumentClassificationJob_603193, base: "/",
    url: url_DescribeDocumentClassificationJob_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentClassifier_603207 = ref object of OpenApiRestCall_602466
proc url_DescribeDocumentClassifier_603209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocumentClassifier_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDocumentClassifier"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DescribeDocumentClassifier_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a document classifier.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DescribeDocumentClassifier_603207; body: JsonNode): Recallable =
  ## describeDocumentClassifier
  ## Gets the properties associated with a document classifier.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var describeDocumentClassifier* = Call_DescribeDocumentClassifier_603207(
    name: "describeDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeDocumentClassifier",
    validator: validate_DescribeDocumentClassifier_603208, base: "/",
    url: url_DescribeDocumentClassifier_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDominantLanguageDetectionJob_603222 = ref object of OpenApiRestCall_602466
proc url_DescribeDominantLanguageDetectionJob_603224(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDominantLanguageDetectionJob_603223(path: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeDominantLanguageDetectionJob"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DescribeDominantLanguageDetectionJob_603222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DescribeDominantLanguageDetectionJob_603222;
          body: JsonNode): Recallable =
  ## describeDominantLanguageDetectionJob
  ## Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var describeDominantLanguageDetectionJob* = Call_DescribeDominantLanguageDetectionJob_603222(
    name: "describeDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.DescribeDominantLanguageDetectionJob",
    validator: validate_DescribeDominantLanguageDetectionJob_603223, base: "/",
    url: url_DescribeDominantLanguageDetectionJob_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntitiesDetectionJob_603237 = ref object of OpenApiRestCall_602466
proc url_DescribeEntitiesDetectionJob_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEntitiesDetectionJob_603238(path: JsonNode; query: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntitiesDetectionJob"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DescribeEntitiesDetectionJob_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DescribeEntitiesDetectionJob_603237; body: JsonNode): Recallable =
  ## describeEntitiesDetectionJob
  ## Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var describeEntitiesDetectionJob* = Call_DescribeEntitiesDetectionJob_603237(
    name: "describeEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntitiesDetectionJob",
    validator: validate_DescribeEntitiesDetectionJob_603238, base: "/",
    url: url_DescribeEntitiesDetectionJob_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityRecognizer_603252 = ref object of OpenApiRestCall_602466
proc url_DescribeEntityRecognizer_603254(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEntityRecognizer_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeEntityRecognizer"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DescribeEntityRecognizer_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DescribeEntityRecognizer_603252; body: JsonNode): Recallable =
  ## describeEntityRecognizer
  ## Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var describeEntityRecognizer* = Call_DescribeEntityRecognizer_603252(
    name: "describeEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeEntityRecognizer",
    validator: validate_DescribeEntityRecognizer_603253, base: "/",
    url: url_DescribeEntityRecognizer_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKeyPhrasesDetectionJob_603267 = ref object of OpenApiRestCall_602466
proc url_DescribeKeyPhrasesDetectionJob_603269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeKeyPhrasesDetectionJob_603268(path: JsonNode;
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DescribeKeyPhrasesDetectionJob_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DescribeKeyPhrasesDetectionJob_603267; body: JsonNode): Recallable =
  ## describeKeyPhrasesDetectionJob
  ## Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var describeKeyPhrasesDetectionJob* = Call_DescribeKeyPhrasesDetectionJob_603267(
    name: "describeKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeKeyPhrasesDetectionJob",
    validator: validate_DescribeKeyPhrasesDetectionJob_603268, base: "/",
    url: url_DescribeKeyPhrasesDetectionJob_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSentimentDetectionJob_603282 = ref object of OpenApiRestCall_602466
proc url_DescribeSentimentDetectionJob_603284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSentimentDetectionJob_603283(path: JsonNode; query: JsonNode;
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeSentimentDetectionJob"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_DescribeSentimentDetectionJob_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_DescribeSentimentDetectionJob_603282; body: JsonNode): Recallable =
  ## describeSentimentDetectionJob
  ## Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var describeSentimentDetectionJob* = Call_DescribeSentimentDetectionJob_603282(
    name: "describeSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeSentimentDetectionJob",
    validator: validate_DescribeSentimentDetectionJob_603283, base: "/",
    url: url_DescribeSentimentDetectionJob_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTopicsDetectionJob_603297 = ref object of OpenApiRestCall_602466
proc url_DescribeTopicsDetectionJob_603299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTopicsDetectionJob_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "Comprehend_20171127.DescribeTopicsDetectionJob"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DescribeTopicsDetectionJob_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DescribeTopicsDetectionJob_603297; body: JsonNode): Recallable =
  ## describeTopicsDetectionJob
  ## Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var describeTopicsDetectionJob* = Call_DescribeTopicsDetectionJob_603297(
    name: "describeTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DescribeTopicsDetectionJob",
    validator: validate_DescribeTopicsDetectionJob_603298, base: "/",
    url: url_DescribeTopicsDetectionJob_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectDominantLanguage_603312 = ref object of OpenApiRestCall_602466
proc url_DetectDominantLanguage_603314(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetectDominantLanguage_603313(path: JsonNode; query: JsonNode;
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectDominantLanguage"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DetectDominantLanguage_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DetectDominantLanguage_603312; body: JsonNode): Recallable =
  ## detectDominantLanguage
  ## Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see <a href="https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html">Amazon Comprehend Supported Languages</a>. 
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var detectDominantLanguage* = Call_DetectDominantLanguage_603312(
    name: "detectDominantLanguage", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectDominantLanguage",
    validator: validate_DetectDominantLanguage_603313, base: "/",
    url: url_DetectDominantLanguage_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectEntities_603327 = ref object of OpenApiRestCall_602466
proc url_DetectEntities_603329(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetectEntities_603328(path: JsonNode; query: JsonNode;
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectEntities"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DetectEntities_603327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DetectEntities_603327; body: JsonNode): Recallable =
  ## detectEntities
  ## Inspects text for named entities, and returns information about them. For more information, about named entities, see <a>how-entities</a>. 
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var detectEntities* = Call_DetectEntities_603327(name: "detectEntities",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectEntities",
    validator: validate_DetectEntities_603328, base: "/", url: url_DetectEntities_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectKeyPhrases_603342 = ref object of OpenApiRestCall_602466
proc url_DetectKeyPhrases_603344(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetectKeyPhrases_603343(path: JsonNode; query: JsonNode;
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectKeyPhrases"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DetectKeyPhrases_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detects the key noun phrases found in the text. 
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DetectKeyPhrases_603342; body: JsonNode): Recallable =
  ## detectKeyPhrases
  ## Detects the key noun phrases found in the text. 
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var detectKeyPhrases* = Call_DetectKeyPhrases_603342(name: "detectKeyPhrases",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectKeyPhrases",
    validator: validate_DetectKeyPhrases_603343, base: "/",
    url: url_DetectKeyPhrases_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSentiment_603357 = ref object of OpenApiRestCall_602466
proc url_DetectSentiment_603359(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetectSentiment_603358(path: JsonNode; query: JsonNode;
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSentiment"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DetectSentiment_603357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DetectSentiment_603357; body: JsonNode): Recallable =
  ## detectSentiment
  ## Inspects text and returns an inference of the prevailing sentiment (<code>POSITIVE</code>, <code>NEUTRAL</code>, <code>MIXED</code>, or <code>NEGATIVE</code>). 
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var detectSentiment* = Call_DetectSentiment_603357(name: "detectSentiment",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSentiment",
    validator: validate_DetectSentiment_603358, base: "/", url: url_DetectSentiment_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectSyntax_603372 = ref object of OpenApiRestCall_602466
proc url_DetectSyntax_603374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetectSyntax_603373(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "Comprehend_20171127.DetectSyntax"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DetectSyntax_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DetectSyntax_603372; body: JsonNode): Recallable =
  ## detectSyntax
  ## Inspects text for syntax and the part of speech of words in the document. For more information, <a>how-syntax</a>.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var detectSyntax* = Call_DetectSyntax_603372(name: "detectSyntax",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.DetectSyntax",
    validator: validate_DetectSyntax_603373, base: "/", url: url_DetectSyntax_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassificationJobs_603387 = ref object of OpenApiRestCall_602466
proc url_ListDocumentClassificationJobs_603389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocumentClassificationJobs_603388(path: JsonNode;
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
  var valid_603390 = query.getOrDefault("NextToken")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "NextToken", valid_603390
  var valid_603391 = query.getOrDefault("MaxResults")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "MaxResults", valid_603391
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
  var valid_603392 = header.getOrDefault("X-Amz-Date")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Date", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Security-Token")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Security-Token", valid_603393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603394 = header.getOrDefault("X-Amz-Target")
  valid_603394 = validateParameter(valid_603394, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassificationJobs"))
  if valid_603394 != nil:
    section.add "X-Amz-Target", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Content-Sha256", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Algorithm")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Algorithm", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Signature")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Signature", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-SignedHeaders", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Credential")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Credential", valid_603399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603401: Call_ListDocumentClassificationJobs_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the documentation classification jobs that you have submitted.
  ## 
  let valid = call_603401.validator(path, query, header, formData, body)
  let scheme = call_603401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603401.url(scheme.get, call_603401.host, call_603401.base,
                         call_603401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603401, url, valid)

proc call*(call_603402: Call_ListDocumentClassificationJobs_603387; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassificationJobs
  ## Gets a list of the documentation classification jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603403 = newJObject()
  var body_603404 = newJObject()
  add(query_603403, "NextToken", newJString(NextToken))
  if body != nil:
    body_603404 = body
  add(query_603403, "MaxResults", newJString(MaxResults))
  result = call_603402.call(nil, query_603403, nil, nil, body_603404)

var listDocumentClassificationJobs* = Call_ListDocumentClassificationJobs_603387(
    name: "listDocumentClassificationJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassificationJobs",
    validator: validate_ListDocumentClassificationJobs_603388, base: "/",
    url: url_ListDocumentClassificationJobs_603389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentClassifiers_603406 = ref object of OpenApiRestCall_602466
proc url_ListDocumentClassifiers_603408(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocumentClassifiers_603407(path: JsonNode; query: JsonNode;
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
  var valid_603409 = query.getOrDefault("NextToken")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "NextToken", valid_603409
  var valid_603410 = query.getOrDefault("MaxResults")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "MaxResults", valid_603410
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
  var valid_603411 = header.getOrDefault("X-Amz-Date")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Date", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Security-Token")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Security-Token", valid_603412
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603413 = header.getOrDefault("X-Amz-Target")
  valid_603413 = validateParameter(valid_603413, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDocumentClassifiers"))
  if valid_603413 != nil:
    section.add "X-Amz-Target", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Content-Sha256", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Algorithm")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Algorithm", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Signature")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Signature", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-SignedHeaders", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Credential")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Credential", valid_603418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603420: Call_ListDocumentClassifiers_603406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the document classifiers that you have created.
  ## 
  let valid = call_603420.validator(path, query, header, formData, body)
  let scheme = call_603420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603420.url(scheme.get, call_603420.host, call_603420.base,
                         call_603420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603420, url, valid)

proc call*(call_603421: Call_ListDocumentClassifiers_603406; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocumentClassifiers
  ## Gets a list of the document classifiers that you have created.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603422 = newJObject()
  var body_603423 = newJObject()
  add(query_603422, "NextToken", newJString(NextToken))
  if body != nil:
    body_603423 = body
  add(query_603422, "MaxResults", newJString(MaxResults))
  result = call_603421.call(nil, query_603422, nil, nil, body_603423)

var listDocumentClassifiers* = Call_ListDocumentClassifiers_603406(
    name: "listDocumentClassifiers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListDocumentClassifiers",
    validator: validate_ListDocumentClassifiers_603407, base: "/",
    url: url_ListDocumentClassifiers_603408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDominantLanguageDetectionJobs_603424 = ref object of OpenApiRestCall_602466
proc url_ListDominantLanguageDetectionJobs_603426(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDominantLanguageDetectionJobs_603425(path: JsonNode;
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
  var valid_603427 = query.getOrDefault("NextToken")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "NextToken", valid_603427
  var valid_603428 = query.getOrDefault("MaxResults")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "MaxResults", valid_603428
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
  var valid_603429 = header.getOrDefault("X-Amz-Date")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Date", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Security-Token")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Security-Token", valid_603430
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603431 = header.getOrDefault("X-Amz-Target")
  valid_603431 = validateParameter(valid_603431, JString, required = true, default = newJString(
      "Comprehend_20171127.ListDominantLanguageDetectionJobs"))
  if valid_603431 != nil:
    section.add "X-Amz-Target", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Content-Sha256", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Algorithm")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Algorithm", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Signature")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Signature", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-SignedHeaders", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Credential")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Credential", valid_603436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_ListDominantLanguageDetectionJobs_603424;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ## 
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_ListDominantLanguageDetectionJobs_603424;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDominantLanguageDetectionJobs
  ## Gets a list of the dominant language detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603440 = newJObject()
  var body_603441 = newJObject()
  add(query_603440, "NextToken", newJString(NextToken))
  if body != nil:
    body_603441 = body
  add(query_603440, "MaxResults", newJString(MaxResults))
  result = call_603439.call(nil, query_603440, nil, nil, body_603441)

var listDominantLanguageDetectionJobs* = Call_ListDominantLanguageDetectionJobs_603424(
    name: "listDominantLanguageDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.ListDominantLanguageDetectionJobs",
    validator: validate_ListDominantLanguageDetectionJobs_603425, base: "/",
    url: url_ListDominantLanguageDetectionJobs_603426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitiesDetectionJobs_603442 = ref object of OpenApiRestCall_602466
proc url_ListEntitiesDetectionJobs_603444(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEntitiesDetectionJobs_603443(path: JsonNode; query: JsonNode;
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
  var valid_603445 = query.getOrDefault("NextToken")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "NextToken", valid_603445
  var valid_603446 = query.getOrDefault("MaxResults")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "MaxResults", valid_603446
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
  var valid_603447 = header.getOrDefault("X-Amz-Date")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Date", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Security-Token")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Security-Token", valid_603448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603449 = header.getOrDefault("X-Amz-Target")
  valid_603449 = validateParameter(valid_603449, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntitiesDetectionJobs"))
  if valid_603449 != nil:
    section.add "X-Amz-Target", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Content-Sha256", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Algorithm")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Algorithm", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Signature")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Signature", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Credential")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Credential", valid_603454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_ListEntitiesDetectionJobs_603442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the entity detection jobs that you have submitted.
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_ListEntitiesDetectionJobs_603442; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntitiesDetectionJobs
  ## Gets a list of the entity detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603458 = newJObject()
  var body_603459 = newJObject()
  add(query_603458, "NextToken", newJString(NextToken))
  if body != nil:
    body_603459 = body
  add(query_603458, "MaxResults", newJString(MaxResults))
  result = call_603457.call(nil, query_603458, nil, nil, body_603459)

var listEntitiesDetectionJobs* = Call_ListEntitiesDetectionJobs_603442(
    name: "listEntitiesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntitiesDetectionJobs",
    validator: validate_ListEntitiesDetectionJobs_603443, base: "/",
    url: url_ListEntitiesDetectionJobs_603444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntityRecognizers_603460 = ref object of OpenApiRestCall_602466
proc url_ListEntityRecognizers_603462(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEntityRecognizers_603461(path: JsonNode; query: JsonNode;
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
  var valid_603463 = query.getOrDefault("NextToken")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "NextToken", valid_603463
  var valid_603464 = query.getOrDefault("MaxResults")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "MaxResults", valid_603464
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
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "Comprehend_20171127.ListEntityRecognizers"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_ListEntityRecognizers_603460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_ListEntityRecognizers_603460; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntityRecognizers
  ## <p>Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list.</p> <p>The results of this list are not in any particular order. Please get the list and sort locally if needed.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603476 = newJObject()
  var body_603477 = newJObject()
  add(query_603476, "NextToken", newJString(NextToken))
  if body != nil:
    body_603477 = body
  add(query_603476, "MaxResults", newJString(MaxResults))
  result = call_603475.call(nil, query_603476, nil, nil, body_603477)

var listEntityRecognizers* = Call_ListEntityRecognizers_603460(
    name: "listEntityRecognizers", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListEntityRecognizers",
    validator: validate_ListEntityRecognizers_603461, base: "/",
    url: url_ListEntityRecognizers_603462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPhrasesDetectionJobs_603478 = ref object of OpenApiRestCall_602466
proc url_ListKeyPhrasesDetectionJobs_603480(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListKeyPhrasesDetectionJobs_603479(path: JsonNode; query: JsonNode;
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
  var valid_603481 = query.getOrDefault("NextToken")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "NextToken", valid_603481
  var valid_603482 = query.getOrDefault("MaxResults")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "MaxResults", valid_603482
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
  var valid_603483 = header.getOrDefault("X-Amz-Date")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Date", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Security-Token")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Security-Token", valid_603484
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603485 = header.getOrDefault("X-Amz-Target")
  valid_603485 = validateParameter(valid_603485, JString, required = true, default = newJString(
      "Comprehend_20171127.ListKeyPhrasesDetectionJobs"))
  if valid_603485 != nil:
    section.add "X-Amz-Target", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Content-Sha256", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Algorithm")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Algorithm", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Signature")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Signature", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-SignedHeaders", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Credential")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Credential", valid_603490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603492: Call_ListKeyPhrasesDetectionJobs_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a list of key phrase detection jobs that you have submitted.
  ## 
  let valid = call_603492.validator(path, query, header, formData, body)
  let scheme = call_603492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603492.url(scheme.get, call_603492.host, call_603492.base,
                         call_603492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603492, url, valid)

proc call*(call_603493: Call_ListKeyPhrasesDetectionJobs_603478; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listKeyPhrasesDetectionJobs
  ## Get a list of key phrase detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603494 = newJObject()
  var body_603495 = newJObject()
  add(query_603494, "NextToken", newJString(NextToken))
  if body != nil:
    body_603495 = body
  add(query_603494, "MaxResults", newJString(MaxResults))
  result = call_603493.call(nil, query_603494, nil, nil, body_603495)

var listKeyPhrasesDetectionJobs* = Call_ListKeyPhrasesDetectionJobs_603478(
    name: "listKeyPhrasesDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListKeyPhrasesDetectionJobs",
    validator: validate_ListKeyPhrasesDetectionJobs_603479, base: "/",
    url: url_ListKeyPhrasesDetectionJobs_603480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSentimentDetectionJobs_603496 = ref object of OpenApiRestCall_602466
proc url_ListSentimentDetectionJobs_603498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSentimentDetectionJobs_603497(path: JsonNode; query: JsonNode;
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
  var valid_603499 = query.getOrDefault("NextToken")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "NextToken", valid_603499
  var valid_603500 = query.getOrDefault("MaxResults")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "MaxResults", valid_603500
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
  var valid_603501 = header.getOrDefault("X-Amz-Date")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Date", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Security-Token")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Security-Token", valid_603502
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603503 = header.getOrDefault("X-Amz-Target")
  valid_603503 = validateParameter(valid_603503, JString, required = true, default = newJString(
      "Comprehend_20171127.ListSentimentDetectionJobs"))
  if valid_603503 != nil:
    section.add "X-Amz-Target", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Content-Sha256", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Algorithm")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Algorithm", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Signature")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Signature", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-SignedHeaders", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Credential")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Credential", valid_603508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603510: Call_ListSentimentDetectionJobs_603496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of sentiment detection jobs that you have submitted.
  ## 
  let valid = call_603510.validator(path, query, header, formData, body)
  let scheme = call_603510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603510.url(scheme.get, call_603510.host, call_603510.base,
                         call_603510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603510, url, valid)

proc call*(call_603511: Call_ListSentimentDetectionJobs_603496; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSentimentDetectionJobs
  ## Gets a list of sentiment detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603512 = newJObject()
  var body_603513 = newJObject()
  add(query_603512, "NextToken", newJString(NextToken))
  if body != nil:
    body_603513 = body
  add(query_603512, "MaxResults", newJString(MaxResults))
  result = call_603511.call(nil, query_603512, nil, nil, body_603513)

var listSentimentDetectionJobs* = Call_ListSentimentDetectionJobs_603496(
    name: "listSentimentDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListSentimentDetectionJobs",
    validator: validate_ListSentimentDetectionJobs_603497, base: "/",
    url: url_ListSentimentDetectionJobs_603498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603514 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603516(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603515(path: JsonNode; query: JsonNode;
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603519 = header.getOrDefault("X-Amz-Target")
  valid_603519 = validateParameter(valid_603519, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTagsForResource"))
  if valid_603519 != nil:
    section.add "X-Amz-Target", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Content-Sha256", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Algorithm")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Algorithm", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-SignedHeaders", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Credential")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Credential", valid_603524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_ListTagsForResource_603514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_ListTagsForResource_603514; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with a given Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_603528 = newJObject()
  if body != nil:
    body_603528 = body
  result = call_603527.call(nil, nil, nil, nil, body_603528)

var listTagsForResource* = Call_ListTagsForResource_603514(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTagsForResource",
    validator: validate_ListTagsForResource_603515, base: "/",
    url: url_ListTagsForResource_603516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTopicsDetectionJobs_603529 = ref object of OpenApiRestCall_602466
proc url_ListTopicsDetectionJobs_603531(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTopicsDetectionJobs_603530(path: JsonNode; query: JsonNode;
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
  var valid_603532 = query.getOrDefault("NextToken")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "NextToken", valid_603532
  var valid_603533 = query.getOrDefault("MaxResults")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "MaxResults", valid_603533
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
  var valid_603534 = header.getOrDefault("X-Amz-Date")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Date", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Security-Token")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Security-Token", valid_603535
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603536 = header.getOrDefault("X-Amz-Target")
  valid_603536 = validateParameter(valid_603536, JString, required = true, default = newJString(
      "Comprehend_20171127.ListTopicsDetectionJobs"))
  if valid_603536 != nil:
    section.add "X-Amz-Target", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Algorithm")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Algorithm", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Signature")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Signature", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-SignedHeaders", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603543: Call_ListTopicsDetectionJobs_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the topic detection jobs that you have submitted.
  ## 
  let valid = call_603543.validator(path, query, header, formData, body)
  let scheme = call_603543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603543.url(scheme.get, call_603543.host, call_603543.base,
                         call_603543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603543, url, valid)

proc call*(call_603544: Call_ListTopicsDetectionJobs_603529; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTopicsDetectionJobs
  ## Gets a list of the topic detection jobs that you have submitted.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603545 = newJObject()
  var body_603546 = newJObject()
  add(query_603545, "NextToken", newJString(NextToken))
  if body != nil:
    body_603546 = body
  add(query_603545, "MaxResults", newJString(MaxResults))
  result = call_603544.call(nil, query_603545, nil, nil, body_603546)

var listTopicsDetectionJobs* = Call_ListTopicsDetectionJobs_603529(
    name: "listTopicsDetectionJobs", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.ListTopicsDetectionJobs",
    validator: validate_ListTopicsDetectionJobs_603530, base: "/",
    url: url_ListTopicsDetectionJobs_603531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDocumentClassificationJob_603547 = ref object of OpenApiRestCall_602466
proc url_StartDocumentClassificationJob_603549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartDocumentClassificationJob_603548(path: JsonNode;
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
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603552 = header.getOrDefault("X-Amz-Target")
  valid_603552 = validateParameter(valid_603552, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDocumentClassificationJob"))
  if valid_603552 != nil:
    section.add "X-Amz-Target", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Content-Sha256", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Algorithm")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Algorithm", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Signature")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Signature", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-SignedHeaders", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Credential")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Credential", valid_603557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_StartDocumentClassificationJob_603547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ## 
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_StartDocumentClassificationJob_603547; body: JsonNode): Recallable =
  ## startDocumentClassificationJob
  ## Starts an asynchronous document classification job. Use the operation to track the progress of the job.
  ##   body: JObject (required)
  var body_603561 = newJObject()
  if body != nil:
    body_603561 = body
  result = call_603560.call(nil, nil, nil, nil, body_603561)

var startDocumentClassificationJob* = Call_StartDocumentClassificationJob_603547(
    name: "startDocumentClassificationJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartDocumentClassificationJob",
    validator: validate_StartDocumentClassificationJob_603548, base: "/",
    url: url_StartDocumentClassificationJob_603549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDominantLanguageDetectionJob_603562 = ref object of OpenApiRestCall_602466
proc url_StartDominantLanguageDetectionJob_603564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartDominantLanguageDetectionJob_603563(path: JsonNode;
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
  var valid_603565 = header.getOrDefault("X-Amz-Date")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Date", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Security-Token")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Security-Token", valid_603566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603567 = header.getOrDefault("X-Amz-Target")
  valid_603567 = validateParameter(valid_603567, JString, required = true, default = newJString(
      "Comprehend_20171127.StartDominantLanguageDetectionJob"))
  if valid_603567 != nil:
    section.add "X-Amz-Target", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Content-Sha256", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Algorithm")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Algorithm", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Signature")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Signature", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-SignedHeaders", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Credential")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Credential", valid_603572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603574: Call_StartDominantLanguageDetectionJob_603562;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_603574.validator(path, query, header, formData, body)
  let scheme = call_603574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603574.url(scheme.get, call_603574.host, call_603574.base,
                         call_603574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603574, url, valid)

proc call*(call_603575: Call_StartDominantLanguageDetectionJob_603562;
          body: JsonNode): Recallable =
  ## startDominantLanguageDetectionJob
  ## Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_603576 = newJObject()
  if body != nil:
    body_603576 = body
  result = call_603575.call(nil, nil, nil, nil, body_603576)

var startDominantLanguageDetectionJob* = Call_StartDominantLanguageDetectionJob_603562(
    name: "startDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StartDominantLanguageDetectionJob",
    validator: validate_StartDominantLanguageDetectionJob_603563, base: "/",
    url: url_StartDominantLanguageDetectionJob_603564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartEntitiesDetectionJob_603577 = ref object of OpenApiRestCall_602466
proc url_StartEntitiesDetectionJob_603579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartEntitiesDetectionJob_603578(path: JsonNode; query: JsonNode;
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
  var valid_603580 = header.getOrDefault("X-Amz-Date")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Date", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Security-Token")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Security-Token", valid_603581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603582 = header.getOrDefault("X-Amz-Target")
  valid_603582 = validateParameter(valid_603582, JString, required = true, default = newJString(
      "Comprehend_20171127.StartEntitiesDetectionJob"))
  if valid_603582 != nil:
    section.add "X-Amz-Target", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Content-Sha256", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Algorithm")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Algorithm", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Signature")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Signature", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-SignedHeaders", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Credential")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Credential", valid_603587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603589: Call_StartEntitiesDetectionJob_603577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ## 
  let valid = call_603589.validator(path, query, header, formData, body)
  let scheme = call_603589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603589.url(scheme.get, call_603589.host, call_603589.base,
                         call_603589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603589, url, valid)

proc call*(call_603590: Call_StartEntitiesDetectionJob_603577; body: JsonNode): Recallable =
  ## startEntitiesDetectionJob
  ## <p>Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job.</p> <p>This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional <code>EntityRecognizerArn</code> must be used in order to provide access to the recognizer being used to detect the custom entity.</p>
  ##   body: JObject (required)
  var body_603591 = newJObject()
  if body != nil:
    body_603591 = body
  result = call_603590.call(nil, nil, nil, nil, body_603591)

var startEntitiesDetectionJob* = Call_StartEntitiesDetectionJob_603577(
    name: "startEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartEntitiesDetectionJob",
    validator: validate_StartEntitiesDetectionJob_603578, base: "/",
    url: url_StartEntitiesDetectionJob_603579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartKeyPhrasesDetectionJob_603592 = ref object of OpenApiRestCall_602466
proc url_StartKeyPhrasesDetectionJob_603594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartKeyPhrasesDetectionJob_603593(path: JsonNode; query: JsonNode;
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
  var valid_603595 = header.getOrDefault("X-Amz-Date")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Date", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Security-Token")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Security-Token", valid_603596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603597 = header.getOrDefault("X-Amz-Target")
  valid_603597 = validateParameter(valid_603597, JString, required = true, default = newJString(
      "Comprehend_20171127.StartKeyPhrasesDetectionJob"))
  if valid_603597 != nil:
    section.add "X-Amz-Target", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Content-Sha256", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Algorithm")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Algorithm", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-SignedHeaders", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Credential")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Credential", valid_603602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603604: Call_StartKeyPhrasesDetectionJob_603592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ## 
  let valid = call_603604.validator(path, query, header, formData, body)
  let scheme = call_603604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603604.url(scheme.get, call_603604.host, call_603604.base,
                         call_603604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603604, url, valid)

proc call*(call_603605: Call_StartKeyPhrasesDetectionJob_603592; body: JsonNode): Recallable =
  ## startKeyPhrasesDetectionJob
  ## Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_603606 = newJObject()
  if body != nil:
    body_603606 = body
  result = call_603605.call(nil, nil, nil, nil, body_603606)

var startKeyPhrasesDetectionJob* = Call_StartKeyPhrasesDetectionJob_603592(
    name: "startKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartKeyPhrasesDetectionJob",
    validator: validate_StartKeyPhrasesDetectionJob_603593, base: "/",
    url: url_StartKeyPhrasesDetectionJob_603594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSentimentDetectionJob_603607 = ref object of OpenApiRestCall_602466
proc url_StartSentimentDetectionJob_603609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSentimentDetectionJob_603608(path: JsonNode; query: JsonNode;
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
  var valid_603610 = header.getOrDefault("X-Amz-Date")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Date", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Security-Token")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Security-Token", valid_603611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603612 = header.getOrDefault("X-Amz-Target")
  valid_603612 = validateParameter(valid_603612, JString, required = true, default = newJString(
      "Comprehend_20171127.StartSentimentDetectionJob"))
  if valid_603612 != nil:
    section.add "X-Amz-Target", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Content-Sha256", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Algorithm")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Algorithm", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Signature")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Signature", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-SignedHeaders", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Credential")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Credential", valid_603617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603619: Call_StartSentimentDetectionJob_603607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ## 
  let valid = call_603619.validator(path, query, header, formData, body)
  let scheme = call_603619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603619.url(scheme.get, call_603619.host, call_603619.base,
                         call_603619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603619, url, valid)

proc call*(call_603620: Call_StartSentimentDetectionJob_603607; body: JsonNode): Recallable =
  ## startSentimentDetectionJob
  ## Starts an asynchronous sentiment detection job for a collection of documents. use the operation to track the status of a job.
  ##   body: JObject (required)
  var body_603621 = newJObject()
  if body != nil:
    body_603621 = body
  result = call_603620.call(nil, nil, nil, nil, body_603621)

var startSentimentDetectionJob* = Call_StartSentimentDetectionJob_603607(
    name: "startSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartSentimentDetectionJob",
    validator: validate_StartSentimentDetectionJob_603608, base: "/",
    url: url_StartSentimentDetectionJob_603609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTopicsDetectionJob_603622 = ref object of OpenApiRestCall_602466
proc url_StartTopicsDetectionJob_603624(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTopicsDetectionJob_603623(path: JsonNode; query: JsonNode;
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
  var valid_603625 = header.getOrDefault("X-Amz-Date")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Date", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Security-Token")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Security-Token", valid_603626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603627 = header.getOrDefault("X-Amz-Target")
  valid_603627 = validateParameter(valid_603627, JString, required = true, default = newJString(
      "Comprehend_20171127.StartTopicsDetectionJob"))
  if valid_603627 != nil:
    section.add "X-Amz-Target", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Content-Sha256", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Algorithm")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Algorithm", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Signature")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Signature", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-SignedHeaders", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Credential")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Credential", valid_603632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603634: Call_StartTopicsDetectionJob_603622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ## 
  let valid = call_603634.validator(path, query, header, formData, body)
  let scheme = call_603634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603634.url(scheme.get, call_603634.host, call_603634.base,
                         call_603634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603634, url, valid)

proc call*(call_603635: Call_StartTopicsDetectionJob_603622; body: JsonNode): Recallable =
  ## startTopicsDetectionJob
  ## Starts an asynchronous topic detection job. Use the <code>DescribeTopicDetectionJob</code> operation to track the status of a job.
  ##   body: JObject (required)
  var body_603636 = newJObject()
  if body != nil:
    body_603636 = body
  result = call_603635.call(nil, nil, nil, nil, body_603636)

var startTopicsDetectionJob* = Call_StartTopicsDetectionJob_603622(
    name: "startTopicsDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StartTopicsDetectionJob",
    validator: validate_StartTopicsDetectionJob_603623, base: "/",
    url: url_StartTopicsDetectionJob_603624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDominantLanguageDetectionJob_603637 = ref object of OpenApiRestCall_602466
proc url_StopDominantLanguageDetectionJob_603639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopDominantLanguageDetectionJob_603638(path: JsonNode;
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
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603642 = header.getOrDefault("X-Amz-Target")
  valid_603642 = validateParameter(valid_603642, JString, required = true, default = newJString(
      "Comprehend_20171127.StopDominantLanguageDetectionJob"))
  if valid_603642 != nil:
    section.add "X-Amz-Target", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Content-Sha256", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Algorithm")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Algorithm", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-SignedHeaders", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Credential")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Credential", valid_603647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603649: Call_StopDominantLanguageDetectionJob_603637;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_603649.validator(path, query, header, formData, body)
  let scheme = call_603649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603649.url(scheme.get, call_603649.host, call_603649.base,
                         call_603649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603649, url, valid)

proc call*(call_603650: Call_StopDominantLanguageDetectionJob_603637;
          body: JsonNode): Recallable =
  ## stopDominantLanguageDetectionJob
  ## <p>Stops a dominant language detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_603651 = newJObject()
  if body != nil:
    body_603651 = body
  result = call_603650.call(nil, nil, nil, nil, body_603651)

var stopDominantLanguageDetectionJob* = Call_StopDominantLanguageDetectionJob_603637(
    name: "stopDominantLanguageDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.StopDominantLanguageDetectionJob",
    validator: validate_StopDominantLanguageDetectionJob_603638, base: "/",
    url: url_StopDominantLanguageDetectionJob_603639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopEntitiesDetectionJob_603652 = ref object of OpenApiRestCall_602466
proc url_StopEntitiesDetectionJob_603654(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopEntitiesDetectionJob_603653(path: JsonNode; query: JsonNode;
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
  var valid_603655 = header.getOrDefault("X-Amz-Date")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Date", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Security-Token")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Security-Token", valid_603656
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603657 = header.getOrDefault("X-Amz-Target")
  valid_603657 = validateParameter(valid_603657, JString, required = true, default = newJString(
      "Comprehend_20171127.StopEntitiesDetectionJob"))
  if valid_603657 != nil:
    section.add "X-Amz-Target", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Content-Sha256", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Algorithm")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Algorithm", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Signature")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Signature", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-SignedHeaders", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Credential")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Credential", valid_603662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603664: Call_StopEntitiesDetectionJob_603652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_603664.validator(path, query, header, formData, body)
  let scheme = call_603664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603664.url(scheme.get, call_603664.host, call_603664.base,
                         call_603664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603664, url, valid)

proc call*(call_603665: Call_StopEntitiesDetectionJob_603652; body: JsonNode): Recallable =
  ## stopEntitiesDetectionJob
  ## <p>Stops an entities detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_603666 = newJObject()
  if body != nil:
    body_603666 = body
  result = call_603665.call(nil, nil, nil, nil, body_603666)

var stopEntitiesDetectionJob* = Call_StopEntitiesDetectionJob_603652(
    name: "stopEntitiesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopEntitiesDetectionJob",
    validator: validate_StopEntitiesDetectionJob_603653, base: "/",
    url: url_StopEntitiesDetectionJob_603654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopKeyPhrasesDetectionJob_603667 = ref object of OpenApiRestCall_602466
proc url_StopKeyPhrasesDetectionJob_603669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopKeyPhrasesDetectionJob_603668(path: JsonNode; query: JsonNode;
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
  var valid_603670 = header.getOrDefault("X-Amz-Date")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Date", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Security-Token")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Security-Token", valid_603671
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603672 = header.getOrDefault("X-Amz-Target")
  valid_603672 = validateParameter(valid_603672, JString, required = true, default = newJString(
      "Comprehend_20171127.StopKeyPhrasesDetectionJob"))
  if valid_603672 != nil:
    section.add "X-Amz-Target", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Content-Sha256", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Algorithm")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Algorithm", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Signature")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Signature", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-SignedHeaders", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Credential")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Credential", valid_603677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_StopKeyPhrasesDetectionJob_603667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603679, url, valid)

proc call*(call_603680: Call_StopKeyPhrasesDetectionJob_603667; body: JsonNode): Recallable =
  ## stopKeyPhrasesDetectionJob
  ## <p>Stops a key phrases detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_603681 = newJObject()
  if body != nil:
    body_603681 = body
  result = call_603680.call(nil, nil, nil, nil, body_603681)

var stopKeyPhrasesDetectionJob* = Call_StopKeyPhrasesDetectionJob_603667(
    name: "stopKeyPhrasesDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopKeyPhrasesDetectionJob",
    validator: validate_StopKeyPhrasesDetectionJob_603668, base: "/",
    url: url_StopKeyPhrasesDetectionJob_603669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopSentimentDetectionJob_603682 = ref object of OpenApiRestCall_602466
proc url_StopSentimentDetectionJob_603684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopSentimentDetectionJob_603683(path: JsonNode; query: JsonNode;
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
  var valid_603685 = header.getOrDefault("X-Amz-Date")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Date", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Security-Token")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Security-Token", valid_603686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603687 = header.getOrDefault("X-Amz-Target")
  valid_603687 = validateParameter(valid_603687, JString, required = true, default = newJString(
      "Comprehend_20171127.StopSentimentDetectionJob"))
  if valid_603687 != nil:
    section.add "X-Amz-Target", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Content-Sha256", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Algorithm")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Algorithm", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Signature")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Signature", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-SignedHeaders", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Credential")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Credential", valid_603692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603694: Call_StopSentimentDetectionJob_603682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ## 
  let valid = call_603694.validator(path, query, header, formData, body)
  let scheme = call_603694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603694.url(scheme.get, call_603694.host, call_603694.base,
                         call_603694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603694, url, valid)

proc call*(call_603695: Call_StopSentimentDetectionJob_603682; body: JsonNode): Recallable =
  ## stopSentimentDetectionJob
  ## <p>Stops a sentiment detection job in progress.</p> <p>If the job state is <code>IN_PROGRESS</code> the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state; otherwise the job is be stopped and put into the <code>STOPPED</code> state.</p> <p>If the job is in the <code>COMPLETED</code> or <code>FAILED</code> state when you call the <code>StopDominantLanguageDetectionJob</code> operation, the operation returns a 400 Internal Request Exception. </p> <p>When a job is stopped, any documents already processed are written to the output location.</p>
  ##   body: JObject (required)
  var body_603696 = newJObject()
  if body != nil:
    body_603696 = body
  result = call_603695.call(nil, nil, nil, nil, body_603696)

var stopSentimentDetectionJob* = Call_StopSentimentDetectionJob_603682(
    name: "stopSentimentDetectionJob", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopSentimentDetectionJob",
    validator: validate_StopSentimentDetectionJob_603683, base: "/",
    url: url_StopSentimentDetectionJob_603684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingDocumentClassifier_603697 = ref object of OpenApiRestCall_602466
proc url_StopTrainingDocumentClassifier_603699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrainingDocumentClassifier_603698(path: JsonNode;
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
  var valid_603700 = header.getOrDefault("X-Amz-Date")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Date", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Security-Token")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Security-Token", valid_603701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603702 = header.getOrDefault("X-Amz-Target")
  valid_603702 = validateParameter(valid_603702, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingDocumentClassifier"))
  if valid_603702 != nil:
    section.add "X-Amz-Target", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Content-Sha256", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Algorithm")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Algorithm", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Signature")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Signature", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-SignedHeaders", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Credential")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Credential", valid_603707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603709: Call_StopTrainingDocumentClassifier_603697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ## 
  let valid = call_603709.validator(path, query, header, formData, body)
  let scheme = call_603709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603709.url(scheme.get, call_603709.host, call_603709.base,
                         call_603709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603709, url, valid)

proc call*(call_603710: Call_StopTrainingDocumentClassifier_603697; body: JsonNode): Recallable =
  ## stopTrainingDocumentClassifier
  ## <p>Stops a document classifier training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and put into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body. </p>
  ##   body: JObject (required)
  var body_603711 = newJObject()
  if body != nil:
    body_603711 = body
  result = call_603710.call(nil, nil, nil, nil, body_603711)

var stopTrainingDocumentClassifier* = Call_StopTrainingDocumentClassifier_603697(
    name: "stopTrainingDocumentClassifier", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingDocumentClassifier",
    validator: validate_StopTrainingDocumentClassifier_603698, base: "/",
    url: url_StopTrainingDocumentClassifier_603699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingEntityRecognizer_603712 = ref object of OpenApiRestCall_602466
proc url_StopTrainingEntityRecognizer_603714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrainingEntityRecognizer_603713(path: JsonNode; query: JsonNode;
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
  var valid_603715 = header.getOrDefault("X-Amz-Date")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Date", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Security-Token")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Security-Token", valid_603716
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603717 = header.getOrDefault("X-Amz-Target")
  valid_603717 = validateParameter(valid_603717, JString, required = true, default = newJString(
      "Comprehend_20171127.StopTrainingEntityRecognizer"))
  if valid_603717 != nil:
    section.add "X-Amz-Target", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Algorithm")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Algorithm", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-SignedHeaders", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Credential")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Credential", valid_603722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603724: Call_StopTrainingEntityRecognizer_603712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ## 
  let valid = call_603724.validator(path, query, header, formData, body)
  let scheme = call_603724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603724.url(scheme.get, call_603724.host, call_603724.base,
                         call_603724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603724, url, valid)

proc call*(call_603725: Call_StopTrainingEntityRecognizer_603712; body: JsonNode): Recallable =
  ## stopTrainingEntityRecognizer
  ## <p>Stops an entity recognizer training job while in progress.</p> <p>If the training job state is <code>TRAINING</code>, the job is marked for termination and put into the <code>STOP_REQUESTED</code> state. If the training job completes before it can be stopped, it is put into the <code>TRAINED</code>; otherwise the training job is stopped and putted into the <code>STOPPED</code> state and the service sends back an HTTP 200 response with an empty HTTP body.</p>
  ##   body: JObject (required)
  var body_603726 = newJObject()
  if body != nil:
    body_603726 = body
  result = call_603725.call(nil, nil, nil, nil, body_603726)

var stopTrainingEntityRecognizer* = Call_StopTrainingEntityRecognizer_603712(
    name: "stopTrainingEntityRecognizer", meth: HttpMethod.HttpPost,
    host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.StopTrainingEntityRecognizer",
    validator: validate_StopTrainingEntityRecognizer_603713, base: "/",
    url: url_StopTrainingEntityRecognizer_603714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603727 = ref object of OpenApiRestCall_602466
proc url_TagResource_603729(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Security-Token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Security-Token", valid_603731
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603732 = header.getOrDefault("X-Amz-Target")
  valid_603732 = validateParameter(valid_603732, JString, required = true, default = newJString(
      "Comprehend_20171127.TagResource"))
  if valid_603732 != nil:
    section.add "X-Amz-Target", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Content-Sha256", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Algorithm")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Algorithm", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Signature")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Signature", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-SignedHeaders", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Credential")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Credential", valid_603737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_TagResource_603727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_TagResource_603727; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. 
  ##   body: JObject (required)
  var body_603741 = newJObject()
  if body != nil:
    body_603741 = body
  result = call_603740.call(nil, nil, nil, nil, body_603741)

var tagResource* = Call_TagResource_603727(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "comprehend.amazonaws.com", route: "/#X-Amz-Target=Comprehend_20171127.TagResource",
                                        validator: validate_TagResource_603728,
                                        base: "/", url: url_TagResource_603729,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603742 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603744(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603743(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603745 = header.getOrDefault("X-Amz-Date")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Date", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Security-Token")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Security-Token", valid_603746
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603747 = header.getOrDefault("X-Amz-Target")
  valid_603747 = validateParameter(valid_603747, JString, required = true, default = newJString(
      "Comprehend_20171127.UntagResource"))
  if valid_603747 != nil:
    section.add "X-Amz-Target", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Content-Sha256", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Algorithm")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Algorithm", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Signature")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Signature", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-SignedHeaders", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Credential")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Credential", valid_603752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603754: Call_UntagResource_603742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ## 
  let valid = call_603754.validator(path, query, header, formData, body)
  let scheme = call_603754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603754.url(scheme.get, call_603754.host, call_603754.base,
                         call_603754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603754, url, valid)

proc call*(call_603755: Call_UntagResource_603742; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a specific tag associated with an Amazon Comprehend resource. 
  ##   body: JObject (required)
  var body_603756 = newJObject()
  if body != nil:
    body_603756 = body
  result = call_603755.call(nil, nil, nil, nil, body_603756)

var untagResource* = Call_UntagResource_603742(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "comprehend.amazonaws.com",
    route: "/#X-Amz-Target=Comprehend_20171127.UntagResource",
    validator: validate_UntagResource_603743, base: "/", url: url_UntagResource_603744,
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
