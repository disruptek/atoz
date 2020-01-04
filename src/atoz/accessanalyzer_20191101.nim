
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateAnalyzer_601998 = ref object of OpenApiRestCall_601389
proc url_CreateAnalyzer_602000(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAnalyzer_601999(path: JsonNode; query: JsonNode;
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_CreateAnalyzer_601998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an analyzer for your account.
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_CreateAnalyzer_601998; body: JsonNode): Recallable =
  ## createAnalyzer
  ## Creates an analyzer for your account.
  ##   body: JObject (required)
  var body_602011 = newJObject()
  if body != nil:
    body_602011 = body
  result = call_602010.call(nil, nil, nil, nil, body_602011)

var createAnalyzer* = Call_CreateAnalyzer_601998(name: "createAnalyzer",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_CreateAnalyzer_601999, base: "/",
    url: url_CreateAnalyzer_602000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzers_601727 = ref object of OpenApiRestCall_601389
proc url_ListAnalyzers_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzers_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601855 = query.getOrDefault("type")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = newJString("ACCOUNT"))
  if valid_601855 != nil:
    section.add "type", valid_601855
  var valid_601856 = query.getOrDefault("maxResults")
  valid_601856 = validateParameter(valid_601856, JInt, required = false, default = nil)
  if valid_601856 != nil:
    section.add "maxResults", valid_601856
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
  var valid_601857 = header.getOrDefault("X-Amz-Signature")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Signature", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Credential")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Credential", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_ListAnalyzers_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of analyzers.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_ListAnalyzers_601727; nextToken: string = "";
          `type`: string = "ACCOUNT"; maxResults: int = 0): Recallable =
  ## listAnalyzers
  ## Retrieves a list of analyzers.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   type: string
  ##       : The type of analyzer.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  var query_601958 = newJObject()
  add(query_601958, "nextToken", newJString(nextToken))
  add(query_601958, "type", newJString(`type`))
  add(query_601958, "maxResults", newJInt(maxResults))
  result = call_601957.call(nil, query_601958, nil, nil, nil)

var listAnalyzers* = Call_ListAnalyzers_601727(name: "listAnalyzers",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_ListAnalyzers_601728, base: "/",
    url: url_ListAnalyzers_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateArchiveRule_602043 = ref object of OpenApiRestCall_601389
proc url_CreateArchiveRule_602045(protocol: Scheme; host: string; base: string;
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

proc validate_CreateArchiveRule_602044(path: JsonNode; query: JsonNode;
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
  var valid_602046 = path.getOrDefault("analyzerName")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = nil)
  if valid_602046 != nil:
    section.add "analyzerName", valid_602046
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
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Content-Sha256", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Date")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Date", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-SignedHeaders", valid_602053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_CreateArchiveRule_602043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ## 
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602055, url, valid)

proc call*(call_602056: Call_CreateArchiveRule_602043; analyzerName: string;
          body: JsonNode): Recallable =
  ## createArchiveRule
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ##   analyzerName: string (required)
  ##               : The name of the created analyzer.
  ##   body: JObject (required)
  var path_602057 = newJObject()
  var body_602058 = newJObject()
  add(path_602057, "analyzerName", newJString(analyzerName))
  if body != nil:
    body_602058 = body
  result = call_602056.call(path_602057, nil, nil, nil, body_602058)

