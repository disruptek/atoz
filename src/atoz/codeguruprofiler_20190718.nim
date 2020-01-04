
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
  Call_ConfigureAgent_601727 = ref object of OpenApiRestCall_601389
proc url_ConfigureAgent_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ConfigureAgent_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("profilingGroupName")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "profilingGroupName", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_ConfigureAgent_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_ConfigureAgent_601727; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_601958 = newJObject()
  var body_601960 = newJObject()
  add(path_601958, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_601960 = body
  result = call_601957.call(path_601958, nil, nil, nil, body_601960)

var configureAgent* = Call_ConfigureAgent_601727(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_601728, base: "/", url: url_ConfigureAgent_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_601999 = ref object of OpenApiRestCall_601389
proc url_CreateProfilingGroup_602001(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfilingGroup_602000(path: JsonNode; query: JsonNode;
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
  var valid_602002 = query.getOrDefault("clientToken")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "clientToken", valid_602002
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
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_CreateProfilingGroup_601999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_CreateProfilingGroup_601999; body: JsonNode;
          clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
  ##              : Client token for the request.
  var query_602013 = newJObject()
  var body_602014 = newJObject()
  if body != nil:
    body_602014 = body
  add(query_602013, "clientToken", newJString(clientToken))
  result = call_602012.call(nil, query_602013, nil, nil, body_602014)

var createProfilingGroup* = Call_CreateProfilingGroup_601999(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_602000, base: "/",
    url: url_CreateProfilingGroup_602001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_602029 = ref object of OpenApiRestCall_601389
proc url_UpdateProfilingGroup_602031(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfilingGroup_602030(path: JsonNode; query: JsonNode;
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
  var valid_602032 = path.getOrDefault("profilingGroupName")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "profilingGroupName", valid_602032
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
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Content-Sha256", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Credential")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Credential", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Security-Token")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Security-Token", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Algorithm")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Algorithm", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_UpdateProfilingGroup_602029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602041, url, valid)

proc call*(call_602042: Call_UpdateProfilingGroup_602029;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_602043 = newJObject()
  var body_602044 = newJObject()
  add(path_602043, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_602044 = body
  result = call_602042.call(path_602043, nil, nil, nil, body_602044)

var updateProfilingGroup* = Call_UpdateProfilingGroup_602029(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_602030, base: "/",
    url: url_UpdateProfilingGroup_602031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_602015 = ref object of OpenApiRestCall_601389
proc url_DescribeProfilingGroup_602017(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProfilingGroup_602016(path: JsonNode; query: JsonNode;
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
  var valid_602018 = path.getOrDefault("profilingGroupName")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "profilingGroupName", valid_602018
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
  var valid_602019 = header.getOrDefault("X-Amz-Signature")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Signature", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Content-Sha256", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Date")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Date", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Credential")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Credential", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Algorithm")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Algorithm", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-SignedHeaders", valid_602025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602026: Call_DescribeProfilingGroup_602015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_602026.validator(path, query, header, formData, body)
  let scheme = call_602026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602026.url(scheme.get, call_602026.host, call_602026.base,
                         call_602026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602026, url, valid)

proc call*(call_602027: Call_DescribeProfilingGroup_602015;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_602028 = newJObject()
  add(path_602028, "profilingGroupName", newJString(profilingGroupName))
  result = call_602027.call(path_602028, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_602015(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_602016, base: "/",
    url: url_DescribeProfilingGroup_602017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_602045 = ref object of OpenApiRestCall_601389
proc url_DeleteProfilingGroup_602047(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfilingGroup_602046(path: JsonNode; query: JsonNode;
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
  var valid_602048 = path.getOrDefault("profilingGroupName")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "profilingGroupName", valid_602048
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
  var valid_602049 = header.getOrDefault("X-Amz-Signature")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Signature", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Content-Sha256", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Credential")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Credential", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Security-Token")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Security-Token", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-SignedHeaders", valid_602055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602056: Call_DeleteProfilingGroup_602045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_602056.validator(path, query, header, formData, body)
  let scheme = call_602056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602056.url(scheme.get, call_602056.host, call_602056.base,
                         call_602056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602056, url, valid)

proc call*(call_602057: Call_DeleteProfilingGroup_602045;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_602058 = newJObject()
  add(path_602058, "profilingGroupName", newJString(profilingGroupName))
  result = call_602057.call(path_602058, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_602045(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_602046, base: "/",
    url: url_DeleteProfilingGroup_602047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_602059 = ref object of OpenApiRestCall_601389
proc url_GetProfile_602061(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProfile_602060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602062 = path.getOrDefault("profilingGroupName")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "profilingGroupName", valid_602062
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
  var valid_602063 = query.getOrDefault("startTime")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "startTime", valid_602063
  var valid_602064 = query.getOrDefault("period")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "period", valid_602064
  var valid_602065 = query.getOrDefault("maxDepth")
  valid_602065 = validateParameter(valid_602065, JInt, required = false, default = nil)
  if valid_602065 != nil:
    section.add "maxDepth", valid_602065
  var valid_602066 = query.getOrDefault("endTime")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "endTime", valid_602066
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
  var valid_602067 = header.getOrDefault("X-Amz-Signature")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Signature", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Content-Sha256", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Date")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Date", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Credential")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Credential", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Security-Token")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Security-Token", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Algorithm")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Algorithm", valid_602072
  var valid_602073 = header.getOrDefault("Accept")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "Accept", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602075: Call_GetProfile_602059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_602075.validator(path, query, header, formData, body)
  let scheme = call_602075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602075.url(scheme.get, call_602075.host, call_602075.base,
                         call_602075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602075, url, valid)

proc call*(call_602076: Call_GetProfile_602059; profilingGroupName: string;
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
  var path_602077 = newJObject()
  var query_602078 = newJObject()
  add(query_602078, "startTime", newJString(startTime))
  add(path_602077, "profilingGroupName", newJString(profilingGroupName))
  add(query_602078, "period", newJString(period))
  add(query_602078, "maxDepth", newJInt(maxDepth))
  add(query_602078, "endTime", newJString(endTime))
  result = call_602076.call(path_602077, query_602078, nil, nil, nil)

var getProfile* = Call_GetProfile_602059(name: "getProfile",
                                      meth: HttpMethod.HttpGet,
                                      host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                      validator: validate_GetProfile_602060,
                                      base: "/", url: url_GetProfile_602061,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_602079 = ref object of OpenApiRestCall_601389
proc url_ListProfileTimes_602081(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfileTimes_602080(path: JsonNode; query: JsonNode;
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
  var valid_602082 = path.getOrDefault("profilingGroupName")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "profilingGroupName", valid_602082
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
  var valid_602083 = query.getOrDefault("endTime")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "endTime", valid_602083
  var valid_602084 = query.getOrDefault("nextToken")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "nextToken", valid_602084
  var valid_602085 = query.getOrDefault("startTime")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = nil)
  if valid_602085 != nil:
    section.add "startTime", valid_602085
  var valid_602099 = query.getOrDefault("orderBy")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = newJString("TimestampAscending"))
  if valid_602099 != nil:
    section.add "orderBy", valid_602099
  var valid_602100 = query.getOrDefault("period")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = newJString("P1D"))
  if valid_602100 != nil:
    section.add "period", valid_602100
  var valid_602101 = query.getOrDefault("maxResults")
  valid_602101 = validateParameter(valid_602101, JInt, required = false, default = nil)
  if valid_602101 != nil:
    section.add "maxResults", valid_602101
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
  var valid_602102 = header.getOrDefault("X-Amz-Signature")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Signature", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Content-Sha256", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Date")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Date", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Credential")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Credential", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Security-Token")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Security-Token", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Algorithm")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Algorithm", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-SignedHeaders", valid_602108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602109: Call_ListProfileTimes_602079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_602109.validator(path, query, header, formData, body)
  let scheme = call_602109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602109.url(scheme.get, call_602109.host, call_602109.base,
                         call_602109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602109, url, valid)

proc call*(call_602110: Call_ListProfileTimes_602079; endTime: string;
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
  var path_602111 = newJObject()
  var query_602112 = newJObject()
  add(query_602112, "endTime", newJString(endTime))
  add(query_602112, "nextToken", newJString(nextToken))
  add(query_602112, "startTime", newJString(startTime))
  add(path_602111, "profilingGroupName", newJString(profilingGroupName))
  add(query_602112, "orderBy", newJString(orderBy))
  add(query_602112, "period", newJString(period))
  add(query_602112, "maxResults", newJInt(maxResults))
  result = call_602110.call(path_602111, query_602112, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_602079(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_602080, base: "/",
    url: url_ListProfileTimes_602081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_602113 = ref object of OpenApiRestCall_601389
proc url_ListProfilingGroups_602115(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfilingGroups_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = query.getOrDefault("nextToken")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "nextToken", valid_602116
  var valid_602117 = query.getOrDefault("includeDescription")
  valid_602117 = validateParameter(valid_602117, JBool, required = false, default = nil)
  if valid_602117 != nil:
    section.add "includeDescription", valid_602117
  var valid_602118 = query.getOrDefault("maxResults")
  valid_602118 = validateParameter(valid_602118, JInt, required = false, default = nil)
  if valid_602118 != nil:
    section.add "maxResults", valid_602118
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
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-SignedHeaders", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_ListProfilingGroups_602113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_ListProfilingGroups_602113; nextToken: string = "";
          includeDescription: bool = false; maxResults: int = 0): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var query_602128 = newJObject()
  add(query_602128, "nextToken", newJString(nextToken))
  add(query_602128, "includeDescription", newJBool(includeDescription))
  add(query_602128, "maxResults", newJInt(maxResults))
  result = call_602127.call(nil, query_602128, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_602113(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_602114, base: "/",
    url: url_ListProfilingGroups_602115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_602129 = ref object of OpenApiRestCall_601389
proc url_PostAgentProfile_602131(protocol: Scheme; host: string; base: string;
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

proc validate_PostAgentProfile_602130(path: JsonNode; query: JsonNode;
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
  var valid_602132 = path.getOrDefault("profilingGroupName")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "profilingGroupName", valid_602132
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_602133 = query.getOrDefault("profileToken")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "profileToken", valid_602133
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
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Content-Sha256", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Date")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Date", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Credential")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Credential", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Security-Token")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Security-Token", valid_602138
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_602139 = header.getOrDefault("Content-Type")
  valid_602139 = validateParameter(valid_602139, JString, required = true,
                                 default = nil)
  if valid_602139 != nil:
    section.add "Content-Type", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_PostAgentProfile_602129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_PostAgentProfile_602129; profilingGroupName: string;
          body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_602145 = newJObject()
  var query_602146 = newJObject()
  var body_602147 = newJObject()
  add(path_602145, "profilingGroupName", newJString(profilingGroupName))
  add(query_602146, "profileToken", newJString(profileToken))
  if body != nil:
    body_602147 = body
  result = call_602144.call(path_602145, query_602146, nil, nil, body_602147)

var postAgentProfile* = Call_PostAgentProfile_602129(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_602130, base: "/",
    url: url_PostAgentProfile_602131, schemes: {Scheme.Https, Scheme.Http})
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
