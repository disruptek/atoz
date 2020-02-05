
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_ConfigureAgent_612996 = ref object of OpenApiRestCall_612658
proc url_ConfigureAgent_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ConfigureAgent_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("profilingGroupName")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "profilingGroupName", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_ConfigureAgent_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_ConfigureAgent_612996; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_613227 = newJObject()
  var body_613229 = newJObject()
  add(path_613227, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_613229 = body
  result = call_613226.call(path_613227, nil, nil, nil, body_613229)

var configureAgent* = Call_ConfigureAgent_612996(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_612997, base: "/", url: url_ConfigureAgent_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_613268 = ref object of OpenApiRestCall_612658
proc url_CreateProfilingGroup_613270(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfilingGroup_613269(path: JsonNode; query: JsonNode;
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
  var valid_613271 = query.getOrDefault("clientToken")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "clientToken", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_CreateProfilingGroup_613268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_CreateProfilingGroup_613268; body: JsonNode;
          clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
  ##              : Client token for the request.
  var query_613282 = newJObject()
  var body_613283 = newJObject()
  if body != nil:
    body_613283 = body
  add(query_613282, "clientToken", newJString(clientToken))
  result = call_613281.call(nil, query_613282, nil, nil, body_613283)

var createProfilingGroup* = Call_CreateProfilingGroup_613268(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_613269, base: "/",
    url: url_CreateProfilingGroup_613270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_613298 = ref object of OpenApiRestCall_612658
proc url_UpdateProfilingGroup_613300(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfilingGroup_613299(path: JsonNode; query: JsonNode;
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
  var valid_613301 = path.getOrDefault("profilingGroupName")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "profilingGroupName", valid_613301
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
  var valid_613302 = header.getOrDefault("X-Amz-Signature")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Signature", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Content-Sha256", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Date")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Date", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Credential")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Credential", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Security-Token")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Security-Token", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Algorithm")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Algorithm", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-SignedHeaders", valid_613308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613310: Call_UpdateProfilingGroup_613298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_613310.validator(path, query, header, formData, body)
  let scheme = call_613310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613310.url(scheme.get, call_613310.host, call_613310.base,
                         call_613310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613310, url, valid)

proc call*(call_613311: Call_UpdateProfilingGroup_613298;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_613312 = newJObject()
  var body_613313 = newJObject()
  add(path_613312, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_613313 = body
  result = call_613311.call(path_613312, nil, nil, nil, body_613313)

var updateProfilingGroup* = Call_UpdateProfilingGroup_613298(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_613299, base: "/",
    url: url_UpdateProfilingGroup_613300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_613284 = ref object of OpenApiRestCall_612658
proc url_DescribeProfilingGroup_613286(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProfilingGroup_613285(path: JsonNode; query: JsonNode;
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
  var valid_613287 = path.getOrDefault("profilingGroupName")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "profilingGroupName", valid_613287
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
  var valid_613288 = header.getOrDefault("X-Amz-Signature")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Signature", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Content-Sha256", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Date")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Date", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Credential")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Credential", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Security-Token")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Security-Token", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Algorithm")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Algorithm", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-SignedHeaders", valid_613294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613295: Call_DescribeProfilingGroup_613284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_613295.validator(path, query, header, formData, body)
  let scheme = call_613295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613295.url(scheme.get, call_613295.host, call_613295.base,
                         call_613295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613295, url, valid)

proc call*(call_613296: Call_DescribeProfilingGroup_613284;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_613297 = newJObject()
  add(path_613297, "profilingGroupName", newJString(profilingGroupName))
  result = call_613296.call(path_613297, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_613284(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_613285, base: "/",
    url: url_DescribeProfilingGroup_613286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_613314 = ref object of OpenApiRestCall_612658
proc url_DeleteProfilingGroup_613316(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfilingGroup_613315(path: JsonNode; query: JsonNode;
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
  var valid_613317 = path.getOrDefault("profilingGroupName")
  valid_613317 = validateParameter(valid_613317, JString, required = true,
                                 default = nil)
  if valid_613317 != nil:
    section.add "profilingGroupName", valid_613317
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
  var valid_613318 = header.getOrDefault("X-Amz-Signature")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Signature", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Content-Sha256", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Date")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Date", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Credential")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Credential", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Security-Token")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Security-Token", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Algorithm")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Algorithm", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-SignedHeaders", valid_613324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613325: Call_DeleteProfilingGroup_613314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_613325.validator(path, query, header, formData, body)
  let scheme = call_613325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613325.url(scheme.get, call_613325.host, call_613325.base,
                         call_613325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613325, url, valid)

proc call*(call_613326: Call_DeleteProfilingGroup_613314;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_613327 = newJObject()
  add(path_613327, "profilingGroupName", newJString(profilingGroupName))
  result = call_613326.call(path_613327, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_613314(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_613315, base: "/",
    url: url_DeleteProfilingGroup_613316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_613328 = ref object of OpenApiRestCall_612658
proc url_GetProfile_613330(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProfile_613329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613331 = path.getOrDefault("profilingGroupName")
  valid_613331 = validateParameter(valid_613331, JString, required = true,
                                 default = nil)
  if valid_613331 != nil:
    section.add "profilingGroupName", valid_613331
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
  var valid_613332 = query.getOrDefault("startTime")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "startTime", valid_613332
  var valid_613333 = query.getOrDefault("period")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "period", valid_613333
  var valid_613334 = query.getOrDefault("maxDepth")
  valid_613334 = validateParameter(valid_613334, JInt, required = false, default = nil)
  if valid_613334 != nil:
    section.add "maxDepth", valid_613334
  var valid_613335 = query.getOrDefault("endTime")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "endTime", valid_613335
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
  var valid_613336 = header.getOrDefault("X-Amz-Signature")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Signature", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Content-Sha256", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Date")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Date", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Credential")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Credential", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Security-Token")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Security-Token", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Algorithm")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Algorithm", valid_613341
  var valid_613342 = header.getOrDefault("Accept")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "Accept", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613344: Call_GetProfile_613328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_613344.validator(path, query, header, formData, body)
  let scheme = call_613344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613344.url(scheme.get, call_613344.host, call_613344.base,
                         call_613344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613344, url, valid)

proc call*(call_613345: Call_GetProfile_613328; profilingGroupName: string;
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
  var path_613346 = newJObject()
  var query_613347 = newJObject()
  add(query_613347, "startTime", newJString(startTime))
  add(path_613346, "profilingGroupName", newJString(profilingGroupName))
  add(query_613347, "period", newJString(period))
  add(query_613347, "maxDepth", newJInt(maxDepth))
  add(query_613347, "endTime", newJString(endTime))
  result = call_613345.call(path_613346, query_613347, nil, nil, nil)

var getProfile* = Call_GetProfile_613328(name: "getProfile",
                                      meth: HttpMethod.HttpGet,
                                      host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                      validator: validate_GetProfile_613329,
                                      base: "/", url: url_GetProfile_613330,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_613348 = ref object of OpenApiRestCall_612658
proc url_ListProfileTimes_613350(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfileTimes_613349(path: JsonNode; query: JsonNode;
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
  var valid_613351 = path.getOrDefault("profilingGroupName")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "profilingGroupName", valid_613351
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
  var valid_613352 = query.getOrDefault("endTime")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "endTime", valid_613352
  var valid_613353 = query.getOrDefault("nextToken")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "nextToken", valid_613353
  var valid_613354 = query.getOrDefault("startTime")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = nil)
  if valid_613354 != nil:
    section.add "startTime", valid_613354
  var valid_613368 = query.getOrDefault("orderBy")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = newJString("TimestampAscending"))
  if valid_613368 != nil:
    section.add "orderBy", valid_613368
  var valid_613369 = query.getOrDefault("period")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = newJString("P1D"))
  if valid_613369 != nil:
    section.add "period", valid_613369
  var valid_613370 = query.getOrDefault("maxResults")
  valid_613370 = validateParameter(valid_613370, JInt, required = false, default = nil)
  if valid_613370 != nil:
    section.add "maxResults", valid_613370
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
  var valid_613371 = header.getOrDefault("X-Amz-Signature")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Signature", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Content-Sha256", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Date")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Date", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Credential")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Credential", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Security-Token")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Security-Token", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Algorithm")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Algorithm", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-SignedHeaders", valid_613377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613378: Call_ListProfileTimes_613348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_613378.validator(path, query, header, formData, body)
  let scheme = call_613378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613378.url(scheme.get, call_613378.host, call_613378.base,
                         call_613378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613378, url, valid)

proc call*(call_613379: Call_ListProfileTimes_613348; endTime: string;
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
  var path_613380 = newJObject()
  var query_613381 = newJObject()
  add(query_613381, "endTime", newJString(endTime))
  add(query_613381, "nextToken", newJString(nextToken))
  add(query_613381, "startTime", newJString(startTime))
  add(path_613380, "profilingGroupName", newJString(profilingGroupName))
  add(query_613381, "orderBy", newJString(orderBy))
  add(query_613381, "period", newJString(period))
  add(query_613381, "maxResults", newJInt(maxResults))
  result = call_613379.call(path_613380, query_613381, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_613348(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_613349, base: "/",
    url: url_ListProfileTimes_613350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_613382 = ref object of OpenApiRestCall_612658
proc url_ListProfilingGroups_613384(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfilingGroups_613383(path: JsonNode; query: JsonNode;
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
  var valid_613385 = query.getOrDefault("nextToken")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "nextToken", valid_613385
  var valid_613386 = query.getOrDefault("includeDescription")
  valid_613386 = validateParameter(valid_613386, JBool, required = false, default = nil)
  if valid_613386 != nil:
    section.add "includeDescription", valid_613386
  var valid_613387 = query.getOrDefault("maxResults")
  valid_613387 = validateParameter(valid_613387, JInt, required = false, default = nil)
  if valid_613387 != nil:
    section.add "maxResults", valid_613387
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
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_ListProfilingGroups_613382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_ListProfilingGroups_613382; nextToken: string = "";
          includeDescription: bool = false; maxResults: int = 0): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var query_613397 = newJObject()
  add(query_613397, "nextToken", newJString(nextToken))
  add(query_613397, "includeDescription", newJBool(includeDescription))
  add(query_613397, "maxResults", newJInt(maxResults))
  result = call_613396.call(nil, query_613397, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_613382(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_613383, base: "/",
    url: url_ListProfilingGroups_613384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_613398 = ref object of OpenApiRestCall_612658
proc url_PostAgentProfile_613400(protocol: Scheme; host: string; base: string;
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

proc validate_PostAgentProfile_613399(path: JsonNode; query: JsonNode;
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
  var valid_613401 = path.getOrDefault("profilingGroupName")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "profilingGroupName", valid_613401
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_613402 = query.getOrDefault("profileToken")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "profileToken", valid_613402
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
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_613408 = header.getOrDefault("Content-Type")
  valid_613408 = validateParameter(valid_613408, JString, required = true,
                                 default = nil)
  if valid_613408 != nil:
    section.add "Content-Type", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_PostAgentProfile_613398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_PostAgentProfile_613398; profilingGroupName: string;
          body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_613414 = newJObject()
  var query_613415 = newJObject()
  var body_613416 = newJObject()
  add(path_613414, "profilingGroupName", newJString(profilingGroupName))
  add(query_613415, "profileToken", newJString(profileToken))
  if body != nil:
    body_613416 = body
  result = call_613413.call(path_613414, query_613415, nil, nil, body_613416)

var postAgentProfile* = Call_PostAgentProfile_613398(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_613399, base: "/",
    url: url_PostAgentProfile_613400, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
