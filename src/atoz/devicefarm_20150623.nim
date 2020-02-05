
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

  OpenApiRestCall_612659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612659): Option[Scheme] {.used.} =
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
  Call_CreateDevicePool_612997 = ref object of OpenApiRestCall_612659
proc url_CreateDevicePool_612999(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevicePool_612998(path: JsonNode; query: JsonNode;
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
  var valid_613124 = header.getOrDefault("X-Amz-Target")
  valid_613124 = validateParameter(valid_613124, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_613124 != nil:
    section.add "X-Amz-Target", valid_613124
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

proc call*(call_613155: Call_CreateDevicePool_612997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_CreateDevicePool_612997; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_613227 = newJObject()
  if body != nil:
    body_613227 = body
  result = call_613226.call(nil, nil, nil, nil, body_613227)

var createDevicePool* = Call_CreateDevicePool_612997(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_612998, base: "/",
    url: url_CreateDevicePool_612999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_613266 = ref object of OpenApiRestCall_612659
proc url_CreateInstanceProfile_613268(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstanceProfile_613267(path: JsonNode; query: JsonNode;
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
  var valid_613269 = header.getOrDefault("X-Amz-Target")
  valid_613269 = validateParameter(valid_613269, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_613269 != nil:
    section.add "X-Amz-Target", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_CreateInstanceProfile_613266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_CreateInstanceProfile_613266; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_613280 = newJObject()
  if body != nil:
    body_613280 = body
  result = call_613279.call(nil, nil, nil, nil, body_613280)

var createInstanceProfile* = Call_CreateInstanceProfile_613266(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_613267, base: "/",
    url: url_CreateInstanceProfile_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_613281 = ref object of OpenApiRestCall_612659
proc url_CreateNetworkProfile_613283(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetworkProfile_613282(path: JsonNode; query: JsonNode;
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
  var valid_613284 = header.getOrDefault("X-Amz-Target")
  valid_613284 = validateParameter(valid_613284, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_613284 != nil:
    section.add "X-Amz-Target", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_CreateNetworkProfile_613281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_CreateNetworkProfile_613281; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var createNetworkProfile* = Call_CreateNetworkProfile_613281(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_613282, base: "/",
    url: url_CreateNetworkProfile_613283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_613296 = ref object of OpenApiRestCall_612659
proc url_CreateProject_613298(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_613297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613299 = header.getOrDefault("X-Amz-Target")
  valid_613299 = validateParameter(valid_613299, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_613299 != nil:
    section.add "X-Amz-Target", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Signature")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Signature", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Content-Sha256", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Date")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Date", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Credential")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Credential", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Security-Token")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Security-Token", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Algorithm")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Algorithm", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-SignedHeaders", valid_613306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613308: Call_CreateProject_613296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a project.
  ## 
  let valid = call_613308.validator(path, query, header, formData, body)
  let scheme = call_613308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613308.url(scheme.get, call_613308.host, call_613308.base,
                         call_613308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613308, url, valid)

proc call*(call_613309: Call_CreateProject_613296; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_613310 = newJObject()
  if body != nil:
    body_613310 = body
  result = call_613309.call(nil, nil, nil, nil, body_613310)

var createProject* = Call_CreateProject_613296(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_613297, base: "/", url: url_CreateProject_613298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_613311 = ref object of OpenApiRestCall_612659
proc url_CreateRemoteAccessSession_613313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRemoteAccessSession_613312(path: JsonNode; query: JsonNode;
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
  var valid_613314 = header.getOrDefault("X-Amz-Target")
  valid_613314 = validateParameter(valid_613314, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_613314 != nil:
    section.add "X-Amz-Target", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Signature")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Signature", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Content-Sha256", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Date")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Date", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Credential")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Credential", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Security-Token")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Security-Token", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Algorithm")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Algorithm", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-SignedHeaders", valid_613321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613323: Call_CreateRemoteAccessSession_613311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_613323.validator(path, query, header, formData, body)
  let scheme = call_613323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613323.url(scheme.get, call_613323.host, call_613323.base,
                         call_613323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613323, url, valid)

proc call*(call_613324: Call_CreateRemoteAccessSession_613311; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_613325 = newJObject()
  if body != nil:
    body_613325 = body
  result = call_613324.call(nil, nil, nil, nil, body_613325)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_613311(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_613312, base: "/",
    url: url_CreateRemoteAccessSession_613313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_613326 = ref object of OpenApiRestCall_612659
proc url_CreateTestGridProject_613328(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTestGridProject_613327(path: JsonNode; query: JsonNode;
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
  var valid_613329 = header.getOrDefault("X-Amz-Target")
  valid_613329 = validateParameter(valid_613329, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_613329 != nil:
    section.add "X-Amz-Target", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613338: Call_CreateTestGridProject_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  let valid = call_613338.validator(path, query, header, formData, body)
  let scheme = call_613338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613338.url(scheme.get, call_613338.host, call_613338.base,
                         call_613338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613338, url, valid)

proc call*(call_613339: Call_CreateTestGridProject_613326; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   body: JObject (required)
  var body_613340 = newJObject()
  if body != nil:
    body_613340 = body
  result = call_613339.call(nil, nil, nil, nil, body_613340)

var createTestGridProject* = Call_CreateTestGridProject_613326(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_613327, base: "/",
    url: url_CreateTestGridProject_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_613341 = ref object of OpenApiRestCall_612659
proc url_CreateTestGridUrl_613343(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTestGridUrl_613342(path: JsonNode; query: JsonNode;
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
  var valid_613344 = header.getOrDefault("X-Amz-Target")
  valid_613344 = validateParameter(valid_613344, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_613344 != nil:
    section.add "X-Amz-Target", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Signature")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Signature", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Content-Sha256", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Date")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Date", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Credential")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Credential", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Security-Token")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Security-Token", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Algorithm")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Algorithm", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-SignedHeaders", valid_613351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_CreateTestGridUrl_613341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_CreateTestGridUrl_613341; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   body: JObject (required)
  var body_613355 = newJObject()
  if body != nil:
    body_613355 = body
  result = call_613354.call(nil, nil, nil, nil, body_613355)

var createTestGridUrl* = Call_CreateTestGridUrl_613341(name: "createTestGridUrl",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_613342, base: "/",
    url: url_CreateTestGridUrl_613343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_613356 = ref object of OpenApiRestCall_612659
proc url_CreateUpload_613358(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUpload_613357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613359 = header.getOrDefault("X-Amz-Target")
  valid_613359 = validateParameter(valid_613359, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_613359 != nil:
    section.add "X-Amz-Target", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Signature")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Signature", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Content-Sha256", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Date")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Date", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Credential")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Credential", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Security-Token")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Security-Token", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Algorithm")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Algorithm", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-SignedHeaders", valid_613366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613368: Call_CreateUpload_613356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_613368.validator(path, query, header, formData, body)
  let scheme = call_613368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613368.url(scheme.get, call_613368.host, call_613368.base,
                         call_613368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613368, url, valid)

proc call*(call_613369: Call_CreateUpload_613356; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_613370 = newJObject()
  if body != nil:
    body_613370 = body
  result = call_613369.call(nil, nil, nil, nil, body_613370)

var createUpload* = Call_CreateUpload_613356(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_613357, base: "/", url: url_CreateUpload_613358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_613371 = ref object of OpenApiRestCall_612659
proc url_CreateVPCEConfiguration_613373(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVPCEConfiguration_613372(path: JsonNode; query: JsonNode;
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
  var valid_613374 = header.getOrDefault("X-Amz-Target")
  valid_613374 = validateParameter(valid_613374, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_613374 != nil:
    section.add "X-Amz-Target", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Signature")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Signature", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Content-Sha256", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Date")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Date", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Credential")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Credential", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Security-Token")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Security-Token", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Algorithm")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Algorithm", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-SignedHeaders", valid_613381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613383: Call_CreateVPCEConfiguration_613371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_613383.validator(path, query, header, formData, body)
  let scheme = call_613383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613383.url(scheme.get, call_613383.host, call_613383.base,
                         call_613383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613383, url, valid)

proc call*(call_613384: Call_CreateVPCEConfiguration_613371; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_613385 = newJObject()
  if body != nil:
    body_613385 = body
  result = call_613384.call(nil, nil, nil, nil, body_613385)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_613371(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_613372, base: "/",
    url: url_CreateVPCEConfiguration_613373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_613386 = ref object of OpenApiRestCall_612659
proc url_DeleteDevicePool_613388(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevicePool_613387(path: JsonNode; query: JsonNode;
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
  var valid_613389 = header.getOrDefault("X-Amz-Target")
  valid_613389 = validateParameter(valid_613389, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_613389 != nil:
    section.add "X-Amz-Target", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613398: Call_DeleteDevicePool_613386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_613398.validator(path, query, header, formData, body)
  let scheme = call_613398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613398.url(scheme.get, call_613398.host, call_613398.base,
                         call_613398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613398, url, valid)

proc call*(call_613399: Call_DeleteDevicePool_613386; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_613400 = newJObject()
  if body != nil:
    body_613400 = body
  result = call_613399.call(nil, nil, nil, nil, body_613400)

var deleteDevicePool* = Call_DeleteDevicePool_613386(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_613387, base: "/",
    url: url_DeleteDevicePool_613388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_613401 = ref object of OpenApiRestCall_612659
proc url_DeleteInstanceProfile_613403(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstanceProfile_613402(path: JsonNode; query: JsonNode;
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
  var valid_613404 = header.getOrDefault("X-Amz-Target")
  valid_613404 = validateParameter(valid_613404, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_613404 != nil:
    section.add "X-Amz-Target", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Signature")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Signature", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Content-Sha256", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Date")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Date", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Credential")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Credential", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Security-Token")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Security-Token", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Algorithm")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Algorithm", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-SignedHeaders", valid_613411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613413: Call_DeleteInstanceProfile_613401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_613413.validator(path, query, header, formData, body)
  let scheme = call_613413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613413.url(scheme.get, call_613413.host, call_613413.base,
                         call_613413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613413, url, valid)

proc call*(call_613414: Call_DeleteInstanceProfile_613401; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_613415 = newJObject()
  if body != nil:
    body_613415 = body
  result = call_613414.call(nil, nil, nil, nil, body_613415)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_613401(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_613402, base: "/",
    url: url_DeleteInstanceProfile_613403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_613416 = ref object of OpenApiRestCall_612659
proc url_DeleteNetworkProfile_613418(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNetworkProfile_613417(path: JsonNode; query: JsonNode;
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
  var valid_613419 = header.getOrDefault("X-Amz-Target")
  valid_613419 = validateParameter(valid_613419, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_613419 != nil:
    section.add "X-Amz-Target", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Signature")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Signature", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Content-Sha256", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Date")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Date", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Credential")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Credential", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Security-Token")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Security-Token", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Algorithm")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Algorithm", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-SignedHeaders", valid_613426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613428: Call_DeleteNetworkProfile_613416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_613428.validator(path, query, header, formData, body)
  let scheme = call_613428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613428.url(scheme.get, call_613428.host, call_613428.base,
                         call_613428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613428, url, valid)

proc call*(call_613429: Call_DeleteNetworkProfile_613416; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_613430 = newJObject()
  if body != nil:
    body_613430 = body
  result = call_613429.call(nil, nil, nil, nil, body_613430)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_613416(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_613417, base: "/",
    url: url_DeleteNetworkProfile_613418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_613431 = ref object of OpenApiRestCall_612659
proc url_DeleteProject_613433(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_613432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613434 = header.getOrDefault("X-Amz-Target")
  valid_613434 = validateParameter(valid_613434, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_613434 != nil:
    section.add "X-Amz-Target", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Signature")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Signature", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Content-Sha256", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Date")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Date", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Credential")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Credential", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Security-Token")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Security-Token", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Algorithm")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Algorithm", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-SignedHeaders", valid_613441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613443: Call_DeleteProject_613431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_613443.validator(path, query, header, formData, body)
  let scheme = call_613443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613443.url(scheme.get, call_613443.host, call_613443.base,
                         call_613443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613443, url, valid)

proc call*(call_613444: Call_DeleteProject_613431; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_613445 = newJObject()
  if body != nil:
    body_613445 = body
  result = call_613444.call(nil, nil, nil, nil, body_613445)

var deleteProject* = Call_DeleteProject_613431(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_613432, base: "/", url: url_DeleteProject_613433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_613446 = ref object of OpenApiRestCall_612659
proc url_DeleteRemoteAccessSession_613448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_613447(path: JsonNode; query: JsonNode;
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
  var valid_613449 = header.getOrDefault("X-Amz-Target")
  valid_613449 = validateParameter(valid_613449, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_613449 != nil:
    section.add "X-Amz-Target", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Signature")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Signature", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Content-Sha256", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Date")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Date", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Credential")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Credential", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Security-Token")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Security-Token", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Algorithm")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Algorithm", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-SignedHeaders", valid_613456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613458: Call_DeleteRemoteAccessSession_613446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_613458.validator(path, query, header, formData, body)
  let scheme = call_613458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613458.url(scheme.get, call_613458.host, call_613458.base,
                         call_613458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613458, url, valid)

proc call*(call_613459: Call_DeleteRemoteAccessSession_613446; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_613460 = newJObject()
  if body != nil:
    body_613460 = body
  result = call_613459.call(nil, nil, nil, nil, body_613460)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_613446(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_613447, base: "/",
    url: url_DeleteRemoteAccessSession_613448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_613461 = ref object of OpenApiRestCall_612659
proc url_DeleteRun_613463(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_613462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613464 = header.getOrDefault("X-Amz-Target")
  valid_613464 = validateParameter(valid_613464, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_613464 != nil:
    section.add "X-Amz-Target", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Signature")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Signature", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Content-Sha256", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Date")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Date", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Credential")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Credential", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Security-Token")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Security-Token", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Algorithm")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Algorithm", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-SignedHeaders", valid_613471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_DeleteRun_613461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_DeleteRun_613461; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_613475 = newJObject()
  if body != nil:
    body_613475 = body
  result = call_613474.call(nil, nil, nil, nil, body_613475)

var deleteRun* = Call_DeleteRun_613461(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_613462,
                                    base: "/", url: url_DeleteRun_613463,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_613476 = ref object of OpenApiRestCall_612659
proc url_DeleteTestGridProject_613478(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTestGridProject_613477(path: JsonNode; query: JsonNode;
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
  var valid_613479 = header.getOrDefault("X-Amz-Target")
  valid_613479 = validateParameter(valid_613479, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_613479 != nil:
    section.add "X-Amz-Target", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_DeleteTestGridProject_613476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_DeleteTestGridProject_613476; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   body: JObject (required)
  var body_613490 = newJObject()
  if body != nil:
    body_613490 = body
  result = call_613489.call(nil, nil, nil, nil, body_613490)

var deleteTestGridProject* = Call_DeleteTestGridProject_613476(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_613477, base: "/",
    url: url_DeleteTestGridProject_613478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_613491 = ref object of OpenApiRestCall_612659
proc url_DeleteUpload_613493(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUpload_613492(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613494 = header.getOrDefault("X-Amz-Target")
  valid_613494 = validateParameter(valid_613494, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_613494 != nil:
    section.add "X-Amz-Target", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Signature")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Signature", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Content-Sha256", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Date")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Date", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Credential")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Credential", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Security-Token")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Security-Token", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Algorithm")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Algorithm", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-SignedHeaders", valid_613501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613503: Call_DeleteUpload_613491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_613503.validator(path, query, header, formData, body)
  let scheme = call_613503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613503.url(scheme.get, call_613503.host, call_613503.base,
                         call_613503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613503, url, valid)

proc call*(call_613504: Call_DeleteUpload_613491; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_613505 = newJObject()
  if body != nil:
    body_613505 = body
  result = call_613504.call(nil, nil, nil, nil, body_613505)

var deleteUpload* = Call_DeleteUpload_613491(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_613492, base: "/", url: url_DeleteUpload_613493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_613506 = ref object of OpenApiRestCall_612659
proc url_DeleteVPCEConfiguration_613508(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVPCEConfiguration_613507(path: JsonNode; query: JsonNode;
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
  var valid_613509 = header.getOrDefault("X-Amz-Target")
  valid_613509 = validateParameter(valid_613509, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_613509 != nil:
    section.add "X-Amz-Target", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Signature")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Signature", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Content-Sha256", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Date")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Date", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Credential")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Credential", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Security-Token")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Security-Token", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Algorithm")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Algorithm", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-SignedHeaders", valid_613516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_DeleteVPCEConfiguration_613506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_DeleteVPCEConfiguration_613506; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_613520 = newJObject()
  if body != nil:
    body_613520 = body
  result = call_613519.call(nil, nil, nil, nil, body_613520)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_613506(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_613507, base: "/",
    url: url_DeleteVPCEConfiguration_613508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_613521 = ref object of OpenApiRestCall_612659
proc url_GetAccountSettings_613523(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_613522(path: JsonNode; query: JsonNode;
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
  var valid_613524 = header.getOrDefault("X-Amz-Target")
  valid_613524 = validateParameter(valid_613524, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_613524 != nil:
    section.add "X-Amz-Target", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Signature")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Signature", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Content-Sha256", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Date")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Date", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Credential")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Credential", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Security-Token")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Security-Token", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Algorithm")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Algorithm", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-SignedHeaders", valid_613531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613533: Call_GetAccountSettings_613521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_613533.validator(path, query, header, formData, body)
  let scheme = call_613533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613533.url(scheme.get, call_613533.host, call_613533.base,
                         call_613533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613533, url, valid)

proc call*(call_613534: Call_GetAccountSettings_613521; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_613535 = newJObject()
  if body != nil:
    body_613535 = body
  result = call_613534.call(nil, nil, nil, nil, body_613535)

var getAccountSettings* = Call_GetAccountSettings_613521(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_613522, base: "/",
    url: url_GetAccountSettings_613523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_613536 = ref object of OpenApiRestCall_612659
proc url_GetDevice_613538(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_613537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613539 = header.getOrDefault("X-Amz-Target")
  valid_613539 = validateParameter(valid_613539, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_613539 != nil:
    section.add "X-Amz-Target", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Signature")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Signature", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Content-Sha256", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Date")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Date", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Credential")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Credential", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Security-Token")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Security-Token", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Algorithm")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Algorithm", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-SignedHeaders", valid_613546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613548: Call_GetDevice_613536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_613548.validator(path, query, header, formData, body)
  let scheme = call_613548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613548.url(scheme.get, call_613548.host, call_613548.base,
                         call_613548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613548, url, valid)

proc call*(call_613549: Call_GetDevice_613536; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_613550 = newJObject()
  if body != nil:
    body_613550 = body
  result = call_613549.call(nil, nil, nil, nil, body_613550)

var getDevice* = Call_GetDevice_613536(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_613537,
                                    base: "/", url: url_GetDevice_613538,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_613551 = ref object of OpenApiRestCall_612659
proc url_GetDeviceInstance_613553(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceInstance_613552(path: JsonNode; query: JsonNode;
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
  var valid_613554 = header.getOrDefault("X-Amz-Target")
  valid_613554 = validateParameter(valid_613554, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_613554 != nil:
    section.add "X-Amz-Target", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Signature")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Signature", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Content-Sha256", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Date")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Date", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Credential")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Credential", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Security-Token")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Security-Token", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Algorithm")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Algorithm", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-SignedHeaders", valid_613561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613563: Call_GetDeviceInstance_613551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  let valid = call_613563.validator(path, query, header, formData, body)
  let scheme = call_613563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613563.url(scheme.get, call_613563.host, call_613563.base,
                         call_613563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613563, url, valid)

proc call*(call_613564: Call_GetDeviceInstance_613551; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   body: JObject (required)
  var body_613565 = newJObject()
  if body != nil:
    body_613565 = body
  result = call_613564.call(nil, nil, nil, nil, body_613565)

var getDeviceInstance* = Call_GetDeviceInstance_613551(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_613552, base: "/",
    url: url_GetDeviceInstance_613553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_613566 = ref object of OpenApiRestCall_612659
proc url_GetDevicePool_613568(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevicePool_613567(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613569 = header.getOrDefault("X-Amz-Target")
  valid_613569 = validateParameter(valid_613569, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_613569 != nil:
    section.add "X-Amz-Target", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Signature")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Signature", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Content-Sha256", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Date")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Date", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Credential")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Credential", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Security-Token")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Security-Token", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Algorithm")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Algorithm", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-SignedHeaders", valid_613576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613578: Call_GetDevicePool_613566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_613578.validator(path, query, header, formData, body)
  let scheme = call_613578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613578.url(scheme.get, call_613578.host, call_613578.base,
                         call_613578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613578, url, valid)

proc call*(call_613579: Call_GetDevicePool_613566; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_613580 = newJObject()
  if body != nil:
    body_613580 = body
  result = call_613579.call(nil, nil, nil, nil, body_613580)

var getDevicePool* = Call_GetDevicePool_613566(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_613567, base: "/", url: url_GetDevicePool_613568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_613581 = ref object of OpenApiRestCall_612659
proc url_GetDevicePoolCompatibility_613583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_613582(path: JsonNode; query: JsonNode;
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
  var valid_613584 = header.getOrDefault("X-Amz-Target")
  valid_613584 = validateParameter(valid_613584, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_613584 != nil:
    section.add "X-Amz-Target", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Signature")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Signature", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Content-Sha256", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Date")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Date", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Credential")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Credential", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Security-Token")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Security-Token", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Algorithm")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Algorithm", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-SignedHeaders", valid_613591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613593: Call_GetDevicePoolCompatibility_613581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_613593.validator(path, query, header, formData, body)
  let scheme = call_613593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613593.url(scheme.get, call_613593.host, call_613593.base,
                         call_613593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613593, url, valid)

proc call*(call_613594: Call_GetDevicePoolCompatibility_613581; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_613595 = newJObject()
  if body != nil:
    body_613595 = body
  result = call_613594.call(nil, nil, nil, nil, body_613595)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_613581(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_613582, base: "/",
    url: url_GetDevicePoolCompatibility_613583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_613596 = ref object of OpenApiRestCall_612659
proc url_GetInstanceProfile_613598(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceProfile_613597(path: JsonNode; query: JsonNode;
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
  var valid_613599 = header.getOrDefault("X-Amz-Target")
  valid_613599 = validateParameter(valid_613599, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_613599 != nil:
    section.add "X-Amz-Target", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Signature")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Signature", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Content-Sha256", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Date")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Date", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Credential")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Credential", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Security-Token")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Security-Token", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Algorithm")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Algorithm", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-SignedHeaders", valid_613606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613608: Call_GetInstanceProfile_613596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_613608.validator(path, query, header, formData, body)
  let scheme = call_613608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613608.url(scheme.get, call_613608.host, call_613608.base,
                         call_613608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613608, url, valid)

proc call*(call_613609: Call_GetInstanceProfile_613596; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_613610 = newJObject()
  if body != nil:
    body_613610 = body
  result = call_613609.call(nil, nil, nil, nil, body_613610)

var getInstanceProfile* = Call_GetInstanceProfile_613596(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_613597, base: "/",
    url: url_GetInstanceProfile_613598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_613611 = ref object of OpenApiRestCall_612659
proc url_GetJob_613613(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_613612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613614 = header.getOrDefault("X-Amz-Target")
  valid_613614 = validateParameter(valid_613614, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_613614 != nil:
    section.add "X-Amz-Target", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Signature")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Signature", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Content-Sha256", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Date")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Date", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Credential")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Credential", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Security-Token")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Security-Token", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Algorithm")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Algorithm", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-SignedHeaders", valid_613621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613623: Call_GetJob_613611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_613623.validator(path, query, header, formData, body)
  let scheme = call_613623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613623.url(scheme.get, call_613623.host, call_613623.base,
                         call_613623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613623, url, valid)

proc call*(call_613624: Call_GetJob_613611; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_613625 = newJObject()
  if body != nil:
    body_613625 = body
  result = call_613624.call(nil, nil, nil, nil, body_613625)

var getJob* = Call_GetJob_613611(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_613612, base: "/",
                              url: url_GetJob_613613,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_613626 = ref object of OpenApiRestCall_612659
proc url_GetNetworkProfile_613628(protocol: Scheme; host: string; base: string;
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

proc validate_GetNetworkProfile_613627(path: JsonNode; query: JsonNode;
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
  var valid_613629 = header.getOrDefault("X-Amz-Target")
  valid_613629 = validateParameter(valid_613629, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_613629 != nil:
    section.add "X-Amz-Target", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Signature")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Signature", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Content-Sha256", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Date")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Date", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Credential")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Credential", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Security-Token")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Security-Token", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Algorithm")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Algorithm", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-SignedHeaders", valid_613636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613638: Call_GetNetworkProfile_613626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_613638.validator(path, query, header, formData, body)
  let scheme = call_613638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613638.url(scheme.get, call_613638.host, call_613638.base,
                         call_613638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613638, url, valid)

proc call*(call_613639: Call_GetNetworkProfile_613626; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_613640 = newJObject()
  if body != nil:
    body_613640 = body
  result = call_613639.call(nil, nil, nil, nil, body_613640)

var getNetworkProfile* = Call_GetNetworkProfile_613626(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_613627, base: "/",
    url: url_GetNetworkProfile_613628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_613641 = ref object of OpenApiRestCall_612659
proc url_GetOfferingStatus_613643(protocol: Scheme; host: string; base: string;
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

proc validate_GetOfferingStatus_613642(path: JsonNode; query: JsonNode;
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
  var valid_613644 = query.getOrDefault("nextToken")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "nextToken", valid_613644
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
  var valid_613645 = header.getOrDefault("X-Amz-Target")
  valid_613645 = validateParameter(valid_613645, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_613645 != nil:
    section.add "X-Amz-Target", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Signature")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Signature", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Content-Sha256", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Date")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Date", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Credential")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Credential", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Security-Token")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Security-Token", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Algorithm")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Algorithm", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-SignedHeaders", valid_613652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613654: Call_GetOfferingStatus_613641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_613654.validator(path, query, header, formData, body)
  let scheme = call_613654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613654.url(scheme.get, call_613654.host, call_613654.base,
                         call_613654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613654, url, valid)

proc call*(call_613655: Call_GetOfferingStatus_613641; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613656 = newJObject()
  var body_613657 = newJObject()
  add(query_613656, "nextToken", newJString(nextToken))
  if body != nil:
    body_613657 = body
  result = call_613655.call(nil, query_613656, nil, nil, body_613657)

var getOfferingStatus* = Call_GetOfferingStatus_613641(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_613642, base: "/",
    url: url_GetOfferingStatus_613643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_613659 = ref object of OpenApiRestCall_612659
proc url_GetProject_613661(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_613660(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613662 = header.getOrDefault("X-Amz-Target")
  valid_613662 = validateParameter(valid_613662, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_613662 != nil:
    section.add "X-Amz-Target", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_GetProject_613659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_GetProject_613659; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_613673 = newJObject()
  if body != nil:
    body_613673 = body
  result = call_613672.call(nil, nil, nil, nil, body_613673)

var getProject* = Call_GetProject_613659(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_613660,
                                      base: "/", url: url_GetProject_613661,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_613674 = ref object of OpenApiRestCall_612659
proc url_GetRemoteAccessSession_613676(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoteAccessSession_613675(path: JsonNode; query: JsonNode;
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
  var valid_613677 = header.getOrDefault("X-Amz-Target")
  valid_613677 = validateParameter(valid_613677, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_613677 != nil:
    section.add "X-Amz-Target", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Signature")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Signature", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Content-Sha256", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Date")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Date", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Credential")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Credential", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Security-Token")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Security-Token", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Algorithm")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Algorithm", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-SignedHeaders", valid_613684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613686: Call_GetRemoteAccessSession_613674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_613686.validator(path, query, header, formData, body)
  let scheme = call_613686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613686.url(scheme.get, call_613686.host, call_613686.base,
                         call_613686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613686, url, valid)

proc call*(call_613687: Call_GetRemoteAccessSession_613674; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_613688 = newJObject()
  if body != nil:
    body_613688 = body
  result = call_613687.call(nil, nil, nil, nil, body_613688)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_613674(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_613675, base: "/",
    url: url_GetRemoteAccessSession_613676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_613689 = ref object of OpenApiRestCall_612659
proc url_GetRun_613691(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_613690(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613692 = header.getOrDefault("X-Amz-Target")
  valid_613692 = validateParameter(valid_613692, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_613692 != nil:
    section.add "X-Amz-Target", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Signature")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Signature", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Content-Sha256", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Date")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Date", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Credential")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Credential", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Security-Token")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Security-Token", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Algorithm")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Algorithm", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-SignedHeaders", valid_613699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613701: Call_GetRun_613689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_613701.validator(path, query, header, formData, body)
  let scheme = call_613701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613701.url(scheme.get, call_613701.host, call_613701.base,
                         call_613701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613701, url, valid)

proc call*(call_613702: Call_GetRun_613689; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_613703 = newJObject()
  if body != nil:
    body_613703 = body
  result = call_613702.call(nil, nil, nil, nil, body_613703)

var getRun* = Call_GetRun_613689(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_613690, base: "/",
                              url: url_GetRun_613691,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_613704 = ref object of OpenApiRestCall_612659
proc url_GetSuite_613706(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_613705(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613707 = header.getOrDefault("X-Amz-Target")
  valid_613707 = validateParameter(valid_613707, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_613707 != nil:
    section.add "X-Amz-Target", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_GetSuite_613704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_GetSuite_613704; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_613718 = newJObject()
  if body != nil:
    body_613718 = body
  result = call_613717.call(nil, nil, nil, nil, body_613718)

var getSuite* = Call_GetSuite_613704(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_613705, base: "/",
                                  url: url_GetSuite_613706,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_613719 = ref object of OpenApiRestCall_612659
proc url_GetTest_613721(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_613720(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613722 = header.getOrDefault("X-Amz-Target")
  valid_613722 = validateParameter(valid_613722, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_613722 != nil:
    section.add "X-Amz-Target", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_GetTest_613719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_GetTest_613719; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_613733 = newJObject()
  if body != nil:
    body_613733 = body
  result = call_613732.call(nil, nil, nil, nil, body_613733)

var getTest* = Call_GetTest_613719(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_613720, base: "/",
                                url: url_GetTest_613721,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_613734 = ref object of OpenApiRestCall_612659
proc url_GetTestGridProject_613736(protocol: Scheme; host: string; base: string;
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

proc validate_GetTestGridProject_613735(path: JsonNode; query: JsonNode;
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
  var valid_613737 = header.getOrDefault("X-Amz-Target")
  valid_613737 = validateParameter(valid_613737, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_613737 != nil:
    section.add "X-Amz-Target", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Signature")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Signature", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Content-Sha256", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Date")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Date", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Credential")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Credential", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Security-Token")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Security-Token", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Algorithm")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Algorithm", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-SignedHeaders", valid_613744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613746: Call_GetTestGridProject_613734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Selenium testing project.
  ## 
  let valid = call_613746.validator(path, query, header, formData, body)
  let scheme = call_613746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613746.url(scheme.get, call_613746.host, call_613746.base,
                         call_613746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613746, url, valid)

proc call*(call_613747: Call_GetTestGridProject_613734; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_613748 = newJObject()
  if body != nil:
    body_613748 = body
  result = call_613747.call(nil, nil, nil, nil, body_613748)

var getTestGridProject* = Call_GetTestGridProject_613734(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_613735, base: "/",
    url: url_GetTestGridProject_613736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_613749 = ref object of OpenApiRestCall_612659
proc url_GetTestGridSession_613751(protocol: Scheme; host: string; base: string;
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

proc validate_GetTestGridSession_613750(path: JsonNode; query: JsonNode;
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
  var valid_613752 = header.getOrDefault("X-Amz-Target")
  valid_613752 = validateParameter(valid_613752, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_613752 != nil:
    section.add "X-Amz-Target", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Signature")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Signature", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Content-Sha256", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Date")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Date", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Credential")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Credential", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Security-Token")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Security-Token", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Algorithm")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Algorithm", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-SignedHeaders", valid_613759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613761: Call_GetTestGridSession_613749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  let valid = call_613761.validator(path, query, header, formData, body)
  let scheme = call_613761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613761.url(scheme.get, call_613761.host, call_613761.base,
                         call_613761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613761, url, valid)

proc call*(call_613762: Call_GetTestGridSession_613749; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   body: JObject (required)
  var body_613763 = newJObject()
  if body != nil:
    body_613763 = body
  result = call_613762.call(nil, nil, nil, nil, body_613763)

var getTestGridSession* = Call_GetTestGridSession_613749(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_613750, base: "/",
    url: url_GetTestGridSession_613751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_613764 = ref object of OpenApiRestCall_612659
proc url_GetUpload_613766(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_613765(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613767 = header.getOrDefault("X-Amz-Target")
  valid_613767 = validateParameter(valid_613767, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_613767 != nil:
    section.add "X-Amz-Target", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Signature")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Signature", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Content-Sha256", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Date")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Date", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Credential")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Credential", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Security-Token")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Security-Token", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Algorithm")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Algorithm", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-SignedHeaders", valid_613774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613776: Call_GetUpload_613764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_613776.validator(path, query, header, formData, body)
  let scheme = call_613776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613776.url(scheme.get, call_613776.host, call_613776.base,
                         call_613776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613776, url, valid)

proc call*(call_613777: Call_GetUpload_613764; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_613778 = newJObject()
  if body != nil:
    body_613778 = body
  result = call_613777.call(nil, nil, nil, nil, body_613778)

var getUpload* = Call_GetUpload_613764(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_613765,
                                    base: "/", url: url_GetUpload_613766,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_613779 = ref object of OpenApiRestCall_612659
proc url_GetVPCEConfiguration_613781(protocol: Scheme; host: string; base: string;
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

proc validate_GetVPCEConfiguration_613780(path: JsonNode; query: JsonNode;
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
  var valid_613782 = header.getOrDefault("X-Amz-Target")
  valid_613782 = validateParameter(valid_613782, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_613782 != nil:
    section.add "X-Amz-Target", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Signature")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Signature", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Content-Sha256", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Date")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Date", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Credential")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Credential", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Security-Token")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Security-Token", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Algorithm")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Algorithm", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-SignedHeaders", valid_613789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613791: Call_GetVPCEConfiguration_613779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_613791.validator(path, query, header, formData, body)
  let scheme = call_613791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613791.url(scheme.get, call_613791.host, call_613791.base,
                         call_613791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613791, url, valid)

proc call*(call_613792: Call_GetVPCEConfiguration_613779; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_613793 = newJObject()
  if body != nil:
    body_613793 = body
  result = call_613792.call(nil, nil, nil, nil, body_613793)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_613779(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_613780, base: "/",
    url: url_GetVPCEConfiguration_613781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_613794 = ref object of OpenApiRestCall_612659
proc url_InstallToRemoteAccessSession_613796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_613795(path: JsonNode; query: JsonNode;
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
  var valid_613797 = header.getOrDefault("X-Amz-Target")
  valid_613797 = validateParameter(valid_613797, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_613797 != nil:
    section.add "X-Amz-Target", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Signature")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Signature", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Content-Sha256", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Date")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Date", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Credential")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Credential", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Security-Token")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Security-Token", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Algorithm")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Algorithm", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-SignedHeaders", valid_613804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613806: Call_InstallToRemoteAccessSession_613794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_613806.validator(path, query, header, formData, body)
  let scheme = call_613806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613806.url(scheme.get, call_613806.host, call_613806.base,
                         call_613806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613806, url, valid)

proc call*(call_613807: Call_InstallToRemoteAccessSession_613794; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_613808 = newJObject()
  if body != nil:
    body_613808 = body
  result = call_613807.call(nil, nil, nil, nil, body_613808)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_613794(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_613795, base: "/",
    url: url_InstallToRemoteAccessSession_613796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_613809 = ref object of OpenApiRestCall_612659
proc url_ListArtifacts_613811(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_613810(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613812 = query.getOrDefault("nextToken")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "nextToken", valid_613812
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
  var valid_613813 = header.getOrDefault("X-Amz-Target")
  valid_613813 = validateParameter(valid_613813, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_613813 != nil:
    section.add "X-Amz-Target", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Signature")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Signature", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Content-Sha256", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Date")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Date", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Credential")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Credential", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Security-Token")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Security-Token", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Algorithm")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Algorithm", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-SignedHeaders", valid_613820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613822: Call_ListArtifacts_613809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_613822.validator(path, query, header, formData, body)
  let scheme = call_613822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613822.url(scheme.get, call_613822.host, call_613822.base,
                         call_613822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613822, url, valid)

proc call*(call_613823: Call_ListArtifacts_613809; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613824 = newJObject()
  var body_613825 = newJObject()
  add(query_613824, "nextToken", newJString(nextToken))
  if body != nil:
    body_613825 = body
  result = call_613823.call(nil, query_613824, nil, nil, body_613825)

var listArtifacts* = Call_ListArtifacts_613809(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_613810, base: "/", url: url_ListArtifacts_613811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_613826 = ref object of OpenApiRestCall_612659
proc url_ListDeviceInstances_613828(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceInstances_613827(path: JsonNode; query: JsonNode;
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
  var valid_613829 = header.getOrDefault("X-Amz-Target")
  valid_613829 = validateParameter(valid_613829, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_613829 != nil:
    section.add "X-Amz-Target", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Signature")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Signature", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Content-Sha256", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Date")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Date", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Credential")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Credential", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Security-Token")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Security-Token", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Algorithm")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Algorithm", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-SignedHeaders", valid_613836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613838: Call_ListDeviceInstances_613826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_613838.validator(path, query, header, formData, body)
  let scheme = call_613838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613838.url(scheme.get, call_613838.host, call_613838.base,
                         call_613838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613838, url, valid)

proc call*(call_613839: Call_ListDeviceInstances_613826; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_613840 = newJObject()
  if body != nil:
    body_613840 = body
  result = call_613839.call(nil, nil, nil, nil, body_613840)

var listDeviceInstances* = Call_ListDeviceInstances_613826(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_613827, base: "/",
    url: url_ListDeviceInstances_613828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_613841 = ref object of OpenApiRestCall_612659
proc url_ListDevicePools_613843(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevicePools_613842(path: JsonNode; query: JsonNode;
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
  var valid_613844 = query.getOrDefault("nextToken")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "nextToken", valid_613844
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
  var valid_613845 = header.getOrDefault("X-Amz-Target")
  valid_613845 = validateParameter(valid_613845, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_613845 != nil:
    section.add "X-Amz-Target", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Signature")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Signature", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Content-Sha256", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Date")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Date", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Credential")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Credential", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Security-Token")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Security-Token", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Algorithm")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Algorithm", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-SignedHeaders", valid_613852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_ListDevicePools_613841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_ListDevicePools_613841; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613856 = newJObject()
  var body_613857 = newJObject()
  add(query_613856, "nextToken", newJString(nextToken))
  if body != nil:
    body_613857 = body
  result = call_613855.call(nil, query_613856, nil, nil, body_613857)

var listDevicePools* = Call_ListDevicePools_613841(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_613842, base: "/", url: url_ListDevicePools_613843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_613858 = ref object of OpenApiRestCall_612659
proc url_ListDevices_613860(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_613859(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613861 = query.getOrDefault("nextToken")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "nextToken", valid_613861
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
  var valid_613862 = header.getOrDefault("X-Amz-Target")
  valid_613862 = validateParameter(valid_613862, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_613862 != nil:
    section.add "X-Amz-Target", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Signature")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Signature", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Content-Sha256", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Date")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Date", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Credential")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Credential", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Security-Token")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Security-Token", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Algorithm")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Algorithm", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-SignedHeaders", valid_613869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_ListDevices_613858; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_ListDevices_613858; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613873 = newJObject()
  var body_613874 = newJObject()
  add(query_613873, "nextToken", newJString(nextToken))
  if body != nil:
    body_613874 = body
  result = call_613872.call(nil, query_613873, nil, nil, body_613874)

var listDevices* = Call_ListDevices_613858(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_613859,
                                        base: "/", url: url_ListDevices_613860,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_613875 = ref object of OpenApiRestCall_612659
proc url_ListInstanceProfiles_613877(protocol: Scheme; host: string; base: string;
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

proc validate_ListInstanceProfiles_613876(path: JsonNode; query: JsonNode;
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
  var valid_613878 = header.getOrDefault("X-Amz-Target")
  valid_613878 = validateParameter(valid_613878, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_613878 != nil:
    section.add "X-Amz-Target", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Signature")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Signature", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Content-Sha256", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Date")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Date", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Credential")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Credential", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Security-Token")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Security-Token", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Algorithm")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Algorithm", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-SignedHeaders", valid_613885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_ListInstanceProfiles_613875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_ListInstanceProfiles_613875; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_613889 = newJObject()
  if body != nil:
    body_613889 = body
  result = call_613888.call(nil, nil, nil, nil, body_613889)

var listInstanceProfiles* = Call_ListInstanceProfiles_613875(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_613876, base: "/",
    url: url_ListInstanceProfiles_613877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_613890 = ref object of OpenApiRestCall_612659
proc url_ListJobs_613892(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_613891(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613893 = query.getOrDefault("nextToken")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "nextToken", valid_613893
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
  var valid_613894 = header.getOrDefault("X-Amz-Target")
  valid_613894 = validateParameter(valid_613894, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_613894 != nil:
    section.add "X-Amz-Target", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Signature")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Signature", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Content-Sha256", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Date")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Date", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Credential")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Credential", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Security-Token")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Security-Token", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Algorithm")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Algorithm", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-SignedHeaders", valid_613901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613903: Call_ListJobs_613890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_613903.validator(path, query, header, formData, body)
  let scheme = call_613903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613903.url(scheme.get, call_613903.host, call_613903.base,
                         call_613903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613903, url, valid)

proc call*(call_613904: Call_ListJobs_613890; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613905 = newJObject()
  var body_613906 = newJObject()
  add(query_613905, "nextToken", newJString(nextToken))
  if body != nil:
    body_613906 = body
  result = call_613904.call(nil, query_613905, nil, nil, body_613906)

var listJobs* = Call_ListJobs_613890(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_613891, base: "/",
                                  url: url_ListJobs_613892,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_613907 = ref object of OpenApiRestCall_612659
proc url_ListNetworkProfiles_613909(protocol: Scheme; host: string; base: string;
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

proc validate_ListNetworkProfiles_613908(path: JsonNode; query: JsonNode;
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
  var valid_613910 = header.getOrDefault("X-Amz-Target")
  valid_613910 = validateParameter(valid_613910, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_613910 != nil:
    section.add "X-Amz-Target", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Signature")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Signature", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Content-Sha256", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Date")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Date", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Credential")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Credential", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Security-Token")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Security-Token", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Algorithm")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Algorithm", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-SignedHeaders", valid_613917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613919: Call_ListNetworkProfiles_613907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_613919.validator(path, query, header, formData, body)
  let scheme = call_613919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613919.url(scheme.get, call_613919.host, call_613919.base,
                         call_613919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613919, url, valid)

proc call*(call_613920: Call_ListNetworkProfiles_613907; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_613921 = newJObject()
  if body != nil:
    body_613921 = body
  result = call_613920.call(nil, nil, nil, nil, body_613921)

var listNetworkProfiles* = Call_ListNetworkProfiles_613907(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_613908, base: "/",
    url: url_ListNetworkProfiles_613909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_613922 = ref object of OpenApiRestCall_612659
proc url_ListOfferingPromotions_613924(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferingPromotions_613923(path: JsonNode; query: JsonNode;
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
  var valid_613925 = header.getOrDefault("X-Amz-Target")
  valid_613925 = validateParameter(valid_613925, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_613925 != nil:
    section.add "X-Amz-Target", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Signature")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Signature", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Content-Sha256", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Date")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Date", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Credential")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Credential", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Security-Token")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Security-Token", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Algorithm")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Algorithm", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-SignedHeaders", valid_613932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613934: Call_ListOfferingPromotions_613922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  let valid = call_613934.validator(path, query, header, formData, body)
  let scheme = call_613934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613934.url(scheme.get, call_613934.host, call_613934.base,
                         call_613934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613934, url, valid)

proc call*(call_613935: Call_ListOfferingPromotions_613922; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   body: JObject (required)
  var body_613936 = newJObject()
  if body != nil:
    body_613936 = body
  result = call_613935.call(nil, nil, nil, nil, body_613936)

var listOfferingPromotions* = Call_ListOfferingPromotions_613922(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_613923, base: "/",
    url: url_ListOfferingPromotions_613924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_613937 = ref object of OpenApiRestCall_612659
proc url_ListOfferingTransactions_613939(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingTransactions_613938(path: JsonNode; query: JsonNode;
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
  var valid_613940 = query.getOrDefault("nextToken")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "nextToken", valid_613940
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
  var valid_613941 = header.getOrDefault("X-Amz-Target")
  valid_613941 = validateParameter(valid_613941, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_613941 != nil:
    section.add "X-Amz-Target", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Signature")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Signature", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Content-Sha256", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Date")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Date", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Credential")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Credential", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Security-Token")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Security-Token", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Algorithm")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Algorithm", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-SignedHeaders", valid_613948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613950: Call_ListOfferingTransactions_613937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_613950.validator(path, query, header, formData, body)
  let scheme = call_613950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613950.url(scheme.get, call_613950.host, call_613950.base,
                         call_613950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613950, url, valid)

proc call*(call_613951: Call_ListOfferingTransactions_613937; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613952 = newJObject()
  var body_613953 = newJObject()
  add(query_613952, "nextToken", newJString(nextToken))
  if body != nil:
    body_613953 = body
  result = call_613951.call(nil, query_613952, nil, nil, body_613953)

var listOfferingTransactions* = Call_ListOfferingTransactions_613937(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_613938, base: "/",
    url: url_ListOfferingTransactions_613939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_613954 = ref object of OpenApiRestCall_612659
proc url_ListOfferings_613956(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferings_613955(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613957 = query.getOrDefault("nextToken")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "nextToken", valid_613957
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
  var valid_613958 = header.getOrDefault("X-Amz-Target")
  valid_613958 = validateParameter(valid_613958, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_613958 != nil:
    section.add "X-Amz-Target", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613967: Call_ListOfferings_613954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_613967.validator(path, query, header, formData, body)
  let scheme = call_613967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613967.url(scheme.get, call_613967.host, call_613967.base,
                         call_613967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613967, url, valid)

proc call*(call_613968: Call_ListOfferings_613954; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613969 = newJObject()
  var body_613970 = newJObject()
  add(query_613969, "nextToken", newJString(nextToken))
  if body != nil:
    body_613970 = body
  result = call_613968.call(nil, query_613969, nil, nil, body_613970)

var listOfferings* = Call_ListOfferings_613954(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_613955, base: "/", url: url_ListOfferings_613956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_613971 = ref object of OpenApiRestCall_612659
proc url_ListProjects_613973(protocol: Scheme; host: string; base: string;
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

proc validate_ListProjects_613972(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613974 = query.getOrDefault("nextToken")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "nextToken", valid_613974
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
  var valid_613975 = header.getOrDefault("X-Amz-Target")
  valid_613975 = validateParameter(valid_613975, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_613975 != nil:
    section.add "X-Amz-Target", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Signature")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Signature", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Content-Sha256", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Date")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Date", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Credential")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Credential", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Security-Token")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Security-Token", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Algorithm")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Algorithm", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-SignedHeaders", valid_613982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613984: Call_ListProjects_613971; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_613984.validator(path, query, header, formData, body)
  let scheme = call_613984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613984.url(scheme.get, call_613984.host, call_613984.base,
                         call_613984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613984, url, valid)

proc call*(call_613985: Call_ListProjects_613971; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613986 = newJObject()
  var body_613987 = newJObject()
  add(query_613986, "nextToken", newJString(nextToken))
  if body != nil:
    body_613987 = body
  result = call_613985.call(nil, query_613986, nil, nil, body_613987)

var listProjects* = Call_ListProjects_613971(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_613972, base: "/", url: url_ListProjects_613973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_613988 = ref object of OpenApiRestCall_612659
proc url_ListRemoteAccessSessions_613990(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRemoteAccessSessions_613989(path: JsonNode; query: JsonNode;
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
  var valid_613991 = header.getOrDefault("X-Amz-Target")
  valid_613991 = validateParameter(valid_613991, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_613991 != nil:
    section.add "X-Amz-Target", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Signature")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Signature", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Content-Sha256", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Date")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Date", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Credential")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Credential", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Security-Token")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Security-Token", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Algorithm")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Algorithm", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-SignedHeaders", valid_613998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614000: Call_ListRemoteAccessSessions_613988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_614000.validator(path, query, header, formData, body)
  let scheme = call_614000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614000.url(scheme.get, call_614000.host, call_614000.base,
                         call_614000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614000, url, valid)

proc call*(call_614001: Call_ListRemoteAccessSessions_613988; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_614002 = newJObject()
  if body != nil:
    body_614002 = body
  result = call_614001.call(nil, nil, nil, nil, body_614002)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_613988(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_613989, base: "/",
    url: url_ListRemoteAccessSessions_613990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_614003 = ref object of OpenApiRestCall_612659
proc url_ListRuns_614005(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_614004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614006 = query.getOrDefault("nextToken")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "nextToken", valid_614006
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
  var valid_614007 = header.getOrDefault("X-Amz-Target")
  valid_614007 = validateParameter(valid_614007, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_614007 != nil:
    section.add "X-Amz-Target", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Signature")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Signature", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Content-Sha256", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Date")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Date", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Credential")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Credential", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Security-Token")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Security-Token", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Algorithm")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Algorithm", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-SignedHeaders", valid_614014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614016: Call_ListRuns_614003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_614016.validator(path, query, header, formData, body)
  let scheme = call_614016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614016.url(scheme.get, call_614016.host, call_614016.base,
                         call_614016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614016, url, valid)

proc call*(call_614017: Call_ListRuns_614003; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614018 = newJObject()
  var body_614019 = newJObject()
  add(query_614018, "nextToken", newJString(nextToken))
  if body != nil:
    body_614019 = body
  result = call_614017.call(nil, query_614018, nil, nil, body_614019)

var listRuns* = Call_ListRuns_614003(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_614004, base: "/",
                                  url: url_ListRuns_614005,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_614020 = ref object of OpenApiRestCall_612659
proc url_ListSamples_614022(protocol: Scheme; host: string; base: string;
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

proc validate_ListSamples_614021(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614023 = query.getOrDefault("nextToken")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "nextToken", valid_614023
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
  var valid_614024 = header.getOrDefault("X-Amz-Target")
  valid_614024 = validateParameter(valid_614024, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_614024 != nil:
    section.add "X-Amz-Target", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Signature")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Signature", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Content-Sha256", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Date")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Date", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Credential")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Credential", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Security-Token")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Security-Token", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Algorithm")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Algorithm", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-SignedHeaders", valid_614031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614033: Call_ListSamples_614020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_614033.validator(path, query, header, formData, body)
  let scheme = call_614033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614033.url(scheme.get, call_614033.host, call_614033.base,
                         call_614033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614033, url, valid)

proc call*(call_614034: Call_ListSamples_614020; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614035 = newJObject()
  var body_614036 = newJObject()
  add(query_614035, "nextToken", newJString(nextToken))
  if body != nil:
    body_614036 = body
  result = call_614034.call(nil, query_614035, nil, nil, body_614036)

var listSamples* = Call_ListSamples_614020(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_614021,
                                        base: "/", url: url_ListSamples_614022,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_614037 = ref object of OpenApiRestCall_612659
proc url_ListSuites_614039(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_614038(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614040 = query.getOrDefault("nextToken")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "nextToken", valid_614040
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
  var valid_614041 = header.getOrDefault("X-Amz-Target")
  valid_614041 = validateParameter(valid_614041, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_614041 != nil:
    section.add "X-Amz-Target", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Signature")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Signature", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Content-Sha256", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Date")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Date", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Credential")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Credential", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Security-Token")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Security-Token", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Algorithm")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Algorithm", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-SignedHeaders", valid_614048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614050: Call_ListSuites_614037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_614050.validator(path, query, header, formData, body)
  let scheme = call_614050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614050.url(scheme.get, call_614050.host, call_614050.base,
                         call_614050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614050, url, valid)

proc call*(call_614051: Call_ListSuites_614037; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614052 = newJObject()
  var body_614053 = newJObject()
  add(query_614052, "nextToken", newJString(nextToken))
  if body != nil:
    body_614053 = body
  result = call_614051.call(nil, query_614052, nil, nil, body_614053)

var listSuites* = Call_ListSuites_614037(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_614038,
                                      base: "/", url: url_ListSuites_614039,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_614054 = ref object of OpenApiRestCall_612659
proc url_ListTagsForResource_614056(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_614055(path: JsonNode; query: JsonNode;
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
  var valid_614057 = header.getOrDefault("X-Amz-Target")
  valid_614057 = validateParameter(valid_614057, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_614057 != nil:
    section.add "X-Amz-Target", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Signature")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Signature", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Content-Sha256", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Date")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Date", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Credential")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Credential", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-Security-Token")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Security-Token", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Algorithm")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Algorithm", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-SignedHeaders", valid_614064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614066: Call_ListTagsForResource_614054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_614066.validator(path, query, header, formData, body)
  let scheme = call_614066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614066.url(scheme.get, call_614066.host, call_614066.base,
                         call_614066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614066, url, valid)

proc call*(call_614067: Call_ListTagsForResource_614054; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_614068 = newJObject()
  if body != nil:
    body_614068 = body
  result = call_614067.call(nil, nil, nil, nil, body_614068)

var listTagsForResource* = Call_ListTagsForResource_614054(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_614055, base: "/",
    url: url_ListTagsForResource_614056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_614069 = ref object of OpenApiRestCall_612659
proc url_ListTestGridProjects_614071(protocol: Scheme; host: string; base: string;
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

proc validate_ListTestGridProjects_614070(path: JsonNode; query: JsonNode;
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
  var valid_614072 = query.getOrDefault("nextToken")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "nextToken", valid_614072
  var valid_614073 = query.getOrDefault("maxResult")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "maxResult", valid_614073
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
  var valid_614074 = header.getOrDefault("X-Amz-Target")
  valid_614074 = validateParameter(valid_614074, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_614074 != nil:
    section.add "X-Amz-Target", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-Signature")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Signature", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Content-Sha256", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Date")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Date", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Credential")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Credential", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Security-Token")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Security-Token", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Algorithm")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Algorithm", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-SignedHeaders", valid_614081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614083: Call_ListTestGridProjects_614069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  let valid = call_614083.validator(path, query, header, formData, body)
  let scheme = call_614083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614083.url(scheme.get, call_614083.host, call_614083.base,
                         call_614083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614083, url, valid)

proc call*(call_614084: Call_ListTestGridProjects_614069; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_614085 = newJObject()
  var body_614086 = newJObject()
  add(query_614085, "nextToken", newJString(nextToken))
  add(query_614085, "maxResult", newJString(maxResult))
  if body != nil:
    body_614086 = body
  result = call_614084.call(nil, query_614085, nil, nil, body_614086)

var listTestGridProjects* = Call_ListTestGridProjects_614069(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_614070, base: "/",
    url: url_ListTestGridProjects_614071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_614087 = ref object of OpenApiRestCall_612659
proc url_ListTestGridSessionActions_614089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionActions_614088(path: JsonNode; query: JsonNode;
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
  var valid_614090 = query.getOrDefault("nextToken")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "nextToken", valid_614090
  var valid_614091 = query.getOrDefault("maxResult")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "maxResult", valid_614091
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
  var valid_614092 = header.getOrDefault("X-Amz-Target")
  valid_614092 = validateParameter(valid_614092, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_614092 != nil:
    section.add "X-Amz-Target", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Signature")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Signature", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Content-Sha256", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Date")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Date", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Credential")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Credential", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Security-Token")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Security-Token", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Algorithm")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Algorithm", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-SignedHeaders", valid_614099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614101: Call_ListTestGridSessionActions_614087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  let valid = call_614101.validator(path, query, header, formData, body)
  let scheme = call_614101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614101.url(scheme.get, call_614101.host, call_614101.base,
                         call_614101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614101, url, valid)

proc call*(call_614102: Call_ListTestGridSessionActions_614087; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_614103 = newJObject()
  var body_614104 = newJObject()
  add(query_614103, "nextToken", newJString(nextToken))
  add(query_614103, "maxResult", newJString(maxResult))
  if body != nil:
    body_614104 = body
  result = call_614102.call(nil, query_614103, nil, nil, body_614104)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_614087(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_614088, base: "/",
    url: url_ListTestGridSessionActions_614089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_614105 = ref object of OpenApiRestCall_612659
proc url_ListTestGridSessionArtifacts_614107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionArtifacts_614106(path: JsonNode; query: JsonNode;
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
  var valid_614108 = query.getOrDefault("nextToken")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "nextToken", valid_614108
  var valid_614109 = query.getOrDefault("maxResult")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "maxResult", valid_614109
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
  var valid_614110 = header.getOrDefault("X-Amz-Target")
  valid_614110 = validateParameter(valid_614110, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_614110 != nil:
    section.add "X-Amz-Target", valid_614110
  var valid_614111 = header.getOrDefault("X-Amz-Signature")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Signature", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Content-Sha256", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Date")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Date", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Credential")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Credential", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Security-Token")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Security-Token", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Algorithm")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Algorithm", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-SignedHeaders", valid_614117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614119: Call_ListTestGridSessionArtifacts_614105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of artifacts created during the session.
  ## 
  let valid = call_614119.validator(path, query, header, formData, body)
  let scheme = call_614119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614119.url(scheme.get, call_614119.host, call_614119.base,
                         call_614119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614119, url, valid)

proc call*(call_614120: Call_ListTestGridSessionArtifacts_614105; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_614121 = newJObject()
  var body_614122 = newJObject()
  add(query_614121, "nextToken", newJString(nextToken))
  add(query_614121, "maxResult", newJString(maxResult))
  if body != nil:
    body_614122 = body
  result = call_614120.call(nil, query_614121, nil, nil, body_614122)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_614105(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_614106, base: "/",
    url: url_ListTestGridSessionArtifacts_614107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_614123 = ref object of OpenApiRestCall_612659
proc url_ListTestGridSessions_614125(protocol: Scheme; host: string; base: string;
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

proc validate_ListTestGridSessions_614124(path: JsonNode; query: JsonNode;
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
  var valid_614126 = query.getOrDefault("nextToken")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "nextToken", valid_614126
  var valid_614127 = query.getOrDefault("maxResult")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "maxResult", valid_614127
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
  var valid_614128 = header.getOrDefault("X-Amz-Target")
  valid_614128 = validateParameter(valid_614128, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_614128 != nil:
    section.add "X-Amz-Target", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Signature")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Signature", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Content-Sha256", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Date")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Date", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Credential")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Credential", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Security-Token")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Security-Token", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Algorithm")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Algorithm", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-SignedHeaders", valid_614135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614137: Call_ListTestGridSessions_614123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  let valid = call_614137.validator(path, query, header, formData, body)
  let scheme = call_614137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614137.url(scheme.get, call_614137.host, call_614137.base,
                         call_614137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614137, url, valid)

proc call*(call_614138: Call_ListTestGridSessions_614123; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_614139 = newJObject()
  var body_614140 = newJObject()
  add(query_614139, "nextToken", newJString(nextToken))
  add(query_614139, "maxResult", newJString(maxResult))
  if body != nil:
    body_614140 = body
  result = call_614138.call(nil, query_614139, nil, nil, body_614140)

var listTestGridSessions* = Call_ListTestGridSessions_614123(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_614124, base: "/",
    url: url_ListTestGridSessions_614125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_614141 = ref object of OpenApiRestCall_612659
proc url_ListTests_614143(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_614142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614144 = query.getOrDefault("nextToken")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "nextToken", valid_614144
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
  var valid_614145 = header.getOrDefault("X-Amz-Target")
  valid_614145 = validateParameter(valid_614145, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_614145 != nil:
    section.add "X-Amz-Target", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Signature")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Signature", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Content-Sha256", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Date")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Date", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Credential")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Credential", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Security-Token")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Security-Token", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Algorithm")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Algorithm", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-SignedHeaders", valid_614152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614154: Call_ListTests_614141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_614154.validator(path, query, header, formData, body)
  let scheme = call_614154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614154.url(scheme.get, call_614154.host, call_614154.base,
                         call_614154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614154, url, valid)

proc call*(call_614155: Call_ListTests_614141; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614156 = newJObject()
  var body_614157 = newJObject()
  add(query_614156, "nextToken", newJString(nextToken))
  if body != nil:
    body_614157 = body
  result = call_614155.call(nil, query_614156, nil, nil, body_614157)

var listTests* = Call_ListTests_614141(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_614142,
                                    base: "/", url: url_ListTests_614143,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_614158 = ref object of OpenApiRestCall_612659
proc url_ListUniqueProblems_614160(protocol: Scheme; host: string; base: string;
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

proc validate_ListUniqueProblems_614159(path: JsonNode; query: JsonNode;
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
  var valid_614161 = query.getOrDefault("nextToken")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "nextToken", valid_614161
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
  var valid_614162 = header.getOrDefault("X-Amz-Target")
  valid_614162 = validateParameter(valid_614162, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_614162 != nil:
    section.add "X-Amz-Target", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Signature")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Signature", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Content-Sha256", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Date")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Date", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Credential")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Credential", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Security-Token")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Security-Token", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Algorithm")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Algorithm", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-SignedHeaders", valid_614169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614171: Call_ListUniqueProblems_614158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  let valid = call_614171.validator(path, query, header, formData, body)
  let scheme = call_614171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614171.url(scheme.get, call_614171.host, call_614171.base,
                         call_614171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614171, url, valid)

proc call*(call_614172: Call_ListUniqueProblems_614158; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614173 = newJObject()
  var body_614174 = newJObject()
  add(query_614173, "nextToken", newJString(nextToken))
  if body != nil:
    body_614174 = body
  result = call_614172.call(nil, query_614173, nil, nil, body_614174)

var listUniqueProblems* = Call_ListUniqueProblems_614158(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_614159, base: "/",
    url: url_ListUniqueProblems_614160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_614175 = ref object of OpenApiRestCall_612659
proc url_ListUploads_614177(protocol: Scheme; host: string; base: string;
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

proc validate_ListUploads_614176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614178 = query.getOrDefault("nextToken")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "nextToken", valid_614178
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
  var valid_614179 = header.getOrDefault("X-Amz-Target")
  valid_614179 = validateParameter(valid_614179, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_614179 != nil:
    section.add "X-Amz-Target", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Signature")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Signature", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Content-Sha256", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Date")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Date", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Credential")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Credential", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Security-Token")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Security-Token", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Algorithm")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Algorithm", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-SignedHeaders", valid_614186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614188: Call_ListUploads_614175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_614188.validator(path, query, header, formData, body)
  let scheme = call_614188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614188.url(scheme.get, call_614188.host, call_614188.base,
                         call_614188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614188, url, valid)

proc call*(call_614189: Call_ListUploads_614175; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614190 = newJObject()
  var body_614191 = newJObject()
  add(query_614190, "nextToken", newJString(nextToken))
  if body != nil:
    body_614191 = body
  result = call_614189.call(nil, query_614190, nil, nil, body_614191)

var listUploads* = Call_ListUploads_614175(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_614176,
                                        base: "/", url: url_ListUploads_614177,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_614192 = ref object of OpenApiRestCall_612659
proc url_ListVPCEConfigurations_614194(protocol: Scheme; host: string; base: string;
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

proc validate_ListVPCEConfigurations_614193(path: JsonNode; query: JsonNode;
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
  var valid_614195 = header.getOrDefault("X-Amz-Target")
  valid_614195 = validateParameter(valid_614195, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_614195 != nil:
    section.add "X-Amz-Target", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Signature")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Signature", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Content-Sha256", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Date")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Date", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Credential")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Credential", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Security-Token")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Security-Token", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Algorithm")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Algorithm", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-SignedHeaders", valid_614202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614204: Call_ListVPCEConfigurations_614192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_614204.validator(path, query, header, formData, body)
  let scheme = call_614204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614204.url(scheme.get, call_614204.host, call_614204.base,
                         call_614204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614204, url, valid)

proc call*(call_614205: Call_ListVPCEConfigurations_614192; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_614206 = newJObject()
  if body != nil:
    body_614206 = body
  result = call_614205.call(nil, nil, nil, nil, body_614206)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_614192(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_614193, base: "/",
    url: url_ListVPCEConfigurations_614194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_614207 = ref object of OpenApiRestCall_612659
proc url_PurchaseOffering_614209(protocol: Scheme; host: string; base: string;
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

proc validate_PurchaseOffering_614208(path: JsonNode; query: JsonNode;
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
  var valid_614210 = header.getOrDefault("X-Amz-Target")
  valid_614210 = validateParameter(valid_614210, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_614210 != nil:
    section.add "X-Amz-Target", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Signature")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Signature", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Content-Sha256", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Date")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Date", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Credential")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Credential", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Security-Token")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Security-Token", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Algorithm")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Algorithm", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-SignedHeaders", valid_614217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614219: Call_PurchaseOffering_614207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_614219.validator(path, query, header, formData, body)
  let scheme = call_614219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614219.url(scheme.get, call_614219.host, call_614219.base,
                         call_614219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614219, url, valid)

proc call*(call_614220: Call_PurchaseOffering_614207; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_614221 = newJObject()
  if body != nil:
    body_614221 = body
  result = call_614220.call(nil, nil, nil, nil, body_614221)

var purchaseOffering* = Call_PurchaseOffering_614207(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_614208, base: "/",
    url: url_PurchaseOffering_614209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_614222 = ref object of OpenApiRestCall_612659
proc url_RenewOffering_614224(protocol: Scheme; host: string; base: string;
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

proc validate_RenewOffering_614223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614225 = header.getOrDefault("X-Amz-Target")
  valid_614225 = validateParameter(valid_614225, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_614225 != nil:
    section.add "X-Amz-Target", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Signature")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Signature", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Content-Sha256", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Date")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Date", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Credential")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Credential", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Security-Token")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Security-Token", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Algorithm")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Algorithm", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-SignedHeaders", valid_614232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614234: Call_RenewOffering_614222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_614234.validator(path, query, header, formData, body)
  let scheme = call_614234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614234.url(scheme.get, call_614234.host, call_614234.base,
                         call_614234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614234, url, valid)

proc call*(call_614235: Call_RenewOffering_614222; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_614236 = newJObject()
  if body != nil:
    body_614236 = body
  result = call_614235.call(nil, nil, nil, nil, body_614236)

var renewOffering* = Call_RenewOffering_614222(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_614223, base: "/", url: url_RenewOffering_614224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_614237 = ref object of OpenApiRestCall_612659
proc url_ScheduleRun_614239(protocol: Scheme; host: string; base: string;
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

proc validate_ScheduleRun_614238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614240 = header.getOrDefault("X-Amz-Target")
  valid_614240 = validateParameter(valid_614240, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_614240 != nil:
    section.add "X-Amz-Target", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Signature")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Signature", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Content-Sha256", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Date")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Date", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Credential")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Credential", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Security-Token")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Security-Token", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Algorithm")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Algorithm", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-SignedHeaders", valid_614247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614249: Call_ScheduleRun_614237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_614249.validator(path, query, header, formData, body)
  let scheme = call_614249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614249.url(scheme.get, call_614249.host, call_614249.base,
                         call_614249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614249, url, valid)

proc call*(call_614250: Call_ScheduleRun_614237; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_614251 = newJObject()
  if body != nil:
    body_614251 = body
  result = call_614250.call(nil, nil, nil, nil, body_614251)

var scheduleRun* = Call_ScheduleRun_614237(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_614238,
                                        base: "/", url: url_ScheduleRun_614239,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_614252 = ref object of OpenApiRestCall_612659
proc url_StopJob_614254(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_614253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614255 = header.getOrDefault("X-Amz-Target")
  valid_614255 = validateParameter(valid_614255, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_614255 != nil:
    section.add "X-Amz-Target", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Signature")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Signature", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Content-Sha256", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Date")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Date", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Credential")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Credential", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Security-Token")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Security-Token", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Algorithm")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Algorithm", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-SignedHeaders", valid_614262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614264: Call_StopJob_614252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_614264.validator(path, query, header, formData, body)
  let scheme = call_614264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614264.url(scheme.get, call_614264.host, call_614264.base,
                         call_614264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614264, url, valid)

proc call*(call_614265: Call_StopJob_614252; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_614266 = newJObject()
  if body != nil:
    body_614266 = body
  result = call_614265.call(nil, nil, nil, nil, body_614266)

var stopJob* = Call_StopJob_614252(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_614253, base: "/",
                                url: url_StopJob_614254,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_614267 = ref object of OpenApiRestCall_612659
proc url_StopRemoteAccessSession_614269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRemoteAccessSession_614268(path: JsonNode; query: JsonNode;
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
  var valid_614270 = header.getOrDefault("X-Amz-Target")
  valid_614270 = validateParameter(valid_614270, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_614270 != nil:
    section.add "X-Amz-Target", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Signature")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Signature", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Content-Sha256", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Date")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Date", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Credential")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Credential", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Security-Token")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Security-Token", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Algorithm")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Algorithm", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-SignedHeaders", valid_614277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614279: Call_StopRemoteAccessSession_614267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_614279.validator(path, query, header, formData, body)
  let scheme = call_614279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614279.url(scheme.get, call_614279.host, call_614279.base,
                         call_614279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614279, url, valid)

proc call*(call_614280: Call_StopRemoteAccessSession_614267; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_614281 = newJObject()
  if body != nil:
    body_614281 = body
  result = call_614280.call(nil, nil, nil, nil, body_614281)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_614267(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_614268, base: "/",
    url: url_StopRemoteAccessSession_614269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_614282 = ref object of OpenApiRestCall_612659
proc url_StopRun_614284(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_614283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614285 = header.getOrDefault("X-Amz-Target")
  valid_614285 = validateParameter(valid_614285, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_614285 != nil:
    section.add "X-Amz-Target", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Signature")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Signature", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Content-Sha256", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-Date")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-Date", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Credential")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Credential", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Security-Token")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Security-Token", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Algorithm")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Algorithm", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-SignedHeaders", valid_614292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614294: Call_StopRun_614282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_614294.validator(path, query, header, formData, body)
  let scheme = call_614294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614294.url(scheme.get, call_614294.host, call_614294.base,
                         call_614294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614294, url, valid)

proc call*(call_614295: Call_StopRun_614282; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_614296 = newJObject()
  if body != nil:
    body_614296 = body
  result = call_614295.call(nil, nil, nil, nil, body_614296)

var stopRun* = Call_StopRun_614282(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_614283, base: "/",
                                url: url_StopRun_614284,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614297 = ref object of OpenApiRestCall_612659
proc url_TagResource_614299(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_614298(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614300 = header.getOrDefault("X-Amz-Target")
  valid_614300 = validateParameter(valid_614300, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_614300 != nil:
    section.add "X-Amz-Target", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Signature")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Signature", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Content-Sha256", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Date")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Date", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Credential")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Credential", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Security-Token")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Security-Token", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Algorithm")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Algorithm", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-SignedHeaders", valid_614307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614309: Call_TagResource_614297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  let valid = call_614309.validator(path, query, header, formData, body)
  let scheme = call_614309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614309.url(scheme.get, call_614309.host, call_614309.base,
                         call_614309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614309, url, valid)

proc call*(call_614310: Call_TagResource_614297; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   body: JObject (required)
  var body_614311 = newJObject()
  if body != nil:
    body_614311 = body
  result = call_614310.call(nil, nil, nil, nil, body_614311)

var tagResource* = Call_TagResource_614297(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_614298,
                                        base: "/", url: url_TagResource_614299,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614312 = ref object of OpenApiRestCall_612659
proc url_UntagResource_614314(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_614313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614315 = header.getOrDefault("X-Amz-Target")
  valid_614315 = validateParameter(valid_614315, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_614315 != nil:
    section.add "X-Amz-Target", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Signature")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Signature", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Content-Sha256", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Date")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Date", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Credential")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Credential", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Security-Token")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Security-Token", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Algorithm")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Algorithm", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-SignedHeaders", valid_614322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614324: Call_UntagResource_614312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_614324.validator(path, query, header, formData, body)
  let scheme = call_614324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614324.url(scheme.get, call_614324.host, call_614324.base,
                         call_614324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614324, url, valid)

proc call*(call_614325: Call_UntagResource_614312; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_614326 = newJObject()
  if body != nil:
    body_614326 = body
  result = call_614325.call(nil, nil, nil, nil, body_614326)

var untagResource* = Call_UntagResource_614312(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_614313, base: "/", url: url_UntagResource_614314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_614327 = ref object of OpenApiRestCall_612659
proc url_UpdateDeviceInstance_614329(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceInstance_614328(path: JsonNode; query: JsonNode;
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
  var valid_614330 = header.getOrDefault("X-Amz-Target")
  valid_614330 = validateParameter(valid_614330, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_614330 != nil:
    section.add "X-Amz-Target", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Signature")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Signature", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Content-Sha256", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Date")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Date", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Credential")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Credential", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Security-Token")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Security-Token", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Algorithm")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Algorithm", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-SignedHeaders", valid_614337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614339: Call_UpdateDeviceInstance_614327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about a private device instance.
  ## 
  let valid = call_614339.validator(path, query, header, formData, body)
  let scheme = call_614339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614339.url(scheme.get, call_614339.host, call_614339.base,
                         call_614339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614339, url, valid)

proc call*(call_614340: Call_UpdateDeviceInstance_614327; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_614341 = newJObject()
  if body != nil:
    body_614341 = body
  result = call_614340.call(nil, nil, nil, nil, body_614341)

var updateDeviceInstance* = Call_UpdateDeviceInstance_614327(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_614328, base: "/",
    url: url_UpdateDeviceInstance_614329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_614342 = ref object of OpenApiRestCall_612659
proc url_UpdateDevicePool_614344(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevicePool_614343(path: JsonNode; query: JsonNode;
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
  var valid_614345 = header.getOrDefault("X-Amz-Target")
  valid_614345 = validateParameter(valid_614345, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_614345 != nil:
    section.add "X-Amz-Target", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Signature")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Signature", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Content-Sha256", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Date")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Date", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Credential")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Credential", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Security-Token")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Security-Token", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Algorithm")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Algorithm", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-SignedHeaders", valid_614352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614354: Call_UpdateDevicePool_614342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_614354.validator(path, query, header, formData, body)
  let scheme = call_614354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614354.url(scheme.get, call_614354.host, call_614354.base,
                         call_614354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614354, url, valid)

proc call*(call_614355: Call_UpdateDevicePool_614342; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_614356 = newJObject()
  if body != nil:
    body_614356 = body
  result = call_614355.call(nil, nil, nil, nil, body_614356)

var updateDevicePool* = Call_UpdateDevicePool_614342(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_614343, base: "/",
    url: url_UpdateDevicePool_614344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_614357 = ref object of OpenApiRestCall_612659
proc url_UpdateInstanceProfile_614359(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInstanceProfile_614358(path: JsonNode; query: JsonNode;
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
  var valid_614360 = header.getOrDefault("X-Amz-Target")
  valid_614360 = validateParameter(valid_614360, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_614360 != nil:
    section.add "X-Amz-Target", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-Signature")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Signature", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Content-Sha256", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Date")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Date", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Credential")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Credential", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Security-Token")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Security-Token", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Algorithm")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Algorithm", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-SignedHeaders", valid_614367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614369: Call_UpdateInstanceProfile_614357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_614369.validator(path, query, header, formData, body)
  let scheme = call_614369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614369.url(scheme.get, call_614369.host, call_614369.base,
                         call_614369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614369, url, valid)

proc call*(call_614370: Call_UpdateInstanceProfile_614357; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_614371 = newJObject()
  if body != nil:
    body_614371 = body
  result = call_614370.call(nil, nil, nil, nil, body_614371)

var updateInstanceProfile* = Call_UpdateInstanceProfile_614357(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_614358, base: "/",
    url: url_UpdateInstanceProfile_614359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_614372 = ref object of OpenApiRestCall_612659
proc url_UpdateNetworkProfile_614374(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNetworkProfile_614373(path: JsonNode; query: JsonNode;
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
  var valid_614375 = header.getOrDefault("X-Amz-Target")
  valid_614375 = validateParameter(valid_614375, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_614375 != nil:
    section.add "X-Amz-Target", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-Signature")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-Signature", valid_614376
  var valid_614377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "X-Amz-Content-Sha256", valid_614377
  var valid_614378 = header.getOrDefault("X-Amz-Date")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "X-Amz-Date", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Credential")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Credential", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Security-Token")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Security-Token", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Algorithm")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Algorithm", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-SignedHeaders", valid_614382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614384: Call_UpdateNetworkProfile_614372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile.
  ## 
  let valid = call_614384.validator(path, query, header, formData, body)
  let scheme = call_614384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614384.url(scheme.get, call_614384.host, call_614384.base,
                         call_614384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614384, url, valid)

proc call*(call_614385: Call_UpdateNetworkProfile_614372; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_614386 = newJObject()
  if body != nil:
    body_614386 = body
  result = call_614385.call(nil, nil, nil, nil, body_614386)

var updateNetworkProfile* = Call_UpdateNetworkProfile_614372(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_614373, base: "/",
    url: url_UpdateNetworkProfile_614374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_614387 = ref object of OpenApiRestCall_612659
proc url_UpdateProject_614389(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_614388(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614390 = header.getOrDefault("X-Amz-Target")
  valid_614390 = validateParameter(valid_614390, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_614390 != nil:
    section.add "X-Amz-Target", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Signature")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Signature", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-Content-Sha256", valid_614392
  var valid_614393 = header.getOrDefault("X-Amz-Date")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Date", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Credential")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Credential", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Security-Token")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Security-Token", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-Algorithm")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-Algorithm", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-SignedHeaders", valid_614397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614399: Call_UpdateProject_614387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_614399.validator(path, query, header, formData, body)
  let scheme = call_614399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614399.url(scheme.get, call_614399.host, call_614399.base,
                         call_614399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614399, url, valid)

proc call*(call_614400: Call_UpdateProject_614387; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_614401 = newJObject()
  if body != nil:
    body_614401 = body
  result = call_614400.call(nil, nil, nil, nil, body_614401)

var updateProject* = Call_UpdateProject_614387(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_614388, base: "/", url: url_UpdateProject_614389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_614402 = ref object of OpenApiRestCall_612659
proc url_UpdateTestGridProject_614404(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTestGridProject_614403(path: JsonNode; query: JsonNode;
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
  var valid_614405 = header.getOrDefault("X-Amz-Target")
  valid_614405 = validateParameter(valid_614405, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_614405 != nil:
    section.add "X-Amz-Target", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Signature")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Signature", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Content-Sha256", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Date")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Date", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Credential")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Credential", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Security-Token")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Security-Token", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-Algorithm")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-Algorithm", valid_614411
  var valid_614412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614412 = validateParameter(valid_614412, JString, required = false,
                                 default = nil)
  if valid_614412 != nil:
    section.add "X-Amz-SignedHeaders", valid_614412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614414: Call_UpdateTestGridProject_614402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Change details of a project.
  ## 
  let valid = call_614414.validator(path, query, header, formData, body)
  let scheme = call_614414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614414.url(scheme.get, call_614414.host, call_614414.base,
                         call_614414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614414, url, valid)

proc call*(call_614415: Call_UpdateTestGridProject_614402; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_614416 = newJObject()
  if body != nil:
    body_614416 = body
  result = call_614415.call(nil, nil, nil, nil, body_614416)

var updateTestGridProject* = Call_UpdateTestGridProject_614402(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_614403, base: "/",
    url: url_UpdateTestGridProject_614404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_614417 = ref object of OpenApiRestCall_612659
proc url_UpdateUpload_614419(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUpload_614418(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614420 = header.getOrDefault("X-Amz-Target")
  valid_614420 = validateParameter(valid_614420, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_614420 != nil:
    section.add "X-Amz-Target", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Signature")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Signature", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Content-Sha256", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Date")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Date", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Credential")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Credential", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Security-Token")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Security-Token", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Algorithm")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Algorithm", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-SignedHeaders", valid_614427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614429: Call_UpdateUpload_614417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an uploaded test spec.
  ## 
  let valid = call_614429.validator(path, query, header, formData, body)
  let scheme = call_614429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614429.url(scheme.get, call_614429.host, call_614429.base,
                         call_614429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614429, url, valid)

proc call*(call_614430: Call_UpdateUpload_614417; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_614431 = newJObject()
  if body != nil:
    body_614431 = body
  result = call_614430.call(nil, nil, nil, nil, body_614431)

var updateUpload* = Call_UpdateUpload_614417(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_614418, base: "/", url: url_UpdateUpload_614419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_614432 = ref object of OpenApiRestCall_612659
proc url_UpdateVPCEConfiguration_614434(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVPCEConfiguration_614433(path: JsonNode; query: JsonNode;
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
  var valid_614435 = header.getOrDefault("X-Amz-Target")
  valid_614435 = validateParameter(valid_614435, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_614435 != nil:
    section.add "X-Amz-Target", valid_614435
  var valid_614436 = header.getOrDefault("X-Amz-Signature")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "X-Amz-Signature", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Content-Sha256", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Date")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Date", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Credential")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Credential", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Security-Token")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Security-Token", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Algorithm")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Algorithm", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-SignedHeaders", valid_614442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614444: Call_UpdateVPCEConfiguration_614432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_614444.validator(path, query, header, formData, body)
  let scheme = call_614444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614444.url(scheme.get, call_614444.host, call_614444.base,
                         call_614444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614444, url, valid)

proc call*(call_614445: Call_UpdateVPCEConfiguration_614432; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_614446 = newJObject()
  if body != nil:
    body_614446 = body
  result = call_614445.call(nil, nil, nil, nil, body_614446)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_614432(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_614433, base: "/",
    url: url_UpdateVPCEConfiguration_614434, schemes: {Scheme.Https, Scheme.Http})
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
