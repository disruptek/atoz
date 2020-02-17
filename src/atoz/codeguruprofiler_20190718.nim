
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ConfigureAgent_610996 = ref object of OpenApiRestCall_610658
proc url_ConfigureAgent_610998(protocol: Scheme; host: string; base: string;
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

proc validate_ConfigureAgent_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("profilingGroupName")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "profilingGroupName", valid_611124
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
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_ConfigureAgent_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_ConfigureAgent_610996; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_611227 = newJObject()
  var body_611229 = newJObject()
  add(path_611227, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_611229 = body
  result = call_611226.call(path_611227, nil, nil, nil, body_611229)

var configureAgent* = Call_ConfigureAgent_610996(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_610997, base: "/", url: url_ConfigureAgent_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_611268 = ref object of OpenApiRestCall_610658
proc url_CreateProfilingGroup_611270(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProfilingGroup_611269(path: JsonNode; query: JsonNode;
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
  var valid_611271 = query.getOrDefault("clientToken")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "clientToken", valid_611271
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
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_CreateProfilingGroup_611268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_CreateProfilingGroup_611268; body: JsonNode;
          clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
  ##              : Client token for the request.
  var query_611282 = newJObject()
  var body_611283 = newJObject()
  if body != nil:
    body_611283 = body
  add(query_611282, "clientToken", newJString(clientToken))
  result = call_611281.call(nil, query_611282, nil, nil, body_611283)

var createProfilingGroup* = Call_CreateProfilingGroup_611268(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_611269, base: "/",
    url: url_CreateProfilingGroup_611270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_611298 = ref object of OpenApiRestCall_610658
proc url_UpdateProfilingGroup_611300(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfilingGroup_611299(path: JsonNode; query: JsonNode;
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
  var valid_611301 = path.getOrDefault("profilingGroupName")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = nil)
  if valid_611301 != nil:
    section.add "profilingGroupName", valid_611301
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
  var valid_611302 = header.getOrDefault("X-Amz-Signature")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Signature", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Content-Sha256", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Date")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Date", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Credential")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Credential", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Security-Token")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Security-Token", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Algorithm")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Algorithm", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-SignedHeaders", valid_611308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611310: Call_UpdateProfilingGroup_611298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_611310.validator(path, query, header, formData, body)
  let scheme = call_611310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611310.url(scheme.get, call_611310.host, call_611310.base,
                         call_611310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611310, url, valid)

proc call*(call_611311: Call_UpdateProfilingGroup_611298;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_611312 = newJObject()
  var body_611313 = newJObject()
  add(path_611312, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_611313 = body
  result = call_611311.call(path_611312, nil, nil, nil, body_611313)

var updateProfilingGroup* = Call_UpdateProfilingGroup_611298(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_611299, base: "/",
    url: url_UpdateProfilingGroup_611300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_611284 = ref object of OpenApiRestCall_610658
proc url_DescribeProfilingGroup_611286(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProfilingGroup_611285(path: JsonNode; query: JsonNode;
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
  var valid_611287 = path.getOrDefault("profilingGroupName")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "profilingGroupName", valid_611287
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
  var valid_611288 = header.getOrDefault("X-Amz-Signature")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Signature", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Content-Sha256", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Date")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Date", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Credential")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Credential", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Security-Token")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Security-Token", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Algorithm")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Algorithm", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-SignedHeaders", valid_611294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611295: Call_DescribeProfilingGroup_611284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_611295.validator(path, query, header, formData, body)
  let scheme = call_611295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611295.url(scheme.get, call_611295.host, call_611295.base,
                         call_611295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611295, url, valid)

proc call*(call_611296: Call_DescribeProfilingGroup_611284;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_611297 = newJObject()
  add(path_611297, "profilingGroupName", newJString(profilingGroupName))
  result = call_611296.call(path_611297, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_611284(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_611285, base: "/",
    url: url_DescribeProfilingGroup_611286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_611314 = ref object of OpenApiRestCall_610658
proc url_DeleteProfilingGroup_611316(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfilingGroup_611315(path: JsonNode; query: JsonNode;
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
  var valid_611317 = path.getOrDefault("profilingGroupName")
  valid_611317 = validateParameter(valid_611317, JString, required = true,
                                 default = nil)
  if valid_611317 != nil:
    section.add "profilingGroupName", valid_611317
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
  var valid_611318 = header.getOrDefault("X-Amz-Signature")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Signature", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Content-Sha256", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Date")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Date", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Credential")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Credential", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Security-Token")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Security-Token", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Algorithm")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Algorithm", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-SignedHeaders", valid_611324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611325: Call_DeleteProfilingGroup_611314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_611325.validator(path, query, header, formData, body)
  let scheme = call_611325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611325.url(scheme.get, call_611325.host, call_611325.base,
                         call_611325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611325, url, valid)

proc call*(call_611326: Call_DeleteProfilingGroup_611314;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_611327 = newJObject()
  add(path_611327, "profilingGroupName", newJString(profilingGroupName))
  result = call_611326.call(path_611327, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_611314(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_611315, base: "/",
    url: url_DeleteProfilingGroup_611316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_611328 = ref object of OpenApiRestCall_610658
proc url_GetProfile_611330(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProfile_611329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611331 = path.getOrDefault("profilingGroupName")
  valid_611331 = validateParameter(valid_611331, JString, required = true,
                                 default = nil)
  if valid_611331 != nil:
    section.add "profilingGroupName", valid_611331
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
  var valid_611332 = query.getOrDefault("startTime")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "startTime", valid_611332
  var valid_611333 = query.getOrDefault("period")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "period", valid_611333
  var valid_611334 = query.getOrDefault("maxDepth")
  valid_611334 = validateParameter(valid_611334, JInt, required = false, default = nil)
  if valid_611334 != nil:
    section.add "maxDepth", valid_611334
  var valid_611335 = query.getOrDefault("endTime")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "endTime", valid_611335
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
  var valid_611336 = header.getOrDefault("X-Amz-Signature")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Signature", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Content-Sha256", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Date")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Date", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Credential")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Credential", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Security-Token")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Security-Token", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Algorithm")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Algorithm", valid_611341
  var valid_611342 = header.getOrDefault("Accept")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "Accept", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611344: Call_GetProfile_611328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_611344.validator(path, query, header, formData, body)
  let scheme = call_611344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611344.url(scheme.get, call_611344.host, call_611344.base,
                         call_611344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611344, url, valid)

proc call*(call_611345: Call_GetProfile_611328; profilingGroupName: string;
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
  var path_611346 = newJObject()
  var query_611347 = newJObject()
  add(query_611347, "startTime", newJString(startTime))
  add(path_611346, "profilingGroupName", newJString(profilingGroupName))
  add(query_611347, "period", newJString(period))
  add(query_611347, "maxDepth", newJInt(maxDepth))
  add(query_611347, "endTime", newJString(endTime))
  result = call_611345.call(path_611346, query_611347, nil, nil, nil)

var getProfile* = Call_GetProfile_611328(name: "getProfile",
                                      meth: HttpMethod.HttpGet,
                                      host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                      validator: validate_GetProfile_611329,
                                      base: "/", url: url_GetProfile_611330,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_611348 = ref object of OpenApiRestCall_610658
proc url_ListProfileTimes_611350(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfileTimes_611349(path: JsonNode; query: JsonNode;
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
  var valid_611351 = path.getOrDefault("profilingGroupName")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "profilingGroupName", valid_611351
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
  var valid_611352 = query.getOrDefault("endTime")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "endTime", valid_611352
  var valid_611353 = query.getOrDefault("nextToken")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "nextToken", valid_611353
  var valid_611354 = query.getOrDefault("startTime")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = nil)
  if valid_611354 != nil:
    section.add "startTime", valid_611354
  var valid_611368 = query.getOrDefault("orderBy")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = newJString("TimestampAscending"))
  if valid_611368 != nil:
    section.add "orderBy", valid_611368
  var valid_611369 = query.getOrDefault("period")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = newJString("P1D"))
  if valid_611369 != nil:
    section.add "period", valid_611369
  var valid_611370 = query.getOrDefault("maxResults")
  valid_611370 = validateParameter(valid_611370, JInt, required = false, default = nil)
  if valid_611370 != nil:
    section.add "maxResults", valid_611370
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
  var valid_611371 = header.getOrDefault("X-Amz-Signature")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Signature", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Content-Sha256", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Date")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Date", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Credential")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Credential", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Security-Token")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Security-Token", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Algorithm")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Algorithm", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-SignedHeaders", valid_611377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611378: Call_ListProfileTimes_611348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_611378.validator(path, query, header, formData, body)
  let scheme = call_611378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611378.url(scheme.get, call_611378.host, call_611378.base,
                         call_611378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611378, url, valid)

proc call*(call_611379: Call_ListProfileTimes_611348; endTime: string;
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
  var path_611380 = newJObject()
  var query_611381 = newJObject()
  add(query_611381, "endTime", newJString(endTime))
  add(query_611381, "nextToken", newJString(nextToken))
  add(query_611381, "startTime", newJString(startTime))
  add(path_611380, "profilingGroupName", newJString(profilingGroupName))
  add(query_611381, "orderBy", newJString(orderBy))
  add(query_611381, "period", newJString(period))
  add(query_611381, "maxResults", newJInt(maxResults))
  result = call_611379.call(path_611380, query_611381, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_611348(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_611349, base: "/",
    url: url_ListProfileTimes_611350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_611382 = ref object of OpenApiRestCall_610658
proc url_ListProfilingGroups_611384(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProfilingGroups_611383(path: JsonNode; query: JsonNode;
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
  var valid_611385 = query.getOrDefault("nextToken")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "nextToken", valid_611385
  var valid_611386 = query.getOrDefault("includeDescription")
  valid_611386 = validateParameter(valid_611386, JBool, required = false, default = nil)
  if valid_611386 != nil:
    section.add "includeDescription", valid_611386
  var valid_611387 = query.getOrDefault("maxResults")
  valid_611387 = validateParameter(valid_611387, JInt, required = false, default = nil)
  if valid_611387 != nil:
    section.add "maxResults", valid_611387
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
  var valid_611388 = header.getOrDefault("X-Amz-Signature")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Signature", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Content-Sha256", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Date")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Date", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Credential")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Credential", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Security-Token")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Security-Token", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Algorithm")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Algorithm", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-SignedHeaders", valid_611394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611395: Call_ListProfilingGroups_611382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_611395.validator(path, query, header, formData, body)
  let scheme = call_611395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611395.url(scheme.get, call_611395.host, call_611395.base,
                         call_611395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611395, url, valid)

proc call*(call_611396: Call_ListProfilingGroups_611382; nextToken: string = "";
          includeDescription: bool = false; maxResults: int = 0): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var query_611397 = newJObject()
  add(query_611397, "nextToken", newJString(nextToken))
  add(query_611397, "includeDescription", newJBool(includeDescription))
  add(query_611397, "maxResults", newJInt(maxResults))
  result = call_611396.call(nil, query_611397, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_611382(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_611383, base: "/",
    url: url_ListProfilingGroups_611384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_611398 = ref object of OpenApiRestCall_610658
proc url_PostAgentProfile_611400(protocol: Scheme; host: string; base: string;
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

proc validate_PostAgentProfile_611399(path: JsonNode; query: JsonNode;
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
  var valid_611401 = path.getOrDefault("profilingGroupName")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "profilingGroupName", valid_611401
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_611402 = query.getOrDefault("profileToken")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "profileToken", valid_611402
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
  var valid_611403 = header.getOrDefault("X-Amz-Signature")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Signature", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Content-Sha256", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Date")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Date", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Credential")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Credential", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Security-Token")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Security-Token", valid_611407
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_611408 = header.getOrDefault("Content-Type")
  valid_611408 = validateParameter(valid_611408, JString, required = true,
                                 default = nil)
  if valid_611408 != nil:
    section.add "Content-Type", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_PostAgentProfile_611398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_PostAgentProfile_611398; profilingGroupName: string;
          body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_611414 = newJObject()
  var query_611415 = newJObject()
  var body_611416 = newJObject()
  add(path_611414, "profilingGroupName", newJString(profilingGroupName))
  add(query_611415, "profileToken", newJString(profileToken))
  if body != nil:
    body_611416 = body
  result = call_611413.call(path_611414, query_611415, nil, nil, body_611416)

var postAgentProfile* = Call_PostAgentProfile_611398(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_611399, base: "/",
    url: url_PostAgentProfile_611400, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
