
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Device Farm
## version: 2015-06-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Welcome to the AWS Device Farm API documentation, which contains APIs for:</p> <ul> <li> <p>Testing on desktop browsers</p> <p> Device Farm makes it possible for you to test your web applications on desktop browsers using Selenium. The APIs for desktop browser testing contain <code>TestGrid</code> in their names. For more information, see <a href="https://docs.aws.amazon.com/devicefarm/latest/testgrid/">Testing Web Applications on Selenium with Device Farm</a>.</p> </li> <li> <p>Testing on real mobile devices</p> <p>Device Farm makes it possible for you to test apps on physical phones, tablets, and other devices in the cloud. For more information, see the <a href="https://docs.aws.amazon.com/devicefarm/latest/developerguide/">Device Farm Developer Guide</a>.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/devicefarm/
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

  OpenApiRestCall_610659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610659): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "devicefarm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "devicefarm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "devicefarm.us-west-2.amazonaws.com",
                           "eu-west-2": "devicefarm.eu-west-2.amazonaws.com", "ap-northeast-3": "devicefarm.ap-northeast-3.amazonaws.com", "eu-central-1": "devicefarm.eu-central-1.amazonaws.com",
                           "us-east-2": "devicefarm.us-east-2.amazonaws.com",
                           "us-east-1": "devicefarm.us-east-1.amazonaws.com", "cn-northwest-1": "devicefarm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "devicefarm.ap-south-1.amazonaws.com",
                           "eu-north-1": "devicefarm.eu-north-1.amazonaws.com", "ap-northeast-2": "devicefarm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "devicefarm.us-west-1.amazonaws.com", "us-gov-east-1": "devicefarm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "devicefarm.eu-west-3.amazonaws.com", "cn-north-1": "devicefarm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "devicefarm.sa-east-1.amazonaws.com",
                           "eu-west-1": "devicefarm.eu-west-1.amazonaws.com", "us-gov-west-1": "devicefarm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "devicefarm.ap-southeast-2.amazonaws.com", "ca-central-1": "devicefarm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "devicefarm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "devicefarm.ap-southeast-1.amazonaws.com",
      "us-west-2": "devicefarm.us-west-2.amazonaws.com",
      "eu-west-2": "devicefarm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "devicefarm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "devicefarm.eu-central-1.amazonaws.com",
      "us-east-2": "devicefarm.us-east-2.amazonaws.com",
      "us-east-1": "devicefarm.us-east-1.amazonaws.com",
      "cn-northwest-1": "devicefarm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "devicefarm.ap-south-1.amazonaws.com",
      "eu-north-1": "devicefarm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "devicefarm.ap-northeast-2.amazonaws.com",
      "us-west-1": "devicefarm.us-west-1.amazonaws.com",
      "us-gov-east-1": "devicefarm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "devicefarm.eu-west-3.amazonaws.com",
      "cn-north-1": "devicefarm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "devicefarm.sa-east-1.amazonaws.com",
      "eu-west-1": "devicefarm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "devicefarm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "devicefarm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "devicefarm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "devicefarm"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDevicePool_610997 = ref object of OpenApiRestCall_610659
