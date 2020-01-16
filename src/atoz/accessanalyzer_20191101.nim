
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Access Analyzer
## version: 2019-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS IAM Access Analyzer helps identify potential resource-access risks by enabling you to identify any policies that grant access to an external principal. It does this by using logic-based reasoning to analyze resource-based policies in your AWS environment. An external principal can be another AWS account, a root user, an IAM user or role, a federated user, an AWS service, or an anonymous user. This guide describes the AWS IAM Access Analyzer operations that you can call programmatically. For general information about Access Analyzer, see the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html">AWS IAM Access Analyzer section of the IAM User Guide</a>.</p> <p>To start using Access Analyzer, you first need to create an analyzer.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/access-analyzer/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "access-analyzer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "access-analyzer.ap-southeast-1.amazonaws.com", "us-west-2": "access-analyzer.us-west-2.amazonaws.com", "eu-west-2": "access-analyzer.eu-west-2.amazonaws.com", "ap-northeast-3": "access-analyzer.ap-northeast-3.amazonaws.com", "eu-central-1": "access-analyzer.eu-central-1.amazonaws.com", "us-east-2": "access-analyzer.us-east-2.amazonaws.com", "us-east-1": "access-analyzer.us-east-1.amazonaws.com", "cn-northwest-1": "access-analyzer.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "access-analyzer.ap-south-1.amazonaws.com", "eu-north-1": "access-analyzer.eu-north-1.amazonaws.com", "ap-northeast-2": "access-analyzer.ap-northeast-2.amazonaws.com", "us-west-1": "access-analyzer.us-west-1.amazonaws.com", "us-gov-east-1": "access-analyzer.us-gov-east-1.amazonaws.com", "eu-west-3": "access-analyzer.eu-west-3.amazonaws.com", "cn-north-1": "access-analyzer.cn-north-1.amazonaws.com.cn", "sa-east-1": "access-analyzer.sa-east-1.amazonaws.com", "eu-west-1": "access-analyzer.eu-west-1.amazonaws.com", "us-gov-west-1": "access-analyzer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "access-analyzer.ap-southeast-2.amazonaws.com", "ca-central-1": "access-analyzer.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "access-analyzer.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "access-analyzer.ap-southeast-1.amazonaws.com",
      "us-west-2": "access-analyzer.us-west-2.amazonaws.com",
      "eu-west-2": "access-analyzer.eu-west-2.amazonaws.com",
      "ap-northeast-3": "access-analyzer.ap-northeast-3.amazonaws.com",
      "eu-central-1": "access-analyzer.eu-central-1.amazonaws.com",
      "us-east-2": "access-analyzer.us-east-2.amazonaws.com",
      "us-east-1": "access-analyzer.us-east-1.amazonaws.com",
      "cn-northwest-1": "access-analyzer.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "access-analyzer.ap-south-1.amazonaws.com",
      "eu-north-1": "access-analyzer.eu-north-1.amazonaws.com",
      "ap-northeast-2": "access-analyzer.ap-northeast-2.amazonaws.com",
      "us-west-1": "access-analyzer.us-west-1.amazonaws.com",
      "us-gov-east-1": "access-analyzer.us-gov-east-1.amazonaws.com",
      "eu-west-3": "access-analyzer.eu-west-3.amazonaws.com",
      "cn-north-1": "access-analyzer.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "access-analyzer.sa-east-1.amazonaws.com",
      "eu-west-1": "access-analyzer.eu-west-1.amazonaws.com",
      "us-gov-west-1": "access-analyzer.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "access-analyzer.ap-southeast-2.amazonaws.com",
      "ca-central-1": "access-analyzer.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "accessanalyzer"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateAnalyzer_606198 = ref object of OpenApiRestCall_605589
