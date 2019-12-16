
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateAnalyzer_599976 = ref object of OpenApiRestCall_599368
proc url_CreateAnalyzer_599978(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAnalyzer_599977(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_CreateAnalyzer_599976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an analyzer for your account.
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_CreateAnalyzer_599976; body: JsonNode): Recallable =
  ## createAnalyzer
  ## Creates an analyzer for your account.
  ##   body: JObject (required)
  var body_599989 = newJObject()
  if body != nil:
    body_599989 = body
  result = call_599988.call(nil, nil, nil, nil, body_599989)

var createAnalyzer* = Call_CreateAnalyzer_599976(name: "createAnalyzer",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_CreateAnalyzer_599977, base: "/",
    url: url_CreateAnalyzer_599978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzers_599705 = ref object of OpenApiRestCall_599368
proc url_ListAnalyzers_599707(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAnalyzers_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of analyzers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The type of analyzer.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  section = newJObject()
  var valid_599832 = query.getOrDefault("type")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = newJString("ACCOUNT"))
  if valid_599832 != nil:
    section.add "type", valid_599832
  var valid_599833 = query.getOrDefault("maxResults")
  valid_599833 = validateParameter(valid_599833, JInt, required = false, default = nil)
  if valid_599833 != nil:
    section.add "maxResults", valid_599833
  var valid_599834 = query.getOrDefault("nextToken")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "nextToken", valid_599834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599835 = header.getOrDefault("X-Amz-Date")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Date", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Security-Token")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Security-Token", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_ListAnalyzers_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of analyzers.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_ListAnalyzers_599705; `type`: string = "ACCOUNT";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listAnalyzers
  ## Retrieves a list of analyzers.
  ##   type: string
  ##       : The type of analyzer.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  var query_599936 = newJObject()
  add(query_599936, "type", newJString(`type`))
  add(query_599936, "maxResults", newJInt(maxResults))
  add(query_599936, "nextToken", newJString(nextToken))
  result = call_599935.call(nil, query_599936, nil, nil, nil)

var listAnalyzers* = Call_ListAnalyzers_599705(name: "listAnalyzers",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_ListAnalyzers_599706, base: "/",
    url: url_ListAnalyzers_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateArchiveRule_600021 = ref object of OpenApiRestCall_599368
proc url_CreateArchiveRule_600023(protocol: Scheme; host: string; base: string;
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

proc validate_CreateArchiveRule_600022(path: JsonNode; query: JsonNode;
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
  var valid_600024 = path.getOrDefault("analyzerName")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = nil)
  if valid_600024 != nil:
    section.add "analyzerName", valid_600024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600025 = header.getOrDefault("X-Amz-Date")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Date", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Security-Token")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Security-Token", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Content-Sha256", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Algorithm")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Algorithm", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Signature")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Signature", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-SignedHeaders", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Credential")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Credential", valid_600031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600033: Call_CreateArchiveRule_600021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ## 
  let valid = call_600033.validator(path, query, header, formData, body)
  let scheme = call_600033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600033.url(scheme.get, call_600033.host, call_600033.base,
                         call_600033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600033, url, valid)

proc call*(call_600034: Call_CreateArchiveRule_600021; body: JsonNode;
          analyzerName: string): Recallable =
  ## createArchiveRule
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ##   body: JObject (required)
  ##   analyzerName: string (required)
  ##               : The name of the created analyzer.
  var path_600035 = newJObject()
  var body_600036 = newJObject()
  if body != nil:
    body_600036 = body
  add(path_600035, "analyzerName", newJString(analyzerName))
  result = call_600034.call(path_600035, nil, nil, nil, body_600036)

var createArchiveRule* = Call_CreateArchiveRule_600021(name: "createArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_CreateArchiveRule_600022, base: "/",
    url: url_CreateArchiveRule_600023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArchiveRules_599990 = ref object of OpenApiRestCall_599368
proc url_ListArchiveRules_599992(protocol: Scheme; host: string; base: string;
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

proc validate_ListArchiveRules_599991(path: JsonNode; query: JsonNode;
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
  var valid_600007 = path.getOrDefault("analyzerName")
  valid_600007 = validateParameter(valid_600007, JString, required = true,
                                 default = nil)
  if valid_600007 != nil:
    section.add "analyzerName", valid_600007
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the request.
  ##   nextToken: JString
  ##            : A token used for pagination of results returned.
  section = newJObject()
  var valid_600008 = query.getOrDefault("maxResults")
  valid_600008 = validateParameter(valid_600008, JInt, required = false, default = nil)
  if valid_600008 != nil:
    section.add "maxResults", valid_600008
  var valid_600009 = query.getOrDefault("nextToken")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "nextToken", valid_600009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600010 = header.getOrDefault("X-Amz-Date")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Date", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Security-Token")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Security-Token", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Content-Sha256", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Algorithm")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Algorithm", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Signature")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Signature", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-SignedHeaders", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Credential")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Credential", valid_600016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_ListArchiveRules_599990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of archive rules created for the specified analyzer.
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_ListArchiveRules_599990; analyzerName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listArchiveRules
  ## Retrieves a list of archive rules created for the specified analyzer.
  ##   maxResults: int
  ##             : The maximum number of results to return in the request.
  ##   nextToken: string
  ##            : A token used for pagination of results returned.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  var path_600019 = newJObject()
  var query_600020 = newJObject()
  add(query_600020, "maxResults", newJInt(maxResults))
  add(query_600020, "nextToken", newJString(nextToken))
  add(path_600019, "analyzerName", newJString(analyzerName))
  result = call_600018.call(path_600019, query_600020, nil, nil, nil)

var listArchiveRules* = Call_ListArchiveRules_599990(name: "listArchiveRules",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_ListArchiveRules_599991, base: "/",
    url: url_ListArchiveRules_599992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzer_600037 = ref object of OpenApiRestCall_599368
proc url_GetAnalyzer_600039(protocol: Scheme; host: string; base: string;
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

proc validate_GetAnalyzer_600038(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600040 = path.getOrDefault("analyzerName")
  valid_600040 = validateParameter(valid_600040, JString, required = true,
                                 default = nil)
  if valid_600040 != nil:
    section.add "analyzerName", valid_600040
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600041 = header.getOrDefault("X-Amz-Date")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Date", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Security-Token")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Security-Token", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Content-Sha256", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Algorithm")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Algorithm", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Signature")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Signature", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-SignedHeaders", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Credential")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Credential", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600048: Call_GetAnalyzer_600037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified analyzer.
  ## 
  let valid = call_600048.validator(path, query, header, formData, body)
  let scheme = call_600048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600048.url(scheme.get, call_600048.host, call_600048.base,
                         call_600048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600048, url, valid)

proc call*(call_600049: Call_GetAnalyzer_600037; analyzerName: string): Recallable =
  ## getAnalyzer
  ## Retrieves information about the specified analyzer.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer retrieved.
  var path_600050 = newJObject()
  add(path_600050, "analyzerName", newJString(analyzerName))
  result = call_600049.call(path_600050, nil, nil, nil, nil)

var getAnalyzer* = Call_GetAnalyzer_600037(name: "getAnalyzer",
                                        meth: HttpMethod.HttpGet,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/analyzer/{analyzerName}",
                                        validator: validate_GetAnalyzer_600038,
                                        base: "/", url: url_GetAnalyzer_600039,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAnalyzer_600051 = ref object of OpenApiRestCall_599368
proc url_DeleteAnalyzer_600053(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAnalyzer_600052(path: JsonNode; query: JsonNode;
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
  var valid_600054 = path.getOrDefault("analyzerName")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = nil)
  if valid_600054 != nil:
    section.add "analyzerName", valid_600054
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_600055 = query.getOrDefault("clientToken")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "clientToken", valid_600055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600056 = header.getOrDefault("X-Amz-Date")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Date", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Security-Token")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Security-Token", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Content-Sha256", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Algorithm")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Algorithm", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Signature")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Signature", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-SignedHeaders", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Credential")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Credential", valid_600062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600063: Call_DeleteAnalyzer_600051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ## 
  let valid = call_600063.validator(path, query, header, formData, body)
  let scheme = call_600063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600063.url(scheme.get, call_600063.host, call_600063.base,
                         call_600063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600063, url, valid)

proc call*(call_600064: Call_DeleteAnalyzer_600051; analyzerName: string;
          clientToken: string = ""): Recallable =
  ## deleteAnalyzer
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ##   clientToken: string
  ##              : A client token.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to delete.
  var path_600065 = newJObject()
  var query_600066 = newJObject()
  add(query_600066, "clientToken", newJString(clientToken))
  add(path_600065, "analyzerName", newJString(analyzerName))
  result = call_600064.call(path_600065, query_600066, nil, nil, nil)

var deleteAnalyzer* = Call_DeleteAnalyzer_600051(name: "deleteAnalyzer",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_DeleteAnalyzer_600052,
    base: "/", url: url_DeleteAnalyzer_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateArchiveRule_600082 = ref object of OpenApiRestCall_599368
proc url_UpdateArchiveRule_600084(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateArchiveRule_600083(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the criteria and values for the specified archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ruleName: JString (required)
  ##           : The name of the rule to update.
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to update the archive rules for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ruleName` field"
  var valid_600085 = path.getOrDefault("ruleName")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "ruleName", valid_600085
  var valid_600086 = path.getOrDefault("analyzerName")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = nil)
  if valid_600086 != nil:
    section.add "analyzerName", valid_600086
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600087 = header.getOrDefault("X-Amz-Date")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Date", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Security-Token")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Security-Token", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Content-Sha256", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Algorithm")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Algorithm", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Signature")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Signature", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-SignedHeaders", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Credential")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Credential", valid_600093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_UpdateArchiveRule_600082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the criteria and values for the specified archive rule.
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_UpdateArchiveRule_600082; ruleName: string;
          body: JsonNode; analyzerName: string): Recallable =
  ## updateArchiveRule
  ## Updates the criteria and values for the specified archive rule.
  ##   ruleName: string (required)
  ##           : The name of the rule to update.
  ##   body: JObject (required)
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to update the archive rules for.
  var path_600097 = newJObject()
  var body_600098 = newJObject()
  add(path_600097, "ruleName", newJString(ruleName))
  if body != nil:
    body_600098 = body
  add(path_600097, "analyzerName", newJString(analyzerName))
  result = call_600096.call(path_600097, nil, nil, nil, body_600098)

var updateArchiveRule* = Call_UpdateArchiveRule_600082(name: "updateArchiveRule",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_UpdateArchiveRule_600083, base: "/",
    url: url_UpdateArchiveRule_600084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArchiveRule_600067 = ref object of OpenApiRestCall_599368
proc url_GetArchiveRule_600069(protocol: Scheme; host: string; base: string;
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

proc validate_GetArchiveRule_600068(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves information about an archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ruleName: JString (required)
  ##           : The name of the rule to retrieve.
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer to retrieve rules from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ruleName` field"
  var valid_600070 = path.getOrDefault("ruleName")
  valid_600070 = validateParameter(valid_600070, JString, required = true,
                                 default = nil)
  if valid_600070 != nil:
    section.add "ruleName", valid_600070
  var valid_600071 = path.getOrDefault("analyzerName")
  valid_600071 = validateParameter(valid_600071, JString, required = true,
                                 default = nil)
  if valid_600071 != nil:
    section.add "analyzerName", valid_600071
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600072 = header.getOrDefault("X-Amz-Date")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Date", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Security-Token")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Security-Token", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Content-Sha256", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Algorithm")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Algorithm", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Signature")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Signature", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-SignedHeaders", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Credential")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Credential", valid_600078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600079: Call_GetArchiveRule_600067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about an archive rule.
  ## 
  let valid = call_600079.validator(path, query, header, formData, body)
  let scheme = call_600079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600079.url(scheme.get, call_600079.host, call_600079.base,
                         call_600079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600079, url, valid)

proc call*(call_600080: Call_GetArchiveRule_600067; ruleName: string;
          analyzerName: string): Recallable =
  ## getArchiveRule
  ## Retrieves information about an archive rule.
  ##   ruleName: string (required)
  ##           : The name of the rule to retrieve.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer to retrieve rules from.
  var path_600081 = newJObject()
  add(path_600081, "ruleName", newJString(ruleName))
  add(path_600081, "analyzerName", newJString(analyzerName))
  result = call_600080.call(path_600081, nil, nil, nil, nil)

var getArchiveRule* = Call_GetArchiveRule_600067(name: "getArchiveRule",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_GetArchiveRule_600068, base: "/", url: url_GetArchiveRule_600069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchiveRule_600099 = ref object of OpenApiRestCall_599368
proc url_DeleteArchiveRule_600101(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteArchiveRule_600100(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified archive rule.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ruleName: JString (required)
  ##           : The name of the rule to delete.
  ##   analyzerName: JString (required)
  ##               : The name of the analyzer that associated with the archive rule to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ruleName` field"
  var valid_600102 = path.getOrDefault("ruleName")
  valid_600102 = validateParameter(valid_600102, JString, required = true,
                                 default = nil)
  if valid_600102 != nil:
    section.add "ruleName", valid_600102
  var valid_600103 = path.getOrDefault("analyzerName")
  valid_600103 = validateParameter(valid_600103, JString, required = true,
                                 default = nil)
  if valid_600103 != nil:
    section.add "analyzerName", valid_600103
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A client token.
  section = newJObject()
  var valid_600104 = query.getOrDefault("clientToken")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "clientToken", valid_600104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600105 = header.getOrDefault("X-Amz-Date")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Date", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Security-Token")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Security-Token", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Content-Sha256", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Algorithm")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Algorithm", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Signature")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Signature", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-SignedHeaders", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Credential")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Credential", valid_600111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600112: Call_DeleteArchiveRule_600099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified archive rule.
  ## 
  let valid = call_600112.validator(path, query, header, formData, body)
  let scheme = call_600112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600112.url(scheme.get, call_600112.host, call_600112.base,
                         call_600112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600112, url, valid)

proc call*(call_600113: Call_DeleteArchiveRule_600099; ruleName: string;
          analyzerName: string; clientToken: string = ""): Recallable =
  ## deleteArchiveRule
  ## Deletes the specified archive rule.
  ##   ruleName: string (required)
  ##           : The name of the rule to delete.
  ##   clientToken: string
  ##              : A client token.
  ##   analyzerName: string (required)
  ##               : The name of the analyzer that associated with the archive rule to delete.
  var path_600114 = newJObject()
  var query_600115 = newJObject()
  add(path_600114, "ruleName", newJString(ruleName))
  add(query_600115, "clientToken", newJString(clientToken))
  add(path_600114, "analyzerName", newJString(analyzerName))
  result = call_600113.call(path_600114, query_600115, nil, nil, nil)

var deleteArchiveRule* = Call_DeleteArchiveRule_600099(name: "deleteArchiveRule",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_DeleteArchiveRule_600100, base: "/",
    url: url_DeleteArchiveRule_600101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzedResource_600116 = ref object of OpenApiRestCall_599368
proc url_GetAnalyzedResource_600118(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAnalyzedResource_600117(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves information about a resource that was analyzed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the resource to retrieve information about.
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer to retrieve information from.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_600119 = query.getOrDefault("resourceArn")
  valid_600119 = validateParameter(valid_600119, JString, required = true,
                                 default = nil)
  if valid_600119 != nil:
    section.add "resourceArn", valid_600119
  var valid_600120 = query.getOrDefault("analyzerArn")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "analyzerArn", valid_600120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600121 = header.getOrDefault("X-Amz-Date")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Date", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Security-Token")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Security-Token", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Content-Sha256", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Algorithm")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Algorithm", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Signature")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Signature", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-SignedHeaders", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Credential")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Credential", valid_600127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_GetAnalyzedResource_600116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource that was analyzed.
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_GetAnalyzedResource_600116; resourceArn: string;
          analyzerArn: string): Recallable =
  ## getAnalyzedResource
  ## Retrieves information about a resource that was analyzed.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve information about.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer to retrieve information from.
  var query_600130 = newJObject()
  add(query_600130, "resourceArn", newJString(resourceArn))
  add(query_600130, "analyzerArn", newJString(analyzerArn))
  result = call_600129.call(nil, query_600130, nil, nil, nil)

var getAnalyzedResource* = Call_GetAnalyzedResource_600116(
    name: "getAnalyzedResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzed-resource#analyzerArn&resourceArn",
    validator: validate_GetAnalyzedResource_600117, base: "/",
    url: url_GetAnalyzedResource_600118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFinding_600131 = ref object of OpenApiRestCall_599368
proc url_GetFinding_600133(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFinding_600132(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600134 = path.getOrDefault("id")
  valid_600134 = validateParameter(valid_600134, JString, required = true,
                                 default = nil)
  if valid_600134 != nil:
    section.add "id", valid_600134
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
  ##              : The ARN of the analyzer that generated the finding.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analyzerArn` field"
  var valid_600135 = query.getOrDefault("analyzerArn")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "analyzerArn", valid_600135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600143: Call_GetFinding_600131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the specified finding.
  ## 
  let valid = call_600143.validator(path, query, header, formData, body)
  let scheme = call_600143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600143.url(scheme.get, call_600143.host, call_600143.base,
                         call_600143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600143, url, valid)

proc call*(call_600144: Call_GetFinding_600131; id: string; analyzerArn: string): Recallable =
  ## getFinding
  ## Retrieves information about the specified finding.
  ##   id: string (required)
  ##     : The ID of the finding to retrieve.
  ##   analyzerArn: string (required)
  ##              : The ARN of the analyzer that generated the finding.
  var path_600145 = newJObject()
  var query_600146 = newJObject()
  add(path_600145, "id", newJString(id))
  add(query_600146, "analyzerArn", newJString(analyzerArn))
  result = call_600144.call(path_600145, query_600146, nil, nil, nil)

var getFinding* = Call_GetFinding_600131(name: "getFinding",
                                      meth: HttpMethod.HttpGet,
                                      host: "access-analyzer.amazonaws.com",
                                      route: "/finding/{id}#analyzerArn",
                                      validator: validate_GetFinding_600132,
                                      base: "/", url: url_GetFinding_600133,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzedResources_600147 = ref object of OpenApiRestCall_599368
proc url_ListAnalyzedResources_600149(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAnalyzedResources_600148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600150 = query.getOrDefault("maxResults")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "maxResults", valid_600150
  var valid_600151 = query.getOrDefault("nextToken")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "nextToken", valid_600151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Content-Sha256", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Algorithm")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Algorithm", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Signature")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Signature", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-SignedHeaders", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Credential")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Credential", valid_600158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600160: Call_ListAnalyzedResources_600147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ## 
  let valid = call_600160.validator(path, query, header, formData, body)
  let scheme = call_600160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600160.url(scheme.get, call_600160.host, call_600160.base,
                         call_600160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600160, url, valid)

proc call*(call_600161: Call_ListAnalyzedResources_600147; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAnalyzedResources
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600162 = newJObject()
  var body_600163 = newJObject()
  add(query_600162, "maxResults", newJString(maxResults))
  add(query_600162, "nextToken", newJString(nextToken))
  if body != nil:
    body_600163 = body
  result = call_600161.call(nil, query_600162, nil, nil, body_600163)

var listAnalyzedResources* = Call_ListAnalyzedResources_600147(
    name: "listAnalyzedResources", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/analyzed-resource",
    validator: validate_ListAnalyzedResources_600148, base: "/",
    url: url_ListAnalyzedResources_600149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_600164 = ref object of OpenApiRestCall_599368
proc url_UpdateFindings_600166(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_600165(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600167 = header.getOrDefault("X-Amz-Date")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Date", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Security-Token")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Security-Token", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Content-Sha256", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Algorithm")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Algorithm", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Signature")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Signature", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-SignedHeaders", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Credential")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Credential", valid_600173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600175: Call_UpdateFindings_600164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified findings.
  ## 
  let valid = call_600175.validator(path, query, header, formData, body)
  let scheme = call_600175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600175.url(scheme.get, call_600175.host, call_600175.base,
                         call_600175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600175, url, valid)

proc call*(call_600176: Call_UpdateFindings_600164; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the status for the specified findings.
  ##   body: JObject (required)
  var body_600177 = newJObject()
  if body != nil:
    body_600177 = body
  result = call_600176.call(nil, nil, nil, nil, body_600177)

var updateFindings* = Call_UpdateFindings_600164(name: "updateFindings",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_UpdateFindings_600165, base: "/",
    url: url_UpdateFindings_600166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_600178 = ref object of OpenApiRestCall_599368
proc url_ListFindings_600180(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFindings_600179(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600181 = query.getOrDefault("maxResults")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "maxResults", valid_600181
  var valid_600182 = query.getOrDefault("nextToken")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "nextToken", valid_600182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600183 = header.getOrDefault("X-Amz-Date")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Date", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Security-Token")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Security-Token", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600191: Call_ListFindings_600178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of findings generated by the specified analyzer.
  ## 
  let valid = call_600191.validator(path, query, header, formData, body)
  let scheme = call_600191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600191.url(scheme.get, call_600191.host, call_600191.base,
                         call_600191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600191, url, valid)

proc call*(call_600192: Call_ListFindings_600178; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFindings
  ## Retrieves a list of findings generated by the specified analyzer.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600193 = newJObject()
  var body_600194 = newJObject()
  add(query_600193, "maxResults", newJString(maxResults))
  add(query_600193, "nextToken", newJString(nextToken))
  if body != nil:
    body_600194 = body
  result = call_600192.call(nil, query_600193, nil, nil, body_600194)

var listFindings* = Call_ListFindings_600178(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_ListFindings_600179, base: "/",
    url: url_ListFindings_600180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600209 = ref object of OpenApiRestCall_599368
proc url_TagResource_600211(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600212 = path.getOrDefault("resourceArn")
  valid_600212 = validateParameter(valid_600212, JString, required = true,
                                 default = nil)
  if valid_600212 != nil:
    section.add "resourceArn", valid_600212
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600213 = header.getOrDefault("X-Amz-Date")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Date", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Security-Token")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Security-Token", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600221: Call_TagResource_600209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a tag to the specified resource.
  ## 
  let valid = call_600221.validator(path, query, header, formData, body)
  let scheme = call_600221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600221.url(scheme.get, call_600221.host, call_600221.base,
                         call_600221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600221, url, valid)

proc call*(call_600222: Call_TagResource_600209; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds a tag to the specified resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to add the tag to.
  var path_600223 = newJObject()
  var body_600224 = newJObject()
  if body != nil:
    body_600224 = body
  add(path_600223, "resourceArn", newJString(resourceArn))
  result = call_600222.call(path_600223, nil, nil, nil, body_600224)

var tagResource* = Call_TagResource_600209(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "access-analyzer.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600210,
                                        base: "/", url: url_TagResource_600211,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600195 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600197(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600196(path: JsonNode; query: JsonNode;
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
  var valid_600198 = path.getOrDefault("resourceArn")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "resourceArn", valid_600198
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600199 = header.getOrDefault("X-Amz-Date")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Date", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Security-Token")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Security-Token", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Content-Sha256", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Algorithm")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Algorithm", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Signature")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Signature", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-SignedHeaders", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Credential")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Credential", valid_600205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600206: Call_ListTagsForResource_600195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags applied to the specified resource.
  ## 
  let valid = call_600206.validator(path, query, header, formData, body)
  let scheme = call_600206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600206.url(scheme.get, call_600206.host, call_600206.base,
                         call_600206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600206, url, valid)

proc call*(call_600207: Call_ListTagsForResource_600195; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of tags applied to the specified resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags from.
  var path_600208 = newJObject()
  add(path_600208, "resourceArn", newJString(resourceArn))
  result = call_600207.call(path_600208, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600195(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600196, base: "/",
    url: url_ListTagsForResource_600197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartResourceScan_600225 = ref object of OpenApiRestCall_599368
proc url_StartResourceScan_600227(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartResourceScan_600226(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600228 = header.getOrDefault("X-Amz-Date")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Date", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Security-Token")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Security-Token", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_StartResourceScan_600225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately starts a scan of the policies applied to the specified resource.
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_StartResourceScan_600225; body: JsonNode): Recallable =
  ## startResourceScan
  ## Immediately starts a scan of the policies applied to the specified resource.
  ##   body: JObject (required)
  var body_600238 = newJObject()
  if body != nil:
    body_600238 = body
  result = call_600237.call(nil, nil, nil, nil, body_600238)

var startResourceScan* = Call_StartResourceScan_600225(name: "startResourceScan",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/resource/scan", validator: validate_StartResourceScan_600226,
    base: "/", url: url_StartResourceScan_600227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600239 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600241(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600242 = path.getOrDefault("resourceArn")
  valid_600242 = validateParameter(valid_600242, JString, required = true,
                                 default = nil)
  if valid_600242 != nil:
    section.add "resourceArn", valid_600242
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600243 = query.getOrDefault("tagKeys")
  valid_600243 = validateParameter(valid_600243, JArray, required = true, default = nil)
  if valid_600243 != nil:
    section.add "tagKeys", valid_600243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600244 = header.getOrDefault("X-Amz-Date")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Date", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Security-Token")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Security-Token", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Content-Sha256", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Algorithm")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Algorithm", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Signature")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Signature", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-SignedHeaders", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Credential")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Credential", valid_600250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600251: Call_UntagResource_600239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_600251.validator(path, query, header, formData, body)
  let scheme = call_600251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600251.url(scheme.get, call_600251.host, call_600251.base,
                         call_600251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600251, url, valid)

proc call*(call_600252: Call_UntagResource_600239; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   tagKeys: JArray (required)
  ##          : The key for the tag to add.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource to remove the tag from.
  var path_600253 = newJObject()
  var query_600254 = newJObject()
  if tagKeys != nil:
    query_600254.add "tagKeys", tagKeys
  add(path_600253, "resourceArn", newJString(resourceArn))
  result = call_600252.call(path_600253, query_600254, nil, nil, nil)

var untagResource* = Call_UntagResource_600239(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600240,
    base: "/", url: url_UntagResource_600241, schemes: {Scheme.Https, Scheme.Http})
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
