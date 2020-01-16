
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
  Call_ConfigureAgent_605927 = ref object of OpenApiRestCall_605589
proc url_ConfigureAgent_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ConfigureAgent_605928(path: JsonNode; query: JsonNode;
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
  var valid_606055 = path.getOrDefault("profilingGroupName")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "profilingGroupName", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_ConfigureAgent_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_ConfigureAgent_605927; profilingGroupName: string;
          body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_606158 = newJObject()
  var body_606160 = newJObject()
  add(path_606158, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_606160 = body
  result = call_606157.call(path_606158, nil, nil, nil, body_606160)

var configureAgent* = Call_ConfigureAgent_605927(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_605928, base: "/", url: url_ConfigureAgent_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_606199 = ref object of OpenApiRestCall_605589
proc url_CreateProfilingGroup_606201(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfilingGroup_606200(path: JsonNode; query: JsonNode;
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
  var valid_606202 = query.getOrDefault("clientToken")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "clientToken", valid_606202
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
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_CreateProfilingGroup_606199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a profiling group.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_CreateProfilingGroup_606199; body: JsonNode;
          clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
  ##              : Client token for the request.
  var query_606213 = newJObject()
  var body_606214 = newJObject()
  if body != nil:
    body_606214 = body
  add(query_606213, "clientToken", newJString(clientToken))
  result = call_606212.call(nil, query_606213, nil, nil, body_606214)

var createProfilingGroup* = Call_CreateProfilingGroup_606199(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_606200, base: "/",
    url: url_CreateProfilingGroup_606201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_606229 = ref object of OpenApiRestCall_605589
proc url_UpdateProfilingGroup_606231(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfilingGroup_606230(path: JsonNode; query: JsonNode;
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
  var valid_606232 = path.getOrDefault("profilingGroupName")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "profilingGroupName", valid_606232
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
  var valid_606233 = header.getOrDefault("X-Amz-Signature")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Signature", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Content-Sha256", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Date")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Date", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Credential")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Credential", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Security-Token")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Security-Token", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Algorithm")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Algorithm", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-SignedHeaders", valid_606239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_UpdateProfilingGroup_606229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a profiling group.
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_UpdateProfilingGroup_606229;
          profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   body: JObject (required)
  var path_606243 = newJObject()
  var body_606244 = newJObject()
  add(path_606243, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_606244 = body
  result = call_606242.call(path_606243, nil, nil, nil, body_606244)

var updateProfilingGroup* = Call_UpdateProfilingGroup_606229(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_606230, base: "/",
    url: url_UpdateProfilingGroup_606231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_606215 = ref object of OpenApiRestCall_605589
proc url_DescribeProfilingGroup_606217(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProfilingGroup_606216(path: JsonNode; query: JsonNode;
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
  var valid_606218 = path.getOrDefault("profilingGroupName")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "profilingGroupName", valid_606218
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_DescribeProfilingGroup_606215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a profiling group.
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_DescribeProfilingGroup_606215;
          profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_606228 = newJObject()
  add(path_606228, "profilingGroupName", newJString(profilingGroupName))
  result = call_606227.call(path_606228, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_606215(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_606216, base: "/",
    url: url_DescribeProfilingGroup_606217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_606245 = ref object of OpenApiRestCall_605589
proc url_DeleteProfilingGroup_606247(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfilingGroup_606246(path: JsonNode; query: JsonNode;
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
  var valid_606248 = path.getOrDefault("profilingGroupName")
  valid_606248 = validateParameter(valid_606248, JString, required = true,
                                 default = nil)
  if valid_606248 != nil:
    section.add "profilingGroupName", valid_606248
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
  var valid_606249 = header.getOrDefault("X-Amz-Signature")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Signature", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Content-Sha256", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Date")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Date", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Credential")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Credential", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Security-Token")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Security-Token", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Algorithm")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Algorithm", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-SignedHeaders", valid_606255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606256: Call_DeleteProfilingGroup_606245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a profiling group.
  ## 
  let valid = call_606256.validator(path, query, header, formData, body)
  let scheme = call_606256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606256.url(scheme.get, call_606256.host, call_606256.base,
                         call_606256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606256, url, valid)

proc call*(call_606257: Call_DeleteProfilingGroup_606245;
          profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  var path_606258 = newJObject()
  add(path_606258, "profilingGroupName", newJString(profilingGroupName))
  result = call_606257.call(path_606258, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_606245(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_606246, base: "/",
    url: url_DeleteProfilingGroup_606247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_606259 = ref object of OpenApiRestCall_605589
proc url_GetProfile_606261(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProfile_606260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606262 = path.getOrDefault("profilingGroupName")
  valid_606262 = validateParameter(valid_606262, JString, required = true,
                                 default = nil)
  if valid_606262 != nil:
    section.add "profilingGroupName", valid_606262
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
  var valid_606263 = query.getOrDefault("startTime")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "startTime", valid_606263
  var valid_606264 = query.getOrDefault("period")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "period", valid_606264
  var valid_606265 = query.getOrDefault("maxDepth")
  valid_606265 = validateParameter(valid_606265, JInt, required = false, default = nil)
  if valid_606265 != nil:
    section.add "maxDepth", valid_606265
  var valid_606266 = query.getOrDefault("endTime")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "endTime", valid_606266
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
  var valid_606267 = header.getOrDefault("X-Amz-Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Signature", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Content-Sha256", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Date")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Date", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Credential")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Credential", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Security-Token")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Security-Token", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Algorithm")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Algorithm", valid_606272
  var valid_606273 = header.getOrDefault("Accept")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "Accept", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606275: Call_GetProfile_606259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ## 
  let valid = call_606275.validator(path, query, header, formData, body)
  let scheme = call_606275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606275.url(scheme.get, call_606275.host, call_606275.base,
                         call_606275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606275, url, valid)

proc call*(call_606276: Call_GetProfile_606259; profilingGroupName: string;
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
  var path_606277 = newJObject()
  var query_606278 = newJObject()
  add(query_606278, "startTime", newJString(startTime))
  add(path_606277, "profilingGroupName", newJString(profilingGroupName))
  add(query_606278, "period", newJString(period))
  add(query_606278, "maxDepth", newJInt(maxDepth))
  add(query_606278, "endTime", newJString(endTime))
  result = call_606276.call(path_606277, query_606278, nil, nil, nil)

var getProfile* = Call_GetProfile_606259(name: "getProfile",
                                      meth: HttpMethod.HttpGet,
                                      host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profile",
                                      validator: validate_GetProfile_606260,
                                      base: "/", url: url_GetProfile_606261,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_606279 = ref object of OpenApiRestCall_605589
proc url_ListProfileTimes_606281(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfileTimes_606280(path: JsonNode; query: JsonNode;
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
  var valid_606282 = path.getOrDefault("profilingGroupName")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "profilingGroupName", valid_606282
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
  var valid_606283 = query.getOrDefault("endTime")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "endTime", valid_606283
  var valid_606284 = query.getOrDefault("nextToken")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "nextToken", valid_606284
  var valid_606285 = query.getOrDefault("startTime")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = nil)
  if valid_606285 != nil:
    section.add "startTime", valid_606285
  var valid_606299 = query.getOrDefault("orderBy")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = newJString("TimestampAscending"))
  if valid_606299 != nil:
    section.add "orderBy", valid_606299
  var valid_606300 = query.getOrDefault("period")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = newJString("P1D"))
  if valid_606300 != nil:
    section.add "period", valid_606300
  var valid_606301 = query.getOrDefault("maxResults")
  valid_606301 = validateParameter(valid_606301, JInt, required = false, default = nil)
  if valid_606301 != nil:
    section.add "maxResults", valid_606301
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
  var valid_606302 = header.getOrDefault("X-Amz-Signature")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Signature", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Content-Sha256", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Date")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Date", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Credential")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Credential", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Security-Token")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Security-Token", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Algorithm")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Algorithm", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-SignedHeaders", valid_606308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606309: Call_ListProfileTimes_606279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ## 
  let valid = call_606309.validator(path, query, header, formData, body)
  let scheme = call_606309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606309.url(scheme.get, call_606309.host, call_606309.base,
                         call_606309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606309, url, valid)

proc call*(call_606310: Call_ListProfileTimes_606279; endTime: string;
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
  var path_606311 = newJObject()
  var query_606312 = newJObject()
  add(query_606312, "endTime", newJString(endTime))
  add(query_606312, "nextToken", newJString(nextToken))
  add(query_606312, "startTime", newJString(startTime))
  add(path_606311, "profilingGroupName", newJString(profilingGroupName))
  add(query_606312, "orderBy", newJString(orderBy))
  add(query_606312, "period", newJString(period))
  add(query_606312, "maxResults", newJInt(maxResults))
  result = call_606310.call(path_606311, query_606312, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_606279(name: "listProfileTimes",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_606280, base: "/",
    url: url_ListProfileTimes_606281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_606313 = ref object of OpenApiRestCall_605589
proc url_ListProfilingGroups_606315(protocol: Scheme; host: string; base: string;
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

proc validate_ListProfilingGroups_606314(path: JsonNode; query: JsonNode;
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
  var valid_606316 = query.getOrDefault("nextToken")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "nextToken", valid_606316
  var valid_606317 = query.getOrDefault("includeDescription")
  valid_606317 = validateParameter(valid_606317, JBool, required = false, default = nil)
  if valid_606317 != nil:
    section.add "includeDescription", valid_606317
  var valid_606318 = query.getOrDefault("maxResults")
  valid_606318 = validateParameter(valid_606318, JInt, required = false, default = nil)
  if valid_606318 != nil:
    section.add "maxResults", valid_606318
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
  var valid_606319 = header.getOrDefault("X-Amz-Signature")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Signature", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Content-Sha256", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Date")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Date", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Credential")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Credential", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Security-Token")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Security-Token", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Algorithm")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Algorithm", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-SignedHeaders", valid_606325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_ListProfilingGroups_606313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List profiling groups in the account.
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_ListProfilingGroups_606313; nextToken: string = "";
          includeDescription: bool = false; maxResults: int = 0): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   nextToken: string
  ##            : Token for paginating results.
  ##   includeDescription: bool
  ##                     : If set to true, returns the full description of the profiling groups instead of the names. Defaults to false.
  ##   maxResults: int
  ##             : Upper bound on the number of results to list in a single call.
  var query_606328 = newJObject()
  add(query_606328, "nextToken", newJString(nextToken))
  add(query_606328, "includeDescription", newJBool(includeDescription))
  add(query_606328, "maxResults", newJInt(maxResults))
  result = call_606327.call(nil, query_606328, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_606313(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_606314, base: "/",
    url: url_ListProfilingGroups_606315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_606329 = ref object of OpenApiRestCall_605589
proc url_PostAgentProfile_606331(protocol: Scheme; host: string; base: string;
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

proc validate_PostAgentProfile_606330(path: JsonNode; query: JsonNode;
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
  var valid_606332 = path.getOrDefault("profilingGroupName")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "profilingGroupName", valid_606332
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
  ##               : Client token for the request.
  section = newJObject()
  var valid_606333 = query.getOrDefault("profileToken")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "profileToken", valid_606333
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
  var valid_606334 = header.getOrDefault("X-Amz-Signature")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Signature", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Content-Sha256", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Date")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Date", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Credential")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Credential", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Security-Token")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Security-Token", valid_606338
  assert header != nil,
        "header argument is necessary due to required `Content-Type` field"
  var valid_606339 = header.getOrDefault("Content-Type")
  valid_606339 = validateParameter(valid_606339, JString, required = true,
                                 default = nil)
  if valid_606339 != nil:
    section.add "Content-Type", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_PostAgentProfile_606329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_PostAgentProfile_606329; profilingGroupName: string;
          body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   profilingGroupName: string (required)
  ##                     : The name of the profiling group.
  ##   profileToken: string
  ##               : Client token for the request.
  ##   body: JObject (required)
  var path_606345 = newJObject()
  var query_606346 = newJObject()
  var body_606347 = newJObject()
  add(path_606345, "profilingGroupName", newJString(profilingGroupName))
  add(query_606346, "profileToken", newJString(profileToken))
  if body != nil:
    body_606347 = body
  result = call_606344.call(path_606345, query_606346, nil, nil, body_606347)

var postAgentProfile* = Call_PostAgentProfile_606329(name: "postAgentProfile",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_606330, base: "/",
    url: url_PostAgentProfile_606331, schemes: {Scheme.Https, Scheme.Http})
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
