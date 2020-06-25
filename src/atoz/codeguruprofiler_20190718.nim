
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CodeGuru Profiler
## version: 2019-07-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Example service documentation.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codeguru-profiler/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codeguru-profiler.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codeguru-profiler.ap-southeast-1.amazonaws.com", "us-west-2": "codeguru-profiler.us-west-2.amazonaws.com", "eu-west-2": "codeguru-profiler.eu-west-2.amazonaws.com", "ap-northeast-3": "codeguru-profiler.ap-northeast-3.amazonaws.com", "eu-central-1": "codeguru-profiler.eu-central-1.amazonaws.com", "us-east-2": "codeguru-profiler.us-east-2.amazonaws.com", "us-east-1": "codeguru-profiler.us-east-1.amazonaws.com", "cn-northwest-1": "codeguru-profiler.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codeguru-profiler.ap-south-1.amazonaws.com", "eu-north-1": "codeguru-profiler.eu-north-1.amazonaws.com", "ap-northeast-2": "codeguru-profiler.ap-northeast-2.amazonaws.com", "us-west-1": "codeguru-profiler.us-west-1.amazonaws.com", "us-gov-east-1": "codeguru-profiler.us-gov-east-1.amazonaws.com", "eu-west-3": "codeguru-profiler.eu-west-3.amazonaws.com", "cn-north-1": "codeguru-profiler.cn-north-1.amazonaws.com.cn", "sa-east-1": "codeguru-profiler.sa-east-1.amazonaws.com", "eu-west-1": "codeguru-profiler.eu-west-1.amazonaws.com", "us-gov-west-1": "codeguru-profiler.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codeguru-profiler.ap-southeast-2.amazonaws.com", "ca-central-1": "codeguru-profiler.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codeguru-profiler.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codeguru-profiler.ap-southeast-1.amazonaws.com",
      "us-west-2": "codeguru-profiler.us-west-2.amazonaws.com",
      "eu-west-2": "codeguru-profiler.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codeguru-profiler.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codeguru-profiler.eu-central-1.amazonaws.com",
      "us-east-2": "codeguru-profiler.us-east-2.amazonaws.com",
      "us-east-1": "codeguru-profiler.us-east-1.amazonaws.com",
      "cn-northwest-1": "codeguru-profiler.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codeguru-profiler.ap-south-1.amazonaws.com",
      "eu-north-1": "codeguru-profiler.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codeguru-profiler.ap-northeast-2.amazonaws.com",
      "us-west-1": "codeguru-profiler.us-west-1.amazonaws.com",
      "us-gov-east-1": "codeguru-profiler.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codeguru-profiler.eu-west-3.amazonaws.com",
      "cn-north-1": "codeguru-profiler.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codeguru-profiler.sa-east-1.amazonaws.com",
      "eu-west-1": "codeguru-profiler.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codeguru-profiler.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codeguru-profiler.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codeguru-profiler.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codeguruprofiler"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_ConfigureAgent_21625779 = ref object of OpenApiRestCall_21625435
