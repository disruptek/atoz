
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ConfigureAgent_597727 = ref object of OpenApiRestCall_597389
proc url_ConfigureAgent_597729(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ConfigureAgent_597728(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_597855 = path.getOrDefault("profilingGroupName")
  valid_597855 = validateParameter(valid_597855, JString, required = true,
                                 default = nil)
  if valid_597855 != nil:
    section.add "profilingGroupName", valid_597855
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
  var valid_597856 = header.getOrDefault("X-Amz-Signature")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Signature", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Content-Sha256", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Date")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Date", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Credential")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Credential", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Security-Token")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Security-Token", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Algorithm")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Algorithm", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-SignedHeaders", valid_597862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597886: Call_ConfigureAgent_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_597886.validator(path, query, header, formData, body)
  let scheme = call_597886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597886.url(scheme.get, call_597886.host, call_597886.base,
                         call_597886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597886, url, valid)

proc call*(call_597957: Call_ConfigureAgent_597727; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_597958 = newJObject()
  var body_597960 = newJObject()
  add(path_597958, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_597960 = body
  result = call_597957.call(path_597958, nil, nil, nil, body_597960)

var configureAgent* = Call_ConfigureAgent_597727(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_597728, base: "/", url: url_ConfigureAgent_597729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_597999 = ref object of OpenApiRestCall_597389
proc url_CreateProfilingGroup_598001(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfilingGroup_598000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_598002 = query.getOrDefault("clientToken")
  valid_598002 = validateParameter(valid_598002, JString, required = true,
                                 default = nil)
  if valid_598002 != nil:
    section.add "clientToken", valid_598002
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
  var valid_598003 = header.getOrDefault("X-Amz-Signature")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Signature", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Content-Sha256", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Date")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Date", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Credential")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Credential", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-Security-Token")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Security-Token", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Algorithm")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Algorithm", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-SignedHeaders", valid_598009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598011: Call_CreateProfilingGroup_597999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_598011.validator(path, query, header, formData, body)
  let scheme = call_598011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598011.url(scheme.get, call_598011.host, call_598011.base,
                         call_598011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598011, url, valid)

proc call*(call_598012: Call_CreateProfilingGroup_597999; body: JsonNode;
          clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
  ##              : Client token for the request.
  var query_598013 = newJObject()
  var body_598014 = newJObject()
  if body != nil:
    body_598014 = body
  add(query_598013, "clientToken", newJString(clientToken))
  result = call_598012.call(nil, query_598013, nil, nil, body_598014)

var createProfilingGroup* = Call_CreateProfilingGroup_597999(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_598000, base: "/",
    url: url_CreateProfilingGroup_598001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_598029 = ref object of OpenApiRestCall_597389
proc url_UpdateProfilingGroup_598031(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateProfilingGroup_598030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_598032 = path.getOrDefault("profilingGroupName")
  valid_598032 = validateParameter(valid_598032, JString, required = true,
                                 default = nil)
  if valid_598032 != nil:
    section.add "profilingGroupName", valid_598032
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
  var valid_598033 = header.getOrDefault("X-Amz-Signature")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Signature", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Content-Sha256", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Date")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Date", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Credential")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Credential", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Security-Token")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Security-Token", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-Algorithm")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Algorithm", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-SignedHeaders", valid_598039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598041: Call_UpdateProfilingGroup_598029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_598041.validator(path, query, header, formData, body)
  let scheme = call_598041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598041.url(scheme.get, call_598041.host, call_598041.base,
                         call_598041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598041, url, valid)

proc call*(call_598042: Call_UpdateProfilingGroup_598029;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_598043 = newJObject()
  var body_598044 = newJObject()
  add(path_598043, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_598044 = body
  result = call_598042.call(path_598043, nil, nil, nil, body_598044)

var updateProfilingGroup* = Call_UpdateProfilingGroup_598029(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_598030, base: "/",
    url: url_UpdateProfilingGroup_598031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_598015 = ref object of OpenApiRestCall_597389
proc url_DescribeProfilingGroup_598017(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProfilingGroup_598016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_598018 = path.getOrDefault("profilingGroupName")
  valid_598018 = validateParameter(valid_598018, JString, required = true,
                                 default = nil)
  if valid_598018 != nil:
    section.add "profilingGroupName", valid_598018
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
  var valid_598019 = header.getOrDefault("X-Amz-Signature")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Signature", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Content-Sha256", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-Date")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-Date", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-Credential")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Credential", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Security-Token")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Security-Token", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Algorithm")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Algorithm", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-SignedHeaders", valid_598025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598026: Call_DescribeProfilingGroup_598015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_598026.validator(path, query, header, formData, body)
  let scheme = call_598026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598026.url(scheme.get, call_598026.host, call_598026.base,
                         call_598026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598026, url, valid)

proc call*(call_598027: Call_DescribeProfilingGroup_598015;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_598028 = newJObject()
  add(path_598028, "profilingGroupName", newJString(profilingGroupName))
  result = call_598027.call(path_598028, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_598015(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_598016, base: "/",
    url: url_DescribeProfilingGroup_598017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_598045 = ref object of OpenApiRestCall_597389
proc url_DeleteProfilingGroup_598047(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProfilingGroup_598046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_598048 = path.getOrDefault("profilingGroupName")
  valid_598048 = validateParameter(valid_598048, JString, required = true,
                                 default = nil)
  if valid_598048 != nil:
    section.add "profilingGroupName", valid_598048
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
  var valid_598049 = header.getOrDefault("X-Amz-Signature")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Signature", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Content-Sha256", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Date")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Date", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-Credential")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Credential", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Security-Token")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Security-Token", valid_598053
  var valid_598054 = header.getOrDefault("X-Amz-Algorithm")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Algorithm", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-SignedHeaders", valid_598055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598056: Call_DeleteProfilingGroup_598045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_598056.validator(path, query, header, formData, body)
  let scheme = call_598056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598056.url(scheme.get, call_598056.host, call_598056.base,
                         call_598056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598056, url, valid)

proc call*(call_598057: Call_DeleteProfilingGroup_598045;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_598058 = newJObject()
  add(path_598058, "profilingGroupName", newJString(profilingGroupName))
  result = call_598057.call(path_598058, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_598045(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_598046, base: "/",
    url: url_DeleteProfilingGroup_598047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_598059 = ref object of OpenApiRestCall_597389
proc url_GetProfile_598061(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProfile_598060(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_598062 = path.getOrDefault("profilingGroupName")
  valid_598062 = validateParameter(valid_598062, JString, required = true,
                                 default = nil)
  if valid_598062 != nil:
    section.add "profilingGroupName", valid_598062
  result.add "path", section
  ## parameters in `query` object:
  ##   startTime: JString
  ##            : The start time of the profile to get.
  ##   period: JString
  ##         : Periods of time represented using <a href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 8601 format</a>.
  ##   maxDepth: JInt
  ##           : Limit the max depth of the profile.
  ##   endTime: JString
  ##          : The end time of the profile to get. Either period or endTime must be specified. Must be greater than start and the overall time range to be in the past and not larger than a week.
  section = newJObject()
  var valid_598063 = query.getOrDefault("startTime")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "startTime", valid_598063
  var valid_598064 = query.getOrDefault("period")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "period", valid_598064
  var valid_598065 = query.getOrDefault("maxDepth")
  valid_598065 = validateParameter(valid_598065, JInt, required = false, default = nil)
  if valid_598065 != nil:
    section.add "maxDepth", valid_598065
  var valid_598066 = query.getOrDefault("endTime")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "endTime", valid_598066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   Accept: JString
  ##         : The format of the profile to return. Supports application/json or application/x-amzn-ion. Defaults to application/x-amzn-ion.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598067 = header.getOrDefault("X-Amz-Signature")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-Signature", valid_598067
  var valid_598068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Content-Sha256", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Date")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Date", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Credential")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Credential", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Security-Token")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Security-Token", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Algorithm")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Algorithm", valid_598072
  var valid_598073 = header.getOrDefault("Accept")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "Accept", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-SignedHeaders", valid_598074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598075: Call_GetProfile_598059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_598075.validator(path, query, header, formData, body)
  let scheme = call_598075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598075.url(scheme.get, call_598075.host, call_598075.base,
                         call_598075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598075, url, valid)

proc call*(call_598076: Call_GetProfile_598059; profilingGroupName: string;
          startTime: string = ""; period: string = ""; maxDepth: int = 0;
          endTime: string = ""): Recallable =
  ## getProfile
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ##   startTime: string
  ##            : The start time of the profile to get.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   period: string
  ##         : Periods of time represented using <a href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 8601 format</a>.
  ##   maxDepth: int
  ##           : Limit the max depth of the profile.
  ##   endTime: string
  ##          : The end time of the profile to get. Either period or endTime must be specified. Must be greater than start and the overall time range to be in the past and not larger than a week.
  var path_598077 = newJObject()
  var query_598078 = newJObject()
  add(query_598078, "startTime", newJString(startTime))
  add(path_598077, "profilingGroupName", newJString(profilingGroupName))
  add(query_598078, "period", newJString(period))
  add(query_598078, "maxDepth", newJInt(maxDepth))
  add(query_598078, "endTime", newJString(endTime))
  result = call_598076.call(path_598077, query_598078, nil, nil, nil)

var getProfile* = Call_GetProfile_598059(name: "getProfile",
                                      meth: HttpMethod.HttpGet,
                                      host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                      validator: validate_GetProfile_598060,
                                      base: "/", url: url_GetProfile_598061,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_598079 = ref object of OpenApiRestCall_597389
proc url_ListProfileTimes_598081(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProfileTimes_598080(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_598082 = path.getOrDefault("profilingGroupName")
  valid_598082 = validateParameter(valid_598082, JString, required = true,
                                 default = nil)
  if valid_598082 != nil:
    section.add "profilingGroupName", valid_598082
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString (required)
  ##          : The end time of the time range to list profiles until.
  ##   nextToken: JString
  ##            : Token for paginating results.
  ##   startTime: JString (required)
  ##            : The start time of the time range to list the profiles from.
  ##   orderBy: JString
  ##          : The order (ascending or descending by start time of the profile) to list the profiles by. Defaults to TIMESTAMP_DESCENDING.
  ##   period: JString (required)
  ##         : Periods of time used for aggregation of profiles, represented using ISO 8601 format.
  ##   maxResults: JInt
  ##             : Upper bound on the number of results to list in a single call.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `endTime` field"
  var valid_598083 = query.getOrDefault("endTime")
  valid_598083 = validateParameter(valid_598083, JString, required = true,
                                 default = nil)
  if valid_598083 != nil:
    section.add "endTime", valid_598083
  var valid_598084 = query.getOrDefault("nextToken")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "nextToken", valid_598084
  var valid_598085 = query.getOrDefault("startTime")
  valid_598085 = validateParameter(valid_598085, JString, required = true,
                                 default = nil)
  if valid_598085 != nil:
    section.add "startTime", valid_598085
  var valid_598099 = query.getOrDefault("orderBy")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = newJString("TimestampAscending"))
  if valid_598099 != nil:
    section.add "orderBy", valid_598099
  var valid_598100 = query.getOrDefault("period")
  valid_598100 = validateParameter(valid_598100, JString, required = true,
                                 default = newJString("P1D"))
  if valid_598100 != nil:
    section.add "period", valid_598100
  var valid_598101 = query.getOrDefault("maxResults")
  valid_598101 = validateParameter(valid_598101, JInt, required = false, default = nil)
  if valid_598101 != nil:
    section.add "maxResults", valid_598101
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
  var valid_598102 = header.getOrDefault("X-Amz-Signature")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Signature", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Content-Sha256", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Date")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Date", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Credential")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Credential", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Security-Token")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Security-Token", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Algorithm")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Algorithm", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-SignedHeaders", valid_598108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598109: Call_ListProfileTimes_598079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_598109.validator(path, query, header, formData, body)
  let scheme = call_598109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598109.url(scheme.get, call_598109.host, call_598109.base,
                         call_598109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598109, url, valid)

proc call*(call_598110: Call_ListProfileTimes_598079; endTime: string;
          startTime: string; profilingGroupName: string; nextToken: string = "";
          orderBy: string = "TimestampAscending"; period: string = "P1D";
          maxResults: int = 0): Recallable =
  ## listProfileTimes
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ##   endTime: string (required)
  ##          : The end time of the time range to list profiles until.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   startTime: string (required)
  ##            : The start time of the time range to list the profiles from.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   orderBy: string
  ##          : The order (ascending or descending by start time of the profile) to list the profiles by. Defaults to TIMESTAMP_DESCENDING.
  ##   period: string (required)
  ##         : Periods of time used for aggregation of profiles, represented using ISO 8601 format.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var path_598111 = newJObject()
  var query_598112 = newJObject()
  add(query_598112, "endTime", newJString(endTime))
  add(query_598112, "nextToken", newJString(nextToken))
  add(query_598112, "startTime", newJString(startTime))
  add(path_598111, "profilingGroupName", newJString(profilingGroupName))
  add(query_598112, "orderBy", newJString(orderBy))
  add(query_598112, "period", newJString(period))
  add(query_598112, "maxResults", newJInt(maxResults))
  result = call_598110.call(path_598111, query_598112, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_598079(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_598080, base: "/",
    url: url_ListProfileTimes_598081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_598113 = ref object of OpenApiRestCall_597389
proc url_ListProfilingGroups_598115(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfilingGroups_598114(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List profiling groups in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Token for paginating results.
  ##   includeDescription: JBool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: JInt
  ##             : Upper bound on the number of results to list in a single call.
  section = newJObject()
  var valid_598116 = query.getOrDefault("nextToken")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "nextToken", valid_598116
  var valid_598117 = query.getOrDefault("includeDescription")
  valid_598117 = validateParameter(valid_598117, JBool, required = false, default = nil)
  if valid_598117 != nil:
    section.add "includeDescription", valid_598117
  var valid_598118 = query.getOrDefault("maxResults")
  valid_598118 = validateParameter(valid_598118, JInt, required = false, default = nil)
  if valid_598118 != nil:
    section.add "maxResults", valid_598118
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
  var valid_598119 = header.getOrDefault("X-Amz-Signature")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Signature", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Content-Sha256", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Date")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Date", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Credential")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Credential", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Security-Token")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Security-Token", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Algorithm")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Algorithm", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-SignedHeaders", valid_598125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598126: Call_ListProfilingGroups_598113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_598126.validator(path, query, header, formData, body)
  let scheme = call_598126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598126.url(scheme.get, call_598126.host, call_598126.base,
                         call_598126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598126, url, valid)

proc call*(call_598127: Call_ListProfilingGroups_598113; nextToken: string = "";
          includeDescription: bool = false; maxResults: int = 0): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var query_598128 = newJObject()
  add(query_598128, "nextToken", newJString(nextToken))
  add(query_598128, "includeDescription", newJBool(includeDescription))
  add(query_598128, "maxResults", newJInt(maxResults))
  result = call_598127.call(nil, query_598128, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_598113(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_598114, base: "/",
    url: url_ListProfilingGroups_598115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_598129 = ref object of OpenApiRestCall_597389
proc url_PostAgentProfile_598131(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostAgentProfile_598130(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_598132 = path.getOrDefault("profilingGroupName")
  valid_598132 = validateParameter(valid_598132, JString, required = true,
                                 default = nil)
  if valid_598132 != nil:
    section.add "profilingGroupName", valid_598132
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_598133 = query.getOrDefault("profileToken")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "profileToken", valid_598133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   Content-Type: JString (required)
  ##               : The content type of the agent profile in the payload. Recommended to send the profile gzipped with content-type application/octet-stream. Other accepted values are application/x-amzn-ion and application/json for unzipped Ion and JSON respectively.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598134 = header.getOrDefault("X-Amz-Signature")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-Signature", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Content-Sha256", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Date")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Date", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Credential")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Credential", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Security-Token")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Security-Token", valid_598138
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_598139 = header.getOrDefault("Content-Type")
  valid_598139 = validateParameter(valid_598139, JString, required = true,
                                 default = nil)
  if valid_598139 != nil:
    section.add "Content-Type", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Algorithm")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Algorithm", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-SignedHeaders", valid_598141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598143: Call_PostAgentProfile_598129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_598143.validator(path, query, header, formData, body)
  let scheme = call_598143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598143.url(scheme.get, call_598143.host, call_598143.base,
                         call_598143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598143, url, valid)

proc call*(call_598144: Call_PostAgentProfile_598129; profilingGroupName: string;
          body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_598145 = newJObject()
  var query_598146 = newJObject()
  var body_598147 = newJObject()
  add(path_598145, "profilingGroupName", newJString(profilingGroupName))
  add(query_598146, "profileToken", newJString(profileToken))
  if body != nil:
    body_598147 = body
  result = call_598144.call(path_598145, query_598146, nil, nil, body_598147)

var postAgentProfile* = Call_PostAgentProfile_598129(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_598130, base: "/",
    url: url_PostAgentProfile_598131, schemes: {Scheme.Https, Scheme.Http})
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