proc url_CreateDevicePool_610999(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevicePool_610998(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a device pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611124 = header.getOrDefault("X-Amz-Target")
  valid_611124 = validateParameter(valid_611124, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_611124 != nil:
    section.add "X-Amz-Target", valid_611124
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

proc call*(call_611155: Call_CreateDevicePool_610997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_CreateDevicePool_610997; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_611227 = newJObject()
  if body != nil:
    body_611227 = body
  result = call_611226.call(nil, nil, nil, nil, body_611227)

var createDevicePool* = Call_CreateDevicePool_610997(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_610998, base: "/",
    url: url_CreateDevicePool_610999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_611266 = ref object of OpenApiRestCall_610659
proc url_CreateInstanceProfile_611268(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceProfile_611267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611269 = header.getOrDefault("X-Amz-Target")
  valid_611269 = validateParameter(valid_611269, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_611269 != nil:
    section.add "X-Amz-Target", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611278: Call_CreateInstanceProfile_611266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_611278.validator(path, query, header, formData, body)
  let scheme = call_611278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611278.url(scheme.get, call_611278.host, call_611278.base,
                         call_611278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611278, url, valid)

proc call*(call_611279: Call_CreateInstanceProfile_611266; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_611280 = newJObject()
  if body != nil:
    body_611280 = body
  result = call_611279.call(nil, nil, nil, nil, body_611280)

var createInstanceProfile* = Call_CreateInstanceProfile_611266(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_611267, base: "/",
    url: url_CreateInstanceProfile_611268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_611281 = ref object of OpenApiRestCall_610659
proc url_CreateNetworkProfile_611283(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_611282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a network profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611284 = header.getOrDefault("X-Amz-Target")
  valid_611284 = validateParameter(valid_611284, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_611284 != nil:
    section.add "X-Amz-Target", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Signature")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Signature", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Content-Sha256", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Date")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Date", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Credential")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Credential", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Security-Token")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Security-Token", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Algorithm")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Algorithm", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-SignedHeaders", valid_611291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611293: Call_CreateNetworkProfile_611281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_611293.validator(path, query, header, formData, body)
  let scheme = call_611293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611293.url(scheme.get, call_611293.host, call_611293.base,
                         call_611293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611293, url, valid)

proc call*(call_611294: Call_CreateNetworkProfile_611281; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_611295 = newJObject()
  if body != nil:
    body_611295 = body
  result = call_611294.call(nil, nil, nil, nil, body_611295)

var createNetworkProfile* = Call_CreateNetworkProfile_611281(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_611282, base: "/",
    url: url_CreateNetworkProfile_611283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_611296 = ref object of OpenApiRestCall_610659
proc url_CreateProject_611298(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_611297(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611299 = header.getOrDefault("X-Amz-Target")
  valid_611299 = validateParameter(valid_611299, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_611299 != nil:
    section.add "X-Amz-Target", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Signature")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Signature", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Content-Sha256", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Date")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Date", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Credential")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Credential", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Security-Token")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Security-Token", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Algorithm")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Algorithm", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-SignedHeaders", valid_611306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611308: Call_CreateProject_611296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a project.
  ## 
  let valid = call_611308.validator(path, query, header, formData, body)
  let scheme = call_611308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611308.url(scheme.get, call_611308.host, call_611308.base,
                         call_611308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611308, url, valid)

proc call*(call_611309: Call_CreateProject_611296; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_611310 = newJObject()
  if body != nil:
    body_611310 = body
  result = call_611309.call(nil, nil, nil, nil, body_611310)

var createProject* = Call_CreateProject_611296(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_611297, base: "/", url: url_CreateProject_611298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_611311 = ref object of OpenApiRestCall_610659
proc url_CreateRemoteAccessSession_611313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRemoteAccessSession_611312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specifies and starts a remote access session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611314 = header.getOrDefault("X-Amz-Target")
  valid_611314 = validateParameter(valid_611314, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_611314 != nil:
    section.add "X-Amz-Target", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Signature")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Signature", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Content-Sha256", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Date")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Date", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Credential")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Credential", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Security-Token")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Security-Token", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Algorithm")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Algorithm", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-SignedHeaders", valid_611321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611323: Call_CreateRemoteAccessSession_611311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_611323.validator(path, query, header, formData, body)
  let scheme = call_611323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611323.url(scheme.get, call_611323.host, call_611323.base,
                         call_611323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611323, url, valid)

proc call*(call_611324: Call_CreateRemoteAccessSession_611311; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_611325 = newJObject()
  if body != nil:
    body_611325 = body
  result = call_611324.call(nil, nil, nil, nil, body_611325)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_611311(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_611312, base: "/",
    url: url_CreateRemoteAccessSession_611313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_611326 = ref object of OpenApiRestCall_610659
proc url_CreateTestGridProject_611328(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridProject_611327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611329 = header.getOrDefault("X-Amz-Target")
  valid_611329 = validateParameter(valid_611329, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_611329 != nil:
    section.add "X-Amz-Target", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Signature")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Signature", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Content-Sha256", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Date")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Date", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Credential")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Credential", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Security-Token")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Security-Token", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Algorithm")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Algorithm", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-SignedHeaders", valid_611336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611338: Call_CreateTestGridProject_611326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  let valid = call_611338.validator(path, query, header, formData, body)
  let scheme = call_611338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611338.url(scheme.get, call_611338.host, call_611338.base,
                         call_611338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611338, url, valid)

proc call*(call_611339: Call_CreateTestGridProject_611326; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   body: JObject (required)
  var body_611340 = newJObject()
  if body != nil:
    body_611340 = body
  result = call_611339.call(nil, nil, nil, nil, body_611340)

var createTestGridProject* = Call_CreateTestGridProject_611326(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_611327, base: "/",
    url: url_CreateTestGridProject_611328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_611341 = ref object of OpenApiRestCall_610659
proc url_CreateTestGridUrl_611343(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridUrl_611342(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611344 = header.getOrDefault("X-Amz-Target")
  valid_611344 = validateParameter(valid_611344, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_611344 != nil:
    section.add "X-Amz-Target", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Signature")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Signature", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Content-Sha256", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Date")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Date", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Credential")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Credential", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Security-Token")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Security-Token", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Algorithm")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Algorithm", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-SignedHeaders", valid_611351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611353: Call_CreateTestGridUrl_611341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  let valid = call_611353.validator(path, query, header, formData, body)
  let scheme = call_611353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611353.url(scheme.get, call_611353.host, call_611353.base,
                         call_611353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611353, url, valid)

proc call*(call_611354: Call_CreateTestGridUrl_611341; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   body: JObject (required)
  var body_611355 = newJObject()
  if body != nil:
    body_611355 = body
  result = call_611354.call(nil, nil, nil, nil, body_611355)

var createTestGridUrl* = Call_CreateTestGridUrl_611341(name: "createTestGridUrl",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_611342, base: "/",
    url: url_CreateTestGridUrl_611343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_611356 = ref object of OpenApiRestCall_610659
proc url_CreateUpload_611358(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUpload_611357(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Uploads an app or test scripts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611359 = header.getOrDefault("X-Amz-Target")
  valid_611359 = validateParameter(valid_611359, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_611359 != nil:
    section.add "X-Amz-Target", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Signature")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Signature", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Content-Sha256", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Date")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Date", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Credential")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Credential", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Security-Token")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Security-Token", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Algorithm")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Algorithm", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-SignedHeaders", valid_611366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611368: Call_CreateUpload_611356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_611368.validator(path, query, header, formData, body)
  let scheme = call_611368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611368.url(scheme.get, call_611368.host, call_611368.base,
                         call_611368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611368, url, valid)

proc call*(call_611369: Call_CreateUpload_611356; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_611370 = newJObject()
  if body != nil:
    body_611370 = body
  result = call_611369.call(nil, nil, nil, nil, body_611370)

var createUpload* = Call_CreateUpload_611356(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_611357, base: "/", url: url_CreateUpload_611358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_611371 = ref object of OpenApiRestCall_610659
proc url_CreateVPCEConfiguration_611373(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVPCEConfiguration_611372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611374 = header.getOrDefault("X-Amz-Target")
  valid_611374 = validateParameter(valid_611374, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_611374 != nil:
    section.add "X-Amz-Target", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Signature")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Signature", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Content-Sha256", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Date")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Date", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Credential")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Credential", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Security-Token")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Security-Token", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Algorithm")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Algorithm", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-SignedHeaders", valid_611381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611383: Call_CreateVPCEConfiguration_611371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_611383.validator(path, query, header, formData, body)
  let scheme = call_611383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611383.url(scheme.get, call_611383.host, call_611383.base,
                         call_611383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611383, url, valid)

proc call*(call_611384: Call_CreateVPCEConfiguration_611371; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_611385 = newJObject()
  if body != nil:
    body_611385 = body
  result = call_611384.call(nil, nil, nil, nil, body_611385)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_611371(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_611372, base: "/",
    url: url_CreateVPCEConfiguration_611373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_611386 = ref object of OpenApiRestCall_610659
proc url_DeleteDevicePool_611388(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevicePool_611387(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611389 = header.getOrDefault("X-Amz-Target")
  valid_611389 = validateParameter(valid_611389, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_611389 != nil:
    section.add "X-Amz-Target", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Signature")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Signature", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Content-Sha256", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Date")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Date", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Credential")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Credential", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Security-Token")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Security-Token", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Algorithm")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Algorithm", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-SignedHeaders", valid_611396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611398: Call_DeleteDevicePool_611386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_611398.validator(path, query, header, formData, body)
  let scheme = call_611398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611398.url(scheme.get, call_611398.host, call_611398.base,
                         call_611398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611398, url, valid)

proc call*(call_611399: Call_DeleteDevicePool_611386; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_611400 = newJObject()
  if body != nil:
    body_611400 = body
  result = call_611399.call(nil, nil, nil, nil, body_611400)

var deleteDevicePool* = Call_DeleteDevicePool_611386(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_611387, base: "/",
    url: url_DeleteDevicePool_611388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_611401 = ref object of OpenApiRestCall_610659
proc url_DeleteInstanceProfile_611403(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceProfile_611402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611404 = header.getOrDefault("X-Amz-Target")
  valid_611404 = validateParameter(valid_611404, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_611404 != nil:
    section.add "X-Amz-Target", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Signature")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Signature", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Content-Sha256", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Date")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Date", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Credential")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Credential", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Security-Token")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Security-Token", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Algorithm")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Algorithm", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-SignedHeaders", valid_611411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611413: Call_DeleteInstanceProfile_611401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_611413.validator(path, query, header, formData, body)
  let scheme = call_611413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611413.url(scheme.get, call_611413.host, call_611413.base,
                         call_611413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611413, url, valid)

proc call*(call_611414: Call_DeleteInstanceProfile_611401; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_611415 = newJObject()
  if body != nil:
    body_611415 = body
  result = call_611414.call(nil, nil, nil, nil, body_611415)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_611401(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_611402, base: "/",
    url: url_DeleteInstanceProfile_611403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_611416 = ref object of OpenApiRestCall_610659
proc url_DeleteNetworkProfile_611418(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_611417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a network profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611419 = header.getOrDefault("X-Amz-Target")
  valid_611419 = validateParameter(valid_611419, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_611419 != nil:
    section.add "X-Amz-Target", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Signature")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Signature", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Content-Sha256", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Date")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Date", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Credential")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Credential", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Security-Token")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Security-Token", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Algorithm")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Algorithm", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-SignedHeaders", valid_611426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611428: Call_DeleteNetworkProfile_611416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_611428.validator(path, query, header, formData, body)
  let scheme = call_611428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611428.url(scheme.get, call_611428.host, call_611428.base,
                         call_611428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611428, url, valid)

proc call*(call_611429: Call_DeleteNetworkProfile_611416; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_611430 = newJObject()
  if body != nil:
    body_611430 = body
  result = call_611429.call(nil, nil, nil, nil, body_611430)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_611416(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_611417, base: "/",
    url: url_DeleteNetworkProfile_611418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_611431 = ref object of OpenApiRestCall_610659
proc url_DeleteProject_611433(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_611432(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611434 = header.getOrDefault("X-Amz-Target")
  valid_611434 = validateParameter(valid_611434, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_611434 != nil:
    section.add "X-Amz-Target", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Signature")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Signature", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Content-Sha256", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Date")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Date", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Credential")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Credential", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Security-Token")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Security-Token", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Algorithm")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Algorithm", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-SignedHeaders", valid_611441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611443: Call_DeleteProject_611431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_611443.validator(path, query, header, formData, body)
  let scheme = call_611443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611443.url(scheme.get, call_611443.host, call_611443.base,
                         call_611443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611443, url, valid)

proc call*(call_611444: Call_DeleteProject_611431; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_611445 = newJObject()
  if body != nil:
    body_611445 = body
  result = call_611444.call(nil, nil, nil, nil, body_611445)

var deleteProject* = Call_DeleteProject_611431(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_611432, base: "/", url: url_DeleteProject_611433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_611446 = ref object of OpenApiRestCall_610659
proc url_DeleteRemoteAccessSession_611448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_611447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a completed remote access session and its results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611449 = header.getOrDefault("X-Amz-Target")
  valid_611449 = validateParameter(valid_611449, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_611449 != nil:
    section.add "X-Amz-Target", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Signature", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Content-Sha256", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Date")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Date", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Credential")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Credential", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Security-Token")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Security-Token", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Algorithm")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Algorithm", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-SignedHeaders", valid_611456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_DeleteRemoteAccessSession_611446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_DeleteRemoteAccessSession_611446; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_611460 = newJObject()
  if body != nil:
    body_611460 = body
  result = call_611459.call(nil, nil, nil, nil, body_611460)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_611446(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_611447, base: "/",
    url: url_DeleteRemoteAccessSession_611448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_611461 = ref object of OpenApiRestCall_610659
proc url_DeleteRun_611463(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_611462(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611464 = header.getOrDefault("X-Amz-Target")
  valid_611464 = validateParameter(valid_611464, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_611464 != nil:
    section.add "X-Amz-Target", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Signature")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Signature", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Content-Sha256", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Date")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Date", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Credential")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Credential", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Security-Token")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Security-Token", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Algorithm")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Algorithm", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-SignedHeaders", valid_611471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611473: Call_DeleteRun_611461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_611473.validator(path, query, header, formData, body)
  let scheme = call_611473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611473.url(scheme.get, call_611473.host, call_611473.base,
                         call_611473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611473, url, valid)

proc call*(call_611474: Call_DeleteRun_611461; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_611475 = newJObject()
  if body != nil:
    body_611475 = body
  result = call_611474.call(nil, nil, nil, nil, body_611475)

var deleteRun* = Call_DeleteRun_611461(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_611462,
                                    base: "/", url: url_DeleteRun_611463,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_611476 = ref object of OpenApiRestCall_610659
proc url_DeleteTestGridProject_611478(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTestGridProject_611477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611479 = header.getOrDefault("X-Amz-Target")
  valid_611479 = validateParameter(valid_611479, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_611479 != nil:
    section.add "X-Amz-Target", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Signature")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Signature", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Content-Sha256", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Date")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Date", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Credential")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Credential", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Security-Token")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Security-Token", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Algorithm")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Algorithm", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-SignedHeaders", valid_611486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_DeleteTestGridProject_611476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_DeleteTestGridProject_611476; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   body: JObject (required)
  var body_611490 = newJObject()
  if body != nil:
    body_611490 = body
  result = call_611489.call(nil, nil, nil, nil, body_611490)

var deleteTestGridProject* = Call_DeleteTestGridProject_611476(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_611477, base: "/",
    url: url_DeleteTestGridProject_611478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_611491 = ref object of OpenApiRestCall_610659
proc url_DeleteUpload_611493(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUpload_611492(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an upload given the upload ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611494 = header.getOrDefault("X-Amz-Target")
  valid_611494 = validateParameter(valid_611494, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_611494 != nil:
    section.add "X-Amz-Target", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Signature")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Signature", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Content-Sha256", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Date")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Date", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Credential")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Credential", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Security-Token")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Security-Token", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Algorithm")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Algorithm", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-SignedHeaders", valid_611501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611503: Call_DeleteUpload_611491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_611503.validator(path, query, header, formData, body)
  let scheme = call_611503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611503.url(scheme.get, call_611503.host, call_611503.base,
                         call_611503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611503, url, valid)

proc call*(call_611504: Call_DeleteUpload_611491; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_611505 = newJObject()
  if body != nil:
    body_611505 = body
  result = call_611504.call(nil, nil, nil, nil, body_611505)

var deleteUpload* = Call_DeleteUpload_611491(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_611492, base: "/", url: url_DeleteUpload_611493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_611506 = ref object of OpenApiRestCall_610659
proc url_DeleteVPCEConfiguration_611508(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVPCEConfiguration_611507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611509 = header.getOrDefault("X-Amz-Target")
  valid_611509 = validateParameter(valid_611509, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_611509 != nil:
    section.add "X-Amz-Target", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Signature")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Signature", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Content-Sha256", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Date")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Date", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Credential")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Credential", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Security-Token")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Security-Token", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Algorithm")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Algorithm", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-SignedHeaders", valid_611516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611518: Call_DeleteVPCEConfiguration_611506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_611518.validator(path, query, header, formData, body)
  let scheme = call_611518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611518.url(scheme.get, call_611518.host, call_611518.base,
                         call_611518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611518, url, valid)

proc call*(call_611519: Call_DeleteVPCEConfiguration_611506; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_611520 = newJObject()
  if body != nil:
    body_611520 = body
  result = call_611519.call(nil, nil, nil, nil, body_611520)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_611506(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_611507, base: "/",
    url: url_DeleteVPCEConfiguration_611508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_611521 = ref object of OpenApiRestCall_610659
proc url_GetAccountSettings_611523(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_611522(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611524 = header.getOrDefault("X-Amz-Target")
  valid_611524 = validateParameter(valid_611524, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_611524 != nil:
    section.add "X-Amz-Target", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Signature")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Signature", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Content-Sha256", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Date")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Date", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Credential")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Credential", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Security-Token")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Security-Token", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Algorithm")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Algorithm", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-SignedHeaders", valid_611531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611533: Call_GetAccountSettings_611521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_611533.validator(path, query, header, formData, body)
  let scheme = call_611533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611533.url(scheme.get, call_611533.host, call_611533.base,
                         call_611533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611533, url, valid)

proc call*(call_611534: Call_GetAccountSettings_611521; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_611535 = newJObject()
  if body != nil:
    body_611535 = body
  result = call_611534.call(nil, nil, nil, nil, body_611535)

var getAccountSettings* = Call_GetAccountSettings_611521(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_611522, base: "/",
    url: url_GetAccountSettings_611523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_611536 = ref object of OpenApiRestCall_610659
proc url_GetDevice_611538(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_611537(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a unique device type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611539 = header.getOrDefault("X-Amz-Target")
  valid_611539 = validateParameter(valid_611539, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_611539 != nil:
    section.add "X-Amz-Target", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Signature")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Signature", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Content-Sha256", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Date")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Date", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Credential")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Credential", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Security-Token")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Security-Token", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Algorithm")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Algorithm", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-SignedHeaders", valid_611546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611548: Call_GetDevice_611536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_611548.validator(path, query, header, formData, body)
  let scheme = call_611548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611548.url(scheme.get, call_611548.host, call_611548.base,
                         call_611548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611548, url, valid)

proc call*(call_611549: Call_GetDevice_611536; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_611550 = newJObject()
  if body != nil:
    body_611550 = body
  result = call_611549.call(nil, nil, nil, nil, body_611550)

var getDevice* = Call_GetDevice_611536(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_611537,
                                    base: "/", url: url_GetDevice_611538,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_611551 = ref object of OpenApiRestCall_610659
proc url_GetDeviceInstance_611553(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeviceInstance_611552(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611554 = header.getOrDefault("X-Amz-Target")
  valid_611554 = validateParameter(valid_611554, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_611554 != nil:
    section.add "X-Amz-Target", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Signature")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Signature", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Content-Sha256", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Date")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Date", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Credential")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Credential", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Security-Token")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Security-Token", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Algorithm")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Algorithm", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-SignedHeaders", valid_611561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611563: Call_GetDeviceInstance_611551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  let valid = call_611563.validator(path, query, header, formData, body)
  let scheme = call_611563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611563.url(scheme.get, call_611563.host, call_611563.base,
                         call_611563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611563, url, valid)

proc call*(call_611564: Call_GetDeviceInstance_611551; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   body: JObject (required)
  var body_611565 = newJObject()
  if body != nil:
    body_611565 = body
  result = call_611564.call(nil, nil, nil, nil, body_611565)

var getDeviceInstance* = Call_GetDeviceInstance_611551(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_611552, base: "/",
    url: url_GetDeviceInstance_611553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_611566 = ref object of OpenApiRestCall_610659
proc url_GetDevicePool_611568(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePool_611567(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a device pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611569 = header.getOrDefault("X-Amz-Target")
  valid_611569 = validateParameter(valid_611569, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_611569 != nil:
    section.add "X-Amz-Target", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Signature")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Signature", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Content-Sha256", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Date")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Date", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Credential")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Credential", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Security-Token")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Security-Token", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Algorithm")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Algorithm", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-SignedHeaders", valid_611576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611578: Call_GetDevicePool_611566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_611578.validator(path, query, header, formData, body)
  let scheme = call_611578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611578.url(scheme.get, call_611578.host, call_611578.base,
                         call_611578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611578, url, valid)

proc call*(call_611579: Call_GetDevicePool_611566; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_611580 = newJObject()
  if body != nil:
    body_611580 = body
  result = call_611579.call(nil, nil, nil, nil, body_611580)

var getDevicePool* = Call_GetDevicePool_611566(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_611567, base: "/", url: url_GetDevicePool_611568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_611581 = ref object of OpenApiRestCall_610659
proc url_GetDevicePoolCompatibility_611583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_611582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about compatibility with a device pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611584 = header.getOrDefault("X-Amz-Target")
  valid_611584 = validateParameter(valid_611584, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_611584 != nil:
    section.add "X-Amz-Target", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Signature")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Signature", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Content-Sha256", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Date")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Date", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Credential")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Credential", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Security-Token")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Security-Token", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Algorithm")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Algorithm", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-SignedHeaders", valid_611591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611593: Call_GetDevicePoolCompatibility_611581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_611593.validator(path, query, header, formData, body)
  let scheme = call_611593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611593.url(scheme.get, call_611593.host, call_611593.base,
                         call_611593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611593, url, valid)

proc call*(call_611594: Call_GetDevicePoolCompatibility_611581; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_611595 = newJObject()
  if body != nil:
    body_611595 = body
  result = call_611594.call(nil, nil, nil, nil, body_611595)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_611581(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_611582, base: "/",
    url: url_GetDevicePoolCompatibility_611583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_611596 = ref object of OpenApiRestCall_610659
proc url_GetInstanceProfile_611598(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceProfile_611597(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns information about the specified instance profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611599 = header.getOrDefault("X-Amz-Target")
  valid_611599 = validateParameter(valid_611599, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_611599 != nil:
    section.add "X-Amz-Target", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Signature")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Signature", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Content-Sha256", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Date")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Date", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Credential")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Credential", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Security-Token")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Security-Token", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Algorithm")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Algorithm", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-SignedHeaders", valid_611606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611608: Call_GetInstanceProfile_611596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_611608.validator(path, query, header, formData, body)
  let scheme = call_611608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611608.url(scheme.get, call_611608.host, call_611608.base,
                         call_611608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611608, url, valid)

proc call*(call_611609: Call_GetInstanceProfile_611596; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_611610 = newJObject()
  if body != nil:
    body_611610 = body
  result = call_611609.call(nil, nil, nil, nil, body_611610)

var getInstanceProfile* = Call_GetInstanceProfile_611596(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_611597, base: "/",
    url: url_GetInstanceProfile_611598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_611611 = ref object of OpenApiRestCall_610659
proc url_GetJob_611613(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_611612(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611614 = header.getOrDefault("X-Amz-Target")
  valid_611614 = validateParameter(valid_611614, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_611614 != nil:
    section.add "X-Amz-Target", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Signature")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Signature", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Content-Sha256", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Date")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Date", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Credential")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Credential", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Security-Token")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Security-Token", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Algorithm")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Algorithm", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-SignedHeaders", valid_611621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611623: Call_GetJob_611611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_611623.validator(path, query, header, formData, body)
  let scheme = call_611623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611623.url(scheme.get, call_611623.host, call_611623.base,
                         call_611623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611623, url, valid)

proc call*(call_611624: Call_GetJob_611611; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_611625 = newJObject()
  if body != nil:
    body_611625 = body
  result = call_611624.call(nil, nil, nil, nil, body_611625)

var getJob* = Call_GetJob_611611(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_611612, base: "/",
                              url: url_GetJob_611613,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_611626 = ref object of OpenApiRestCall_610659
proc url_GetNetworkProfile_611628(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_611627(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about a network profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611629 = header.getOrDefault("X-Amz-Target")
  valid_611629 = validateParameter(valid_611629, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_611629 != nil:
    section.add "X-Amz-Target", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Signature")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Signature", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Content-Sha256", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Date")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Date", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Credential")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Credential", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Security-Token")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Security-Token", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Algorithm")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Algorithm", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-SignedHeaders", valid_611636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_GetNetworkProfile_611626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_GetNetworkProfile_611626; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_611640 = newJObject()
  if body != nil:
    body_611640 = body
  result = call_611639.call(nil, nil, nil, nil, body_611640)

var getNetworkProfile* = Call_GetNetworkProfile_611626(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_611627, base: "/",
    url: url_GetNetworkProfile_611628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_611641 = ref object of OpenApiRestCall_610659
proc url_GetOfferingStatus_611643(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOfferingStatus_611642(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611644 = query.getOrDefault("nextToken")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "nextToken", valid_611644
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611645 = header.getOrDefault("X-Amz-Target")
  valid_611645 = validateParameter(valid_611645, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_611645 != nil:
    section.add "X-Amz-Target", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Signature")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Signature", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Content-Sha256", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Date")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Date", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Credential")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Credential", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Security-Token")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Security-Token", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Algorithm")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Algorithm", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-SignedHeaders", valid_611652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611654: Call_GetOfferingStatus_611641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_611654.validator(path, query, header, formData, body)
  let scheme = call_611654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611654.url(scheme.get, call_611654.host, call_611654.base,
                         call_611654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611654, url, valid)

proc call*(call_611655: Call_GetOfferingStatus_611641; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611656 = newJObject()
  var body_611657 = newJObject()
  add(query_611656, "nextToken", newJString(nextToken))
  if body != nil:
    body_611657 = body
  result = call_611655.call(nil, query_611656, nil, nil, body_611657)

var getOfferingStatus* = Call_GetOfferingStatus_611641(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_611642, base: "/",
    url: url_GetOfferingStatus_611643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_611659 = ref object of OpenApiRestCall_610659
proc url_GetProject_611661(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_611660(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611662 = header.getOrDefault("X-Amz-Target")
  valid_611662 = validateParameter(valid_611662, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_611662 != nil:
    section.add "X-Amz-Target", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Signature")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Signature", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Content-Sha256", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Date")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Date", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Credential")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Credential", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Security-Token")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Security-Token", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611671: Call_GetProject_611659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_611671.validator(path, query, header, formData, body)
  let scheme = call_611671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611671.url(scheme.get, call_611671.host, call_611671.base,
                         call_611671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611671, url, valid)

proc call*(call_611672: Call_GetProject_611659; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_611673 = newJObject()
  if body != nil:
    body_611673 = body
  result = call_611672.call(nil, nil, nil, nil, body_611673)

var getProject* = Call_GetProject_611659(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_611660,
                                      base: "/", url: url_GetProject_611661,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_611674 = ref object of OpenApiRestCall_610659
proc url_GetRemoteAccessSession_611676(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoteAccessSession_611675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a link to a currently running remote access session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611677 = header.getOrDefault("X-Amz-Target")
  valid_611677 = validateParameter(valid_611677, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_611677 != nil:
    section.add "X-Amz-Target", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Signature")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Signature", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Content-Sha256", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Date")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Date", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Credential")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Credential", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Security-Token")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Security-Token", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Algorithm")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Algorithm", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-SignedHeaders", valid_611684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611686: Call_GetRemoteAccessSession_611674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_611686.validator(path, query, header, formData, body)
  let scheme = call_611686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611686.url(scheme.get, call_611686.host, call_611686.base,
                         call_611686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611686, url, valid)

proc call*(call_611687: Call_GetRemoteAccessSession_611674; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_611688 = newJObject()
  if body != nil:
    body_611688 = body
  result = call_611687.call(nil, nil, nil, nil, body_611688)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_611674(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_611675, base: "/",
    url: url_GetRemoteAccessSession_611676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_611689 = ref object of OpenApiRestCall_610659
proc url_GetRun_611691(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_611690(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611692 = header.getOrDefault("X-Amz-Target")
  valid_611692 = validateParameter(valid_611692, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_611692 != nil:
    section.add "X-Amz-Target", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Signature")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Signature", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Content-Sha256", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Date")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Date", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Credential")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Credential", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Security-Token")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Security-Token", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Algorithm")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Algorithm", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-SignedHeaders", valid_611699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611701: Call_GetRun_611689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_611701.validator(path, query, header, formData, body)
  let scheme = call_611701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611701.url(scheme.get, call_611701.host, call_611701.base,
                         call_611701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611701, url, valid)

proc call*(call_611702: Call_GetRun_611689; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_611703 = newJObject()
  if body != nil:
    body_611703 = body
  result = call_611702.call(nil, nil, nil, nil, body_611703)

var getRun* = Call_GetRun_611689(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_611690, base: "/",
                              url: url_GetRun_611691,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_611704 = ref object of OpenApiRestCall_610659
proc url_GetSuite_611706(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_611705(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a suite.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611707 = header.getOrDefault("X-Amz-Target")
  valid_611707 = validateParameter(valid_611707, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_611707 != nil:
    section.add "X-Amz-Target", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Signature")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Signature", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Content-Sha256", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Date")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Date", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Credential")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Credential", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Security-Token")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Security-Token", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Algorithm")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Algorithm", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-SignedHeaders", valid_611714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611716: Call_GetSuite_611704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_611716.validator(path, query, header, formData, body)
  let scheme = call_611716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611716.url(scheme.get, call_611716.host, call_611716.base,
                         call_611716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611716, url, valid)

proc call*(call_611717: Call_GetSuite_611704; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_611718 = newJObject()
  if body != nil:
    body_611718 = body
  result = call_611717.call(nil, nil, nil, nil, body_611718)

var getSuite* = Call_GetSuite_611704(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_611705, base: "/",
                                  url: url_GetSuite_611706,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_611719 = ref object of OpenApiRestCall_610659
proc url_GetTest_611721(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_611720(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a test.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611722 = header.getOrDefault("X-Amz-Target")
  valid_611722 = validateParameter(valid_611722, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_611722 != nil:
    section.add "X-Amz-Target", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Signature")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Signature", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Content-Sha256", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Date")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Date", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Credential")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Credential", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Security-Token")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Security-Token", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Algorithm")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Algorithm", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-SignedHeaders", valid_611729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_GetTest_611719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_GetTest_611719; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_611733 = newJObject()
  if body != nil:
    body_611733 = body
  result = call_611732.call(nil, nil, nil, nil, body_611733)

var getTest* = Call_GetTest_611719(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_611720, base: "/",
                                url: url_GetTest_611721,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_611734 = ref object of OpenApiRestCall_610659
proc url_GetTestGridProject_611736(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridProject_611735(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves information about a Selenium testing project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611737 = header.getOrDefault("X-Amz-Target")
  valid_611737 = validateParameter(valid_611737, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_611737 != nil:
    section.add "X-Amz-Target", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Signature")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Signature", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Content-Sha256", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Date")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Date", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Credential")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Credential", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Security-Token")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Security-Token", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Algorithm")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Algorithm", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-SignedHeaders", valid_611744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611746: Call_GetTestGridProject_611734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Selenium testing project.
  ## 
  let valid = call_611746.validator(path, query, header, formData, body)
  let scheme = call_611746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611746.url(scheme.get, call_611746.host, call_611746.base,
                         call_611746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611746, url, valid)

proc call*(call_611747: Call_GetTestGridProject_611734; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_611748 = newJObject()
  if body != nil:
    body_611748 = body
  result = call_611747.call(nil, nil, nil, nil, body_611748)

var getTestGridProject* = Call_GetTestGridProject_611734(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_611735, base: "/",
    url: url_GetTestGridProject_611736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_611749 = ref object of OpenApiRestCall_610659
proc url_GetTestGridSession_611751(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridSession_611750(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611752 = header.getOrDefault("X-Amz-Target")
  valid_611752 = validateParameter(valid_611752, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_611752 != nil:
    section.add "X-Amz-Target", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Signature")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Signature", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Content-Sha256", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Date")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Date", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Credential")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Credential", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Security-Token")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Security-Token", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Algorithm")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Algorithm", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-SignedHeaders", valid_611759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611761: Call_GetTestGridSession_611749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  let valid = call_611761.validator(path, query, header, formData, body)
  let scheme = call_611761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611761.url(scheme.get, call_611761.host, call_611761.base,
                         call_611761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611761, url, valid)

proc call*(call_611762: Call_GetTestGridSession_611749; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   body: JObject (required)
  var body_611763 = newJObject()
  if body != nil:
    body_611763 = body
  result = call_611762.call(nil, nil, nil, nil, body_611763)

var getTestGridSession* = Call_GetTestGridSession_611749(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_611750, base: "/",
    url: url_GetTestGridSession_611751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_611764 = ref object of OpenApiRestCall_610659
proc url_GetUpload_611766(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_611765(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an upload.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611767 = header.getOrDefault("X-Amz-Target")
  valid_611767 = validateParameter(valid_611767, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_611767 != nil:
    section.add "X-Amz-Target", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Signature")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Signature", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Content-Sha256", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Date")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Date", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Credential")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Credential", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Security-Token")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Security-Token", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Algorithm")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Algorithm", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-SignedHeaders", valid_611774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611776: Call_GetUpload_611764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_611776.validator(path, query, header, formData, body)
  let scheme = call_611776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611776.url(scheme.get, call_611776.host, call_611776.base,
                         call_611776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611776, url, valid)

proc call*(call_611777: Call_GetUpload_611764; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_611778 = newJObject()
  if body != nil:
    body_611778 = body
  result = call_611777.call(nil, nil, nil, nil, body_611778)

var getUpload* = Call_GetUpload_611764(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_611765,
                                    base: "/", url: url_GetUpload_611766,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_611779 = ref object of OpenApiRestCall_610659
proc url_GetVPCEConfiguration_611781(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVPCEConfiguration_611780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611782 = header.getOrDefault("X-Amz-Target")
  valid_611782 = validateParameter(valid_611782, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_611782 != nil:
    section.add "X-Amz-Target", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Signature")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Signature", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Content-Sha256", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Date")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Date", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Credential")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Credential", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Security-Token")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Security-Token", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Algorithm")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Algorithm", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-SignedHeaders", valid_611789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611791: Call_GetVPCEConfiguration_611779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_611791.validator(path, query, header, formData, body)
  let scheme = call_611791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611791.url(scheme.get, call_611791.host, call_611791.base,
                         call_611791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611791, url, valid)

proc call*(call_611792: Call_GetVPCEConfiguration_611779; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_611793 = newJObject()
  if body != nil:
    body_611793 = body
  result = call_611792.call(nil, nil, nil, nil, body_611793)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_611779(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_611780, base: "/",
    url: url_GetVPCEConfiguration_611781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_611794 = ref object of OpenApiRestCall_610659
proc url_InstallToRemoteAccessSession_611796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_611795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611797 = header.getOrDefault("X-Amz-Target")
  valid_611797 = validateParameter(valid_611797, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_611797 != nil:
    section.add "X-Amz-Target", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Signature")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Signature", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Content-Sha256", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Date")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Date", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Credential")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Credential", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Security-Token")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Security-Token", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Algorithm")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Algorithm", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-SignedHeaders", valid_611804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611806: Call_InstallToRemoteAccessSession_611794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_611806.validator(path, query, header, formData, body)
  let scheme = call_611806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611806.url(scheme.get, call_611806.host, call_611806.base,
                         call_611806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611806, url, valid)

proc call*(call_611807: Call_InstallToRemoteAccessSession_611794; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_611808 = newJObject()
  if body != nil:
    body_611808 = body
  result = call_611807.call(nil, nil, nil, nil, body_611808)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_611794(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_611795, base: "/",
    url: url_InstallToRemoteAccessSession_611796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_611809 = ref object of OpenApiRestCall_610659
proc url_ListArtifacts_611811(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListArtifacts_611810(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about artifacts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611812 = query.getOrDefault("nextToken")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "nextToken", valid_611812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611813 = header.getOrDefault("X-Amz-Target")
  valid_611813 = validateParameter(valid_611813, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_611813 != nil:
    section.add "X-Amz-Target", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Signature")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Signature", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Content-Sha256", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Date")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Date", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Credential")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Credential", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Security-Token")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Security-Token", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Algorithm")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Algorithm", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-SignedHeaders", valid_611820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611822: Call_ListArtifacts_611809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_611822.validator(path, query, header, formData, body)
  let scheme = call_611822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611822.url(scheme.get, call_611822.host, call_611822.base,
                         call_611822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611822, url, valid)

proc call*(call_611823: Call_ListArtifacts_611809; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611824 = newJObject()
  var body_611825 = newJObject()
  add(query_611824, "nextToken", newJString(nextToken))
  if body != nil:
    body_611825 = body
  result = call_611823.call(nil, query_611824, nil, nil, body_611825)

var listArtifacts* = Call_ListArtifacts_611809(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_611810, base: "/", url: url_ListArtifacts_611811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_611826 = ref object of OpenApiRestCall_610659
proc url_ListDeviceInstances_611828(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceInstances_611827(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611829 = header.getOrDefault("X-Amz-Target")
  valid_611829 = validateParameter(valid_611829, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_611829 != nil:
    section.add "X-Amz-Target", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Signature")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Signature", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Content-Sha256", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Date")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Date", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Credential")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Credential", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Security-Token")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Security-Token", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Algorithm")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Algorithm", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-SignedHeaders", valid_611836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611838: Call_ListDeviceInstances_611826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_611838.validator(path, query, header, formData, body)
  let scheme = call_611838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611838.url(scheme.get, call_611838.host, call_611838.base,
                         call_611838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611838, url, valid)

proc call*(call_611839: Call_ListDeviceInstances_611826; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_611840 = newJObject()
  if body != nil:
    body_611840 = body
  result = call_611839.call(nil, nil, nil, nil, body_611840)

var listDeviceInstances* = Call_ListDeviceInstances_611826(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_611827, base: "/",
    url: url_ListDeviceInstances_611828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_611841 = ref object of OpenApiRestCall_610659
proc url_ListDevicePools_611843(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevicePools_611842(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets information about device pools.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611844 = query.getOrDefault("nextToken")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "nextToken", valid_611844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611845 = header.getOrDefault("X-Amz-Target")
  valid_611845 = validateParameter(valid_611845, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_611845 != nil:
    section.add "X-Amz-Target", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Signature")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Signature", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Content-Sha256", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Date")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Date", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Credential")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Credential", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Security-Token")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Security-Token", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Algorithm")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Algorithm", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-SignedHeaders", valid_611852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_ListDevicePools_611841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_ListDevicePools_611841; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611856 = newJObject()
  var body_611857 = newJObject()
  add(query_611856, "nextToken", newJString(nextToken))
  if body != nil:
    body_611857 = body
  result = call_611855.call(nil, query_611856, nil, nil, body_611857)

var listDevicePools* = Call_ListDevicePools_611841(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_611842, base: "/", url: url_ListDevicePools_611843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_611858 = ref object of OpenApiRestCall_610659
proc url_ListDevices_611860(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_611859(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about unique device types.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611861 = query.getOrDefault("nextToken")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "nextToken", valid_611861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611862 = header.getOrDefault("X-Amz-Target")
  valid_611862 = validateParameter(valid_611862, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_611862 != nil:
    section.add "X-Amz-Target", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Signature")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Signature", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Content-Sha256", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Date")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Date", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Credential")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Credential", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Security-Token")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Security-Token", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Algorithm")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Algorithm", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-SignedHeaders", valid_611869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611871: Call_ListDevices_611858; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_611871.validator(path, query, header, formData, body)
  let scheme = call_611871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611871.url(scheme.get, call_611871.host, call_611871.base,
                         call_611871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611871, url, valid)

proc call*(call_611872: Call_ListDevices_611858; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611873 = newJObject()
  var body_611874 = newJObject()
  add(query_611873, "nextToken", newJString(nextToken))
  if body != nil:
    body_611874 = body
  result = call_611872.call(nil, query_611873, nil, nil, body_611874)

var listDevices* = Call_ListDevices_611858(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_611859,
                                        base: "/", url: url_ListDevices_611860,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_611875 = ref object of OpenApiRestCall_610659
proc url_ListInstanceProfiles_611877(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstanceProfiles_611876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611878 = header.getOrDefault("X-Amz-Target")
  valid_611878 = validateParameter(valid_611878, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_611878 != nil:
    section.add "X-Amz-Target", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Signature")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Signature", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Content-Sha256", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Date")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Date", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Credential")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Credential", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Security-Token")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Security-Token", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Algorithm")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Algorithm", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-SignedHeaders", valid_611885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611887: Call_ListInstanceProfiles_611875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_611887.validator(path, query, header, formData, body)
  let scheme = call_611887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611887.url(scheme.get, call_611887.host, call_611887.base,
                         call_611887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611887, url, valid)

proc call*(call_611888: Call_ListInstanceProfiles_611875; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_611889 = newJObject()
  if body != nil:
    body_611889 = body
  result = call_611888.call(nil, nil, nil, nil, body_611889)

var listInstanceProfiles* = Call_ListInstanceProfiles_611875(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_611876, base: "/",
    url: url_ListInstanceProfiles_611877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_611890 = ref object of OpenApiRestCall_610659
proc url_ListJobs_611892(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_611891(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about jobs for a given test run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611893 = query.getOrDefault("nextToken")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "nextToken", valid_611893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611894 = header.getOrDefault("X-Amz-Target")
  valid_611894 = validateParameter(valid_611894, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_611894 != nil:
    section.add "X-Amz-Target", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Signature")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Signature", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Content-Sha256", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Date")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Date", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Credential")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Credential", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Security-Token")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Security-Token", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Algorithm")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Algorithm", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-SignedHeaders", valid_611901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611903: Call_ListJobs_611890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_611903.validator(path, query, header, formData, body)
  let scheme = call_611903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611903.url(scheme.get, call_611903.host, call_611903.base,
                         call_611903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611903, url, valid)

proc call*(call_611904: Call_ListJobs_611890; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611905 = newJObject()
  var body_611906 = newJObject()
  add(query_611905, "nextToken", newJString(nextToken))
  if body != nil:
    body_611906 = body
  result = call_611904.call(nil, query_611905, nil, nil, body_611906)

var listJobs* = Call_ListJobs_611890(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_611891, base: "/",
                                  url: url_ListJobs_611892,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_611907 = ref object of OpenApiRestCall_610659
proc url_ListNetworkProfiles_611909(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworkProfiles_611908(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the list of available network profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611910 = header.getOrDefault("X-Amz-Target")
  valid_611910 = validateParameter(valid_611910, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_611910 != nil:
    section.add "X-Amz-Target", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Signature")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Signature", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Content-Sha256", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Date")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Date", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Credential")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Credential", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Security-Token")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Security-Token", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Algorithm")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Algorithm", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-SignedHeaders", valid_611917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611919: Call_ListNetworkProfiles_611907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_611919.validator(path, query, header, formData, body)
  let scheme = call_611919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611919.url(scheme.get, call_611919.host, call_611919.base,
                         call_611919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611919, url, valid)

proc call*(call_611920: Call_ListNetworkProfiles_611907; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_611921 = newJObject()
  if body != nil:
    body_611921 = body
  result = call_611920.call(nil, nil, nil, nil, body_611921)

var listNetworkProfiles* = Call_ListNetworkProfiles_611907(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_611908, base: "/",
    url: url_ListNetworkProfiles_611909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_611922 = ref object of OpenApiRestCall_610659
proc url_ListOfferingPromotions_611924(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingPromotions_611923(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611925 = header.getOrDefault("X-Amz-Target")
  valid_611925 = validateParameter(valid_611925, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_611925 != nil:
    section.add "X-Amz-Target", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Signature")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Signature", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Content-Sha256", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Date")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Date", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Credential")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Credential", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Security-Token")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Security-Token", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Algorithm")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Algorithm", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-SignedHeaders", valid_611932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611934: Call_ListOfferingPromotions_611922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  let valid = call_611934.validator(path, query, header, formData, body)
  let scheme = call_611934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611934.url(scheme.get, call_611934.host, call_611934.base,
                         call_611934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611934, url, valid)

proc call*(call_611935: Call_ListOfferingPromotions_611922; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   body: JObject (required)
  var body_611936 = newJObject()
  if body != nil:
    body_611936 = body
  result = call_611935.call(nil, nil, nil, nil, body_611936)

var listOfferingPromotions* = Call_ListOfferingPromotions_611922(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_611923, base: "/",
    url: url_ListOfferingPromotions_611924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_611937 = ref object of OpenApiRestCall_610659
proc url_ListOfferingTransactions_611939(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingTransactions_611938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611940 = query.getOrDefault("nextToken")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "nextToken", valid_611940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611941 = header.getOrDefault("X-Amz-Target")
  valid_611941 = validateParameter(valid_611941, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_611941 != nil:
    section.add "X-Amz-Target", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-Signature")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Signature", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Content-Sha256", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Date")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Date", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Credential")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Credential", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Security-Token")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Security-Token", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Algorithm")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Algorithm", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-SignedHeaders", valid_611948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611950: Call_ListOfferingTransactions_611937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_611950.validator(path, query, header, formData, body)
  let scheme = call_611950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611950.url(scheme.get, call_611950.host, call_611950.base,
                         call_611950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611950, url, valid)

proc call*(call_611951: Call_ListOfferingTransactions_611937; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611952 = newJObject()
  var body_611953 = newJObject()
  add(query_611952, "nextToken", newJString(nextToken))
  if body != nil:
    body_611953 = body
  result = call_611951.call(nil, query_611952, nil, nil, body_611953)

var listOfferingTransactions* = Call_ListOfferingTransactions_611937(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_611938, base: "/",
    url: url_ListOfferingTransactions_611939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_611954 = ref object of OpenApiRestCall_610659
proc url_ListOfferings_611956(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_611955(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611957 = query.getOrDefault("nextToken")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "nextToken", valid_611957
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611958 = header.getOrDefault("X-Amz-Target")
  valid_611958 = validateParameter(valid_611958, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_611958 != nil:
    section.add "X-Amz-Target", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611967: Call_ListOfferings_611954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_611967.validator(path, query, header, formData, body)
  let scheme = call_611967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611967.url(scheme.get, call_611967.host, call_611967.base,
                         call_611967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611967, url, valid)

proc call*(call_611968: Call_ListOfferings_611954; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611969 = newJObject()
  var body_611970 = newJObject()
  add(query_611969, "nextToken", newJString(nextToken))
  if body != nil:
    body_611970 = body
  result = call_611968.call(nil, query_611969, nil, nil, body_611970)

var listOfferings* = Call_ListOfferings_611954(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_611955, base: "/", url: url_ListOfferings_611956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_611971 = ref object of OpenApiRestCall_610659
proc url_ListProjects_611973(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_611972(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about projects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611974 = query.getOrDefault("nextToken")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "nextToken", valid_611974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611975 = header.getOrDefault("X-Amz-Target")
  valid_611975 = validateParameter(valid_611975, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_611975 != nil:
    section.add "X-Amz-Target", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Signature")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Signature", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Content-Sha256", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Date")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Date", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Credential")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Credential", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-Security-Token")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Security-Token", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Algorithm")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Algorithm", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-SignedHeaders", valid_611982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611984: Call_ListProjects_611971; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_611984.validator(path, query, header, formData, body)
  let scheme = call_611984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611984.url(scheme.get, call_611984.host, call_611984.base,
                         call_611984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611984, url, valid)

proc call*(call_611985: Call_ListProjects_611971; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611986 = newJObject()
  var body_611987 = newJObject()
  add(query_611986, "nextToken", newJString(nextToken))
  if body != nil:
    body_611987 = body
  result = call_611985.call(nil, query_611986, nil, nil, body_611987)

var listProjects* = Call_ListProjects_611971(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_611972, base: "/", url: url_ListProjects_611973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_611988 = ref object of OpenApiRestCall_610659
proc url_ListRemoteAccessSessions_611990(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRemoteAccessSessions_611989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all currently running remote access sessions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611991 = header.getOrDefault("X-Amz-Target")
  valid_611991 = validateParameter(valid_611991, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_611991 != nil:
    section.add "X-Amz-Target", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Signature")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Signature", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Content-Sha256", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Date")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Date", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Credential")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Credential", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Security-Token")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Security-Token", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Algorithm")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Algorithm", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-SignedHeaders", valid_611998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612000: Call_ListRemoteAccessSessions_611988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_612000.validator(path, query, header, formData, body)
  let scheme = call_612000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612000.url(scheme.get, call_612000.host, call_612000.base,
                         call_612000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612000, url, valid)

proc call*(call_612001: Call_ListRemoteAccessSessions_611988; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_612002 = newJObject()
  if body != nil:
    body_612002 = body
  result = call_612001.call(nil, nil, nil, nil, body_612002)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_611988(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_611989, base: "/",
    url: url_ListRemoteAccessSessions_611990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_612003 = ref object of OpenApiRestCall_610659
proc url_ListRuns_612005(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_612004(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612006 = query.getOrDefault("nextToken")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "nextToken", valid_612006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612007 = header.getOrDefault("X-Amz-Target")
  valid_612007 = validateParameter(valid_612007, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_612007 != nil:
    section.add "X-Amz-Target", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Signature")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Signature", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Content-Sha256", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Date")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Date", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Credential")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Credential", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Security-Token")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Security-Token", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Algorithm")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Algorithm", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-SignedHeaders", valid_612014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612016: Call_ListRuns_612003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_612016.validator(path, query, header, formData, body)
  let scheme = call_612016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612016.url(scheme.get, call_612016.host, call_612016.base,
                         call_612016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612016, url, valid)

proc call*(call_612017: Call_ListRuns_612003; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612018 = newJObject()
  var body_612019 = newJObject()
  add(query_612018, "nextToken", newJString(nextToken))
  if body != nil:
    body_612019 = body
  result = call_612017.call(nil, query_612018, nil, nil, body_612019)

var listRuns* = Call_ListRuns_612003(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_612004, base: "/",
                                  url: url_ListRuns_612005,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_612020 = ref object of OpenApiRestCall_610659
proc url_ListSamples_612022(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSamples_612021(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612023 = query.getOrDefault("nextToken")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "nextToken", valid_612023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612024 = header.getOrDefault("X-Amz-Target")
  valid_612024 = validateParameter(valid_612024, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_612024 != nil:
    section.add "X-Amz-Target", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Signature")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Signature", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Content-Sha256", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Date")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Date", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Credential")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Credential", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Security-Token")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Security-Token", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Algorithm")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Algorithm", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-SignedHeaders", valid_612031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612033: Call_ListSamples_612020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_612033.validator(path, query, header, formData, body)
  let scheme = call_612033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612033.url(scheme.get, call_612033.host, call_612033.base,
                         call_612033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612033, url, valid)

proc call*(call_612034: Call_ListSamples_612020; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612035 = newJObject()
  var body_612036 = newJObject()
  add(query_612035, "nextToken", newJString(nextToken))
  if body != nil:
    body_612036 = body
  result = call_612034.call(nil, query_612035, nil, nil, body_612036)

var listSamples* = Call_ListSamples_612020(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_612021,
                                        base: "/", url: url_ListSamples_612022,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_612037 = ref object of OpenApiRestCall_610659
proc url_ListSuites_612039(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_612038(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about test suites for a given job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612040 = query.getOrDefault("nextToken")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "nextToken", valid_612040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612041 = header.getOrDefault("X-Amz-Target")
  valid_612041 = validateParameter(valid_612041, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_612041 != nil:
    section.add "X-Amz-Target", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Signature")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Signature", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Content-Sha256", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Date")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Date", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Credential")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Credential", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Security-Token")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Security-Token", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Algorithm")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Algorithm", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-SignedHeaders", valid_612048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612050: Call_ListSuites_612037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_612050.validator(path, query, header, formData, body)
  let scheme = call_612050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612050.url(scheme.get, call_612050.host, call_612050.base,
                         call_612050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612050, url, valid)

proc call*(call_612051: Call_ListSuites_612037; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612052 = newJObject()
  var body_612053 = newJObject()
  add(query_612052, "nextToken", newJString(nextToken))
  if body != nil:
    body_612053 = body
  result = call_612051.call(nil, query_612052, nil, nil, body_612053)

var listSuites* = Call_ListSuites_612037(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_612038,
                                      base: "/", url: url_ListSuites_612039,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612054 = ref object of OpenApiRestCall_610659
proc url_ListTagsForResource_612056(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_612055(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an AWS Device Farm resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612057 = header.getOrDefault("X-Amz-Target")
  valid_612057 = validateParameter(valid_612057, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_612057 != nil:
    section.add "X-Amz-Target", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Signature")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Signature", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Content-Sha256", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Date")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Date", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Credential")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Credential", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Security-Token")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Security-Token", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Algorithm")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Algorithm", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-SignedHeaders", valid_612064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612066: Call_ListTagsForResource_612054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_612066.validator(path, query, header, formData, body)
  let scheme = call_612066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612066.url(scheme.get, call_612066.host, call_612066.base,
                         call_612066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612066, url, valid)

proc call*(call_612067: Call_ListTagsForResource_612054; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_612068 = newJObject()
  if body != nil:
    body_612068 = body
  result = call_612067.call(nil, nil, nil, nil, body_612068)

var listTagsForResource* = Call_ListTagsForResource_612054(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_612055, base: "/",
    url: url_ListTagsForResource_612056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_612069 = ref object of OpenApiRestCall_610659
proc url_ListTestGridProjects_612071(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridProjects_612070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResult: JString
  ##            : Pagination limit
  section = newJObject()
  var valid_612072 = query.getOrDefault("nextToken")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "nextToken", valid_612072
  var valid_612073 = query.getOrDefault("maxResult")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "maxResult", valid_612073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612074 = header.getOrDefault("X-Amz-Target")
  valid_612074 = validateParameter(valid_612074, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_612074 != nil:
    section.add "X-Amz-Target", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Signature")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Signature", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Content-Sha256", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Date")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Date", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Credential")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Credential", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Security-Token")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Security-Token", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Algorithm")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Algorithm", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-SignedHeaders", valid_612081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612083: Call_ListTestGridProjects_612069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  let valid = call_612083.validator(path, query, header, formData, body)
  let scheme = call_612083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612083.url(scheme.get, call_612083.host, call_612083.base,
                         call_612083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612083, url, valid)

proc call*(call_612084: Call_ListTestGridProjects_612069; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_612085 = newJObject()
  var body_612086 = newJObject()
  add(query_612085, "nextToken", newJString(nextToken))
  add(query_612085, "maxResult", newJString(maxResult))
  if body != nil:
    body_612086 = body
  result = call_612084.call(nil, query_612085, nil, nil, body_612086)

var listTestGridProjects* = Call_ListTestGridProjects_612069(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_612070, base: "/",
    url: url_ListTestGridProjects_612071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_612087 = ref object of OpenApiRestCall_610659
proc url_ListTestGridSessionActions_612089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionActions_612088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResult: JString
  ##            : Pagination limit
  section = newJObject()
  var valid_612090 = query.getOrDefault("nextToken")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "nextToken", valid_612090
  var valid_612091 = query.getOrDefault("maxResult")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "maxResult", valid_612091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612092 = header.getOrDefault("X-Amz-Target")
  valid_612092 = validateParameter(valid_612092, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_612092 != nil:
    section.add "X-Amz-Target", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Signature")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Signature", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Content-Sha256", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Date")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Date", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Credential")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Credential", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Security-Token")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Security-Token", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Algorithm")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Algorithm", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-SignedHeaders", valid_612099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612101: Call_ListTestGridSessionActions_612087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  let valid = call_612101.validator(path, query, header, formData, body)
  let scheme = call_612101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612101.url(scheme.get, call_612101.host, call_612101.base,
                         call_612101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612101, url, valid)

proc call*(call_612102: Call_ListTestGridSessionActions_612087; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_612103 = newJObject()
  var body_612104 = newJObject()
  add(query_612103, "nextToken", newJString(nextToken))
  add(query_612103, "maxResult", newJString(maxResult))
  if body != nil:
    body_612104 = body
  result = call_612102.call(nil, query_612103, nil, nil, body_612104)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_612087(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_612088, base: "/",
    url: url_ListTestGridSessionActions_612089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_612105 = ref object of OpenApiRestCall_610659
proc url_ListTestGridSessionArtifacts_612107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionArtifacts_612106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of artifacts created during the session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResult: JString
  ##            : Pagination limit
  section = newJObject()
  var valid_612108 = query.getOrDefault("nextToken")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "nextToken", valid_612108
  var valid_612109 = query.getOrDefault("maxResult")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "maxResult", valid_612109
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612110 = header.getOrDefault("X-Amz-Target")
  valid_612110 = validateParameter(valid_612110, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_612110 != nil:
    section.add "X-Amz-Target", valid_612110
  var valid_612111 = header.getOrDefault("X-Amz-Signature")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Signature", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Content-Sha256", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Date")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Date", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Credential")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Credential", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Security-Token")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Security-Token", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Algorithm")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Algorithm", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-SignedHeaders", valid_612117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612119: Call_ListTestGridSessionArtifacts_612105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of artifacts created during the session.
  ## 
  let valid = call_612119.validator(path, query, header, formData, body)
  let scheme = call_612119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612119.url(scheme.get, call_612119.host, call_612119.base,
                         call_612119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612119, url, valid)

proc call*(call_612120: Call_ListTestGridSessionArtifacts_612105; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_612121 = newJObject()
  var body_612122 = newJObject()
  add(query_612121, "nextToken", newJString(nextToken))
  add(query_612121, "maxResult", newJString(maxResult))
  if body != nil:
    body_612122 = body
  result = call_612120.call(nil, query_612121, nil, nil, body_612122)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_612105(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_612106, base: "/",
    url: url_ListTestGridSessionArtifacts_612107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_612123 = ref object of OpenApiRestCall_610659
proc url_ListTestGridSessions_612125(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessions_612124(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResult: JString
  ##            : Pagination limit
  section = newJObject()
  var valid_612126 = query.getOrDefault("nextToken")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "nextToken", valid_612126
  var valid_612127 = query.getOrDefault("maxResult")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "maxResult", valid_612127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612128 = header.getOrDefault("X-Amz-Target")
  valid_612128 = validateParameter(valid_612128, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_612128 != nil:
    section.add "X-Amz-Target", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Signature")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Signature", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Content-Sha256", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Date")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Date", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Credential")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Credential", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Security-Token")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Security-Token", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Algorithm")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Algorithm", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-SignedHeaders", valid_612135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612137: Call_ListTestGridSessions_612123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  let valid = call_612137.validator(path, query, header, formData, body)
  let scheme = call_612137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612137.url(scheme.get, call_612137.host, call_612137.base,
                         call_612137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612137, url, valid)

proc call*(call_612138: Call_ListTestGridSessions_612123; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_612139 = newJObject()
  var body_612140 = newJObject()
  add(query_612139, "nextToken", newJString(nextToken))
  add(query_612139, "maxResult", newJString(maxResult))
  if body != nil:
    body_612140 = body
  result = call_612138.call(nil, query_612139, nil, nil, body_612140)

var listTestGridSessions* = Call_ListTestGridSessions_612123(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_612124, base: "/",
    url: url_ListTestGridSessions_612125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_612141 = ref object of OpenApiRestCall_610659
proc url_ListTests_612143(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_612142(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about tests in a given test suite.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612144 = query.getOrDefault("nextToken")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "nextToken", valid_612144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612145 = header.getOrDefault("X-Amz-Target")
  valid_612145 = validateParameter(valid_612145, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_612145 != nil:
    section.add "X-Amz-Target", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Signature")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Signature", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Content-Sha256", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Date")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Date", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Credential")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Credential", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Security-Token")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Security-Token", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Algorithm")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Algorithm", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-SignedHeaders", valid_612152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612154: Call_ListTests_612141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_612154.validator(path, query, header, formData, body)
  let scheme = call_612154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612154.url(scheme.get, call_612154.host, call_612154.base,
                         call_612154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612154, url, valid)

proc call*(call_612155: Call_ListTests_612141; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612156 = newJObject()
  var body_612157 = newJObject()
  add(query_612156, "nextToken", newJString(nextToken))
  if body != nil:
    body_612157 = body
  result = call_612155.call(nil, query_612156, nil, nil, body_612157)

var listTests* = Call_ListTests_612141(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_612142,
                                    base: "/", url: url_ListTests_612143,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_612158 = ref object of OpenApiRestCall_610659
proc url_ListUniqueProblems_612160(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUniqueProblems_612159(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612161 = query.getOrDefault("nextToken")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "nextToken", valid_612161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612162 = header.getOrDefault("X-Amz-Target")
  valid_612162 = validateParameter(valid_612162, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_612162 != nil:
    section.add "X-Amz-Target", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Signature")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Signature", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Content-Sha256", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Date")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Date", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Credential")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Credential", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Security-Token")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Security-Token", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Algorithm")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Algorithm", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-SignedHeaders", valid_612169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612171: Call_ListUniqueProblems_612158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  let valid = call_612171.validator(path, query, header, formData, body)
  let scheme = call_612171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612171.url(scheme.get, call_612171.host, call_612171.base,
                         call_612171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612171, url, valid)

proc call*(call_612172: Call_ListUniqueProblems_612158; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612173 = newJObject()
  var body_612174 = newJObject()
  add(query_612173, "nextToken", newJString(nextToken))
  if body != nil:
    body_612174 = body
  result = call_612172.call(nil, query_612173, nil, nil, body_612174)

var listUniqueProblems* = Call_ListUniqueProblems_612158(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_612159, base: "/",
    url: url_ListUniqueProblems_612160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_612175 = ref object of OpenApiRestCall_610659
proc url_ListUploads_612177(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUploads_612176(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612178 = query.getOrDefault("nextToken")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "nextToken", valid_612178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612179 = header.getOrDefault("X-Amz-Target")
  valid_612179 = validateParameter(valid_612179, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_612179 != nil:
    section.add "X-Amz-Target", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Signature")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Signature", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Content-Sha256", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Date")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Date", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Credential")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Credential", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Security-Token")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Security-Token", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Algorithm")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Algorithm", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-SignedHeaders", valid_612186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612188: Call_ListUploads_612175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_612188.validator(path, query, header, formData, body)
  let scheme = call_612188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612188.url(scheme.get, call_612188.host, call_612188.base,
                         call_612188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612188, url, valid)

proc call*(call_612189: Call_ListUploads_612175; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612190 = newJObject()
  var body_612191 = newJObject()
  add(query_612190, "nextToken", newJString(nextToken))
  if body != nil:
    body_612191 = body
  result = call_612189.call(nil, query_612190, nil, nil, body_612191)

var listUploads* = Call_ListUploads_612175(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_612176,
                                        base: "/", url: url_ListUploads_612177,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_612192 = ref object of OpenApiRestCall_610659
proc url_ListVPCEConfigurations_612194(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVPCEConfigurations_612193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612195 = header.getOrDefault("X-Amz-Target")
  valid_612195 = validateParameter(valid_612195, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_612195 != nil:
    section.add "X-Amz-Target", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Signature")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Signature", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Content-Sha256", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Date")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Date", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Credential")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Credential", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Security-Token")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Security-Token", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Algorithm")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Algorithm", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-SignedHeaders", valid_612202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612204: Call_ListVPCEConfigurations_612192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_612204.validator(path, query, header, formData, body)
  let scheme = call_612204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612204.url(scheme.get, call_612204.host, call_612204.base,
                         call_612204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612204, url, valid)

proc call*(call_612205: Call_ListVPCEConfigurations_612192; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_612206 = newJObject()
  if body != nil:
    body_612206 = body
  result = call_612205.call(nil, nil, nil, nil, body_612206)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_612192(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_612193, base: "/",
    url: url_ListVPCEConfigurations_612194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_612207 = ref object of OpenApiRestCall_610659
proc url_PurchaseOffering_612209(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseOffering_612208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612210 = header.getOrDefault("X-Amz-Target")
  valid_612210 = validateParameter(valid_612210, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_612210 != nil:
    section.add "X-Amz-Target", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Signature")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Signature", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Content-Sha256", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Date")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Date", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Credential")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Credential", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Security-Token")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Security-Token", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Algorithm")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Algorithm", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-SignedHeaders", valid_612217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612219: Call_PurchaseOffering_612207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_612219.validator(path, query, header, formData, body)
  let scheme = call_612219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612219.url(scheme.get, call_612219.host, call_612219.base,
                         call_612219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612219, url, valid)

proc call*(call_612220: Call_PurchaseOffering_612207; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_612221 = newJObject()
  if body != nil:
    body_612221 = body
  result = call_612220.call(nil, nil, nil, nil, body_612221)

var purchaseOffering* = Call_PurchaseOffering_612207(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_612208, base: "/",
    url: url_PurchaseOffering_612209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_612222 = ref object of OpenApiRestCall_610659
proc url_RenewOffering_612224(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenewOffering_612223(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612225 = header.getOrDefault("X-Amz-Target")
  valid_612225 = validateParameter(valid_612225, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_612225 != nil:
    section.add "X-Amz-Target", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Signature")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Signature", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Content-Sha256", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Date")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Date", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Credential")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Credential", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Security-Token")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Security-Token", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Algorithm")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Algorithm", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-SignedHeaders", valid_612232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612234: Call_RenewOffering_612222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_612234.validator(path, query, header, formData, body)
  let scheme = call_612234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612234.url(scheme.get, call_612234.host, call_612234.base,
                         call_612234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612234, url, valid)

proc call*(call_612235: Call_RenewOffering_612222; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_612236 = newJObject()
  if body != nil:
    body_612236 = body
  result = call_612235.call(nil, nil, nil, nil, body_612236)

var renewOffering* = Call_RenewOffering_612222(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_612223, base: "/", url: url_RenewOffering_612224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_612237 = ref object of OpenApiRestCall_610659
proc url_ScheduleRun_612239(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleRun_612238(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Schedules a run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612240 = header.getOrDefault("X-Amz-Target")
  valid_612240 = validateParameter(valid_612240, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_612240 != nil:
    section.add "X-Amz-Target", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Signature")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Signature", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Content-Sha256", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Date")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Date", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Credential")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Credential", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Security-Token")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Security-Token", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Algorithm")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Algorithm", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-SignedHeaders", valid_612247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612249: Call_ScheduleRun_612237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_612249.validator(path, query, header, formData, body)
  let scheme = call_612249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612249.url(scheme.get, call_612249.host, call_612249.base,
                         call_612249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612249, url, valid)

proc call*(call_612250: Call_ScheduleRun_612237; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_612251 = newJObject()
  if body != nil:
    body_612251 = body
  result = call_612250.call(nil, nil, nil, nil, body_612251)

var scheduleRun* = Call_ScheduleRun_612237(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_612238,
                                        base: "/", url: url_ScheduleRun_612239,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_612252 = ref object of OpenApiRestCall_610659
proc url_StopJob_612254(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_612253(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612255 = header.getOrDefault("X-Amz-Target")
  valid_612255 = validateParameter(valid_612255, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_612255 != nil:
    section.add "X-Amz-Target", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Signature")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Signature", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Content-Sha256", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Date")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Date", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Credential")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Credential", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Security-Token")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Security-Token", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Algorithm")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Algorithm", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-SignedHeaders", valid_612262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612264: Call_StopJob_612252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_612264.validator(path, query, header, formData, body)
  let scheme = call_612264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612264.url(scheme.get, call_612264.host, call_612264.base,
                         call_612264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612264, url, valid)

proc call*(call_612265: Call_StopJob_612252; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_612266 = newJObject()
  if body != nil:
    body_612266 = body
  result = call_612265.call(nil, nil, nil, nil, body_612266)

var stopJob* = Call_StopJob_612252(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_612253, base: "/",
                                url: url_StopJob_612254,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_612267 = ref object of OpenApiRestCall_610659
proc url_StopRemoteAccessSession_612269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRemoteAccessSession_612268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Ends a specified remote access session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612270 = header.getOrDefault("X-Amz-Target")
  valid_612270 = validateParameter(valid_612270, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_612270 != nil:
    section.add "X-Amz-Target", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Signature")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Signature", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Content-Sha256", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Date")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Date", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Credential")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Credential", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Security-Token")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Security-Token", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Algorithm")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Algorithm", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-SignedHeaders", valid_612277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612279: Call_StopRemoteAccessSession_612267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_612279.validator(path, query, header, formData, body)
  let scheme = call_612279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612279.url(scheme.get, call_612279.host, call_612279.base,
                         call_612279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612279, url, valid)

proc call*(call_612280: Call_StopRemoteAccessSession_612267; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_612281 = newJObject()
  if body != nil:
    body_612281 = body
  result = call_612280.call(nil, nil, nil, nil, body_612281)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_612267(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_612268, base: "/",
    url: url_StopRemoteAccessSession_612269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_612282 = ref object of OpenApiRestCall_610659
proc url_StopRun_612284(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_612283(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612285 = header.getOrDefault("X-Amz-Target")
  valid_612285 = validateParameter(valid_612285, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_612285 != nil:
    section.add "X-Amz-Target", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Signature")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Signature", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Content-Sha256", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Date")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Date", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Credential")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Credential", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Security-Token")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Security-Token", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Algorithm")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Algorithm", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-SignedHeaders", valid_612292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612294: Call_StopRun_612282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_612294.validator(path, query, header, formData, body)
  let scheme = call_612294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612294.url(scheme.get, call_612294.host, call_612294.base,
                         call_612294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612294, url, valid)

proc call*(call_612295: Call_StopRun_612282; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_612296 = newJObject()
  if body != nil:
    body_612296 = body
  result = call_612295.call(nil, nil, nil, nil, body_612296)

var stopRun* = Call_StopRun_612282(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_612283, base: "/",
                                url: url_StopRun_612284,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612297 = ref object of OpenApiRestCall_610659
proc url_TagResource_612299(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_612298(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612300 = header.getOrDefault("X-Amz-Target")
  valid_612300 = validateParameter(valid_612300, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_612300 != nil:
    section.add "X-Amz-Target", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Signature")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Signature", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Content-Sha256", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Date")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Date", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Credential")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Credential", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Security-Token")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Security-Token", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Algorithm")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Algorithm", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-SignedHeaders", valid_612307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612309: Call_TagResource_612297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  let valid = call_612309.validator(path, query, header, formData, body)
  let scheme = call_612309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612309.url(scheme.get, call_612309.host, call_612309.base,
                         call_612309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612309, url, valid)

proc call*(call_612310: Call_TagResource_612297; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   body: JObject (required)
  var body_612311 = newJObject()
  if body != nil:
    body_612311 = body
  result = call_612310.call(nil, nil, nil, nil, body_612311)

var tagResource* = Call_TagResource_612297(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_612298,
                                        base: "/", url: url_TagResource_612299,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612312 = ref object of OpenApiRestCall_610659
proc url_UntagResource_612314(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_612313(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612315 = header.getOrDefault("X-Amz-Target")
  valid_612315 = validateParameter(valid_612315, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_612315 != nil:
    section.add "X-Amz-Target", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Signature")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Signature", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Content-Sha256", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Date")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Date", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Credential")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Credential", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Security-Token")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Security-Token", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Algorithm")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Algorithm", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-SignedHeaders", valid_612322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612324: Call_UntagResource_612312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_612324.validator(path, query, header, formData, body)
  let scheme = call_612324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612324.url(scheme.get, call_612324.host, call_612324.base,
                         call_612324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612324, url, valid)

proc call*(call_612325: Call_UntagResource_612312; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_612326 = newJObject()
  if body != nil:
    body_612326 = body
  result = call_612325.call(nil, nil, nil, nil, body_612326)

var untagResource* = Call_UntagResource_612312(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_612313, base: "/", url: url_UntagResource_612314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_612327 = ref object of OpenApiRestCall_610659
proc url_UpdateDeviceInstance_612329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceInstance_612328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about a private device instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612330 = header.getOrDefault("X-Amz-Target")
  valid_612330 = validateParameter(valid_612330, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_612330 != nil:
    section.add "X-Amz-Target", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-Signature")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Signature", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Content-Sha256", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Date")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Date", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Credential")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Credential", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Security-Token")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Security-Token", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Algorithm")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Algorithm", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-SignedHeaders", valid_612337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612339: Call_UpdateDeviceInstance_612327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about a private device instance.
  ## 
  let valid = call_612339.validator(path, query, header, formData, body)
  let scheme = call_612339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612339.url(scheme.get, call_612339.host, call_612339.base,
                         call_612339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612339, url, valid)

proc call*(call_612340: Call_UpdateDeviceInstance_612327; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_612341 = newJObject()
  if body != nil:
    body_612341 = body
  result = call_612340.call(nil, nil, nil, nil, body_612341)

var updateDeviceInstance* = Call_UpdateDeviceInstance_612327(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_612328, base: "/",
    url: url_UpdateDeviceInstance_612329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_612342 = ref object of OpenApiRestCall_610659
proc url_UpdateDevicePool_612344(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePool_612343(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612345 = header.getOrDefault("X-Amz-Target")
  valid_612345 = validateParameter(valid_612345, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_612345 != nil:
    section.add "X-Amz-Target", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Signature")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Signature", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Content-Sha256", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Date")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Date", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Credential")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Credential", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Security-Token")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Security-Token", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Algorithm")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Algorithm", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-SignedHeaders", valid_612352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612354: Call_UpdateDevicePool_612342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_612354.validator(path, query, header, formData, body)
  let scheme = call_612354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612354.url(scheme.get, call_612354.host, call_612354.base,
                         call_612354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612354, url, valid)

proc call*(call_612355: Call_UpdateDevicePool_612342; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_612356 = newJObject()
  if body != nil:
    body_612356 = body
  result = call_612355.call(nil, nil, nil, nil, body_612356)

var updateDevicePool* = Call_UpdateDevicePool_612342(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_612343, base: "/",
    url: url_UpdateDevicePool_612344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_612357 = ref object of OpenApiRestCall_610659
proc url_UpdateInstanceProfile_612359(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceProfile_612358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about an existing private device instance profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612360 = header.getOrDefault("X-Amz-Target")
  valid_612360 = validateParameter(valid_612360, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_612360 != nil:
    section.add "X-Amz-Target", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Signature")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Signature", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Content-Sha256", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Date")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Date", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Credential")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Credential", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Security-Token")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Security-Token", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Algorithm")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Algorithm", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-SignedHeaders", valid_612367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612369: Call_UpdateInstanceProfile_612357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_612369.validator(path, query, header, formData, body)
  let scheme = call_612369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612369.url(scheme.get, call_612369.host, call_612369.base,
                         call_612369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612369, url, valid)

proc call*(call_612370: Call_UpdateInstanceProfile_612357; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_612371 = newJObject()
  if body != nil:
    body_612371 = body
  result = call_612370.call(nil, nil, nil, nil, body_612371)

var updateInstanceProfile* = Call_UpdateInstanceProfile_612357(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_612358, base: "/",
    url: url_UpdateInstanceProfile_612359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_612372 = ref object of OpenApiRestCall_610659
proc url_UpdateNetworkProfile_612374(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_612373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the network profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612375 = header.getOrDefault("X-Amz-Target")
  valid_612375 = validateParameter(valid_612375, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_612375 != nil:
    section.add "X-Amz-Target", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-Signature")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-Signature", valid_612376
  var valid_612377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "X-Amz-Content-Sha256", valid_612377
  var valid_612378 = header.getOrDefault("X-Amz-Date")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "X-Amz-Date", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Credential")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Credential", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Security-Token")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Security-Token", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Algorithm")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Algorithm", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-SignedHeaders", valid_612382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612384: Call_UpdateNetworkProfile_612372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile.
  ## 
  let valid = call_612384.validator(path, query, header, formData, body)
  let scheme = call_612384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612384.url(scheme.get, call_612384.host, call_612384.base,
                         call_612384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612384, url, valid)

proc call*(call_612385: Call_UpdateNetworkProfile_612372; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_612386 = newJObject()
  if body != nil:
    body_612386 = body
  result = call_612385.call(nil, nil, nil, nil, body_612386)

var updateNetworkProfile* = Call_UpdateNetworkProfile_612372(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_612373, base: "/",
    url: url_UpdateNetworkProfile_612374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_612387 = ref object of OpenApiRestCall_610659
proc url_UpdateProject_612389(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_612388(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612390 = header.getOrDefault("X-Amz-Target")
  valid_612390 = validateParameter(valid_612390, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_612390 != nil:
    section.add "X-Amz-Target", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Signature")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Signature", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-Content-Sha256", valid_612392
  var valid_612393 = header.getOrDefault("X-Amz-Date")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Date", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Credential")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Credential", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Security-Token")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Security-Token", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-Algorithm")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-Algorithm", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-SignedHeaders", valid_612397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612399: Call_UpdateProject_612387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_612399.validator(path, query, header, formData, body)
  let scheme = call_612399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612399.url(scheme.get, call_612399.host, call_612399.base,
                         call_612399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612399, url, valid)

proc call*(call_612400: Call_UpdateProject_612387; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_612401 = newJObject()
  if body != nil:
    body_612401 = body
  result = call_612400.call(nil, nil, nil, nil, body_612401)

var updateProject* = Call_UpdateProject_612387(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_612388, base: "/", url: url_UpdateProject_612389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_612402 = ref object of OpenApiRestCall_610659
proc url_UpdateTestGridProject_612404(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTestGridProject_612403(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Change details of a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612405 = header.getOrDefault("X-Amz-Target")
  valid_612405 = validateParameter(valid_612405, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_612405 != nil:
    section.add "X-Amz-Target", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Signature")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Signature", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Content-Sha256", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Date")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Date", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Credential")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Credential", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Security-Token")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Security-Token", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-Algorithm")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-Algorithm", valid_612411
  var valid_612412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612412 = validateParameter(valid_612412, JString, required = false,
                                 default = nil)
  if valid_612412 != nil:
    section.add "X-Amz-SignedHeaders", valid_612412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612414: Call_UpdateTestGridProject_612402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Change details of a project.
  ## 
  let valid = call_612414.validator(path, query, header, formData, body)
  let scheme = call_612414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612414.url(scheme.get, call_612414.host, call_612414.base,
                         call_612414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612414, url, valid)

proc call*(call_612415: Call_UpdateTestGridProject_612402; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_612416 = newJObject()
  if body != nil:
    body_612416 = body
  result = call_612415.call(nil, nil, nil, nil, body_612416)

var updateTestGridProject* = Call_UpdateTestGridProject_612402(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_612403, base: "/",
    url: url_UpdateTestGridProject_612404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_612417 = ref object of OpenApiRestCall_610659
proc url_UpdateUpload_612419(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUpload_612418(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an uploaded test spec.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612420 = header.getOrDefault("X-Amz-Target")
  valid_612420 = validateParameter(valid_612420, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_612420 != nil:
    section.add "X-Amz-Target", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Signature")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Signature", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Content-Sha256", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Date")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Date", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Credential")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Credential", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Security-Token")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Security-Token", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Algorithm")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Algorithm", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-SignedHeaders", valid_612427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612429: Call_UpdateUpload_612417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an uploaded test spec.
  ## 
  let valid = call_612429.validator(path, query, header, formData, body)
  let scheme = call_612429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612429.url(scheme.get, call_612429.host, call_612429.base,
                         call_612429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612429, url, valid)

proc call*(call_612430: Call_UpdateUpload_612417; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_612431 = newJObject()
  if body != nil:
    body_612431 = body
  result = call_612430.call(nil, nil, nil, nil, body_612431)

var updateUpload* = Call_UpdateUpload_612417(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_612418, base: "/", url: url_UpdateUpload_612419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_612432 = ref object of OpenApiRestCall_610659
proc url_UpdateVPCEConfiguration_612434(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVPCEConfiguration_612433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612435 = header.getOrDefault("X-Amz-Target")
  valid_612435 = validateParameter(valid_612435, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_612435 != nil:
    section.add "X-Amz-Target", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Signature")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Signature", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Content-Sha256", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Date")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Date", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Credential")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Credential", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Security-Token")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Security-Token", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Algorithm")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Algorithm", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-SignedHeaders", valid_612442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612444: Call_UpdateVPCEConfiguration_612432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_612444.validator(path, query, header, formData, body)
  let scheme = call_612444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612444.url(scheme.get, call_612444.host, call_612444.base,
                         call_612444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612444, url, valid)

proc call*(call_612445: Call_UpdateVPCEConfiguration_612432; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_612446 = newJObject()
  if body != nil:
    body_612446 = body
  result = call_612445.call(nil, nil, nil, nil, body_612446)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_612432(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_612433, base: "/",
    url: url_UpdateVPCEConfiguration_612434, schemes: {Scheme.Https, Scheme.Http})
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