proc url_ConfigureAgent_21625781(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName"),
               (kind: ConstantSegment, value: "/configureAgent")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ConfigureAgent_21625780(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21625895 = path.getOrDefault("profilingGroupName")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "profilingGroupName", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
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

proc call*(call_21625928: Call_ConfigureAgent_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_21625928.validator(path, query, header, formData, body, _)
  let scheme = call_21625928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625928.makeUrl(scheme.get, call_21625928.host, call_21625928.base,
                               call_21625928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625928, uri, valid, _)

proc call*(call_21625991: Call_ConfigureAgent_21625779; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_21625993 = newJObject()
  var body_21625995 = newJObject()
  add(path_21625993, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_21625995 = body
  result = call_21625991.call(path_21625993, nil, nil, nil, body_21625995)

var configureAgent* = Call_ConfigureAgent_21625779(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_21625780, base: "/",
    makeUrl: url_ConfigureAgent_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_21626032 = ref object of OpenApiRestCall_21625435
proc url_CreateProfilingGroup_21626034(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProfilingGroup_21626033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a profiling group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString (required)
  ##              : Client token for the request.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `clientToken` field"
  var valid_21626035 = query.getOrDefault("clientToken")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "clientToken", valid_21626035
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
  var valid_21626036 = header.getOrDefault("X-Amz-Date")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Date", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Security-Token", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Algorithm", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Signature")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Signature", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Credential")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Credential", valid_21626042
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

proc call*(call_21626044: Call_CreateProfilingGroup_21626032; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

proc call*(call_21626045: Call_CreateProfilingGroup_21626032; clientToken: string;
          body: JsonNode): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   clientToken: string (required)
  ##              : Client token for the request.
  ##   body: JObject (required)
  var query_21626046 = newJObject()
  var body_21626047 = newJObject()
  add(query_21626046, "clientToken", newJString(clientToken))
  if body != nil:
    body_21626047 = body
  result = call_21626045.call(nil, query_21626046, nil, nil, body_21626047)

var createProfilingGroup* = Call_CreateProfilingGroup_21626032(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_21626033, base: "/",
    makeUrl: url_CreateProfilingGroup_21626034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_21626062 = ref object of OpenApiRestCall_21625435
proc url_UpdateProfilingGroup_21626064(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateProfilingGroup_21626063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a profiling group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626065 = path.getOrDefault("profilingGroupName")
  valid_21626065 = validateParameter(valid_21626065, JString, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "profilingGroupName", valid_21626065
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
  var valid_21626066 = header.getOrDefault("X-Amz-Date")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Date", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Security-Token", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Algorithm", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Signature")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Signature", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Credential")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Credential", valid_21626072
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

proc call*(call_21626074: Call_UpdateProfilingGroup_21626062; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_UpdateProfilingGroup_21626062;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_21626076 = newJObject()
  var body_21626077 = newJObject()
  add(path_21626076, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_21626077 = body
  result = call_21626075.call(path_21626076, nil, nil, nil, body_21626077)

var updateProfilingGroup* = Call_UpdateProfilingGroup_21626062(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_21626063, base: "/",
    makeUrl: url_UpdateProfilingGroup_21626064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_21626048 = ref object of OpenApiRestCall_21625435
proc url_DescribeProfilingGroup_21626050(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProfilingGroup_21626049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describe a profiling group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626051 = path.getOrDefault("profilingGroupName")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "profilingGroupName", valid_21626051
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
  var valid_21626052 = header.getOrDefault("X-Amz-Date")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Date", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Security-Token", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Algorithm", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Signature")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Signature", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Credential")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Credential", valid_21626058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626059: Call_DescribeProfilingGroup_21626048;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_DescribeProfilingGroup_21626048;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_21626061 = newJObject()
  add(path_21626061, "profilingGroupName", newJString(profilingGroupName))
  result = call_21626060.call(path_21626061, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_21626048(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_21626049, base: "/",
    makeUrl: url_DescribeProfilingGroup_21626050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_21626078 = ref object of OpenApiRestCall_21625435
proc url_DeleteProfilingGroup_21626080(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProfilingGroup_21626079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a profiling group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626081 = path.getOrDefault("profilingGroupName")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "profilingGroupName", valid_21626081
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
  var valid_21626082 = header.getOrDefault("X-Amz-Date")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Date", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Security-Token", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Algorithm", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Signature")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Signature", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Credential")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Credential", valid_21626088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626089: Call_DeleteProfilingGroup_21626078; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_21626089.validator(path, query, header, formData, body, _)
  let scheme = call_21626089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626089.makeUrl(scheme.get, call_21626089.host, call_21626089.base,
                               call_21626089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626089, uri, valid, _)

proc call*(call_21626090: Call_DeleteProfilingGroup_21626078;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_21626091 = newJObject()
  add(path_21626091, "profilingGroupName", newJString(profilingGroupName))
  result = call_21626090.call(path_21626091, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_21626078(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_21626079, base: "/",
    makeUrl: url_DeleteProfilingGroup_21626080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_21626092 = ref object of OpenApiRestCall_21625435
proc url_GetProfile_21626094(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName"),
               (kind: ConstantSegment, value: "/profile")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProfile_21626093(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626095 = path.getOrDefault("profilingGroupName")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "profilingGroupName", valid_21626095
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The end time of the profile to get. Either period or endTime must be specified. Must be greater than start and the overall time range to be in the past and not larger than a week.
  ##   maxDepth: JInt
  ##           : Limit the max depth of the profile.
  ##   period: JString
  ##         : Periods of time represented using <a href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 8601 format</a>.
  ##   startTime: JString
  ##            : The start time of the profile to get.
  section = newJObject()
  var valid_21626096 = query.getOrDefault("endTime")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "endTime", valid_21626096
  var valid_21626097 = query.getOrDefault("maxDepth")
  valid_21626097 = validateParameter(valid_21626097, JInt, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "maxDepth", valid_21626097
  var valid_21626098 = query.getOrDefault("period")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "period", valid_21626098
  var valid_21626099 = query.getOrDefault("startTime")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "startTime", valid_21626099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   Accept: JString
  ##         : The format of the profile to return. Supports application/json or application/x-amzn-ion. Defaults to application/x-amzn-ion.
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("Accept")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "Accept", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Credential")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Credential", valid_21626107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626108: Call_GetProfile_21626092; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_21626108.validator(path, query, header, formData, body, _)
  let scheme = call_21626108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626108.makeUrl(scheme.get, call_21626108.host, call_21626108.base,
                               call_21626108.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626108, uri, valid, _)

proc call*(call_21626109: Call_GetProfile_21626092; profilingGroupName: string;
          endTime: string = ""; maxDepth: int = 0; period: string = "";
          startTime: string = ""): Recallable =
  ## getProfile
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   endTime: string
  ##          : The end time of the profile to get. Either period or endTime must be specified. Must be greater than start and the overall time range to be in the past and not larger than a week.
  ##   maxDepth: int
  ##           : Limit the max depth of the profile.
  ##   period: string
  ##         : Periods of time represented using <a href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 8601 format</a>.
  ##   startTime: string
  ##            : The start time of the profile to get.
  var path_21626110 = newJObject()
  var query_21626111 = newJObject()
  add(path_21626110, "profilingGroupName", newJString(profilingGroupName))
  add(query_21626111, "endTime", newJString(endTime))
  add(query_21626111, "maxDepth", newJInt(maxDepth))
  add(query_21626111, "period", newJString(period))
  add(query_21626111, "startTime", newJString(startTime))
  result = call_21626109.call(path_21626110, query_21626111, nil, nil, nil)

var getProfile* = Call_GetProfile_21626092(name: "getProfile",
                                        meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                        validator: validate_GetProfile_21626093,
                                        base: "/", makeUrl: url_GetProfile_21626094,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_21626113 = ref object of OpenApiRestCall_21625435
proc url_ListProfileTimes_21626115(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName"), (
        kind: ConstantSegment, value: "/profileTimes#endTime&period&startTime")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProfileTimes_21626114(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626116 = path.getOrDefault("profilingGroupName")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "profilingGroupName", valid_21626116
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString (required)
  ##          : The end time of the time range to list profiles until.
  ##   period: JString (required)
  ##         : Periods of time used for aggregation of profiles, represented using ISO 8601 format.
  ##   maxResults: JInt
  ##             : Upper bound on the number of results to list in a single call.
  ##   nextToken: JString
  ##            : Token for paginating results.
  ##   orderBy: JString
  ##          : The order (ascending or descending by start time of the profile) to list the profiles by. Defaults to TIMESTAMP_DESCENDING.
  ##   startTime: JString (required)
  ##            : The start time of the time range to list the profiles from.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `endTime` field"
  var valid_21626117 = query.getOrDefault("endTime")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "endTime", valid_21626117
  var valid_21626132 = query.getOrDefault("period")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = newJString("P1D"))
  if valid_21626132 != nil:
    section.add "period", valid_21626132
  var valid_21626133 = query.getOrDefault("maxResults")
  valid_21626133 = validateParameter(valid_21626133, JInt, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "maxResults", valid_21626133
  var valid_21626134 = query.getOrDefault("nextToken")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "nextToken", valid_21626134
  var valid_21626135 = query.getOrDefault("orderBy")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = newJString("TimestampAscending"))
  if valid_21626135 != nil:
    section.add "orderBy", valid_21626135
  var valid_21626136 = query.getOrDefault("startTime")
  valid_21626136 = validateParameter(valid_21626136, JString, required = true,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "startTime", valid_21626136
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
  var valid_21626139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Algorithm", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Signature")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Signature", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Credential")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Credential", valid_21626143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626144: Call_ListProfileTimes_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_21626144.validator(path, query, header, formData, body, _)
  let scheme = call_21626144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626144.makeUrl(scheme.get, call_21626144.host, call_21626144.base,
                               call_21626144.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626144, uri, valid, _)

proc call*(call_21626145: Call_ListProfileTimes_21626113;
          profilingGroupName: string; endTime: string; startTime: string;
          period: string = "P1D"; maxResults: int = 0; nextToken: string = "";
          orderBy: string = "TimestampAscending"): Recallable =
  ## listProfileTimes
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   endTime: string (required)
  ##          : The end time of the time range to list profiles until.
  ##   period: string (required)
  ##         : Periods of time used for aggregation of profiles, represented using ISO 8601 format.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   orderBy: string
  ##          : The order (ascending or descending by start time of the profile) to list the profiles by. Defaults to TIMESTAMP_DESCENDING.
  ##   startTime: string (required)
  ##            : The start time of the time range to list the profiles from.
  var path_21626146 = newJObject()
  var query_21626147 = newJObject()
  add(path_21626146, "profilingGroupName", newJString(profilingGroupName))
  add(query_21626147, "endTime", newJString(endTime))
  add(query_21626147, "period", newJString(period))
  add(query_21626147, "maxResults", newJInt(maxResults))
  add(query_21626147, "nextToken", newJString(nextToken))
  add(query_21626147, "orderBy", newJString(orderBy))
  add(query_21626147, "startTime", newJString(startTime))
  result = call_21626145.call(path_21626146, query_21626147, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_21626113(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_21626114, base: "/",
    makeUrl: url_ListProfileTimes_21626115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_21626149 = ref object of OpenApiRestCall_21625435
proc url_ListProfilingGroups_21626151(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProfilingGroups_21626150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List profiling groups in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDescription: JBool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: JInt
  ##             : Upper bound on the number of results to list in a single call.
  ##   nextToken: JString
  ##            : Token for paginating results.
  section = newJObject()
  var valid_21626152 = query.getOrDefault("includeDescription")
  valid_21626152 = validateParameter(valid_21626152, JBool, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "includeDescription", valid_21626152
  var valid_21626153 = query.getOrDefault("maxResults")
  valid_21626153 = validateParameter(valid_21626153, JInt, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "maxResults", valid_21626153
  var valid_21626154 = query.getOrDefault("nextToken")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "nextToken", valid_21626154
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
  var valid_21626155 = header.getOrDefault("X-Amz-Date")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Date", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Security-Token", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626162: Call_ListProfilingGroups_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_21626162.validator(path, query, header, formData, body, _)
  let scheme = call_21626162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626162.makeUrl(scheme.get, call_21626162.host, call_21626162.base,
                               call_21626162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626162, uri, valid, _)

proc call*(call_21626163: Call_ListProfilingGroups_21626149;
          includeDescription: bool = false; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  ##   nextToken: string
  ##            : Token for paginating results.
  var query_21626164 = newJObject()
  add(query_21626164, "includeDescription", newJBool(includeDescription))
  add(query_21626164, "maxResults", newJInt(maxResults))
  add(query_21626164, "nextToken", newJString(nextToken))
  result = call_21626163.call(nil, query_21626164, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_21626149(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_21626150, base: "/",
    makeUrl: url_ListProfilingGroups_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_21626165 = ref object of OpenApiRestCall_21625435
proc url_PostAgentProfile_21626167(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
        "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
               (kind: VariableSegment, value: "profilingGroupName"),
               (kind: ConstantSegment, value: "/agentProfile#Content-Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostAgentProfile_21626166(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
  ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `profilingGroupName` field"
  var valid_21626168 = path.getOrDefault("profilingGroupName")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "profilingGroupName", valid_21626168
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_21626169 = query.getOrDefault("profileToken")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "profileToken", valid_21626169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Content-Type: JString (required)
  ##               : The content type of the agent profile in the payload. Recommended to send the profile gzipped with content-type application/octet-stream. Other accepted values are application/x-amzn-ion and application/json for unzipped Ion and JSON respectively.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626170 = header.getOrDefault("X-Amz-Date")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Date", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Security-Token", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626172
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_21626173 = header.getOrDefault("Content-Type")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "Content-Type", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Algorithm", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Signature")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Signature", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Credential")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Credential", valid_21626177
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

proc call*(call_21626179: Call_PostAgentProfile_21626165; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_21626179.validator(path, query, header, formData, body, _)
  let scheme = call_21626179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626179.makeUrl(scheme.get, call_21626179.host, call_21626179.base,
                               call_21626179.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626179, uri, valid, _)

proc call*(call_21626180: Call_PostAgentProfile_21626165;
          profilingGroupName: string; body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_21626181 = newJObject()
  var query_21626182 = newJObject()
  var body_21626183 = newJObject()
  add(path_21626181, "profilingGroupName", newJString(profilingGroupName))
  add(query_21626182, "profileToken", newJString(profileToken))
  if body != nil:
    body_21626183 = body
  result = call_21626180.call(path_21626181, query_21626182, nil, nil, body_21626183)

var postAgentProfile* = Call_PostAgentProfile_21626165(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_21626166, base: "/",
    makeUrl: url_PostAgentProfile_21626167, schemes: {Scheme.Https, Scheme.Http})
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