proc url_CreateAnalyzer_606200(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAnalyzer_606199(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates an analyzer for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_CreateAnalyzer_606198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an analyzer for your account.
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_CreateAnalyzer_606198; body: JsonNode): Recallable =
  ## createAnalyzer
  ## Creates an analyzer for your account.
  ##   body: JObject (required)
  var body_606211 = newJObject()
  if body != nil:
    body_606211 = body
  result = call_606210.call(nil, nil, nil, nil, body_606211)

var createAnalyzer* = Call_CreateAnalyzer_606198(name: "createAnalyzer",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_CreateAnalyzer_606199, base: "/",
    url: url_CreateAnalyzer_606200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzers_605927 = ref object of OpenApiRestCall_605589
proc url_ListAnalyzers_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzers_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of analyzers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  ##   type: JString
  ##       : The type of analyzer.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  section = newJObject()
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606055 = query.getOrDefault("type")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = newJString("ACCOUNT"))
  if valid_606055 != nil:
    section.add "type", valid_606055
  var valid_606056 = query.getOrDefault("maxResults")
  valid_606056 = validateParameter(valid_606056, JInt, required = false, default = nil)
  if valid_606056 != nil:
    section.add "maxResults", valid_606056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_ListAnalyzers_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of analyzers.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_ListAnalyzers_605927; nextToken: string = "";
          `type`: string = "ACCOUNT"; maxResults: int = 0): Recallable =
  ## listAnalyzers
  ## Retrieves a list of analyzers.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   type: string
  ##       : The type of analyzer.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  var query_606158 = newJObject()
  add(query_606158, "nextToken", newJString(nextToken))
  add(query_606158, "type", newJString(`type`))
  add(query_606158, "maxResults", newJInt(maxResults))
  result = call_606157.call(nil, query_606158, nil, nil, nil)

