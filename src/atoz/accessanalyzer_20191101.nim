
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "access-analyzer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "access-analyzer.ap-southeast-1.amazonaws.com", "us-west-2": "access-analyzer.us-west-2.amazonaws.com", "eu-west-2": "access-analyzer.eu-west-2.amazonaws.com", "ap-northeast-3": "access-analyzer.ap-northeast-3.amazonaws.com", "eu-central-1": "access-analyzer.eu-central-1.amazonaws.com", "us-east-2": "access-analyzer.us-east-2.amazonaws.com", "us-east-1": "access-analyzer.us-east-1.amazonaws.com", "cn-northwest-1": "access-analyzer.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "access-analyzer.ap-south-1.amazonaws.com", "eu-north-1": "access-analyzer.eu-north-1.amazonaws.com", "ap-northeast-2": "access-analyzer.ap-northeast-2.amazonaws.com", "us-west-1": "access-analyzer.us-west-1.amazonaws.com", "us-gov-east-1": "access-analyzer.us-gov-east-1.amazonaws.com", "eu-west-3": "access-analyzer.eu-west-3.amazonaws.com", "cn-north-1": "access-analyzer.cn-north-1.amazonaws.com.cn", "sa-east-1": "access-analyzer.sa-east-1.amazonaws.com", "eu-west-1": "access-analyzer.eu-west-1.amazonaws.com", "us-gov-west-1": "access-analyzer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "access-analyzer.ap-southeast-2.amazonaws.com", "ca-central-1": "access-analyzer.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateAnalyzer_402656484 = ref object of OpenApiRestCall_402656038
proc url_CreateAnalyzer_402656486(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAnalyzer_402656485(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an analyzer for your account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_CreateAnalyzer_402656484; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an analyzer for your account.
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_CreateAnalyzer_402656484; body: JsonNode): Recallable =
  ## createAnalyzer
  ## Creates an analyzer for your account.
  ##   body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var createAnalyzer* = Call_CreateAnalyzer_402656484(name: "createAnalyzer",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_CreateAnalyzer_402656485, base: "/",
    makeUrl: url_CreateAnalyzer_402656486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzers_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListAnalyzers_402656290(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAnalyzers_402656289(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of analyzers.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return in the response.
  ##   
                                                                                                           ## nextToken: JString
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## A 
                                                                                                           ## token 
                                                                                                           ## used 
                                                                                                           ## for 
                                                                                                           ## pagination 
                                                                                                           ## of 
                                                                                                           ## results 
                                                                                                           ## returned.
  ##   
                                                                                                                       ## type: JString
                                                                                                                       ##       
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## type 
                                                                                                                       ## of 
                                                                                                                       ## analyzer.
  section = newJObject()
  var valid_402656372 = query.getOrDefault("maxResults")
  valid_402656372 = validateParameter(valid_402656372, JInt, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "maxResults", valid_402656372
  var valid_402656373 = query.getOrDefault("nextToken")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "nextToken", valid_402656373
  var valid_402656386 = query.getOrDefault("type")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false,
                                      default = newJString("ACCOUNT"))
  if valid_402656386 != nil:
    section.add "type", valid_402656386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_ListAnalyzers_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of analyzers.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_ListAnalyzers_402656288; maxResults: int = 0;
           nextToken: string = ""; `type`: string = "ACCOUNT"): Recallable =
  ## listAnalyzers
  ## Retrieves a list of analyzers.
  ##   maxResults: int
                                   ##             : The maximum number of results to return in the response.
  ##   
                                                                                                            ## nextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## A 
                                                                                                            ## token 
                                                                                                            ## used 
                                                                                                            ## for 
                                                                                                            ## pagination 
                                                                                                            ## of 
                                                                                                            ## results 
                                                                                                            ## returned.
  ##   
                                                                                                                        ## type: string
                                                                                                                        ##       
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## type 
                                                                                                                        ## of 
                                                                                                                        ## analyzer.
  var query_402656457 = newJObject()
  add(query_402656457, "maxResults", newJInt(maxResults))
  add(query_402656457, "nextToken", newJString(nextToken))
  add(query_402656457, "type", newJString(`type`))
  result = call_402656456.call(nil, query_402656457, nil, nil, nil)

var listAnalyzers* = Call_ListAnalyzers_402656288(name: "listAnalyzers",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer", validator: validate_ListAnalyzers_402656289, base: "/",
    makeUrl: url_ListAnalyzers_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateArchiveRule_402656526 = ref object of OpenApiRestCall_402656038
proc url_CreateArchiveRule_402656528(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateArchiveRule_402656527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656529 = path.getOrDefault("analyzerName")
  valid_402656529 = validateParameter(valid_402656529, JString, required = true,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "analyzerName", valid_402656529
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656530 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Security-Token", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Signature")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Signature", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Algorithm", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Date")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Date", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Credential")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Credential", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656536
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

proc call*(call_402656538: Call_CreateArchiveRule_402656526;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
                                                                                         ## 
  let valid = call_402656538.validator(path, query, header, formData, body, _)
  let scheme = call_402656538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656538.makeUrl(scheme.get, call_402656538.host, call_402656538.base,
                                   call_402656538.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656538, uri, valid, _)

proc call*(call_402656539: Call_CreateArchiveRule_402656526;
           analyzerName: string; body: JsonNode): Recallable =
  ## createArchiveRule
  ## Creates an archive rule for the specified analyzer. Archive rules automatically archive findings that meet the criteria you define when you create the rule.
  ##   
                                                                                                                                                                 ## analyzerName: string (required)
                                                                                                                                                                 ##               
                                                                                                                                                                 ## : 
                                                                                                                                                                 ## The 
                                                                                                                                                                 ## name 
                                                                                                                                                                 ## of 
                                                                                                                                                                 ## the 
                                                                                                                                                                 ## created 
                                                                                                                                                                 ## analyzer.
  ##   
                                                                                                                                                                             ## body: JObject (required)
  var path_402656540 = newJObject()
  var body_402656541 = newJObject()
  add(path_402656540, "analyzerName", newJString(analyzerName))
  if body != nil:
    body_402656541 = body
  result = call_402656539.call(path_402656540, nil, nil, nil, body_402656541)

var createArchiveRule* = Call_CreateArchiveRule_402656526(
    name: "createArchiveRule", meth: HttpMethod.HttpPut,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_CreateArchiveRule_402656527, base: "/",
    makeUrl: url_CreateArchiveRule_402656528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArchiveRules_402656498 = ref object of OpenApiRestCall_402656038
proc url_ListArchiveRules_402656500(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListArchiveRules_402656499(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656512 = path.getOrDefault("analyzerName")
  valid_402656512 = validateParameter(valid_402656512, JString, required = true,
                                      default = nil)
  if valid_402656512 != nil:
    section.add "analyzerName", valid_402656512
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return in the request.
  ##   
                                                                                                          ## nextToken: JString
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## A 
                                                                                                          ## token 
                                                                                                          ## used 
                                                                                                          ## for 
                                                                                                          ## pagination 
                                                                                                          ## of 
                                                                                                          ## results 
                                                                                                          ## returned.
  section = newJObject()
  var valid_402656513 = query.getOrDefault("maxResults")
  valid_402656513 = validateParameter(valid_402656513, JInt, required = false,
                                      default = nil)
  if valid_402656513 != nil:
    section.add "maxResults", valid_402656513
  var valid_402656514 = query.getOrDefault("nextToken")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "nextToken", valid_402656514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656522: Call_ListArchiveRules_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of archive rules created for the specified analyzer.
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_ListArchiveRules_402656498;
           analyzerName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listArchiveRules
  ## Retrieves a list of archive rules created for the specified analyzer.
  ##   
                                                                          ## analyzerName: string (required)
                                                                          ##               
                                                                          ## : 
                                                                          ## The 
                                                                          ## name 
                                                                          ## of 
                                                                          ## the 
                                                                          ## analyzer 
                                                                          ## to 
                                                                          ## retrieve 
                                                                          ## rules 
                                                                          ## from.
  ##   
                                                                                  ## maxResults: int
                                                                                  ##             
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## maximum 
                                                                                  ## number 
                                                                                  ## of 
                                                                                  ## results 
                                                                                  ## to 
                                                                                  ## return 
                                                                                  ## in 
                                                                                  ## the 
                                                                                  ## request.
  ##   
                                                                                             ## nextToken: string
                                                                                             ##            
                                                                                             ## : 
                                                                                             ## A 
                                                                                             ## token 
                                                                                             ## used 
                                                                                             ## for 
                                                                                             ## pagination 
                                                                                             ## of 
                                                                                             ## results 
                                                                                             ## returned.
  var path_402656524 = newJObject()
  var query_402656525 = newJObject()
  add(path_402656524, "analyzerName", newJString(analyzerName))
  add(query_402656525, "maxResults", newJInt(maxResults))
  add(query_402656525, "nextToken", newJString(nextToken))
  result = call_402656523.call(path_402656524, query_402656525, nil, nil, nil)

var listArchiveRules* = Call_ListArchiveRules_402656498(
    name: "listArchiveRules", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule",
    validator: validate_ListArchiveRules_402656499, base: "/",
    makeUrl: url_ListArchiveRules_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzer_402656542 = ref object of OpenApiRestCall_402656038
proc url_GetAnalyzer_402656544(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAnalyzer_402656543(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656545 = path.getOrDefault("analyzerName")
  valid_402656545 = validateParameter(valid_402656545, JString, required = true,
                                      default = nil)
  if valid_402656545 != nil:
    section.add "analyzerName", valid_402656545
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Security-Token", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Signature")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Signature", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Algorithm", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Date")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Date", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Credential")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Credential", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656553: Call_GetAnalyzer_402656542; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the specified analyzer.
                                                                                         ## 
  let valid = call_402656553.validator(path, query, header, formData, body, _)
  let scheme = call_402656553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656553.makeUrl(scheme.get, call_402656553.host, call_402656553.base,
                                   call_402656553.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656553, uri, valid, _)

proc call*(call_402656554: Call_GetAnalyzer_402656542; analyzerName: string): Recallable =
  ## getAnalyzer
  ## Retrieves information about the specified analyzer.
  ##   analyzerName: string (required)
                                                        ##               : The name of the analyzer retrieved.
  var path_402656555 = newJObject()
  add(path_402656555, "analyzerName", newJString(analyzerName))
  result = call_402656554.call(path_402656555, nil, nil, nil, nil)

var getAnalyzer* = Call_GetAnalyzer_402656542(name: "getAnalyzer",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_GetAnalyzer_402656543,
    base: "/", makeUrl: url_GetAnalyzer_402656544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAnalyzer_402656556 = ref object of OpenApiRestCall_402656038
proc url_DeleteAnalyzer_402656558(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAnalyzer_402656557(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656559 = path.getOrDefault("analyzerName")
  valid_402656559 = validateParameter(valid_402656559, JString, required = true,
                                      default = nil)
  if valid_402656559 != nil:
    section.add "analyzerName", valid_402656559
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
                                  ##              : A client token.
  section = newJObject()
  var valid_402656560 = query.getOrDefault("clientToken")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "clientToken", valid_402656560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656561 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Security-Token", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Signature")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Signature", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Algorithm", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Date")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Date", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Credential")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Credential", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656568: Call_DeleteAnalyzer_402656556; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
                                                                                         ## 
  let valid = call_402656568.validator(path, query, header, formData, body, _)
  let scheme = call_402656568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656568.makeUrl(scheme.get, call_402656568.host, call_402656568.base,
                                   call_402656568.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656568, uri, valid, _)

proc call*(call_402656569: Call_DeleteAnalyzer_402656556; analyzerName: string;
           clientToken: string = ""): Recallable =
  ## deleteAnalyzer
  ## Deletes the specified analyzer. When you delete an analyzer, Access Analyzer is disabled for the account in the current or specific Region. All findings that were generated by the analyzer are deleted. You cannot undo this action.
  ##   
                                                                                                                                                                                                                                           ## analyzerName: string (required)
                                                                                                                                                                                                                                           ##               
                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                           ## analyzer 
                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                           ## delete.
  ##   
                                                                                                                                                                                                                                                     ## clientToken: string
                                                                                                                                                                                                                                                     ##              
                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                     ## client 
                                                                                                                                                                                                                                                     ## token.
  var path_402656570 = newJObject()
  var query_402656571 = newJObject()
  add(path_402656570, "analyzerName", newJString(analyzerName))
  add(query_402656571, "clientToken", newJString(clientToken))
  result = call_402656569.call(path_402656570, query_402656571, nil, nil, nil)

var deleteAnalyzer* = Call_DeleteAnalyzer_402656556(name: "deleteAnalyzer",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}", validator: validate_DeleteAnalyzer_402656557,
    base: "/", makeUrl: url_DeleteAnalyzer_402656558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateArchiveRule_402656587 = ref object of OpenApiRestCall_402656038
proc url_UpdateArchiveRule_402656589(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateArchiveRule_402656588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the criteria and values for the specified archive rule.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
                                 ##               : The name of the analyzer to update the archive rules for.
  ##   
                                                                                                             ## ruleName: JString (required)
                                                                                                             ##           
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## name 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## rule 
                                                                                                             ## to 
                                                                                                             ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `analyzerName` field"
  var valid_402656590 = path.getOrDefault("analyzerName")
  valid_402656590 = validateParameter(valid_402656590, JString, required = true,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "analyzerName", valid_402656590
  var valid_402656591 = path.getOrDefault("ruleName")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "ruleName", valid_402656591
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Security-Token", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Signature")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Signature", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Algorithm", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Date")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Date", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Credential")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Credential", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656598
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

proc call*(call_402656600: Call_UpdateArchiveRule_402656587;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the criteria and values for the specified archive rule.
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_UpdateArchiveRule_402656587;
           analyzerName: string; body: JsonNode; ruleName: string): Recallable =
  ## updateArchiveRule
  ## Updates the criteria and values for the specified archive rule.
  ##   
                                                                    ## analyzerName: string (required)
                                                                    ##               
                                                                    ## : 
                                                                    ## The name of the 
                                                                    ## analyzer 
                                                                    ## to 
                                                                    ## update the 
                                                                    ## archive 
                                                                    ## rules 
                                                                    ## for.
  ##   body: 
                                                                           ## JObject (required)
  ##   
                                                                                                ## ruleName: string (required)
                                                                                                ##           
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## name 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## rule 
                                                                                                ## to 
                                                                                                ## update.
  var path_402656602 = newJObject()
  var body_402656603 = newJObject()
  add(path_402656602, "analyzerName", newJString(analyzerName))
  if body != nil:
    body_402656603 = body
  add(path_402656602, "ruleName", newJString(ruleName))
  result = call_402656601.call(path_402656602, nil, nil, nil, body_402656603)

var updateArchiveRule* = Call_UpdateArchiveRule_402656587(
    name: "updateArchiveRule", meth: HttpMethod.HttpPut,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_UpdateArchiveRule_402656588, base: "/",
    makeUrl: url_UpdateArchiveRule_402656589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArchiveRule_402656572 = ref object of OpenApiRestCall_402656038
proc url_GetArchiveRule_402656574(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetArchiveRule_402656573(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about an archive rule.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
                                 ##               : The name of the analyzer to retrieve rules from.
  ##   
                                                                                                    ## ruleName: JString (required)
                                                                                                    ##           
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## name 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## rule 
                                                                                                    ## to 
                                                                                                    ## retrieve.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `analyzerName` field"
  var valid_402656575 = path.getOrDefault("analyzerName")
  valid_402656575 = validateParameter(valid_402656575, JString, required = true,
                                      default = nil)
  if valid_402656575 != nil:
    section.add "analyzerName", valid_402656575
  var valid_402656576 = path.getOrDefault("ruleName")
  valid_402656576 = validateParameter(valid_402656576, JString, required = true,
                                      default = nil)
  if valid_402656576 != nil:
    section.add "ruleName", valid_402656576
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656584: Call_GetArchiveRule_402656572; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about an archive rule.
                                                                                         ## 
  let valid = call_402656584.validator(path, query, header, formData, body, _)
  let scheme = call_402656584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656584.makeUrl(scheme.get, call_402656584.host, call_402656584.base,
                                   call_402656584.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656584, uri, valid, _)

proc call*(call_402656585: Call_GetArchiveRule_402656572; analyzerName: string;
           ruleName: string): Recallable =
  ## getArchiveRule
  ## Retrieves information about an archive rule.
  ##   analyzerName: string (required)
                                                 ##               : The name of the analyzer to retrieve rules from.
  ##   
                                                                                                                    ## ruleName: string (required)
                                                                                                                    ##           
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## name 
                                                                                                                    ## of 
                                                                                                                    ## the 
                                                                                                                    ## rule 
                                                                                                                    ## to 
                                                                                                                    ## retrieve.
  var path_402656586 = newJObject()
  add(path_402656586, "analyzerName", newJString(analyzerName))
  add(path_402656586, "ruleName", newJString(ruleName))
  result = call_402656585.call(path_402656586, nil, nil, nil, nil)

var getArchiveRule* = Call_GetArchiveRule_402656572(name: "getArchiveRule",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_GetArchiveRule_402656573, base: "/",
    makeUrl: url_GetArchiveRule_402656574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchiveRule_402656604 = ref object of OpenApiRestCall_402656038
proc url_DeleteArchiveRule_402656606(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteArchiveRule_402656605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified archive rule.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   analyzerName: JString (required)
                                 ##               : The name of the analyzer that associated with the archive rule to delete.
  ##   
                                                                                                                             ## ruleName: JString (required)
                                                                                                                             ##           
                                                                                                                             ## : 
                                                                                                                             ## The 
                                                                                                                             ## name 
                                                                                                                             ## of 
                                                                                                                             ## the 
                                                                                                                             ## rule 
                                                                                                                             ## to 
                                                                                                                             ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `analyzerName` field"
  var valid_402656607 = path.getOrDefault("analyzerName")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "analyzerName", valid_402656607
  var valid_402656608 = path.getOrDefault("ruleName")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "ruleName", valid_402656608
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
                                  ##              : A client token.
  section = newJObject()
  var valid_402656609 = query.getOrDefault("clientToken")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "clientToken", valid_402656609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656610 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Security-Token", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Signature")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Signature", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Algorithm", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Date")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Date", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Credential")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Credential", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656617: Call_DeleteArchiveRule_402656604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified archive rule.
                                                                                         ## 
  let valid = call_402656617.validator(path, query, header, formData, body, _)
  let scheme = call_402656617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656617.makeUrl(scheme.get, call_402656617.host, call_402656617.base,
                                   call_402656617.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656617, uri, valid, _)

proc call*(call_402656618: Call_DeleteArchiveRule_402656604;
           analyzerName: string; ruleName: string; clientToken: string = ""): Recallable =
  ## deleteArchiveRule
  ## Deletes the specified archive rule.
  ##   analyzerName: string (required)
                                        ##               : The name of the analyzer that associated with the archive rule to delete.
  ##   
                                                                                                                                    ## clientToken: string
                                                                                                                                    ##              
                                                                                                                                    ## : 
                                                                                                                                    ## A 
                                                                                                                                    ## client 
                                                                                                                                    ## token.
  ##   
                                                                                                                                             ## ruleName: string (required)
                                                                                                                                             ##           
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## name 
                                                                                                                                             ## of 
                                                                                                                                             ## the 
                                                                                                                                             ## rule 
                                                                                                                                             ## to 
                                                                                                                                             ## delete.
  var path_402656619 = newJObject()
  var query_402656620 = newJObject()
  add(path_402656619, "analyzerName", newJString(analyzerName))
  add(query_402656620, "clientToken", newJString(clientToken))
  add(path_402656619, "ruleName", newJString(ruleName))
  result = call_402656618.call(path_402656619, query_402656620, nil, nil, nil)

var deleteArchiveRule* = Call_DeleteArchiveRule_402656604(
    name: "deleteArchiveRule", meth: HttpMethod.HttpDelete,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzer/{analyzerName}/archive-rule/{ruleName}",
    validator: validate_DeleteArchiveRule_402656605, base: "/",
    makeUrl: url_DeleteArchiveRule_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAnalyzedResource_402656621 = ref object of OpenApiRestCall_402656038
proc url_GetAnalyzedResource_402656623(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAnalyzedResource_402656622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a resource that was analyzed.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
                                  ##              : The ARN of the analyzer to retrieve information from.
  ##   
                                                                                                         ## resourceArn: JString (required)
                                                                                                         ##              
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## ARN 
                                                                                                         ## of 
                                                                                                         ## the 
                                                                                                         ## resource 
                                                                                                         ## to 
                                                                                                         ## retrieve 
                                                                                                         ## information 
                                                                                                         ## about.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `analyzerArn` field"
  var valid_402656624 = query.getOrDefault("analyzerArn")
  valid_402656624 = validateParameter(valid_402656624, JString, required = true,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "analyzerArn", valid_402656624
  var valid_402656625 = query.getOrDefault("resourceArn")
  valid_402656625 = validateParameter(valid_402656625, JString, required = true,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "resourceArn", valid_402656625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656633: Call_GetAnalyzedResource_402656621;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a resource that was analyzed.
                                                                                         ## 
  let valid = call_402656633.validator(path, query, header, formData, body, _)
  let scheme = call_402656633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656633.makeUrl(scheme.get, call_402656633.host, call_402656633.base,
                                   call_402656633.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656633, uri, valid, _)

proc call*(call_402656634: Call_GetAnalyzedResource_402656621;
           analyzerArn: string; resourceArn: string): Recallable =
  ## getAnalyzedResource
  ## Retrieves information about a resource that was analyzed.
  ##   analyzerArn: string (required)
                                                              ##              : The ARN of the analyzer to retrieve information from.
  ##   
                                                                                                                                     ## resourceArn: string (required)
                                                                                                                                     ##              
                                                                                                                                     ## : 
                                                                                                                                     ## The 
                                                                                                                                     ## ARN 
                                                                                                                                     ## of 
                                                                                                                                     ## the 
                                                                                                                                     ## resource 
                                                                                                                                     ## to 
                                                                                                                                     ## retrieve 
                                                                                                                                     ## information 
                                                                                                                                     ## about.
  var query_402656635 = newJObject()
  add(query_402656635, "analyzerArn", newJString(analyzerArn))
  add(query_402656635, "resourceArn", newJString(resourceArn))
  result = call_402656634.call(nil, query_402656635, nil, nil, nil)

var getAnalyzedResource* = Call_GetAnalyzedResource_402656621(
    name: "getAnalyzedResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com",
    route: "/analyzed-resource#analyzerArn&resourceArn",
    validator: validate_GetAnalyzedResource_402656622, base: "/",
    makeUrl: url_GetAnalyzedResource_402656623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFinding_402656636 = ref object of OpenApiRestCall_402656038
proc url_GetFinding_402656638(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFinding_402656637(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the specified finding.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the finding to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656639 = path.getOrDefault("id")
  valid_402656639 = validateParameter(valid_402656639, JString, required = true,
                                      default = nil)
  if valid_402656639 != nil:
    section.add "id", valid_402656639
  result.add "path", section
  ## parameters in `query` object:
  ##   analyzerArn: JString (required)
                                  ##              : The ARN of the analyzer that generated the finding.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `analyzerArn` field"
  var valid_402656640 = query.getOrDefault("analyzerArn")
  valid_402656640 = validateParameter(valid_402656640, JString, required = true,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "analyzerArn", valid_402656640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656641 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Security-Token", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Signature")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Signature", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Algorithm", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Date")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Date", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Credential")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Credential", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656648: Call_GetFinding_402656636; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the specified finding.
                                                                                         ## 
  let valid = call_402656648.validator(path, query, header, formData, body, _)
  let scheme = call_402656648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656648.makeUrl(scheme.get, call_402656648.host, call_402656648.base,
                                   call_402656648.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656648, uri, valid, _)

proc call*(call_402656649: Call_GetFinding_402656636; id: string;
           analyzerArn: string): Recallable =
  ## getFinding
  ## Retrieves information about the specified finding.
  ##   id: string (required)
                                                       ##     : The ID of the finding to retrieve.
  ##   
                                                                                                  ## analyzerArn: string (required)
                                                                                                  ##              
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## ARN 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## analyzer 
                                                                                                  ## that 
                                                                                                  ## generated 
                                                                                                  ## the 
                                                                                                  ## finding.
  var path_402656650 = newJObject()
  var query_402656651 = newJObject()
  add(path_402656650, "id", newJString(id))
  add(query_402656651, "analyzerArn", newJString(analyzerArn))
  result = call_402656649.call(path_402656650, query_402656651, nil, nil, nil)

var getFinding* = Call_GetFinding_402656636(name: "getFinding",
    meth: HttpMethod.HttpGet, host: "access-analyzer.amazonaws.com",
    route: "/finding/{id}#analyzerArn", validator: validate_GetFinding_402656637,
    base: "/", makeUrl: url_GetFinding_402656638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAnalyzedResources_402656652 = ref object of OpenApiRestCall_402656038
proc url_ListAnalyzedResources_402656654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAnalyzedResources_402656653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656655 = query.getOrDefault("maxResults")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "maxResults", valid_402656655
  var valid_402656656 = query.getOrDefault("nextToken")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "nextToken", valid_402656656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Security-Token", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Signature")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Signature", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Algorithm", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Date")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Date", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Credential")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Credential", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656663
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

proc call*(call_402656665: Call_ListAnalyzedResources_402656652;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
                                                                                         ## 
  let valid = call_402656665.validator(path, query, header, formData, body, _)
  let scheme = call_402656665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656665.makeUrl(scheme.get, call_402656665.host, call_402656665.base,
                                   call_402656665.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656665, uri, valid, _)

proc call*(call_402656666: Call_ListAnalyzedResources_402656652; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAnalyzedResources
  ## Retrieves a list of resources of the specified type that have been analyzed by the specified analyzer..
  ##   
                                                                                                            ## maxResults: string
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## limit
  ##   
                                                                                                                    ## nextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  ##   
                                                                                                                            ## body: JObject (required)
  var query_402656667 = newJObject()
  var body_402656668 = newJObject()
  add(query_402656667, "maxResults", newJString(maxResults))
  add(query_402656667, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656668 = body
  result = call_402656666.call(nil, query_402656667, nil, nil, body_402656668)

var listAnalyzedResources* = Call_ListAnalyzedResources_402656652(
    name: "listAnalyzedResources", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/analyzed-resource",
    validator: validate_ListAnalyzedResources_402656653, base: "/",
    makeUrl: url_ListAnalyzedResources_402656654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_402656669 = ref object of OpenApiRestCall_402656038
proc url_UpdateFindings_402656671(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_402656670(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status for the specified findings.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Security-Token", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Signature")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Signature", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Algorithm", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Date")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Date", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Credential")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Credential", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656678
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

proc call*(call_402656680: Call_UpdateFindings_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status for the specified findings.
                                                                                         ## 
  let valid = call_402656680.validator(path, query, header, formData, body, _)
  let scheme = call_402656680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656680.makeUrl(scheme.get, call_402656680.host, call_402656680.base,
                                   call_402656680.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656680, uri, valid, _)

proc call*(call_402656681: Call_UpdateFindings_402656669; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the status for the specified findings.
  ##   body: JObject (required)
  var body_402656682 = newJObject()
  if body != nil:
    body_402656682 = body
  result = call_402656681.call(nil, nil, nil, nil, body_402656682)

var updateFindings* = Call_UpdateFindings_402656669(name: "updateFindings",
    meth: HttpMethod.HttpPut, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_UpdateFindings_402656670, base: "/",
    makeUrl: url_UpdateFindings_402656671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_402656683 = ref object of OpenApiRestCall_402656038
proc url_ListFindings_402656685(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFindings_402656684(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656686 = query.getOrDefault("maxResults")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "maxResults", valid_402656686
  var valid_402656687 = query.getOrDefault("nextToken")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "nextToken", valid_402656687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
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

proc call*(call_402656696: Call_ListFindings_402656683; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of findings generated by the specified analyzer.
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_ListFindings_402656683; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFindings
  ## Retrieves a list of findings generated by the specified analyzer.
  ##   
                                                                      ## maxResults: string
                                                                      ##             
                                                                      ## : 
                                                                      ## Pagination limit
  ##   
                                                                                         ## nextToken: string
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Pagination 
                                                                                         ## token
  ##   
                                                                                                 ## body: JObject (required)
  var query_402656698 = newJObject()
  var body_402656699 = newJObject()
  add(query_402656698, "maxResults", newJString(maxResults))
  add(query_402656698, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656699 = body
  result = call_402656697.call(nil, query_402656698, nil, nil, body_402656699)

var listFindings* = Call_ListFindings_402656683(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/finding", validator: validate_ListFindings_402656684, base: "/",
    makeUrl: url_ListFindings_402656685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656714 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656716(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656715(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656717 = path.getOrDefault("resourceArn")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "resourceArn", valid_402656717
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
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

proc call*(call_402656726: Call_TagResource_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a tag to the specified resource.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_TagResource_402656714; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds a tag to the specified resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The ARN of the resource to add the tag to.
  var path_402656728 = newJObject()
  var body_402656729 = newJObject()
  if body != nil:
    body_402656729 = body
  add(path_402656728, "resourceArn", newJString(resourceArn))
  result = call_402656727.call(path_402656728, nil, nil, nil, body_402656729)

var tagResource* = Call_TagResource_402656714(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656715,
    base: "/", makeUrl: url_TagResource_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656700 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656702(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656703 = path.getOrDefault("resourceArn")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true,
                                      default = nil)
  if valid_402656703 != nil:
    section.add "resourceArn", valid_402656703
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656704 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Security-Token", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Signature")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Signature", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Algorithm", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Date")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Date", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Credential")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Credential", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_ListTagsForResource_402656700;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of tags applied to the specified resource.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_ListTagsForResource_402656700;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of tags applied to the specified resource.
  ##   resourceArn: string (required)
                                                                ##              : The ARN of the resource to retrieve tags from.
  var path_402656713 = newJObject()
  add(path_402656713, "resourceArn", newJString(resourceArn))
  result = call_402656712.call(path_402656713, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656700(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "access-analyzer.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656701, base: "/",
    makeUrl: url_ListTagsForResource_402656702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartResourceScan_402656730 = ref object of OpenApiRestCall_402656038
proc url_StartResourceScan_402656732(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartResourceScan_402656731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Immediately starts a scan of the policies applied to the specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_StartResourceScan_402656730;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Immediately starts a scan of the policies applied to the specified resource.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_StartResourceScan_402656730; body: JsonNode): Recallable =
  ## startResourceScan
  ## Immediately starts a scan of the policies applied to the specified resource.
  ##   
                                                                                 ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var startResourceScan* = Call_StartResourceScan_402656730(
    name: "startResourceScan", meth: HttpMethod.HttpPost,
    host: "access-analyzer.amazonaws.com", route: "/resource/scan",
    validator: validate_StartResourceScan_402656731, base: "/",
    makeUrl: url_StartResourceScan_402656732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656744 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656746(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656745(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656747 = path.getOrDefault("resourceArn")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true,
                                      default = nil)
  if valid_402656747 != nil:
    section.add "resourceArn", valid_402656747
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The key for the tag to add.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656748 = query.getOrDefault("tagKeys")
  valid_402656748 = validateParameter(valid_402656748, JArray, required = true,
                                      default = nil)
  if valid_402656748 != nil:
    section.add "tagKeys", valid_402656748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656749 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Security-Token", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Signature")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Signature", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Algorithm", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Date")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Date", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Credential")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Credential", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_UntagResource_402656744; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from the specified resource.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_UntagResource_402656744; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   tagKeys: JArray (required)
                                               ##          : The key for the tag to add.
  ##   
                                                                                        ## resourceArn: string (required)
                                                                                        ##              
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ARN 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## resource 
                                                                                        ## to 
                                                                                        ## remove 
                                                                                        ## the 
                                                                                        ## tag 
                                                                                        ## from.
  var path_402656758 = newJObject()
  var query_402656759 = newJObject()
  if tagKeys != nil:
    query_402656759.add "tagKeys", tagKeys
  add(path_402656758, "resourceArn", newJString(resourceArn))
  result = call_402656757.call(path_402656758, query_402656759, nil, nil, nil)

var untagResource* = Call_UntagResource_402656744(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "access-analyzer.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656745,
    base: "/", makeUrl: url_UntagResource_402656746,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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