var createArchiveRule* = Call_CreateArchiveRule_602043(name: "createArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_CreateArchiveRule_602044, base: "/",
    url: url_CreateArchiveRule_602045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArchiveRules_602012 = ref object of OpenApiRestCall_601389
proc url_ListArchiveRules_602014(protocol: Scheme; host: string; base: string;
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

proc validate_ListArchiveRules_602013(path: JsonNode; query: JsonNode;
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
  var valid_602029 = path.getOrDefault("analyzerName")
  valid_602029 = validateParameter(valid_602029, JString, required = true,
                                 default = nil)
  if valid_602029 != nil:
    section.add "analyzerName", valid_602029
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the request.
  section = newJObject()
  var valid_602030 = query.getOrDefault("nextToken")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "nextToken", valid_602030
  var valid_602031 = query.getOrDefault("maxResults")
  valid_602031 = validateParameter(valid_602031, JInt, required = false, default = nil)
  if valid_602031 != nil:
    section.add "maxResults", valid_602031
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
  var valid_602032 = header.getOrDefault("X-Amz-Signature")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Signature", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Content-Sha256", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Date")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Date", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Credential")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Credential", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Security-Token")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Security-Token", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-SignedHeaders", valid_602038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_ListArchiveRules_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of archive rules created for the specified analyzer.
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_ListArchiveRules_602012; analyzerName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listArchiveRules
  ## Retrieves a list of archive rules created for the specified analyzer.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   maxResults: int
  ##             : The maximum number of results to return in the request.
  var path_602041 = newJObject()
  var query_602042 = newJObject()
  add(query_602042, "nextToken", newJString(nextToken))
  add(path_602041, "analyzerName", newJString(analyzerName))
  add(query_602042, "maxResults", newJInt(maxResults))
  result = call_602040.call(path_602041, query_602042, nil, nil, nil)

var listArchiveRules* = Call_ListArchiveRules_602012(name: "listArchiveRules",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_ListArchiveRules_602013, base: "/",
    url: url_ListArchiveRules_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzer_602059 = ref object of OpenApiRestCall_601389
proc url_GetAnalyzer_602061(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzer_602060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602062 = path.getOrDefault("analyzerName")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "analyzerName", valid_602062
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
  var valid_602063 = header.getOrDefault("X-Amz-Signature")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Signature", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Content-Sha256", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Credential")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Credential", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602070: Call_GetAnalyzer_602059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified analyzer.
  ## 
  let valid = call_602070.validator(path, query, header, formData, body)
  let scheme = call_602070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602070.url(scheme.get, call_602070.host, call_602070.base,
                         call_602070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602070, url, valid)

proc call*(call_602071: Call_GetAnalyzer_602059; analyzerName: string): Recallable =
  ## getAnalyzer
  ## Retrieves information about the specified analyzer.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer retrieved.
  var path_602072 = newJObject()
  add(path_602072, "analyzerName", newJString(analyzerName))
  result = call_602071.call(path_602072, nil, nil, nil, nil)

var getAnalyzer* = Call_GetAnalyzer_602059(name: "getAnalyzer",
                                        meth: HttpMethod.HttpGet,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/analyzer/{analyzerName}",
                                        validator: validate_GetAnalyzer_602060,
                                        base: "/", url: url_GetAnalyzer_602061,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAnalyzer_602073 = ref object of OpenApiRestCall_601389
proc url_DeleteAnalyzer_602075(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAnalyzer_602074(path: JsonNode; query: JsonNode;
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
  var valid_602076 = path.getOrDefault("analyzerName")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = nil)
  if valid_602076 != nil:
    section.add "analyzerName", valid_602076
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_602077 = query.getOrDefault("clientToken")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "clientToken", valid_602077
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
  var valid_602078 = header.getOrDefault("X-Amz-Signature")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Signature", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Content-Sha256", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Date")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Date", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Credential")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Credential", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Algorithm")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Algorithm", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602085: Call_DeleteAnalyzer_602073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ## 
  let valid = call_602085.validator(path, query, header, formData, body)
  let scheme = call_602085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602085.url(scheme.get, call_602085.host, call_602085.base,
                         call_602085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602085, url, valid)

proc call*(call_602086: Call_DeleteAnalyzer_602073; analyzerName: string;
          clientToken: string = ""): Recallable =
  ## deleteAnalyzer
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_602087 = newJObject()
  var query_602088 = newJObject()
  add(path_602087, "analyzerName", newJString(analyzerName))
  add(query_602088, "clientToken", newJString(clientToken))
  result = call_602086.call(path_602087, query_602088, nil, nil, nil)

var deleteAnalyzer* = Call_DeleteAnalyzer_602073(name: "deleteAnalyzer",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_DeleteAnalyzer_602074,
    base: "/", url: url_DeleteAnalyzer_602075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateArchiveRule_602104 = ref object of OpenApiRestCall_601389
proc url_UpdateArchiveRule_602106(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateArchiveRule_602105(path: JsonNode; query: JsonNode;
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
  var valid_602107 = path.getOrDefault("analyzerName")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = nil)
  if valid_602107 != nil:
    section.add "analyzerName", valid_602107
  var valid_602108 = path.getOrDefault("ruleName")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = nil)
  if valid_602108 != nil:
    section.add "ruleName", valid_602108
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
  var valid_602109 = header.getOrDefault("X-Amz-Signature")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Signature", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Content-Sha256", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Date")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Date", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Credential")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Credential", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Security-Token")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Security-Token", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Algorithm")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Algorithm", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-SignedHeaders", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602117: Call_UpdateArchiveRule_602104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the criteria and values for the specified archive rule.
  ## 
  let valid = call_602117.validator(path, query, header, formData, body)
  let scheme = call_602117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602117.url(scheme.get, call_602117.host, call_602117.base,
                         call_602117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602117, url, valid)

proc call*(call_602118: Call_UpdateArchiveRule_602104; analyzerName: string;
          ruleName: string; body: JsonNode): Recallable =
  ## updateArchiveRule
  ## Updates the criteria and values for the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to update the archive rules for.
  ##   ruleName: string (required)
  ##           : The name of the rule to update.
  ##   body: JObject (required)
  var path_602119 = newJObject()
  var body_602120 = newJObject()
  add(path_602119, "analyzerName", newJString(analyzerName))
  add(path_602119, "ruleName", newJString(ruleName))
  if body != nil:
    body_602120 = body
  result = call_602118.call(path_602119, nil, nil, nil, body_602120)

var updateArchiveRule* = Call_UpdateArchiveRule_602104(name: "updateArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_UpdateArchiveRule_602105, base: "/",
    url: url_UpdateArchiveRule_602106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArchiveRule_602089 = ref object of OpenApiRestCall_601389
proc url_GetArchiveRule_602091(protocol: Scheme; host: string; base: string;
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

proc validate_GetArchiveRule_602090(path: JsonNode; query: JsonNode;
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
  var valid_602092 = path.getOrDefault("analyzerName")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = nil)
  if valid_602092 != nil:
    section.add "analyzerName", valid_602092
  var valid_602093 = path.getOrDefault("ruleName")
  valid_602093 = validateParameter(valid_602093, JString, required = true,
                                 default = nil)
  if valid_602093 != nil:
    section.add "ruleName", valid_602093
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
  var valid_602094 = header.getOrDefault("X-Amz-Signature")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Signature", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Content-Sha256", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Date")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Date", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Credential")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Credential", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Security-Token")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Security-Token", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Algorithm")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Algorithm", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-SignedHeaders", valid_602100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602101: Call_GetArchiveRule_602089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an archive rule.
  ## 
  let valid = call_602101.validator(path, query, header, formData, body)
  let scheme = call_602101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602101.url(scheme.get, call_602101.host, call_602101.base,
                         call_602101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602101, url, valid)

proc call*(call_602102: Call_GetArchiveRule_602089; analyzerName: string;
          ruleName: string): Recallable =
  ## getArchiveRule
  ## Retrieves information about an archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  ##   ruleName: string (required)
  ##           : The name of the rule to retrieve.
  var path_602103 = newJObject()
  add(path_602103, "analyzerName", newJString(analyzerName))
  add(path_602103, "ruleName", newJString(ruleName))
  result = call_602102.call(path_602103, nil, nil, nil, nil)

var getArchiveRule* = Call_GetArchiveRule_602089(name: "getArchiveRule",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_GetArchiveRule_602090, base: "/", url: url_GetArchiveRule_602091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchiveRule_602121 = ref object of OpenApiRestCall_601389
proc url_DeleteArchiveRule_602123(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteArchiveRule_602122(path: JsonNode; query: JsonNode;
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
  var valid_602124 = path.getOrDefault("analyzerName")
  valid_602124 = validateParameter(valid_602124, JString, required = true,
                                 default = nil)
  if valid_602124 != nil:
    section.add "analyzerName", valid_602124
  var valid_602125 = path.getOrDefault("ruleName")
  valid_602125 = validateParameter(valid_602125, JString, required = true,
                                 default = nil)
  if valid_602125 != nil:
    section.add "ruleName", valid_602125
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_602126 = query.getOrDefault("clientToken")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "clientToken", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Signature")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Signature", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Date")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Date", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Algorithm")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Algorithm", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-SignedHeaders", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_DeleteArchiveRule_602121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified archive rule.
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_DeleteArchiveRule_602121; analyzerName: string;
          ruleName: string; clientToken: string = ""): Recallable =
  ## deleteArchiveRule
  ## Deletes the specified archive rule.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer that associated with the archive rule to delete.
  ##   ruleName: string (required)
  ##           : The name of the rule to delete.
  ##   clientToken: string
  ##              : A client token.
  var path_602136 = newJObject()
  var query_602137 = newJObject()
  add(path_602136, "analyzerName", newJString(analyzerName))
  add(path_602136, "ruleName", newJString(ruleName))
  add(query_602137, "clientToken", newJString(clientToken))
  result = call_602135.call(path_602136, query_602137, nil, nil, nil)

var deleteArchiveRule* = Call_DeleteArchiveRule_602121(name: "deleteArchiveRule",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_DeleteArchiveRule_602122, base: "/",
    url: url_DeleteArchiveRule_602123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzedResource_602138 = ref object of OpenApiRestCall_601389
proc url_GetAnalyzedResource_602140(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzedResource_602139(path: JsonNode; query: JsonNode;
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
  var valid_602141 = query.getOrDefault("analyzerArn")
  valid_602141 = validateParameter(valid_602141, JString, required = true,
                                 default = nil)
  if valid_602141 != nil:
    section.add "analyzerArn", valid_602141
  var valid_602142 = query.getOrDefault("resourceArn")
  valid_602142 = validateParameter(valid_602142, JString, required = true,
                                 default = nil)
  if valid_602142 != nil:
    section.add "resourceArn", valid_602142
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
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Date")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Date", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Algorithm")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Algorithm", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-SignedHeaders", valid_602149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_GetAnalyzedResource_602138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource that was analyzed.
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_GetAnalyzedResource_602138; analyzerArn: string;
          resourceArn: string): Recallable =
  ## getAnalyzedResource
  ## Retrieves information about a resource that was analyzed.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer to retrieve information from.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve information about.
  var query_602152 = newJObject()
  add(query_602152, "analyzerArn", newJString(analyzerArn))
  add(query_602152, "resourceArn", newJString(resourceArn))
  result = call_602151.call(nil, query_602152, nil, nil, nil)

var getAnalyzedResource* = Call_GetAnalyzedResource_602138(
    name: "getAnalyzedResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzed-resource#analyzerArn&resourceArn",
    validator: validate_GetAnalyzedResource_602139, base: "/",
    url: url_GetAnalyzedResource_602140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFinding_602153 = ref object of OpenApiRestCall_601389
proc url_GetFinding_602155(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFinding_602154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602156 = path.getOrDefault("id")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = nil)
  if valid_602156 != nil:
    section.add "id", valid_602156
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer that generated the finding.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analyzerArn` field"
  var valid_602157 = query.getOrDefault("analyzerArn")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "analyzerArn", valid_602157
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
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Date")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Date", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Algorithm")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Algorithm", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-SignedHeaders", valid_602164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602165: Call_GetFinding_602153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified finding.
  ## 
  let valid = call_602165.validator(path, query, header, formData, body)
  let scheme = call_602165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602165.url(scheme.get, call_602165.host, call_602165.base,
                         call_602165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602165, url, valid)

proc call*(call_602166: Call_GetFinding_602153; analyzerArn: string; id: string): Recallable =
  ## getFinding
  ## Retrieves information about the specified finding.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer that generated the finding.
  ##   id: string (required)
  ##     : The ID of the finding to retrieve.
  var path_602167 = newJObject()
  var query_602168 = newJObject()
  add(query_602168, "analyzerArn", newJString(analyzerArn))
  add(path_602167, "id", newJString(id))
  result = call_602166.call(path_602167, query_602168, nil, nil, nil)

var getFinding* = Call_GetFinding_602153(name: "getFinding",
                                      meth: HttpMethod.HttpGet,
                                      host: "access-analyzer.amazonaws.com",
                                      route: "/finding/{id}#analyzerArn",
                                      validator: validate_GetFinding_602154,
                                      base: "/", url: url_GetFinding_602155,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzedResources_602169 = ref object of OpenApiRestCall_601389
proc url_ListAnalyzedResources_602171(protocol: Scheme; host: string; base: string;
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

proc validate_ListAnalyzedResources_602170(path: JsonNode; query: JsonNode;
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
  var valid_602172 = query.getOrDefault("nextToken")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "nextToken", valid_602172
  var valid_602173 = query.getOrDefault("maxResults")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "maxResults", valid_602173
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
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Date")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Date", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Algorithm")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Algorithm", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_ListAnalyzedResources_602169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ## 
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602182, url, valid)

proc call*(call_602183: Call_ListAnalyzedResources_602169; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAnalyzedResources
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602184 = newJObject()
  var body_602185 = newJObject()
  add(query_602184, "nextToken", newJString(nextToken))
  if body != nil:
    body_602185 = body
  add(query_602184, "maxResults", newJString(maxResults))
  result = call_602183.call(nil, query_602184, nil, nil, body_602185)

var listAnalyzedResources* = Call_ListAnalyzedResources_602169(
    name: "listAnalyzedResources", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/analyzed-resource",
    validator: validate_ListAnalyzedResources_602170, base: "/",
    url: url_ListAnalyzedResources_602171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_602186 = ref object of OpenApiRestCall_601389
proc url_UpdateFindings_602188(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_602187(path: JsonNode; query: JsonNode;
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
  var valid_602189 = header.getOrDefault("X-Amz-Signature")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Signature", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Content-Sha256", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Date")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Date", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Credential")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Credential", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Algorithm")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Algorithm", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-SignedHeaders", valid_602195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602197: Call_UpdateFindings_602186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified findings.
  ## 
  let valid = call_602197.validator(path, query, header, formData, body)
  let scheme = call_602197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602197.url(scheme.get, call_602197.host, call_602197.base,
                         call_602197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602197, url, valid)

proc call*(call_602198: Call_UpdateFindings_602186; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the status for the specified findings.
  ##   body: JObject (required)
  var body_602199 = newJObject()
  if body != nil:
    body_602199 = body
  result = call_602198.call(nil, nil, nil, nil, body_602199)

var updateFindings* = Call_UpdateFindings_602186(name: "updateFindings",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_UpdateFindings_602187, base: "/",
    url: url_UpdateFindings_602188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_602200 = ref object of OpenApiRestCall_601389
proc url_ListFindings_602202(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_602201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602203 = query.getOrDefault("nextToken")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "nextToken", valid_602203
  var valid_602204 = query.getOrDefault("maxResults")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "maxResults", valid_602204
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
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_ListFindings_602200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_ListFindings_602200; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Retrieves a list of findings generated by the specified analyzer.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602215 = newJObject()
  var body_602216 = newJObject()
  add(query_602215, "nextToken", newJString(nextToken))
  if body != nil:
    body_602216 = body
  add(query_602215, "maxResults", newJString(maxResults))
  result = call_602214.call(nil, query_602215, nil, nil, body_602216)

var listFindings* = Call_ListFindings_602200(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_ListFindings_602201, base: "/",
    url: url_ListFindings_602202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602231 = ref object of OpenApiRestCall_601389
proc url_TagResource_602233(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602234 = path.getOrDefault("resourceArn")
  valid_602234 = validateParameter(valid_602234, JString, required = true,
                                 default = nil)
  if valid_602234 != nil:
    section.add "resourceArn", valid_602234
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
  var valid_602235 = header.getOrDefault("X-Amz-Signature")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Signature", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Content-Sha256", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Date")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Date", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Security-Token")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Security-Token", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Algorithm")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Algorithm", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602243: Call_TagResource_602231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a tag to the specified resource.
  ## 
  let valid = call_602243.validator(path, query, header, formData, body)
  let scheme = call_602243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602243.url(scheme.get, call_602243.host, call_602243.base,
                         call_602243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602243, url, valid)

proc call*(call_602244: Call_TagResource_602231; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds a tag to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to add the tag to.
  ##   body: JObject (required)
  var path_602245 = newJObject()
  var body_602246 = newJObject()
  add(path_602245, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602246 = body
  result = call_602244.call(path_602245, nil, nil, nil, body_602246)

var tagResource* = Call_TagResource_602231(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602232,
                                        base: "/", url: url_TagResource_602233,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602217 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602219(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602218(path: JsonNode; query: JsonNode;
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
  var valid_602220 = path.getOrDefault("resourceArn")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = nil)
  if valid_602220 != nil:
    section.add "resourceArn", valid_602220
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
  var valid_602221 = header.getOrDefault("X-Amz-Signature")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Signature", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Content-Sha256", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Date")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Date", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Credential")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Credential", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Security-Token")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Security-Token", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Algorithm")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Algorithm", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-SignedHeaders", valid_602227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602228: Call_ListTagsForResource_602217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags applied to the specified resource.
  ## 
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602228, url, valid)

proc call*(call_602229: Call_ListTagsForResource_602217; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of tags applied to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags from.
  var path_602230 = newJObject()
  add(path_602230, "resourceArn", newJString(resourceArn))
  result = call_602229.call(path_602230, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602217(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602218, base: "/",
    url: url_ListTagsForResource_602219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartResourceScan_602247 = ref object of OpenApiRestCall_601389
proc url_StartResourceScan_602249(protocol: Scheme; host: string; base: string;
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

proc validate_StartResourceScan_602248(path: JsonNode; query: JsonNode;
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
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_StartResourceScan_602247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately starts a scan of the policies applied to the specified resource.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_StartResourceScan_602247; body: JsonNode): Recallable =
  ## startResourceScan
  ## Immediately starts a scan of the policies applied to the specified resource.
  ##   body: JObject (required)
  var body_602260 = newJObject()
  if body != nil:
    body_602260 = body
  result = call_602259.call(nil, nil, nil, nil, body_602260)

var startResourceScan* = Call_StartResourceScan_602247(name: "startResourceScan",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/resource/scan", validator: validate_StartResourceScan_602248,
    base: "/", url: url_StartResourceScan_602249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602261 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602263(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602262(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602264 = path.getOrDefault("resourceArn")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "resourceArn", valid_602264
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602265 = query.getOrDefault("tagKeys")
  valid_602265 = validateParameter(valid_602265, JArray, required = true, default = nil)
  if valid_602265 != nil:
    section.add "tagKeys", valid_602265
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
  var valid_602266 = header.getOrDefault("X-Amz-Signature")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Signature", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Content-Sha256", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Date")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Date", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Credential")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Credential", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Security-Token")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Security-Token", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Algorithm")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Algorithm", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-SignedHeaders", valid_602272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602273: Call_UntagResource_602261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_602273.validator(path, query, header, formData, body)
  let scheme = call_602273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602273.url(scheme.get, call_602273.host, call_602273.base,
                         call_602273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602273, url, valid)

proc call*(call_602274: Call_UntagResource_602261; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to remove the tag from.
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  var path_602275 = newJObject()
  var query_602276 = newJObject()
  add(path_602275, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602276.add "tagKeys", tagKeys
  result = call_602274.call(path_602275, query_602276, nil, nil, nil)

var untagResource* = Call_UntagResource_602261(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602262,
    base: "/", url: url_UntagResource_602263, schemes: {Scheme.Https, Scheme.Http})
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