var listAnalyzers* = Call_ListAnalyzers_605927(name: "listAnalyzers",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_ListAnalyzers_605928, base: "/",
    url: url_ListAnalyzers_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateArchiveRule_606243 = ref object of OpenApiRestCall_605589
proc url_CreateArchiveRule_606245(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName"),
               (kind: ConstantSegment, value: "/archive-rule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateArchiveRule_606244(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the created analyzer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606246 = path.getOrDefault("analyzerName")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = nil)
  if valid_606246 != nil:
    section.add "analyzerName", valid_606246
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_CreateArchiveRule_606243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_CreateArchiveRule_606243; analyzerName: string;
          body: JsonNode): Recallable =
  ## createArchiveRule
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ##   analyzerName: string (required)
  ##               : The name of the created analyzer.
  ##   body: JObject (required)
  var path_606257 = newJObject()
  var body_606258 = newJObject()
  add(path_606257, "analyzerName", newJString(analyzerName))
  if body != nil:
    body_606258 = body
  result = call_606256.call(path_606257, nil, nil, nil, body_606258)

var createArchiveRule* = Call_CreateArchiveRule_606243(name: "createArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_CreateArchiveRule_606244, base: "/",
    url: url_CreateArchiveRule_606245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArchiveRules_606212 = ref object of OpenApiRestCall_605589
proc url_ListArchiveRules_606214(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName"),
               (kind: ConstantSegment, value: "/archive-rule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListArchiveRules_606213(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of archive rules created for the specified analyzer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to retrieve rules from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606229 = path.getOrDefault("analyzerName")
  valid_606229 = validateParameter(valid_606229, JString, required = true,
                                 default = nil)
  if valid_606229 != nil:
    section.add "analyzerName", valid_606229
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the request.
  section = newJObject()
  var valid_606230 = query.getOrDefault("nextToken")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "nextToken", valid_606230
  var valid_606231 = query.getOrDefault("maxResults")
  valid_606231 = validateParameter(valid_606231, JInt, required = false, default = nil)
  if valid_606231 != nil:
    section.add "maxResults", valid_606231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606232 = header.getOrDefault("X-Amz-Signature")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Signature", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Content-Sha256", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Date")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Date", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Credential")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Credential", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Security-Token")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Security-Token", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Algorithm")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Algorithm", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-SignedHeaders", valid_606238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_ListArchiveRules_606212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of archive rules created for the specified analyzer.
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_ListArchiveRules_606212; analyzerName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listArchiveRules
  ## Retrieves a list of archive rules created for the specified analyzer.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   maxResults: int
  ##             : The maximum number of results to return in the request.
  var path_606241 = newJObject()
  var query_606242 = newJObject()
  add(query_606242, "nextToken", newJString(nextToken))
  add(path_606241, "analyzerName", newJString(analyzerName))
  add(query_606242, "maxResults", newJInt(maxResults))
  result = call_606240.call(path_606241, query_606242, nil, nil, nil)

var listArchiveRules* = Call_ListArchiveRules_606212(name: "listArchiveRules",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_ListArchiveRules_606213, base: "/",
    url: url_ListArchiveRules_606214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzer_606259 = ref object of OpenApiRestCall_605589
proc url_GetAnalyzer_606261(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAnalyzer_606260(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the specified analyzer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer retrieved.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606262 = path.getOrDefault("analyzerName")
  valid_606262 = validateParameter(valid_606262, JString, required = true,
                                 default = nil)
  if valid_606262 != nil:
    section.add "analyzerName", valid_606262
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606263 = header.getOrDefault("X-Amz-Signature")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Signature", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Content-Sha256", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Date")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Date", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Credential")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Credential", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Security-Token")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Security-Token", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Algorithm")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Algorithm", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-SignedHeaders", valid_606269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606270: Call_GetAnalyzer_606259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified analyzer.
  ## 
  let valid = call_606270.validator(path, query, header, formData, body)
  let scheme = call_606270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606270.url(scheme.get, call_606270.host, call_606270.base,
                         call_606270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606270, url, valid)

proc call*(call_606271: Call_GetAnalyzer_606259; analyzerName: string): Recallable =
  ## getAnalyzer
  ## Retrieves information about the specified analyzer.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer retrieved.
  var path_606272 = newJObject()
  add(path_606272, "analyzerName", newJString(analyzerName))
  result = call_606271.call(path_606272, nil, nil, nil, nil)

var getAnalyzer* = Call_GetAnalyzer_606259(name: "getAnalyzer",
                                        meth: HttpMethod.HttpGet,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/analyzer/{analyzerName}",
                                        validator: validate_GetAnalyzer_606260,
                                        base: "/", url: url_GetAnalyzer_606261,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAnalyzer_606273 = ref object of OpenApiRestCall_605589
proc url_DeleteAnalyzer_606275(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAnalyzer_606274(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606276 = path.getOrDefault("analyzerName")
  valid_606276 = validateParameter(valid_606276, JString, required = true,
                                 default = nil)
  if valid_606276 != nil:
    section.add "analyzerName", valid_606276
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_606277 = query.getOrDefault("clientToken")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "clientToken", valid_606277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606285: Call_DeleteAnalyzer_606273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ## 
  let valid = call_606285.validator(path, query, header, formData, body)
  let scheme = call_606285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606285.url(scheme.get, call_606285.host, call_606285.base,
                         call_606285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606285, url, valid)

proc call*(call_606286: Call_DeleteAnalyzer_606273; analyzerName: string;
          clientToken: string = ""): Recallable =
  ## deleteAnalyzer
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_606287 = newJObject()
  var query_606288 = newJObject()
  add(path_606287, "analyzerName", newJString(analyzerName))
  add(query_606288, "clientToken", newJString(clientToken))
  result = call_606286.call(path_606287, query_606288, nil, nil, nil)

var deleteAnalyzer* = Call_DeleteAnalyzer_606273(name: "deleteAnalyzer",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_DeleteAnalyzer_606274,
    base: "/", url: url_DeleteAnalyzer_606275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateArchiveRule_606304 = ref object of OpenApiRestCall_605589
proc url_UpdateArchiveRule_606306(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  assert "ruleName" in path, "`ruleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName"),
               (kind: ConstantSegment, value: "/archive-rule/"),
               (kind: VariableSegment, value: "ruleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateArchiveRule_606305(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the criteria and values for the specified archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to update the archive rules for.
  ##   ruleName: JString (required)
  ##           : The name of the rule to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606307 = path.getOrDefault("analyzerName")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = nil)
  if valid_606307 != nil:
    section.add "analyzerName", valid_606307
  var valid_606308 = path.getOrDefault("ruleName")
  valid_606308 = validateParameter(valid_606308, JString, required = true,
                                 default = nil)
  if valid_606308 != nil:
    section.add "ruleName", valid_606308
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606309 = header.getOrDefault("X-Amz-Signature")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Signature", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Content-Sha256", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Date")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Date", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Credential")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Credential", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Security-Token")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Security-Token", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Algorithm")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Algorithm", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-SignedHeaders", valid_606315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606317: Call_UpdateArchiveRule_606304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the criteria and values for the specified archive rule.
  ## 
  let valid = call_606317.validator(path, query, header, formData, body)
  let scheme = call_606317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606317.url(scheme.get, call_606317.host, call_606317.base,
                         call_606317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606317, url, valid)

proc call*(call_606318: Call_UpdateArchiveRule_606304; analyzerName: string;
          ruleName: string; body: JsonNode): Recallable =
  ## updateArchiveRule
  ## Updates the criteria and values for the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to update the archive rules for.
  ##   ruleName: string (required)
  ##           : The name of the rule to update.
  ##   body: JObject (required)
  var path_606319 = newJObject()
  var body_606320 = newJObject()
  add(path_606319, "analyzerName", newJString(analyzerName))
  add(path_606319, "ruleName", newJString(ruleName))
  if body != nil:
    body_606320 = body
  result = call_606318.call(path_606319, nil, nil, nil, body_606320)

var updateArchiveRule* = Call_UpdateArchiveRule_606304(name: "updateArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_UpdateArchiveRule_606305, base: "/",
    url: url_UpdateArchiveRule_606306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArchiveRule_606289 = ref object of OpenApiRestCall_605589
proc url_GetArchiveRule_606291(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  assert "ruleName" in path, "`ruleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName"),
               (kind: ConstantSegment, value: "/archive-rule/"),
               (kind: VariableSegment, value: "ruleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetArchiveRule_606290(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves information about an archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   ruleName: JString (required)
  ##           : The name of the rule to retrieve.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606292 = path.getOrDefault("analyzerName")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = nil)
  if valid_606292 != nil:
    section.add "analyzerName", valid_606292
  var valid_606293 = path.getOrDefault("ruleName")
  valid_606293 = validateParameter(valid_606293, JString, required = true,
                                 default = nil)
  if valid_606293 != nil:
    section.add "ruleName", valid_606293
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606294 = header.getOrDefault("X-Amz-Signature")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Signature", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Content-Sha256", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Date")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Date", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Credential")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Credential", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Security-Token")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Security-Token", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Algorithm")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Algorithm", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-SignedHeaders", valid_606300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606301: Call_GetArchiveRule_606289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an archive rule.
  ## 
  let valid = call_606301.validator(path, query, header, formData, body)
  let scheme = call_606301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606301.url(scheme.get, call_606301.host, call_606301.base,
                         call_606301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606301, url, valid)

proc call*(call_606302: Call_GetArchiveRule_606289; analyzerName: string;
          ruleName: string): Recallable =
  ## getArchiveRule
  ## Retrieves information about an archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   ruleName: string (required)
  ##           : The name of the rule to retrieve.
  var path_606303 = newJObject()
  add(path_606303, "analyzerName", newJString(analyzerName))
  add(path_606303, "ruleName", newJString(ruleName))
  result = call_606302.call(path_606303, nil, nil, nil, nil)

var getArchiveRule* = Call_GetArchiveRule_606289(name: "getArchiveRule",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_GetArchiveRule_606290, base: "/", url: url_GetArchiveRule_606291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchiveRule_606321 = ref object of OpenApiRestCall_605589
proc url_DeleteArchiveRule_606323(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "analyzerName" in path, "`analyzerName` is a required path parameter"
  assert "ruleName" in path, "`ruleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/analyzer/"),
               (kind: VariableSegment, value: "analyzerName"),
               (kind: ConstantSegment, value: "/archive-rule/"),
               (kind: VariableSegment, value: "ruleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteArchiveRule_606322(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer that associated with the archive rule to delete.
  ##   ruleName: JString (required)
  ##           : The name of the rule to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_606324 = path.getOrDefault("analyzerName")
  valid_606324 = validateParameter(valid_606324, JString, required = true,
                                 default = nil)
  if valid_606324 != nil:
    section.add "analyzerName", valid_606324
  var valid_606325 = path.getOrDefault("ruleName")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "ruleName", valid_606325
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_606326 = query.getOrDefault("clientToken")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "clientToken", valid_606326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DeleteArchiveRule_606321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified archive rule.
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DeleteArchiveRule_606321; analyzerName: string;
          ruleName: string; clientToken: string = ""): Recallable =
  ## deleteArchiveRule
  ## Deletes the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer that associated with the archive rule to delete.
  ##   ruleName: string (required)
  ##           : The name of the rule to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_606336 = newJObject()
  var query_606337 = newJObject()
  add(path_606336, "analyzerName", newJString(analyzerName))
  add(path_606336, "ruleName", newJString(ruleName))
  add(query_606337, "clientToken", newJString(clientToken))
  result = call_606335.call(path_606336, query_606337, nil, nil, nil)

var deleteArchiveRule* = Call_DeleteArchiveRule_606321(name: "deleteArchiveRule",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_DeleteArchiveRule_606322, base: "/",
    url: url_DeleteArchiveRule_606323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzedResource_606338 = ref object of OpenApiRestCall_605589
proc url_GetAnalyzedResource_606340(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzedResource_606339(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves information about a resource that was analyzed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer to retrieve information from.
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource to retrieve information about.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analyzerArn` field"
  var valid_606341 = query.getOrDefault("analyzerArn")
  valid_606341 = validateParameter(valid_606341, JString, required = true,
                                 default = nil)
  if valid_606341 != nil:
    section.add "analyzerArn", valid_606341
  var valid_606342 = query.getOrDefault("resourceArn")
  valid_606342 = validateParameter(valid_606342, JString, required = true,
                                 default = nil)
  if valid_606342 != nil:
    section.add "resourceArn", valid_606342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606343 = header.getOrDefault("X-Amz-Signature")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Signature", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Content-Sha256", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Date")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Date", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Credential")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Credential", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Security-Token")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Security-Token", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Algorithm")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Algorithm", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-SignedHeaders", valid_606349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_GetAnalyzedResource_606338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource that was analyzed.
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_GetAnalyzedResource_606338; analyzerArn: string;
          resourceArn: string): Recallable =
  ## getAnalyzedResource
  ## Retrieves information about a resource that was analyzed.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer to retrieve information from.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve information about.
  var query_606352 = newJObject()
  add(query_606352, "analyzerArn", newJString(analyzerArn))
  add(query_606352, "resourceArn", newJString(resourceArn))
  result = call_606351.call(nil, query_606352, nil, nil, nil)

var getAnalyzedResource* = Call_GetAnalyzedResource_606338(
    name: "getAnalyzedResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzed-resource#analyzerArn&resourceArn",
    validator: validate_GetAnalyzedResource_606339, base: "/",
    url: url_GetAnalyzedResource_606340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFinding_606353 = ref object of OpenApiRestCall_605589
proc url_GetFinding_606355(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/finding/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "#analyzerArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFinding_606354(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the specified finding.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the finding to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_606356 = path.getOrDefault("id")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = nil)
  if valid_606356 != nil:
    section.add "id", valid_606356
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer that generated the finding.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analyzerArn` field"
  var valid_606357 = query.getOrDefault("analyzerArn")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "analyzerArn", valid_606357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606365: Call_GetFinding_606353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified finding.
  ## 
  let valid = call_606365.validator(path, query, header, formData, body)
  let scheme = call_606365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606365.url(scheme.get, call_606365.host, call_606365.base,
                         call_606365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606365, url, valid)

proc call*(call_606366: Call_GetFinding_606353; analyzerArn: string; id: string): Recallable =
  ## getFinding
  ## Retrieves information about the specified finding.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer that generated the finding.
  ##   id: string (required)
  ##     : The ID of the finding to retrieve.
  var path_606367 = newJObject()
  var query_606368 = newJObject()
  add(query_606368, "analyzerArn", newJString(analyzerArn))
  add(path_606367, "id", newJString(id))
  result = call_606366.call(path_606367, query_606368, nil, nil, nil)

var getFinding* = Call_GetFinding_606353(name: "getFinding",
                                      meth: HttpMethod.HttpGet,
                                      host: "access-analyzer.amazonaws.com",
                                      route: "/finding/{id}#analyzerArn",
                                      validator: validate_GetFinding_606354,
                                      base: "/", url: url_GetFinding_606355,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzedResources_606369 = ref object of OpenApiRestCall_605589
proc url_ListAnalyzedResources_606371(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzedResources_606370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606372 = query.getOrDefault("nextToken")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "nextToken", valid_606372
  var valid_606373 = query.getOrDefault("maxResults")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "maxResults", valid_606373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606374 = header.getOrDefault("X-Amz-Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Signature", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Content-Sha256", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Date")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Date", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Credential")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Credential", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Security-Token")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Security-Token", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Algorithm")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Algorithm", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-SignedHeaders", valid_606380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606382: Call_ListAnalyzedResources_606369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ## 
  let valid = call_606382.validator(path, query, header, formData, body)
  let scheme = call_606382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606382.url(scheme.get, call_606382.host, call_606382.base,
                         call_606382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606382, url, valid)

proc call*(call_606383: Call_ListAnalyzedResources_606369; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAnalyzedResources
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606384 = newJObject()
  var body_606385 = newJObject()
  add(query_606384, "nextToken", newJString(nextToken))
  if body != nil:
    body_606385 = body
  add(query_606384, "maxResults", newJString(maxResults))
  result = call_606383.call(nil, query_606384, nil, nil, body_606385)

var listAnalyzedResources* = Call_ListAnalyzedResources_606369(
    name: "listAnalyzedResources", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/analyzed-resource",
    validator: validate_ListAnalyzedResources_606370, base: "/",
    url: url_ListAnalyzedResources_606371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_606386 = ref object of OpenApiRestCall_605589
proc url_UpdateFindings_606388(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_606387(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the status for the specified findings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606389 = header.getOrDefault("X-Amz-Signature")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Signature", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Content-Sha256", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Date")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Date", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Credential")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Credential", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Security-Token")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Security-Token", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Algorithm")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Algorithm", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-SignedHeaders", valid_606395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606397: Call_UpdateFindings_606386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified findings.
  ## 
  let valid = call_606397.validator(path, query, header, formData, body)
  let scheme = call_606397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606397.url(scheme.get, call_606397.host, call_606397.base,
                         call_606397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606397, url, valid)

proc call*(call_606398: Call_UpdateFindings_606386; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the status for the specified findings.
  ##   body: JObject (required)
  var body_606399 = newJObject()
  if body != nil:
    body_606399 = body
  result = call_606398.call(nil, nil, nil, nil, body_606399)

var updateFindings* = Call_UpdateFindings_606386(name: "updateFindings",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_UpdateFindings_606387, base: "/",
    url: url_UpdateFindings_606388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_606400 = ref object of OpenApiRestCall_605589
proc url_ListFindings_606402(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_606401(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606403 = query.getOrDefault("nextToken")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "nextToken", valid_606403
  var valid_606404 = query.getOrDefault("maxResults")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "maxResults", valid_606404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606413: Call_ListFindings_606400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  let valid = call_606413.validator(path, query, header, formData, body)
  let scheme = call_606413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606413.url(scheme.get, call_606413.host, call_606413.base,
                         call_606413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606413, url, valid)

proc call*(call_606414: Call_ListFindings_606400; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Retrieves a list of findings generated by the specified analyzer.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606415 = newJObject()
  var body_606416 = newJObject()
  add(query_606415, "nextToken", newJString(nextToken))
  if body != nil:
    body_606416 = body
  add(query_606415, "maxResults", newJString(maxResults))
  result = call_606414.call(nil, query_606415, nil, nil, body_606416)

var listFindings* = Call_ListFindings_606400(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_ListFindings_606401, base: "/",
    url: url_ListFindings_606402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606431 = ref object of OpenApiRestCall_605589
proc url_TagResource_606433(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606432(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a tag to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource to add the tag to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606434 = path.getOrDefault("resourceArn")
  valid_606434 = validateParameter(valid_606434, JString, required = true,
                                 default = nil)
  if valid_606434 != nil:
    section.add "resourceArn", valid_606434
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606435 = header.getOrDefault("X-Amz-Signature")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Signature", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Content-Sha256", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Date")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Date", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Credential")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Credential", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Security-Token")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Security-Token", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Algorithm")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Algorithm", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-SignedHeaders", valid_606441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606443: Call_TagResource_606431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a tag to the specified resource.
  ## 
  let valid = call_606443.validator(path, query, header, formData, body)
  let scheme = call_606443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606443.url(scheme.get, call_606443.host, call_606443.base,
                         call_606443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606443, url, valid)

proc call*(call_606444: Call_TagResource_606431; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds a tag to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to add the tag to.
  ##   body: JObject (required)
  var path_606445 = newJObject()
  var body_606446 = newJObject()
  add(path_606445, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606446 = body
  result = call_606444.call(path_606445, nil, nil, nil, body_606446)

var tagResource* = Call_TagResource_606431(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606432,
                                        base: "/", url: url_TagResource_606433,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606417 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606419(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606418(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves a list of tags applied to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource to retrieve tags from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606420 = path.getOrDefault("resourceArn")
  valid_606420 = validateParameter(valid_606420, JString, required = true,
                                 default = nil)
  if valid_606420 != nil:
    section.add "resourceArn", valid_606420
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606421 = header.getOrDefault("X-Amz-Signature")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Signature", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Content-Sha256", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Date")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Date", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Credential")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Credential", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Security-Token")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Security-Token", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Algorithm")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Algorithm", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-SignedHeaders", valid_606427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606428: Call_ListTagsForResource_606417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags applied to the specified resource.
  ## 
  let valid = call_606428.validator(path, query, header, formData, body)
  let scheme = call_606428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606428.url(scheme.get, call_606428.host, call_606428.base,
                         call_606428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606428, url, valid)

proc call*(call_606429: Call_ListTagsForResource_606417; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of tags applied to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags from.
  var path_606430 = newJObject()
  add(path_606430, "resourceArn", newJString(resourceArn))
  result = call_606429.call(path_606430, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606417(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606418, base: "/",
    url: url_ListTagsForResource_606419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartResourceScan_606447 = ref object of OpenApiRestCall_605589
proc url_StartResourceScan_606449(protocol: Scheme; host: string; base: string;
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

proc validate_StartResourceScan_606448(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Immediately starts a scan of the policies applied to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606450 = header.getOrDefault("X-Amz-Signature")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Signature", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Content-Sha256", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Date")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Date", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Credential")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Credential", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Security-Token")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Security-Token", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Algorithm")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Algorithm", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-SignedHeaders", valid_606456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606458: Call_StartResourceScan_606447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately starts a scan of the policies applied to the specified resource.
  ## 
  let valid = call_606458.validator(path, query, header, formData, body)
  let scheme = call_606458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606458.url(scheme.get, call_606458.host, call_606458.base,
                         call_606458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606458, url, valid)

proc call*(call_606459: Call_StartResourceScan_606447; body: JsonNode): Recallable =
  ## startResourceScan
  ## Immediately starts a scan of the policies applied to the specified resource.
  ##   body: JObject (required)
  var body_606460 = newJObject()
  if body != nil:
    body_606460 = body
  result = call_606459.call(nil, nil, nil, nil, body_606460)

var startResourceScan* = Call_StartResourceScan_606447(name: "startResourceScan",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/resource/scan", validator: validate_StartResourceScan_606448,
    base: "/", url: url_StartResourceScan_606449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606461 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606463(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606462(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource to remove the tag from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606464 = path.getOrDefault("resourceArn")
  valid_606464 = validateParameter(valid_606464, JString, required = true,
                                 default = nil)
  if valid_606464 != nil:
    section.add "resourceArn", valid_606464
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606465 = query.getOrDefault("tagKeys")
  valid_606465 = validateParameter(valid_606465, JArray, required = true, default = nil)
  if valid_606465 != nil:
    section.add "tagKeys", valid_606465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606466 = header.getOrDefault("X-Amz-Signature")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Signature", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Content-Sha256", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Date")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Date", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Credential")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Credential", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Security-Token")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Security-Token", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Algorithm")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Algorithm", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-SignedHeaders", valid_606472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606473: Call_UntagResource_606461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_606473.validator(path, query, header, formData, body)
  let scheme = call_606473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606473.url(scheme.get, call_606473.host, call_606473.base,
                         call_606473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606473, url, valid)

proc call*(call_606474: Call_UntagResource_606461; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to remove the tag from.
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  var path_606475 = newJObject()
  var query_606476 = newJObject()
  add(path_606475, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606476.add "tagKeys", tagKeys
  result = call_606474.call(path_606475, query_606476, nil, nil, nil)

var untagResource* = Call_UntagResource_606461(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606462,
    base: "/", url: url_UntagResource_606463, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
