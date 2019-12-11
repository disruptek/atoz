
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
## AWS IAM Access Analyzer API Reference
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CreateAnalyzer_597998 = ref object of OpenApiRestCall_597389
proc url_CreateAnalyzer_598000(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAnalyzer_597999(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates an analyzer with a zone of trust set to your account.
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
  var valid_598001 = header.getOrDefault("X-Amz-Signature")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Signature", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Content-Sha256", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Date")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Date", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Credential")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Credential", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Security-Token")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Security-Token", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Algorithm")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Algorithm", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-SignedHeaders", valid_598007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598009: Call_CreateAnalyzer_597998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an analyzer with a zone of trust set to your account.
  ## 
  let valid = call_598009.validator(path, query, header, formData, body)
  let scheme = call_598009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598009.url(scheme.get, call_598009.host, call_598009.base,
                         call_598009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598009, url, valid)

proc call*(call_598010: Call_CreateAnalyzer_597998; body: JsonNode): Recallable =
  ## createAnalyzer
  ## Creates an analyzer with a zone of trust set to your account.
  ##   body: JObject (required)
  var body_598011 = newJObject()
  if body != nil:
    body_598011 = body
  result = call_598010.call(nil, nil, nil, nil, body_598011)

var createAnalyzer* = Call_CreateAnalyzer_597998(name: "createAnalyzer",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_CreateAnalyzer_597999, base: "/",
    url: url_CreateAnalyzer_598000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzers_597727 = ref object of OpenApiRestCall_597389
proc url_ListAnalyzers_597729(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzers_597728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##       : The type of analyzer, which corresponds to the zone of trust selected when the analyzer was created.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  section = newJObject()
  var valid_597841 = query.getOrDefault("nextToken")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "nextToken", valid_597841
  var valid_597855 = query.getOrDefault("type")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = newJString("ACCOUNT"))
  if valid_597855 != nil:
    section.add "type", valid_597855
  var valid_597856 = query.getOrDefault("maxResults")
  valid_597856 = validateParameter(valid_597856, JInt, required = false, default = nil)
  if valid_597856 != nil:
    section.add "maxResults", valid_597856
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
  var valid_597857 = header.getOrDefault("X-Amz-Signature")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Signature", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Content-Sha256", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Date")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Date", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Credential")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Credential", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Security-Token")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Security-Token", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-Algorithm")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-Algorithm", valid_597862
  var valid_597863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597863 = validateParameter(valid_597863, JString, required = false,
                                 default = nil)
  if valid_597863 != nil:
    section.add "X-Amz-SignedHeaders", valid_597863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597886: Call_ListAnalyzers_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of analyzers.
  ## 
  let valid = call_597886.validator(path, query, header, formData, body)
  let scheme = call_597886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597886.url(scheme.get, call_597886.host, call_597886.base,
                         call_597886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597886, url, valid)

proc call*(call_597957: Call_ListAnalyzers_597727; nextToken: string = "";
          `type`: string = "ACCOUNT"; maxResults: int = 0): Recallable =
  ## listAnalyzers
  ## Retrieves a list of analyzers.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   type: string
  ##       : The type of analyzer, which corresponds to the zone of trust selected when the analyzer was created.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  var query_597958 = newJObject()
  add(query_597958, "nextToken", newJString(nextToken))
  add(query_597958, "type", newJString(`type`))
  add(query_597958, "maxResults", newJInt(maxResults))
  result = call_597957.call(nil, query_597958, nil, nil, nil)

var listAnalyzers* = Call_ListAnalyzers_597727(name: "listAnalyzers",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_ListAnalyzers_597728, base: "/",
    url: url_ListAnalyzers_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateArchiveRule_598043 = ref object of OpenApiRestCall_597389
proc url_CreateArchiveRule_598045(protocol: Scheme; host: string; base: string;
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

proc validate_CreateArchiveRule_598044(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an archive rule for the specified analyzer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the created analyzer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_598046 = path.getOrDefault("analyzerName")
  valid_598046 = validateParameter(valid_598046, JString, required = true,
                                 default = nil)
  if valid_598046 != nil:
    section.add "analyzerName", valid_598046
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
  var valid_598047 = header.getOrDefault("X-Amz-Signature")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Signature", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Content-Sha256", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Date")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Date", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Credential")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Credential", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Security-Token")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Security-Token", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-Algorithm")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Algorithm", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-SignedHeaders", valid_598053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598055: Call_CreateArchiveRule_598043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an archive rule for the specified analyzer.
  ## 
  let valid = call_598055.validator(path, query, header, formData, body)
  let scheme = call_598055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598055.url(scheme.get, call_598055.host, call_598055.base,
                         call_598055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598055, url, valid)

proc call*(call_598056: Call_CreateArchiveRule_598043; analyzerName: string;
          body: JsonNode): Recallable =
  ## createArchiveRule
  ## Creates an archive rule for the specified analyzer.
  ##   analyzerName: string (required)
  ##               : The name of the created analyzer.
  ##   body: JObject (required)
  var path_598057 = newJObject()
  var body_598058 = newJObject()
  add(path_598057, "analyzerName", newJString(analyzerName))
  if body != nil:
    body_598058 = body
  result = call_598056.call(path_598057, nil, nil, nil, body_598058)

var createArchiveRule* = Call_CreateArchiveRule_598043(name: "createArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_CreateArchiveRule_598044, base: "/",
    url: url_CreateArchiveRule_598045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArchiveRules_598012 = ref object of OpenApiRestCall_597389
proc url_ListArchiveRules_598014(protocol: Scheme; host: string; base: string;
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

proc validate_ListArchiveRules_598013(path: JsonNode; query: JsonNode;
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
  var valid_598029 = path.getOrDefault("analyzerName")
  valid_598029 = validateParameter(valid_598029, JString, required = true,
                                 default = nil)
  if valid_598029 != nil:
    section.add "analyzerName", valid_598029
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the request.
  section = newJObject()
  var valid_598030 = query.getOrDefault("nextToken")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "nextToken", valid_598030
  var valid_598031 = query.getOrDefault("maxResults")
  valid_598031 = validateParameter(valid_598031, JInt, required = false, default = nil)
  if valid_598031 != nil:
    section.add "maxResults", valid_598031
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
  var valid_598032 = header.getOrDefault("X-Amz-Signature")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Signature", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Content-Sha256", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Date")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Date", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Credential")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Credential", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Security-Token")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Security-Token", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Algorithm")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Algorithm", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-SignedHeaders", valid_598038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598039: Call_ListArchiveRules_598012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of archive rules created for the specified analyzer.
  ## 
  let valid = call_598039.validator(path, query, header, formData, body)
  let scheme = call_598039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598039.url(scheme.get, call_598039.host, call_598039.base,
                         call_598039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598039, url, valid)

proc call*(call_598040: Call_ListArchiveRules_598012; analyzerName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listArchiveRules
  ## Retrieves a list of archive rules created for the specified analyzer.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   maxResults: int
  ##             : The maximum number of results to return in the request.
  var path_598041 = newJObject()
  var query_598042 = newJObject()
  add(query_598042, "nextToken", newJString(nextToken))
  add(path_598041, "analyzerName", newJString(analyzerName))
  add(query_598042, "maxResults", newJInt(maxResults))
  result = call_598040.call(path_598041, query_598042, nil, nil, nil)

var listArchiveRules* = Call_ListArchiveRules_598012(name: "listArchiveRules",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_ListArchiveRules_598013, base: "/",
    url: url_ListArchiveRules_598014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzer_598059 = ref object of OpenApiRestCall_597389
proc url_GetAnalyzer_598061(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzer_598060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598062 = path.getOrDefault("analyzerName")
  valid_598062 = validateParameter(valid_598062, JString, required = true,
                                 default = nil)
  if valid_598062 != nil:
    section.add "analyzerName", valid_598062
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
  var valid_598063 = header.getOrDefault("X-Amz-Signature")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Signature", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Content-Sha256", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Date")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Date", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-Credential")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-Credential", valid_598066
  var valid_598067 = header.getOrDefault("X-Amz-Security-Token")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-Security-Token", valid_598067
  var valid_598068 = header.getOrDefault("X-Amz-Algorithm")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Algorithm", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-SignedHeaders", valid_598069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598070: Call_GetAnalyzer_598059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified analyzer.
  ## 
  let valid = call_598070.validator(path, query, header, formData, body)
  let scheme = call_598070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598070.url(scheme.get, call_598070.host, call_598070.base,
                         call_598070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598070, url, valid)

proc call*(call_598071: Call_GetAnalyzer_598059; analyzerName: string): Recallable =
  ## getAnalyzer
  ## Retrieves information about the specified analyzer.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer retrieved.
  var path_598072 = newJObject()
  add(path_598072, "analyzerName", newJString(analyzerName))
  result = call_598071.call(path_598072, nil, nil, nil, nil)

var getAnalyzer* = Call_GetAnalyzer_598059(name: "getAnalyzer",
                                        meth: HttpMethod.HttpGet,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/analyzer/{analyzerName}",
                                        validator: validate_GetAnalyzer_598060,
                                        base: "/", url: url_GetAnalyzer_598061,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAnalyzer_598073 = ref object of OpenApiRestCall_597389
proc url_DeleteAnalyzer_598075(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAnalyzer_598074(path: JsonNode; query: JsonNode;
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
  var valid_598076 = path.getOrDefault("analyzerName")
  valid_598076 = validateParameter(valid_598076, JString, required = true,
                                 default = nil)
  if valid_598076 != nil:
    section.add "analyzerName", valid_598076
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_598077 = query.getOrDefault("clientToken")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "clientToken", valid_598077
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
  var valid_598078 = header.getOrDefault("X-Amz-Signature")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Signature", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Content-Sha256", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Date")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Date", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-Credential")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-Credential", valid_598081
  var valid_598082 = header.getOrDefault("X-Amz-Security-Token")
  valid_598082 = validateParameter(valid_598082, JString, required = false,
                                 default = nil)
  if valid_598082 != nil:
    section.add "X-Amz-Security-Token", valid_598082
  var valid_598083 = header.getOrDefault("X-Amz-Algorithm")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Algorithm", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-SignedHeaders", valid_598084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598085: Call_DeleteAnalyzer_598073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ## 
  let valid = call_598085.validator(path, query, header, formData, body)
  let scheme = call_598085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598085.url(scheme.get, call_598085.host, call_598085.base,
                         call_598085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598085, url, valid)

proc call*(call_598086: Call_DeleteAnalyzer_598073; analyzerName: string;
          clientToken: string = ""): Recallable =
  ## deleteAnalyzer
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_598087 = newJObject()
  var query_598088 = newJObject()
  add(path_598087, "analyzerName", newJString(analyzerName))
  add(query_598088, "clientToken", newJString(clientToken))
  result = call_598086.call(path_598087, query_598088, nil, nil, nil)

var deleteAnalyzer* = Call_DeleteAnalyzer_598073(name: "deleteAnalyzer",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_DeleteAnalyzer_598074,
    base: "/", url: url_DeleteAnalyzer_598075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateArchiveRule_598104 = ref object of OpenApiRestCall_597389
proc url_UpdateArchiveRule_598106(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateArchiveRule_598105(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the specified archive rule.
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
  var valid_598107 = path.getOrDefault("analyzerName")
  valid_598107 = validateParameter(valid_598107, JString, required = true,
                                 default = nil)
  if valid_598107 != nil:
    section.add "analyzerName", valid_598107
  var valid_598108 = path.getOrDefault("ruleName")
  valid_598108 = validateParameter(valid_598108, JString, required = true,
                                 default = nil)
  if valid_598108 != nil:
    section.add "ruleName", valid_598108
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
  var valid_598109 = header.getOrDefault("X-Amz-Signature")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Signature", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Content-Sha256", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-Date")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-Date", valid_598111
  var valid_598112 = header.getOrDefault("X-Amz-Credential")
  valid_598112 = validateParameter(valid_598112, JString, required = false,
                                 default = nil)
  if valid_598112 != nil:
    section.add "X-Amz-Credential", valid_598112
  var valid_598113 = header.getOrDefault("X-Amz-Security-Token")
  valid_598113 = validateParameter(valid_598113, JString, required = false,
                                 default = nil)
  if valid_598113 != nil:
    section.add "X-Amz-Security-Token", valid_598113
  var valid_598114 = header.getOrDefault("X-Amz-Algorithm")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-Algorithm", valid_598114
  var valid_598115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-SignedHeaders", valid_598115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598117: Call_UpdateArchiveRule_598104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified archive rule.
  ## 
  let valid = call_598117.validator(path, query, header, formData, body)
  let scheme = call_598117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598117.url(scheme.get, call_598117.host, call_598117.base,
                         call_598117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598117, url, valid)

proc call*(call_598118: Call_UpdateArchiveRule_598104; analyzerName: string;
          ruleName: string; body: JsonNode): Recallable =
  ## updateArchiveRule
  ## Updates the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to update the archive rules for.
  ##   ruleName: string (required)
  ##           : The name of the rule to update.
  ##   body: JObject (required)
  var path_598119 = newJObject()
  var body_598120 = newJObject()
  add(path_598119, "analyzerName", newJString(analyzerName))
  add(path_598119, "ruleName", newJString(ruleName))
  if body != nil:
    body_598120 = body
  result = call_598118.call(path_598119, nil, nil, nil, body_598120)

var updateArchiveRule* = Call_UpdateArchiveRule_598104(name: "updateArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_UpdateArchiveRule_598105, base: "/",
    url: url_UpdateArchiveRule_598106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArchiveRule_598089 = ref object of OpenApiRestCall_597389
proc url_GetArchiveRule_598091(protocol: Scheme; host: string; base: string;
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

proc validate_GetArchiveRule_598090(path: JsonNode; query: JsonNode;
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
  var valid_598092 = path.getOrDefault("analyzerName")
  valid_598092 = validateParameter(valid_598092, JString, required = true,
                                 default = nil)
  if valid_598092 != nil:
    section.add "analyzerName", valid_598092
  var valid_598093 = path.getOrDefault("ruleName")
  valid_598093 = validateParameter(valid_598093, JString, required = true,
                                 default = nil)
  if valid_598093 != nil:
    section.add "ruleName", valid_598093
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
  var valid_598094 = header.getOrDefault("X-Amz-Signature")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Signature", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Content-Sha256", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-Date")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-Date", valid_598096
  var valid_598097 = header.getOrDefault("X-Amz-Credential")
  valid_598097 = validateParameter(valid_598097, JString, required = false,
                                 default = nil)
  if valid_598097 != nil:
    section.add "X-Amz-Credential", valid_598097
  var valid_598098 = header.getOrDefault("X-Amz-Security-Token")
  valid_598098 = validateParameter(valid_598098, JString, required = false,
                                 default = nil)
  if valid_598098 != nil:
    section.add "X-Amz-Security-Token", valid_598098
  var valid_598099 = header.getOrDefault("X-Amz-Algorithm")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "X-Amz-Algorithm", valid_598099
  var valid_598100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "X-Amz-SignedHeaders", valid_598100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598101: Call_GetArchiveRule_598089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an archive rule.
  ## 
  let valid = call_598101.validator(path, query, header, formData, body)
  let scheme = call_598101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598101.url(scheme.get, call_598101.host, call_598101.base,
                         call_598101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598101, url, valid)

proc call*(call_598102: Call_GetArchiveRule_598089; analyzerName: string;
          ruleName: string): Recallable =
  ## getArchiveRule
  ## Retrieves information about an archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   ruleName: string (required)
  ##           : The name of the rule to retrieve.
  var path_598103 = newJObject()
  add(path_598103, "analyzerName", newJString(analyzerName))
  add(path_598103, "ruleName", newJString(ruleName))
  result = call_598102.call(path_598103, nil, nil, nil, nil)

var getArchiveRule* = Call_GetArchiveRule_598089(name: "getArchiveRule",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_GetArchiveRule_598090, base: "/", url: url_GetArchiveRule_598091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchiveRule_598121 = ref object of OpenApiRestCall_597389
proc url_DeleteArchiveRule_598123(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteArchiveRule_598122(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer that was deleted.
  ##   ruleName: JString (required)
  ##           : The name of the rule to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `analyzerName` field"
  var valid_598124 = path.getOrDefault("analyzerName")
  valid_598124 = validateParameter(valid_598124, JString, required = true,
                                 default = nil)
  if valid_598124 != nil:
    section.add "analyzerName", valid_598124
  var valid_598125 = path.getOrDefault("ruleName")
  valid_598125 = validateParameter(valid_598125, JString, required = true,
                                 default = nil)
  if valid_598125 != nil:
    section.add "ruleName", valid_598125
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_598126 = query.getOrDefault("clientToken")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "clientToken", valid_598126
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
  var valid_598127 = header.getOrDefault("X-Amz-Signature")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Signature", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Content-Sha256", valid_598128
  var valid_598129 = header.getOrDefault("X-Amz-Date")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "X-Amz-Date", valid_598129
  var valid_598130 = header.getOrDefault("X-Amz-Credential")
  valid_598130 = validateParameter(valid_598130, JString, required = false,
                                 default = nil)
  if valid_598130 != nil:
    section.add "X-Amz-Credential", valid_598130
  var valid_598131 = header.getOrDefault("X-Amz-Security-Token")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "X-Amz-Security-Token", valid_598131
  var valid_598132 = header.getOrDefault("X-Amz-Algorithm")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Algorithm", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-SignedHeaders", valid_598133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598134: Call_DeleteArchiveRule_598121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified archive rule.
  ## 
  let valid = call_598134.validator(path, query, header, formData, body)
  let scheme = call_598134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598134.url(scheme.get, call_598134.host, call_598134.base,
                         call_598134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598134, url, valid)

proc call*(call_598135: Call_DeleteArchiveRule_598121; analyzerName: string;
          ruleName: string; clientToken: string = ""): Recallable =
  ## deleteArchiveRule
  ## Deletes the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer that was deleted.
  ##   ruleName: string (required)
  ##           : The name of the rule to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_598136 = newJObject()
  var query_598137 = newJObject()
  add(path_598136, "analyzerName", newJString(analyzerName))
  add(path_598136, "ruleName", newJString(ruleName))
  add(query_598137, "clientToken", newJString(clientToken))
  result = call_598135.call(path_598136, query_598137, nil, nil, nil)

var deleteArchiveRule* = Call_DeleteArchiveRule_598121(name: "deleteArchiveRule",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_DeleteArchiveRule_598122, base: "/",
    url: url_DeleteArchiveRule_598123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzedResource_598138 = ref object of OpenApiRestCall_597389
proc url_GetAnalyzedResource_598140(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzedResource_598139(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves information about an analyzed resource.
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
  var valid_598141 = query.getOrDefault("analyzerArn")
  valid_598141 = validateParameter(valid_598141, JString, required = true,
                                 default = nil)
  if valid_598141 != nil:
    section.add "analyzerArn", valid_598141
  var valid_598142 = query.getOrDefault("resourceArn")
  valid_598142 = validateParameter(valid_598142, JString, required = true,
                                 default = nil)
  if valid_598142 != nil:
    section.add "resourceArn", valid_598142
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
  var valid_598143 = header.getOrDefault("X-Amz-Signature")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Signature", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Content-Sha256", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Date")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Date", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Credential")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Credential", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Security-Token")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Security-Token", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Algorithm")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Algorithm", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-SignedHeaders", valid_598149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598150: Call_GetAnalyzedResource_598138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an analyzed resource.
  ## 
  let valid = call_598150.validator(path, query, header, formData, body)
  let scheme = call_598150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598150.url(scheme.get, call_598150.host, call_598150.base,
                         call_598150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598150, url, valid)

proc call*(call_598151: Call_GetAnalyzedResource_598138; analyzerArn: string;
          resourceArn: string): Recallable =
  ## getAnalyzedResource
  ## Retrieves information about an analyzed resource.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer to retrieve information from.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve information about.
  var query_598152 = newJObject()
  add(query_598152, "analyzerArn", newJString(analyzerArn))
  add(query_598152, "resourceArn", newJString(resourceArn))
  result = call_598151.call(nil, query_598152, nil, nil, nil)

var getAnalyzedResource* = Call_GetAnalyzedResource_598138(
    name: "getAnalyzedResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzed-resource#analyzerArn&resourceArn",
    validator: validate_GetAnalyzedResource_598139, base: "/",
    url: url_GetAnalyzedResource_598140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFinding_598153 = ref object of OpenApiRestCall_597389
proc url_GetFinding_598155(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFinding_598154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598156 = path.getOrDefault("id")
  valid_598156 = validateParameter(valid_598156, JString, required = true,
                                 default = nil)
  if valid_598156 != nil:
    section.add "id", valid_598156
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer that generated the finding.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analyzerArn` field"
  var valid_598157 = query.getOrDefault("analyzerArn")
  valid_598157 = validateParameter(valid_598157, JString, required = true,
                                 default = nil)
  if valid_598157 != nil:
    section.add "analyzerArn", valid_598157
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
  var valid_598158 = header.getOrDefault("X-Amz-Signature")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Signature", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Content-Sha256", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Date")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Date", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Credential")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Credential", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Security-Token")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Security-Token", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-Algorithm")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Algorithm", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-SignedHeaders", valid_598164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598165: Call_GetFinding_598153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified finding.
  ## 
  let valid = call_598165.validator(path, query, header, formData, body)
  let scheme = call_598165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598165.url(scheme.get, call_598165.host, call_598165.base,
                         call_598165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598165, url, valid)

proc call*(call_598166: Call_GetFinding_598153; analyzerArn: string; id: string): Recallable =
  ## getFinding
  ## Retrieves information about the specified finding.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer that generated the finding.
  ##   id: string (required)
  ##     : The ID of the finding to retrieve.
  var path_598167 = newJObject()
  var query_598168 = newJObject()
  add(query_598168, "analyzerArn", newJString(analyzerArn))
  add(path_598167, "id", newJString(id))
  result = call_598166.call(path_598167, query_598168, nil, nil, nil)

var getFinding* = Call_GetFinding_598153(name: "getFinding",
                                      meth: HttpMethod.HttpGet,
                                      host: "access-analyzer.amazonaws.com",
                                      route: "/finding/{id}#analyzerArn",
                                      validator: validate_GetFinding_598154,
                                      base: "/", url: url_GetFinding_598155,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzedResources_598169 = ref object of OpenApiRestCall_597389
proc url_ListAnalyzedResources_598171(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzedResources_598170(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of resources that have been analyzed.
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
  var valid_598172 = query.getOrDefault("nextToken")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "nextToken", valid_598172
  var valid_598173 = query.getOrDefault("maxResults")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "maxResults", valid_598173
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
  var valid_598174 = header.getOrDefault("X-Amz-Signature")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Signature", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Content-Sha256", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Date")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Date", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Credential")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Credential", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Security-Token")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Security-Token", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Algorithm")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Algorithm", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-SignedHeaders", valid_598180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598182: Call_ListAnalyzedResources_598169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resources that have been analyzed.
  ## 
  let valid = call_598182.validator(path, query, header, formData, body)
  let scheme = call_598182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598182.url(scheme.get, call_598182.host, call_598182.base,
                         call_598182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598182, url, valid)

proc call*(call_598183: Call_ListAnalyzedResources_598169; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAnalyzedResources
  ## Retrieves a list of resources that have been analyzed.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598184 = newJObject()
  var body_598185 = newJObject()
  add(query_598184, "nextToken", newJString(nextToken))
  if body != nil:
    body_598185 = body
  add(query_598184, "maxResults", newJString(maxResults))
  result = call_598183.call(nil, query_598184, nil, nil, body_598185)

var listAnalyzedResources* = Call_ListAnalyzedResources_598169(
    name: "listAnalyzedResources", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/analyzed-resource",
    validator: validate_ListAnalyzedResources_598170, base: "/",
    url: url_ListAnalyzedResources_598171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_598186 = ref object of OpenApiRestCall_597389
proc url_UpdateFindings_598188(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_598187(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates findings with the new values provided in the request.
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
  var valid_598189 = header.getOrDefault("X-Amz-Signature")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Signature", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Content-Sha256", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Date")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Date", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Credential")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Credential", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Security-Token")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Security-Token", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Algorithm")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Algorithm", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-SignedHeaders", valid_598195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598197: Call_UpdateFindings_598186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates findings with the new values provided in the request.
  ## 
  let valid = call_598197.validator(path, query, header, formData, body)
  let scheme = call_598197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598197.url(scheme.get, call_598197.host, call_598197.base,
                         call_598197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598197, url, valid)

proc call*(call_598198: Call_UpdateFindings_598186; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates findings with the new values provided in the request.
  ##   body: JObject (required)
  var body_598199 = newJObject()
  if body != nil:
    body_598199 = body
  result = call_598198.call(nil, nil, nil, nil, body_598199)

var updateFindings* = Call_UpdateFindings_598186(name: "updateFindings",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_UpdateFindings_598187, base: "/",
    url: url_UpdateFindings_598188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_598200 = ref object of OpenApiRestCall_597389
proc url_ListFindings_598202(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_598201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598203 = query.getOrDefault("nextToken")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "nextToken", valid_598203
  var valid_598204 = query.getOrDefault("maxResults")
  valid_598204 = validateParameter(valid_598204, JString, required = false,
                                 default = nil)
  if valid_598204 != nil:
    section.add "maxResults", valid_598204
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
  var valid_598205 = header.getOrDefault("X-Amz-Signature")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Signature", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Content-Sha256", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Date")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Date", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-Credential")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-Credential", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-Security-Token")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Security-Token", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Algorithm")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Algorithm", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-SignedHeaders", valid_598211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598213: Call_ListFindings_598200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  let valid = call_598213.validator(path, query, header, formData, body)
  let scheme = call_598213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598213.url(scheme.get, call_598213.host, call_598213.base,
                         call_598213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598213, url, valid)

proc call*(call_598214: Call_ListFindings_598200; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Retrieves a list of findings generated by the specified analyzer.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598215 = newJObject()
  var body_598216 = newJObject()
  add(query_598215, "nextToken", newJString(nextToken))
  if body != nil:
    body_598216 = body
  add(query_598215, "maxResults", newJString(maxResults))
  result = call_598214.call(nil, query_598215, nil, nil, body_598216)

var listFindings* = Call_ListFindings_598200(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_ListFindings_598201, base: "/",
    url: url_ListFindings_598202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598231 = ref object of OpenApiRestCall_597389
proc url_TagResource_598233(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598234 = path.getOrDefault("resourceArn")
  valid_598234 = validateParameter(valid_598234, JString, required = true,
                                 default = nil)
  if valid_598234 != nil:
    section.add "resourceArn", valid_598234
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
  var valid_598235 = header.getOrDefault("X-Amz-Signature")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-Signature", valid_598235
  var valid_598236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Content-Sha256", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-Date")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Date", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Credential")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Credential", valid_598238
  var valid_598239 = header.getOrDefault("X-Amz-Security-Token")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-Security-Token", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Algorithm")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Algorithm", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-SignedHeaders", valid_598241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598243: Call_TagResource_598231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a tag to the specified resource.
  ## 
  let valid = call_598243.validator(path, query, header, formData, body)
  let scheme = call_598243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598243.url(scheme.get, call_598243.host, call_598243.base,
                         call_598243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598243, url, valid)

proc call*(call_598244: Call_TagResource_598231; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds a tag to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to add the tag to.
  ##   body: JObject (required)
  var path_598245 = newJObject()
  var body_598246 = newJObject()
  add(path_598245, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_598246 = body
  result = call_598244.call(path_598245, nil, nil, nil, body_598246)

var tagResource* = Call_TagResource_598231(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_598232,
                                        base: "/", url: url_TagResource_598233,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598217 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598219(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598218(path: JsonNode; query: JsonNode;
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
  var valid_598220 = path.getOrDefault("resourceArn")
  valid_598220 = validateParameter(valid_598220, JString, required = true,
                                 default = nil)
  if valid_598220 != nil:
    section.add "resourceArn", valid_598220
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
  var valid_598221 = header.getOrDefault("X-Amz-Signature")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Signature", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-Content-Sha256", valid_598222
  var valid_598223 = header.getOrDefault("X-Amz-Date")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "X-Amz-Date", valid_598223
  var valid_598224 = header.getOrDefault("X-Amz-Credential")
  valid_598224 = validateParameter(valid_598224, JString, required = false,
                                 default = nil)
  if valid_598224 != nil:
    section.add "X-Amz-Credential", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Security-Token")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Security-Token", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Algorithm")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Algorithm", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-SignedHeaders", valid_598227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598228: Call_ListTagsForResource_598217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags applied to the specified resource.
  ## 
  let valid = call_598228.validator(path, query, header, formData, body)
  let scheme = call_598228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598228.url(scheme.get, call_598228.host, call_598228.base,
                         call_598228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598228, url, valid)

proc call*(call_598229: Call_ListTagsForResource_598217; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of tags applied to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags from.
  var path_598230 = newJObject()
  add(path_598230, "resourceArn", newJString(resourceArn))
  result = call_598229.call(path_598230, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598217(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_598218, base: "/",
    url: url_ListTagsForResource_598219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartResourceScan_598247 = ref object of OpenApiRestCall_597389
proc url_StartResourceScan_598249(protocol: Scheme; host: string; base: string;
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

proc validate_StartResourceScan_598248(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Starts a scan of the policies applied to the specified resource.
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
  var valid_598250 = header.getOrDefault("X-Amz-Signature")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Signature", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-Content-Sha256", valid_598251
  var valid_598252 = header.getOrDefault("X-Amz-Date")
  valid_598252 = validateParameter(valid_598252, JString, required = false,
                                 default = nil)
  if valid_598252 != nil:
    section.add "X-Amz-Date", valid_598252
  var valid_598253 = header.getOrDefault("X-Amz-Credential")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Credential", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-Security-Token")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-Security-Token", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Algorithm")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Algorithm", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-SignedHeaders", valid_598256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598258: Call_StartResourceScan_598247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a scan of the policies applied to the specified resource.
  ## 
  let valid = call_598258.validator(path, query, header, formData, body)
  let scheme = call_598258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598258.url(scheme.get, call_598258.host, call_598258.base,
                         call_598258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598258, url, valid)

proc call*(call_598259: Call_StartResourceScan_598247; body: JsonNode): Recallable =
  ## startResourceScan
  ## Starts a scan of the policies applied to the specified resource.
  ##   body: JObject (required)
  var body_598260 = newJObject()
  if body != nil:
    body_598260 = body
  result = call_598259.call(nil, nil, nil, nil, body_598260)

var startResourceScan* = Call_StartResourceScan_598247(name: "startResourceScan",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/resource/scan", validator: validate_StartResourceScan_598248,
    base: "/", url: url_StartResourceScan_598249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598261 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598263(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598262(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598264 = path.getOrDefault("resourceArn")
  valid_598264 = validateParameter(valid_598264, JString, required = true,
                                 default = nil)
  if valid_598264 != nil:
    section.add "resourceArn", valid_598264
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598265 = query.getOrDefault("tagKeys")
  valid_598265 = validateParameter(valid_598265, JArray, required = true, default = nil)
  if valid_598265 != nil:
    section.add "tagKeys", valid_598265
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
  var valid_598266 = header.getOrDefault("X-Amz-Signature")
  valid_598266 = validateParameter(valid_598266, JString, required = false,
                                 default = nil)
  if valid_598266 != nil:
    section.add "X-Amz-Signature", valid_598266
  var valid_598267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Content-Sha256", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Date")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Date", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Credential")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Credential", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Security-Token")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Security-Token", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Algorithm")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Algorithm", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-SignedHeaders", valid_598272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598273: Call_UntagResource_598261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_598273.validator(path, query, header, formData, body)
  let scheme = call_598273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598273.url(scheme.get, call_598273.host, call_598273.base,
                         call_598273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598273, url, valid)

proc call*(call_598274: Call_UntagResource_598261; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to remove the tag from.
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  var path_598275 = newJObject()
  var query_598276 = newJObject()
  add(path_598275, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_598276.add "tagKeys", tagKeys
  result = call_598274.call(path_598275, query_598276, nil, nil, nil)

var untagResource* = Call_UntagResource_598261(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_598262,
    base: "/", url: url_UntagResource_598263, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
