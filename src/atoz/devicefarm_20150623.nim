
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "devicefarm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "devicefarm.ap-southeast-1.amazonaws.com", "us-west-2": "devicefarm.us-west-2.amazonaws.com", "eu-west-2": "devicefarm.eu-west-2.amazonaws.com", "ap-northeast-3": "devicefarm.ap-northeast-3.amazonaws.com", "eu-central-1": "devicefarm.eu-central-1.amazonaws.com", "us-east-2": "devicefarm.us-east-2.amazonaws.com", "us-east-1": "devicefarm.us-east-1.amazonaws.com", "cn-northwest-1": "devicefarm.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "devicefarm.ap-south-1.amazonaws.com", "eu-north-1": "devicefarm.eu-north-1.amazonaws.com", "ap-northeast-2": "devicefarm.ap-northeast-2.amazonaws.com", "us-west-1": "devicefarm.us-west-1.amazonaws.com", "us-gov-east-1": "devicefarm.us-gov-east-1.amazonaws.com", "eu-west-3": "devicefarm.eu-west-3.amazonaws.com", "cn-north-1": "devicefarm.cn-north-1.amazonaws.com.cn", "sa-east-1": "devicefarm.sa-east-1.amazonaws.com", "eu-west-1": "devicefarm.eu-west-1.amazonaws.com", "us-gov-west-1": "devicefarm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "devicefarm.ap-southeast-2.amazonaws.com", "ca-central-1": "devicefarm.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateDevicePool_402656294 = ref object of OpenApiRestCall_402656044
proc url_CreateDevicePool_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevicePool_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_CreateDevicePool_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a device pool.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_CreateDevicePool_402656294; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var createDevicePool* = Call_CreateDevicePool_402656294(
    name: "createDevicePool", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_402656295, base: "/",
    makeUrl: url_CreateDevicePool_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_402656489 = ref object of OpenApiRestCall_402656044
proc url_CreateInstanceProfile_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceProfile_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_CreateInstanceProfile_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CreateInstanceProfile_402656489; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   
                                                                                         ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createInstanceProfile* = Call_CreateInstanceProfile_402656489(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_402656490, base: "/",
    makeUrl: url_CreateInstanceProfile_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateNetworkProfile_402656506(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_CreateNetworkProfile_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a network profile.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateNetworkProfile_402656504; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createNetworkProfile* = Call_CreateNetworkProfile_402656504(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_402656505, base: "/",
    makeUrl: url_CreateNetworkProfile_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateProject_402656521(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_402656520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_CreateProject_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a project.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateProject_402656519; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createProject* = Call_CreateProject_402656519(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_402656520, base: "/",
    makeUrl: url_CreateProject_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateRemoteAccessSession_402656536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRemoteAccessSession_402656535(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_CreateRemoteAccessSession_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specifies and starts a remote access session.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateRemoteAccessSession_402656534;
           body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_402656534(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_402656535, base: "/",
    makeUrl: url_CreateRemoteAccessSession_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateTestGridProject_402656551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridProject_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_CreateTestGridProject_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateTestGridProject_402656549; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   
                                                                                                     ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createTestGridProject* = Call_CreateTestGridProject_402656549(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_402656550, base: "/",
    makeUrl: url_CreateTestGridProject_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_402656564 = ref object of OpenApiRestCall_402656044
proc url_CreateTestGridUrl_402656566(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridUrl_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_CreateTestGridUrl_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CreateTestGridUrl_402656564; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   
                                                                                                                ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var createTestGridUrl* = Call_CreateTestGridUrl_402656564(
    name: "createTestGridUrl", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_402656565, base: "/",
    makeUrl: url_CreateTestGridUrl_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_402656579 = ref object of OpenApiRestCall_402656044
proc url_CreateUpload_402656581(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUpload_402656580(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_CreateUpload_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Uploads an app or test scripts.
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateUpload_402656579; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createUpload* = Call_CreateUpload_402656579(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_402656580, base: "/",
    makeUrl: url_CreateUpload_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_402656594 = ref object of OpenApiRestCall_402656044
proc url_CreateVPCEConfiguration_402656596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVPCEConfiguration_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_CreateVPCEConfiguration_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateVPCEConfiguration_402656594;
           body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   
                                                                                                        ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_402656594(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_402656595, base: "/",
    makeUrl: url_CreateVPCEConfiguration_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_402656609 = ref object of OpenApiRestCall_402656044
proc url_DeleteDevicePool_402656611(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevicePool_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_DeleteDevicePool_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DeleteDevicePool_402656609; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   
                                                                                                            ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var deleteDevicePool* = Call_DeleteDevicePool_402656609(
    name: "deleteDevicePool", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_402656610, base: "/",
    makeUrl: url_DeleteDevicePool_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_402656624 = ref object of OpenApiRestCall_402656044
proc url_DeleteInstanceProfile_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceProfile_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_DeleteInstanceProfile_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DeleteInstanceProfile_402656624; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_402656624(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_402656625, base: "/",
    makeUrl: url_DeleteInstanceProfile_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_402656639 = ref object of OpenApiRestCall_402656044
proc url_DeleteNetworkProfile_402656641(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_DeleteNetworkProfile_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a network profile.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeleteNetworkProfile_402656639; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_402656639(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_402656640, base: "/",
    makeUrl: url_DeleteNetworkProfile_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_402656654 = ref object of OpenApiRestCall_402656044
proc url_DeleteProject_402656656(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_402656655(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_DeleteProject_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DeleteProject_402656654; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   
                                                                                                                                       ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var deleteProject* = Call_DeleteProject_402656654(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_402656655, base: "/",
    makeUrl: url_DeleteProject_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_402656669 = ref object of OpenApiRestCall_402656044
proc url_DeleteRemoteAccessSession_402656671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_402656670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_DeleteRemoteAccessSession_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a completed remote access session and its results.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DeleteRemoteAccessSession_402656669;
           body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_402656669(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_402656670, base: "/",
    makeUrl: url_DeleteRemoteAccessSession_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_402656684 = ref object of OpenApiRestCall_402656044
proc url_DeleteRun_402656686(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_402656685(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
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

proc call*(call_402656696: Call_DeleteRun_402656684; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
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

proc call*(call_402656697: Call_DeleteRun_402656684; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   
                                                                                                                ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var deleteRun* = Call_DeleteRun_402656684(name: "deleteRun",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
    validator: validate_DeleteRun_402656685, base: "/", makeUrl: url_DeleteRun_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_402656699 = ref object of OpenApiRestCall_402656044
proc url_DeleteTestGridProject_402656701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTestGridProject_402656700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_DeleteTestGridProject_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
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

proc call*(call_402656712: Call_DeleteTestGridProject_402656699; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   
                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var deleteTestGridProject* = Call_DeleteTestGridProject_402656699(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_402656700, base: "/",
    makeUrl: url_DeleteTestGridProject_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_402656714 = ref object of OpenApiRestCall_402656044
proc url_DeleteUpload_402656716(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUpload_402656715(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
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

proc call*(call_402656726: Call_DeleteUpload_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an upload given the upload ARN.
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

proc call*(call_402656727: Call_DeleteUpload_402656714; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var deleteUpload* = Call_DeleteUpload_402656714(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_402656715, base: "/",
    makeUrl: url_DeleteUpload_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_402656729 = ref object of OpenApiRestCall_402656044
proc url_DeleteVPCEConfiguration_402656731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVPCEConfiguration_402656730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
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

proc call*(call_402656741: Call_DeleteVPCEConfiguration_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
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

proc call*(call_402656742: Call_DeleteVPCEConfiguration_402656729;
           body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   
                                                                                  ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_402656729(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_402656730, base: "/",
    makeUrl: url_DeleteVPCEConfiguration_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_402656744 = ref object of OpenApiRestCall_402656044
proc url_GetAccountSettings_402656746(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_GetAccountSettings_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
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

proc call*(call_402656757: Call_GetAccountSettings_402656744; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   
                                                                                                              ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var getAccountSettings* = Call_GetAccountSettings_402656744(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_402656745, base: "/",
    makeUrl: url_GetAccountSettings_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_402656759 = ref object of OpenApiRestCall_402656044
proc url_GetDevice_402656761(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_402656760(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
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

proc call*(call_402656771: Call_GetDevice_402656759; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a unique device type.
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_GetDevice_402656759; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var getDevice* = Call_GetDevice_402656759(name: "getDevice",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
    validator: validate_GetDevice_402656760, base: "/", makeUrl: url_GetDevice_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_402656774 = ref object of OpenApiRestCall_402656044
proc url_GetDeviceInstance_402656776(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeviceInstance_402656775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
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

proc call*(call_402656786: Call_GetDeviceInstance_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_GetDeviceInstance_402656774; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   
                                                                                        ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var getDeviceInstance* = Call_GetDeviceInstance_402656774(
    name: "getDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_402656775, base: "/",
    makeUrl: url_GetDeviceInstance_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_402656789 = ref object of OpenApiRestCall_402656044
proc url_GetDevicePool_402656791(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePool_402656790(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
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

proc call*(call_402656801: Call_GetDevicePool_402656789; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a device pool.
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_GetDevicePool_402656789; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var getDevicePool* = Call_GetDevicePool_402656789(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_402656790, base: "/",
    makeUrl: url_GetDevicePool_402656791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_402656804 = ref object of OpenApiRestCall_402656044
proc url_GetDevicePoolCompatibility_402656806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_402656805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
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

proc call*(call_402656816: Call_GetDevicePoolCompatibility_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about compatibility with a device pool.
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_GetDevicePoolCompatibility_402656804;
           body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_402656804(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_402656805, base: "/",
    makeUrl: url_GetDevicePoolCompatibility_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_402656819 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceProfile_402656821(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceProfile_402656820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
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

proc call*(call_402656831: Call_GetInstanceProfile_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified instance profile.
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_GetInstanceProfile_402656819; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var getInstanceProfile* = Call_GetInstanceProfile_402656819(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_402656820, base: "/",
    makeUrl: url_GetInstanceProfile_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_402656834 = ref object of OpenApiRestCall_402656044
proc url_GetJob_402656836(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_402656835(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
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

proc call*(call_402656846: Call_GetJob_402656834; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a job.
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_GetJob_402656834; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var getJob* = Call_GetJob_402656834(name: "getJob", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                                    validator: validate_GetJob_402656835,
                                    base: "/", makeUrl: url_GetJob_402656836,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_402656849 = ref object of OpenApiRestCall_402656044
proc url_GetNetworkProfile_402656851(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_402656850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
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

proc call*(call_402656861: Call_GetNetworkProfile_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a network profile.
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_GetNetworkProfile_402656849; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var getNetworkProfile* = Call_GetNetworkProfile_402656849(
    name: "getNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_402656850, base: "/",
    makeUrl: url_GetNetworkProfile_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_402656864 = ref object of OpenApiRestCall_402656044
proc url_GetOfferingStatus_402656866(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOfferingStatus_402656865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656867 = query.getOrDefault("nextToken")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "nextToken", valid_402656867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656868 = header.getOrDefault("X-Amz-Target")
  valid_402656868 = validateParameter(valid_402656868, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_402656868 != nil:
    section.add "X-Amz-Target", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Security-Token", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Signature")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Signature", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Algorithm", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Date")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Date", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Credential")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Credential", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656875
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

proc call*(call_402656877: Call_GetOfferingStatus_402656864;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
                                                                                         ## 
  let valid = call_402656877.validator(path, query, header, formData, body, _)
  let scheme = call_402656877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656877.makeUrl(scheme.get, call_402656877.host, call_402656877.base,
                                   call_402656877.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656877, uri, valid, _)

proc call*(call_402656878: Call_GetOfferingStatus_402656864; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var query_402656879 = newJObject()
  var body_402656880 = newJObject()
  add(query_402656879, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656880 = body
  result = call_402656878.call(nil, query_402656879, nil, nil, body_402656880)

var getOfferingStatus* = Call_GetOfferingStatus_402656864(
    name: "getOfferingStatus", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_402656865, base: "/",
    makeUrl: url_GetOfferingStatus_402656866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_402656881 = ref object of OpenApiRestCall_402656044
proc url_GetProject_402656883(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_402656882(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656884 = header.getOrDefault("X-Amz-Target")
  valid_402656884 = validateParameter(valid_402656884, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_402656884 != nil:
    section.add "X-Amz-Target", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Security-Token", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Signature")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Signature", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Algorithm", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Date")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Date", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Credential")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Credential", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656891
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

proc call*(call_402656893: Call_GetProject_402656881; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a project.
                                                                                         ## 
  let valid = call_402656893.validator(path, query, header, formData, body, _)
  let scheme = call_402656893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656893.makeUrl(scheme.get, call_402656893.host, call_402656893.base,
                                   call_402656893.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656893, uri, valid, _)

proc call*(call_402656894: Call_GetProject_402656881; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_402656895 = newJObject()
  if body != nil:
    body_402656895 = body
  result = call_402656894.call(nil, nil, nil, nil, body_402656895)

var getProject* = Call_GetProject_402656881(name: "getProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
    validator: validate_GetProject_402656882, base: "/",
    makeUrl: url_GetProject_402656883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_402656896 = ref object of OpenApiRestCall_402656044
proc url_GetRemoteAccessSession_402656898(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoteAccessSession_402656897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656899 = header.getOrDefault("X-Amz-Target")
  valid_402656899 = validateParameter(valid_402656899, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_402656899 != nil:
    section.add "X-Amz-Target", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Security-Token", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Signature")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Signature", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Algorithm", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Date")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Date", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Credential")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Credential", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656906
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

proc call*(call_402656908: Call_GetRemoteAccessSession_402656896;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a link to a currently running remote access session.
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_GetRemoteAccessSession_402656896; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_402656910 = newJObject()
  if body != nil:
    body_402656910 = body
  result = call_402656909.call(nil, nil, nil, nil, body_402656910)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_402656896(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_402656897, base: "/",
    makeUrl: url_GetRemoteAccessSession_402656898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_402656911 = ref object of OpenApiRestCall_402656044
proc url_GetRun_402656913(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_402656912(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656914 = header.getOrDefault("X-Amz-Target")
  valid_402656914 = validateParameter(valid_402656914, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_402656914 != nil:
    section.add "X-Amz-Target", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Security-Token", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Signature")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Signature", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Algorithm", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Date")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Date", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Credential")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Credential", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656921
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

proc call*(call_402656923: Call_GetRun_402656911; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a run.
                                                                                         ## 
  let valid = call_402656923.validator(path, query, header, formData, body, _)
  let scheme = call_402656923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656923.makeUrl(scheme.get, call_402656923.host, call_402656923.base,
                                   call_402656923.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656923, uri, valid, _)

proc call*(call_402656924: Call_GetRun_402656911; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_402656925 = newJObject()
  if body != nil:
    body_402656925 = body
  result = call_402656924.call(nil, nil, nil, nil, body_402656925)

var getRun* = Call_GetRun_402656911(name: "getRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                                    validator: validate_GetRun_402656912,
                                    base: "/", makeUrl: url_GetRun_402656913,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_402656926 = ref object of OpenApiRestCall_402656044
proc url_GetSuite_402656928(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_402656927(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656929 = header.getOrDefault("X-Amz-Target")
  valid_402656929 = validateParameter(valid_402656929, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_402656929 != nil:
    section.add "X-Amz-Target", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Security-Token", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Signature")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Signature", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Algorithm", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Date")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Date", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Credential")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Credential", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656936
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

proc call*(call_402656938: Call_GetSuite_402656926; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a suite.
                                                                                         ## 
  let valid = call_402656938.validator(path, query, header, formData, body, _)
  let scheme = call_402656938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656938.makeUrl(scheme.get, call_402656938.host, call_402656938.base,
                                   call_402656938.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656938, uri, valid, _)

proc call*(call_402656939: Call_GetSuite_402656926; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_402656940 = newJObject()
  if body != nil:
    body_402656940 = body
  result = call_402656939.call(nil, nil, nil, nil, body_402656940)

var getSuite* = Call_GetSuite_402656926(name: "getSuite",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                        validator: validate_GetSuite_402656927,
                                        base: "/", makeUrl: url_GetSuite_402656928,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_402656941 = ref object of OpenApiRestCall_402656044
proc url_GetTest_402656943(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_402656942(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656944 = header.getOrDefault("X-Amz-Target")
  valid_402656944 = validateParameter(valid_402656944, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_402656944 != nil:
    section.add "X-Amz-Target", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Security-Token", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Signature")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Signature", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Algorithm", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Date")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Date", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Credential")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Credential", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656951
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

proc call*(call_402656953: Call_GetTest_402656941; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a test.
                                                                                         ## 
  let valid = call_402656953.validator(path, query, header, formData, body, _)
  let scheme = call_402656953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656953.makeUrl(scheme.get, call_402656953.host, call_402656953.base,
                                   call_402656953.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656953, uri, valid, _)

proc call*(call_402656954: Call_GetTest_402656941; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_402656955 = newJObject()
  if body != nil:
    body_402656955 = body
  result = call_402656954.call(nil, nil, nil, nil, body_402656955)

var getTest* = Call_GetTest_402656941(name: "getTest",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                      validator: validate_GetTest_402656942,
                                      base: "/", makeUrl: url_GetTest_402656943,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_402656956 = ref object of OpenApiRestCall_402656044
proc url_GetTestGridProject_402656958(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridProject_402656957(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656959 = header.getOrDefault("X-Amz-Target")
  valid_402656959 = validateParameter(valid_402656959, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_402656959 != nil:
    section.add "X-Amz-Target", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Security-Token", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Signature")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Signature", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Algorithm", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Date")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Date", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Credential")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Credential", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656966
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

proc call*(call_402656968: Call_GetTestGridProject_402656956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Selenium testing project.
                                                                                         ## 
  let valid = call_402656968.validator(path, query, header, formData, body, _)
  let scheme = call_402656968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656968.makeUrl(scheme.get, call_402656968.host, call_402656968.base,
                                   call_402656968.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656968, uri, valid, _)

proc call*(call_402656969: Call_GetTestGridProject_402656956; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_402656970 = newJObject()
  if body != nil:
    body_402656970 = body
  result = call_402656969.call(nil, nil, nil, nil, body_402656970)

var getTestGridProject* = Call_GetTestGridProject_402656956(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_402656957, base: "/",
    makeUrl: url_GetTestGridProject_402656958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_402656971 = ref object of OpenApiRestCall_402656044
proc url_GetTestGridSession_402656973(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridSession_402656972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656974 = header.getOrDefault("X-Amz-Target")
  valid_402656974 = validateParameter(valid_402656974, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_402656974 != nil:
    section.add "X-Amz-Target", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Security-Token", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Signature")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Signature", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Algorithm", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Date")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Date", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Credential")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Credential", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656981
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

proc call*(call_402656983: Call_GetTestGridSession_402656971;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
                                                                                         ## 
  let valid = call_402656983.validator(path, query, header, formData, body, _)
  let scheme = call_402656983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656983.makeUrl(scheme.get, call_402656983.host, call_402656983.base,
                                   call_402656983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656983, uri, valid, _)

proc call*(call_402656984: Call_GetTestGridSession_402656971; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656985 = newJObject()
  if body != nil:
    body_402656985 = body
  result = call_402656984.call(nil, nil, nil, nil, body_402656985)

var getTestGridSession* = Call_GetTestGridSession_402656971(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_402656972, base: "/",
    makeUrl: url_GetTestGridSession_402656973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_402656986 = ref object of OpenApiRestCall_402656044
proc url_GetUpload_402656988(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_402656987(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656989 = header.getOrDefault("X-Amz-Target")
  valid_402656989 = validateParameter(valid_402656989, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_402656989 != nil:
    section.add "X-Amz-Target", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Security-Token", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Signature")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Signature", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Algorithm", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Date")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Date", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Credential")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Credential", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656996
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

proc call*(call_402656998: Call_GetUpload_402656986; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about an upload.
                                                                                         ## 
  let valid = call_402656998.validator(path, query, header, formData, body, _)
  let scheme = call_402656998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656998.makeUrl(scheme.get, call_402656998.host, call_402656998.base,
                                   call_402656998.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656998, uri, valid, _)

proc call*(call_402656999: Call_GetUpload_402656986; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_402657000 = newJObject()
  if body != nil:
    body_402657000 = body
  result = call_402656999.call(nil, nil, nil, nil, body_402657000)

var getUpload* = Call_GetUpload_402656986(name: "getUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
    validator: validate_GetUpload_402656987, base: "/", makeUrl: url_GetUpload_402656988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_402657001 = ref object of OpenApiRestCall_402656044
proc url_GetVPCEConfiguration_402657003(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVPCEConfiguration_402657002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657004 = header.getOrDefault("X-Amz-Target")
  valid_402657004 = validateParameter(valid_402657004, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_402657004 != nil:
    section.add "X-Amz-Target", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Security-Token", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Signature")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Signature", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Algorithm", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Date")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Date", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Credential")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Credential", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657011
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

proc call*(call_402657013: Call_GetVPCEConfiguration_402657001;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
                                                                                         ## 
  let valid = call_402657013.validator(path, query, header, formData, body, _)
  let scheme = call_402657013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657013.makeUrl(scheme.get, call_402657013.host, call_402657013.base,
                                   call_402657013.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657013, uri, valid, _)

proc call*(call_402657014: Call_GetVPCEConfiguration_402657001; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   
                                                                                                               ## body: JObject (required)
  var body_402657015 = newJObject()
  if body != nil:
    body_402657015 = body
  result = call_402657014.call(nil, nil, nil, nil, body_402657015)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_402657001(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_402657002, base: "/",
    makeUrl: url_GetVPCEConfiguration_402657003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_402657016 = ref object of OpenApiRestCall_402656044
proc url_InstallToRemoteAccessSession_402657018(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_402657017(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657019 = header.getOrDefault("X-Amz-Target")
  valid_402657019 = validateParameter(valid_402657019, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_402657019 != nil:
    section.add "X-Amz-Target", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Security-Token", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Signature")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Signature", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Algorithm", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Date")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Date", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Credential")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Credential", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657026
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

proc call*(call_402657028: Call_InstallToRemoteAccessSession_402657016;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
                                                                                         ## 
  let valid = call_402657028.validator(path, query, header, formData, body, _)
  let scheme = call_402657028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657028.makeUrl(scheme.get, call_402657028.host, call_402657028.base,
                                   call_402657028.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657028, uri, valid, _)

proc call*(call_402657029: Call_InstallToRemoteAccessSession_402657016;
           body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   
                                                                                                                                                                                        ## body: JObject (required)
  var body_402657030 = newJObject()
  if body != nil:
    body_402657030 = body
  result = call_402657029.call(nil, nil, nil, nil, body_402657030)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_402657016(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_402657017, base: "/",
    makeUrl: url_InstallToRemoteAccessSession_402657018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_402657031 = ref object of OpenApiRestCall_402656044
proc url_ListArtifacts_402657033(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListArtifacts_402657032(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657034 = query.getOrDefault("nextToken")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "nextToken", valid_402657034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657035 = header.getOrDefault("X-Amz-Target")
  valid_402657035 = validateParameter(valid_402657035, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_402657035 != nil:
    section.add "X-Amz-Target", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Security-Token", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Signature")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Signature", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Algorithm", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Date")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Date", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Credential")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Credential", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657042
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

proc call*(call_402657044: Call_ListArtifacts_402657031; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about artifacts.
                                                                                         ## 
  let valid = call_402657044.validator(path, query, header, formData, body, _)
  let scheme = call_402657044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657044.makeUrl(scheme.get, call_402657044.host, call_402657044.base,
                                   call_402657044.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657044, uri, valid, _)

proc call*(call_402657045: Call_ListArtifacts_402657031; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
                                      ##            : Pagination token
  ##   body: JObject (required)
  var query_402657046 = newJObject()
  var body_402657047 = newJObject()
  add(query_402657046, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657047 = body
  result = call_402657045.call(nil, query_402657046, nil, nil, body_402657047)

var listArtifacts* = Call_ListArtifacts_402657031(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_402657032, base: "/",
    makeUrl: url_ListArtifacts_402657033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_402657048 = ref object of OpenApiRestCall_402656044
proc url_ListDeviceInstances_402657050(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceInstances_402657049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657051 = header.getOrDefault("X-Amz-Target")
  valid_402657051 = validateParameter(valid_402657051, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_402657051 != nil:
    section.add "X-Amz-Target", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Security-Token", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Signature")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Signature", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Algorithm", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Date")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Date", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Credential")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Credential", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657058
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

proc call*(call_402657060: Call_ListDeviceInstances_402657048;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
                                                                                         ## 
  let valid = call_402657060.validator(path, query, header, formData, body, _)
  let scheme = call_402657060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657060.makeUrl(scheme.get, call_402657060.host, call_402657060.base,
                                   call_402657060.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657060, uri, valid, _)

proc call*(call_402657061: Call_ListDeviceInstances_402657048; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   
                                                                                                     ## body: JObject (required)
  var body_402657062 = newJObject()
  if body != nil:
    body_402657062 = body
  result = call_402657061.call(nil, nil, nil, nil, body_402657062)

var listDeviceInstances* = Call_ListDeviceInstances_402657048(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_402657049, base: "/",
    makeUrl: url_ListDeviceInstances_402657050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_402657063 = ref object of OpenApiRestCall_402656044
proc url_ListDevicePools_402657065(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevicePools_402657064(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657066 = query.getOrDefault("nextToken")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "nextToken", valid_402657066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657067 = header.getOrDefault("X-Amz-Target")
  valid_402657067 = validateParameter(valid_402657067, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_402657067 != nil:
    section.add "X-Amz-Target", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Security-Token", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Signature")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Signature", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Algorithm", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Date")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Date", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Credential")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Credential", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657074
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

proc call*(call_402657076: Call_ListDevicePools_402657063; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about device pools.
                                                                                         ## 
  let valid = call_402657076.validator(path, query, header, formData, body, _)
  let scheme = call_402657076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657076.makeUrl(scheme.get, call_402657076.host, call_402657076.base,
                                   call_402657076.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657076, uri, valid, _)

proc call*(call_402657077: Call_ListDevicePools_402657063; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
                                         ##            : Pagination token
  ##   body: JObject 
                                                                         ## (required)
  var query_402657078 = newJObject()
  var body_402657079 = newJObject()
  add(query_402657078, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657079 = body
  result = call_402657077.call(nil, query_402657078, nil, nil, body_402657079)

var listDevicePools* = Call_ListDevicePools_402657063(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_402657064, base: "/",
    makeUrl: url_ListDevicePools_402657065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_402657080 = ref object of OpenApiRestCall_402656044
proc url_ListDevices_402657082(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_402657081(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657083 = query.getOrDefault("nextToken")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "nextToken", valid_402657083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657084 = header.getOrDefault("X-Amz-Target")
  valid_402657084 = validateParameter(valid_402657084, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_402657084 != nil:
    section.add "X-Amz-Target", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Security-Token", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Signature")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Signature", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Algorithm", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Date")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Date", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Credential")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Credential", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657091
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

proc call*(call_402657093: Call_ListDevices_402657080; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about unique device types.
                                                                                         ## 
  let valid = call_402657093.validator(path, query, header, formData, body, _)
  let scheme = call_402657093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657093.makeUrl(scheme.get, call_402657093.host, call_402657093.base,
                                   call_402657093.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657093, uri, valid, _)

proc call*(call_402657094: Call_ListDevices_402657080; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
                                                ##            : Pagination token
  ##   
                                                                                ## body: JObject (required)
  var query_402657095 = newJObject()
  var body_402657096 = newJObject()
  add(query_402657095, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657096 = body
  result = call_402657094.call(nil, query_402657095, nil, nil, body_402657096)

var listDevices* = Call_ListDevices_402657080(name: "listDevices",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
    validator: validate_ListDevices_402657081, base: "/",
    makeUrl: url_ListDevices_402657082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_402657097 = ref object of OpenApiRestCall_402656044
proc url_ListInstanceProfiles_402657099(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstanceProfiles_402657098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657100 = header.getOrDefault("X-Amz-Target")
  valid_402657100 = validateParameter(valid_402657100, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_402657100 != nil:
    section.add "X-Amz-Target", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Security-Token", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Signature")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Signature", valid_402657102
  var valid_402657103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-Algorithm", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-Date")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-Date", valid_402657105
  var valid_402657106 = header.getOrDefault("X-Amz-Credential")
  valid_402657106 = validateParameter(valid_402657106, JString,
                                      required = false, default = nil)
  if valid_402657106 != nil:
    section.add "X-Amz-Credential", valid_402657106
  var valid_402657107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657107 = validateParameter(valid_402657107, JString,
                                      required = false, default = nil)
  if valid_402657107 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657107
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

proc call*(call_402657109: Call_ListInstanceProfiles_402657097;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
                                                                                         ## 
  let valid = call_402657109.validator(path, query, header, formData, body, _)
  let scheme = call_402657109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657109.makeUrl(scheme.get, call_402657109.host, call_402657109.base,
                                   call_402657109.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657109, uri, valid, _)

proc call*(call_402657110: Call_ListInstanceProfiles_402657097; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657111 = newJObject()
  if body != nil:
    body_402657111 = body
  result = call_402657110.call(nil, nil, nil, nil, body_402657111)

var listInstanceProfiles* = Call_ListInstanceProfiles_402657097(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_402657098, base: "/",
    makeUrl: url_ListInstanceProfiles_402657099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_402657112 = ref object of OpenApiRestCall_402656044
proc url_ListJobs_402657114(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_402657113(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657115 = query.getOrDefault("nextToken")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "nextToken", valid_402657115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657116 = header.getOrDefault("X-Amz-Target")
  valid_402657116 = validateParameter(valid_402657116, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_402657116 != nil:
    section.add "X-Amz-Target", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Security-Token", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Signature")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Signature", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-Algorithm", valid_402657120
  var valid_402657121 = header.getOrDefault("X-Amz-Date")
  valid_402657121 = validateParameter(valid_402657121, JString,
                                      required = false, default = nil)
  if valid_402657121 != nil:
    section.add "X-Amz-Date", valid_402657121
  var valid_402657122 = header.getOrDefault("X-Amz-Credential")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-Credential", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657123
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

proc call*(call_402657125: Call_ListJobs_402657112; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about jobs for a given test run.
                                                                                         ## 
  let valid = call_402657125.validator(path, query, header, formData, body, _)
  let scheme = call_402657125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657125.makeUrl(scheme.get, call_402657125.host, call_402657125.base,
                                   call_402657125.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657125, uri, valid, _)

proc call*(call_402657126: Call_ListJobs_402657112; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
                                                      ##            : Pagination token
  ##   
                                                                                      ## body: JObject (required)
  var query_402657127 = newJObject()
  var body_402657128 = newJObject()
  add(query_402657127, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657128 = body
  result = call_402657126.call(nil, query_402657127, nil, nil, body_402657128)

var listJobs* = Call_ListJobs_402657112(name: "listJobs",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                        validator: validate_ListJobs_402657113,
                                        base: "/", makeUrl: url_ListJobs_402657114,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_402657129 = ref object of OpenApiRestCall_402656044
proc url_ListNetworkProfiles_402657131(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworkProfiles_402657130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657132 = header.getOrDefault("X-Amz-Target")
  valid_402657132 = validateParameter(valid_402657132, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_402657132 != nil:
    section.add "X-Amz-Target", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Security-Token", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Signature")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Signature", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Algorithm", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Date")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Date", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Credential")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Credential", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657139
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

proc call*(call_402657141: Call_ListNetworkProfiles_402657129;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of available network profiles.
                                                                                         ## 
  let valid = call_402657141.validator(path, query, header, formData, body, _)
  let scheme = call_402657141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657141.makeUrl(scheme.get, call_402657141.host, call_402657141.base,
                                   call_402657141.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657141, uri, valid, _)

proc call*(call_402657142: Call_ListNetworkProfiles_402657129; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_402657143 = newJObject()
  if body != nil:
    body_402657143 = body
  result = call_402657142.call(nil, nil, nil, nil, body_402657143)

var listNetworkProfiles* = Call_ListNetworkProfiles_402657129(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_402657130, base: "/",
    makeUrl: url_ListNetworkProfiles_402657131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_402657144 = ref object of OpenApiRestCall_402656044
proc url_ListOfferingPromotions_402657146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingPromotions_402657145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657147 = header.getOrDefault("X-Amz-Target")
  valid_402657147 = validateParameter(valid_402657147, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_402657147 != nil:
    section.add "X-Amz-Target", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Security-Token", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Signature")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Signature", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Algorithm", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Date")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Date", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Credential")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Credential", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657154
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

proc call*(call_402657156: Call_ListOfferingPromotions_402657144;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
                                                                                         ## 
  let valid = call_402657156.validator(path, query, header, formData, body, _)
  let scheme = call_402657156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657156.makeUrl(scheme.get, call_402657156.host, call_402657156.base,
                                   call_402657156.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657156, uri, valid, _)

proc call*(call_402657157: Call_ListOfferingPromotions_402657144; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657158 = newJObject()
  if body != nil:
    body_402657158 = body
  result = call_402657157.call(nil, nil, nil, nil, body_402657158)

var listOfferingPromotions* = Call_ListOfferingPromotions_402657144(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_402657145, base: "/",
    makeUrl: url_ListOfferingPromotions_402657146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_402657159 = ref object of OpenApiRestCall_402656044
proc url_ListOfferingTransactions_402657161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingTransactions_402657160(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657162 = query.getOrDefault("nextToken")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "nextToken", valid_402657162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657163 = header.getOrDefault("X-Amz-Target")
  valid_402657163 = validateParameter(valid_402657163, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_402657163 != nil:
    section.add "X-Amz-Target", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Security-Token", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Signature")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Signature", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Algorithm", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Date")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Date", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Credential")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Credential", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657170
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

proc call*(call_402657172: Call_ListOfferingTransactions_402657159;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
                                                                                         ## 
  let valid = call_402657172.validator(path, query, header, formData, body, _)
  let scheme = call_402657172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657172.makeUrl(scheme.get, call_402657172.host, call_402657172.base,
                                   call_402657172.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657172, uri, valid, _)

proc call*(call_402657173: Call_ListOfferingTransactions_402657159;
           body: JsonNode; nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var query_402657174 = newJObject()
  var body_402657175 = newJObject()
  add(query_402657174, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657175 = body
  result = call_402657173.call(nil, query_402657174, nil, nil, body_402657175)

var listOfferingTransactions* = Call_ListOfferingTransactions_402657159(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_402657160, base: "/",
    makeUrl: url_ListOfferingTransactions_402657161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_402657176 = ref object of OpenApiRestCall_402656044
proc url_ListOfferings_402657178(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_402657177(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657179 = query.getOrDefault("nextToken")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "nextToken", valid_402657179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657180 = header.getOrDefault("X-Amz-Target")
  valid_402657180 = validateParameter(valid_402657180, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_402657180 != nil:
    section.add "X-Amz-Target", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-Security-Token", valid_402657181
  var valid_402657182 = header.getOrDefault("X-Amz-Signature")
  valid_402657182 = validateParameter(valid_402657182, JString,
                                      required = false, default = nil)
  if valid_402657182 != nil:
    section.add "X-Amz-Signature", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Algorithm", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Date")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Date", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-Credential")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-Credential", valid_402657186
  var valid_402657187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657187
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

proc call*(call_402657189: Call_ListOfferings_402657176; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
                                                                                         ## 
  let valid = call_402657189.validator(path, query, header, formData, body, _)
  let scheme = call_402657189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657189.makeUrl(scheme.get, call_402657189.host, call_402657189.base,
                                   call_402657189.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657189, uri, valid, _)

proc call*(call_402657190: Call_ListOfferings_402657176; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                              ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                              ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var query_402657191 = newJObject()
  var body_402657192 = newJObject()
  add(query_402657191, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657192 = body
  result = call_402657190.call(nil, query_402657191, nil, nil, body_402657192)

var listOfferings* = Call_ListOfferings_402657176(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_402657177, base: "/",
    makeUrl: url_ListOfferings_402657178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_402657193 = ref object of OpenApiRestCall_402656044
proc url_ListProjects_402657195(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_402657194(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657196 = query.getOrDefault("nextToken")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "nextToken", valid_402657196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657197 = header.getOrDefault("X-Amz-Target")
  valid_402657197 = validateParameter(valid_402657197, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_402657197 != nil:
    section.add "X-Amz-Target", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Security-Token", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Signature")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Signature", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Algorithm", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-Date")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-Date", valid_402657202
  var valid_402657203 = header.getOrDefault("X-Amz-Credential")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Credential", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657204
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

proc call*(call_402657206: Call_ListProjects_402657193; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about projects.
                                                                                         ## 
  let valid = call_402657206.validator(path, query, header, formData, body, _)
  let scheme = call_402657206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657206.makeUrl(scheme.get, call_402657206.host, call_402657206.base,
                                   call_402657206.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657206, uri, valid, _)

proc call*(call_402657207: Call_ListProjects_402657193; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
                                     ##            : Pagination token
  ##   body: JObject (required)
  var query_402657208 = newJObject()
  var body_402657209 = newJObject()
  add(query_402657208, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657209 = body
  result = call_402657207.call(nil, query_402657208, nil, nil, body_402657209)

var listProjects* = Call_ListProjects_402657193(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_402657194, base: "/",
    makeUrl: url_ListProjects_402657195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_402657210 = ref object of OpenApiRestCall_402656044
proc url_ListRemoteAccessSessions_402657212(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRemoteAccessSessions_402657211(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657213 = header.getOrDefault("X-Amz-Target")
  valid_402657213 = validateParameter(valid_402657213, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_402657213 != nil:
    section.add "X-Amz-Target", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Security-Token", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Signature")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Signature", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Algorithm", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Date")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Date", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-Credential")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-Credential", valid_402657219
  var valid_402657220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657220 = validateParameter(valid_402657220, JString,
                                      required = false, default = nil)
  if valid_402657220 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657220
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

proc call*(call_402657222: Call_ListRemoteAccessSessions_402657210;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all currently running remote access sessions.
                                                                                         ## 
  let valid = call_402657222.validator(path, query, header, formData, body, _)
  let scheme = call_402657222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657222.makeUrl(scheme.get, call_402657222.host, call_402657222.base,
                                   call_402657222.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657222, uri, valid, _)

proc call*(call_402657223: Call_ListRemoteAccessSessions_402657210;
           body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_402657224 = newJObject()
  if body != nil:
    body_402657224 = body
  result = call_402657223.call(nil, nil, nil, nil, body_402657224)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_402657210(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_402657211, base: "/",
    makeUrl: url_ListRemoteAccessSessions_402657212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_402657225 = ref object of OpenApiRestCall_402656044
proc url_ListRuns_402657227(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_402657226(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657228 = query.getOrDefault("nextToken")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "nextToken", valid_402657228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657229 = header.getOrDefault("X-Amz-Target")
  valid_402657229 = validateParameter(valid_402657229, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_402657229 != nil:
    section.add "X-Amz-Target", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Security-Token", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Signature")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Signature", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Algorithm", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-Date")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-Date", valid_402657234
  var valid_402657235 = header.getOrDefault("X-Amz-Credential")
  valid_402657235 = validateParameter(valid_402657235, JString,
                                      required = false, default = nil)
  if valid_402657235 != nil:
    section.add "X-Amz-Credential", valid_402657235
  var valid_402657236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657236 = validateParameter(valid_402657236, JString,
                                      required = false, default = nil)
  if valid_402657236 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657236
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

proc call*(call_402657238: Call_ListRuns_402657225; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
                                                                                         ## 
  let valid = call_402657238.validator(path, query, header, formData, body, _)
  let scheme = call_402657238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657238.makeUrl(scheme.get, call_402657238.host, call_402657238.base,
                                   call_402657238.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657238, uri, valid, _)

proc call*(call_402657239: Call_ListRuns_402657225; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   
                                                                       ## nextToken: string
                                                                       ##            
                                                                       ## : 
                                                                       ## Pagination 
                                                                       ## token
  ##   
                                                                               ## body: JObject (required)
  var query_402657240 = newJObject()
  var body_402657241 = newJObject()
  add(query_402657240, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657241 = body
  result = call_402657239.call(nil, query_402657240, nil, nil, body_402657241)

var listRuns* = Call_ListRuns_402657225(name: "listRuns",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                        validator: validate_ListRuns_402657226,
                                        base: "/", makeUrl: url_ListRuns_402657227,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_402657242 = ref object of OpenApiRestCall_402656044
proc url_ListSamples_402657244(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSamples_402657243(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657245 = query.getOrDefault("nextToken")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "nextToken", valid_402657245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657246 = header.getOrDefault("X-Amz-Target")
  valid_402657246 = validateParameter(valid_402657246, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_402657246 != nil:
    section.add "X-Amz-Target", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Security-Token", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Signature")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Signature", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657249
  var valid_402657250 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "X-Amz-Algorithm", valid_402657250
  var valid_402657251 = header.getOrDefault("X-Amz-Date")
  valid_402657251 = validateParameter(valid_402657251, JString,
                                      required = false, default = nil)
  if valid_402657251 != nil:
    section.add "X-Amz-Date", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-Credential")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-Credential", valid_402657252
  var valid_402657253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657253
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

proc call*(call_402657255: Call_ListSamples_402657242; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
                                                                                         ## 
  let valid = call_402657255.validator(path, query, header, formData, body, _)
  let scheme = call_402657255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657255.makeUrl(scheme.get, call_402657255.host, call_402657255.base,
                                   call_402657255.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657255, uri, valid, _)

proc call*(call_402657256: Call_ListSamples_402657242; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
                                                                      ##            : Pagination token
  ##   
                                                                                                      ## body: JObject (required)
  var query_402657257 = newJObject()
  var body_402657258 = newJObject()
  add(query_402657257, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657258 = body
  result = call_402657256.call(nil, query_402657257, nil, nil, body_402657258)

var listSamples* = Call_ListSamples_402657242(name: "listSamples",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
    validator: validate_ListSamples_402657243, base: "/",
    makeUrl: url_ListSamples_402657244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_402657259 = ref object of OpenApiRestCall_402656044
proc url_ListSuites_402657261(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_402657260(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657262 = query.getOrDefault("nextToken")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "nextToken", valid_402657262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657263 = header.getOrDefault("X-Amz-Target")
  valid_402657263 = validateParameter(valid_402657263, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_402657263 != nil:
    section.add "X-Amz-Target", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Security-Token", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Signature")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Signature", valid_402657265
  var valid_402657266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657266 = validateParameter(valid_402657266, JString,
                                      required = false, default = nil)
  if valid_402657266 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-Algorithm", valid_402657267
  var valid_402657268 = header.getOrDefault("X-Amz-Date")
  valid_402657268 = validateParameter(valid_402657268, JString,
                                      required = false, default = nil)
  if valid_402657268 != nil:
    section.add "X-Amz-Date", valid_402657268
  var valid_402657269 = header.getOrDefault("X-Amz-Credential")
  valid_402657269 = validateParameter(valid_402657269, JString,
                                      required = false, default = nil)
  if valid_402657269 != nil:
    section.add "X-Amz-Credential", valid_402657269
  var valid_402657270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657270 = validateParameter(valid_402657270, JString,
                                      required = false, default = nil)
  if valid_402657270 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657270
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

proc call*(call_402657272: Call_ListSuites_402657259; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about test suites for a given job.
                                                                                         ## 
  let valid = call_402657272.validator(path, query, header, formData, body, _)
  let scheme = call_402657272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657272.makeUrl(scheme.get, call_402657272.host, call_402657272.base,
                                   call_402657272.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657272, uri, valid, _)

proc call*(call_402657273: Call_ListSuites_402657259; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
                                                        ##            : Pagination token
  ##   
                                                                                        ## body: JObject (required)
  var query_402657274 = newJObject()
  var body_402657275 = newJObject()
  add(query_402657274, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657275 = body
  result = call_402657273.call(nil, query_402657274, nil, nil, body_402657275)

var listSuites* = Call_ListSuites_402657259(name: "listSuites",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
    validator: validate_ListSuites_402657260, base: "/",
    makeUrl: url_ListSuites_402657261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657276 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657278(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402657277(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657279 = header.getOrDefault("X-Amz-Target")
  valid_402657279 = validateParameter(valid_402657279, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_402657279 != nil:
    section.add "X-Amz-Target", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Security-Token", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Signature")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Signature", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-Algorithm", valid_402657283
  var valid_402657284 = header.getOrDefault("X-Amz-Date")
  valid_402657284 = validateParameter(valid_402657284, JString,
                                      required = false, default = nil)
  if valid_402657284 != nil:
    section.add "X-Amz-Date", valid_402657284
  var valid_402657285 = header.getOrDefault("X-Amz-Credential")
  valid_402657285 = validateParameter(valid_402657285, JString,
                                      required = false, default = nil)
  if valid_402657285 != nil:
    section.add "X-Amz-Credential", valid_402657285
  var valid_402657286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657286 = validateParameter(valid_402657286, JString,
                                      required = false, default = nil)
  if valid_402657286 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657286
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

proc call*(call_402657288: Call_ListTagsForResource_402657276;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for an AWS Device Farm resource.
                                                                                         ## 
  let valid = call_402657288.validator(path, query, header, formData, body, _)
  let scheme = call_402657288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657288.makeUrl(scheme.get, call_402657288.host, call_402657288.base,
                                   call_402657288.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657288, uri, valid, _)

proc call*(call_402657289: Call_ListTagsForResource_402657276; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_402657290 = newJObject()
  if body != nil:
    body_402657290 = body
  result = call_402657289.call(nil, nil, nil, nil, body_402657290)

var listTagsForResource* = Call_ListTagsForResource_402657276(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_402657277, base: "/",
    makeUrl: url_ListTagsForResource_402657278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_402657291 = ref object of OpenApiRestCall_402656044
proc url_ListTestGridProjects_402657293(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridProjects_402657292(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657294 = query.getOrDefault("nextToken")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "nextToken", valid_402657294
  var valid_402657295 = query.getOrDefault("maxResult")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "maxResult", valid_402657295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657296 = header.getOrDefault("X-Amz-Target")
  valid_402657296 = validateParameter(valid_402657296, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_402657296 != nil:
    section.add "X-Amz-Target", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Security-Token", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Signature")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Signature", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657299
  var valid_402657300 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657300 = validateParameter(valid_402657300, JString,
                                      required = false, default = nil)
  if valid_402657300 != nil:
    section.add "X-Amz-Algorithm", valid_402657300
  var valid_402657301 = header.getOrDefault("X-Amz-Date")
  valid_402657301 = validateParameter(valid_402657301, JString,
                                      required = false, default = nil)
  if valid_402657301 != nil:
    section.add "X-Amz-Date", valid_402657301
  var valid_402657302 = header.getOrDefault("X-Amz-Credential")
  valid_402657302 = validateParameter(valid_402657302, JString,
                                      required = false, default = nil)
  if valid_402657302 != nil:
    section.add "X-Amz-Credential", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657303
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

proc call*(call_402657305: Call_ListTestGridProjects_402657291;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
                                                                                         ## 
  let valid = call_402657305.validator(path, query, header, formData, body, _)
  let scheme = call_402657305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657305.makeUrl(scheme.get, call_402657305.host, call_402657305.base,
                                   call_402657305.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657305, uri, valid, _)

proc call*(call_402657306: Call_ListTestGridProjects_402657291; body: JsonNode;
           nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   nextToken: string
                                                                  ##            : Pagination token
  ##   
                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                             ## maxResult: string
                                                                                                                             ##            
                                                                                                                             ## : 
                                                                                                                             ## Pagination 
                                                                                                                             ## limit
  var query_402657307 = newJObject()
  var body_402657308 = newJObject()
  add(query_402657307, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657308 = body
  add(query_402657307, "maxResult", newJString(maxResult))
  result = call_402657306.call(nil, query_402657307, nil, nil, body_402657308)

var listTestGridProjects* = Call_ListTestGridProjects_402657291(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_402657292, base: "/",
    makeUrl: url_ListTestGridProjects_402657293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_402657309 = ref object of OpenApiRestCall_402656044
proc url_ListTestGridSessionActions_402657311(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionActions_402657310(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657312 = query.getOrDefault("nextToken")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "nextToken", valid_402657312
  var valid_402657313 = query.getOrDefault("maxResult")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "maxResult", valid_402657313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657314 = header.getOrDefault("X-Amz-Target")
  valid_402657314 = validateParameter(valid_402657314, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_402657314 != nil:
    section.add "X-Amz-Target", valid_402657314
  var valid_402657315 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "X-Amz-Security-Token", valid_402657315
  var valid_402657316 = header.getOrDefault("X-Amz-Signature")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "X-Amz-Signature", valid_402657316
  var valid_402657317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657317 = validateParameter(valid_402657317, JString,
                                      required = false, default = nil)
  if valid_402657317 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657317
  var valid_402657318 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-Algorithm", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-Date")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Date", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Credential")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Credential", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657321
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

proc call*(call_402657323: Call_ListTestGridSessionActions_402657309;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
                                                                                         ## 
  let valid = call_402657323.validator(path, query, header, formData, body, _)
  let scheme = call_402657323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657323.makeUrl(scheme.get, call_402657323.host, call_402657323.base,
                                   call_402657323.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657323, uri, valid, _)

proc call*(call_402657324: Call_ListTestGridSessionActions_402657309;
           body: JsonNode; nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   nextToken: string
                                                                     ##            : Pagination token
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## maxResult: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## limit
  var query_402657325 = newJObject()
  var body_402657326 = newJObject()
  add(query_402657325, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657326 = body
  add(query_402657325, "maxResult", newJString(maxResult))
  result = call_402657324.call(nil, query_402657325, nil, nil, body_402657326)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_402657309(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_402657310, base: "/",
    makeUrl: url_ListTestGridSessionActions_402657311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_402657327 = ref object of OpenApiRestCall_402656044
proc url_ListTestGridSessionArtifacts_402657329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionArtifacts_402657328(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657330 = query.getOrDefault("nextToken")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "nextToken", valid_402657330
  var valid_402657331 = query.getOrDefault("maxResult")
  valid_402657331 = validateParameter(valid_402657331, JString,
                                      required = false, default = nil)
  if valid_402657331 != nil:
    section.add "maxResult", valid_402657331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657332 = header.getOrDefault("X-Amz-Target")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_402657332 != nil:
    section.add "X-Amz-Target", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Security-Token", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Signature")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Signature", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Algorithm", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Date")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Date", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Credential")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Credential", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657339
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

proc call*(call_402657341: Call_ListTestGridSessionArtifacts_402657327;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of artifacts created during the session.
                                                                                         ## 
  let valid = call_402657341.validator(path, query, header, formData, body, _)
  let scheme = call_402657341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657341.makeUrl(scheme.get, call_402657341.host, call_402657341.base,
                                   call_402657341.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657341, uri, valid, _)

proc call*(call_402657342: Call_ListTestGridSessionArtifacts_402657327;
           body: JsonNode; nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   nextToken: string
                                                              ##            : Pagination token
  ##   
                                                                                              ## body: JObject (required)
  ##   
                                                                                                                         ## maxResult: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## limit
  var query_402657343 = newJObject()
  var body_402657344 = newJObject()
  add(query_402657343, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657344 = body
  add(query_402657343, "maxResult", newJString(maxResult))
  result = call_402657342.call(nil, query_402657343, nil, nil, body_402657344)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_402657327(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_402657328, base: "/",
    makeUrl: url_ListTestGridSessionArtifacts_402657329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_402657345 = ref object of OpenApiRestCall_402656044
proc url_ListTestGridSessions_402657347(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessions_402657346(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657348 = query.getOrDefault("nextToken")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "nextToken", valid_402657348
  var valid_402657349 = query.getOrDefault("maxResult")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "maxResult", valid_402657349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657350 = header.getOrDefault("X-Amz-Target")
  valid_402657350 = validateParameter(valid_402657350, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_402657350 != nil:
    section.add "X-Amz-Target", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Security-Token", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Signature")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Signature", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-Algorithm", valid_402657354
  var valid_402657355 = header.getOrDefault("X-Amz-Date")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "X-Amz-Date", valid_402657355
  var valid_402657356 = header.getOrDefault("X-Amz-Credential")
  valid_402657356 = validateParameter(valid_402657356, JString,
                                      required = false, default = nil)
  if valid_402657356 != nil:
    section.add "X-Amz-Credential", valid_402657356
  var valid_402657357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657357
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

proc call*(call_402657359: Call_ListTestGridSessions_402657345;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
                                                                                         ## 
  let valid = call_402657359.validator(path, query, header, formData, body, _)
  let scheme = call_402657359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657359.makeUrl(scheme.get, call_402657359.host, call_402657359.base,
                                   call_402657359.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657359, uri, valid, _)

proc call*(call_402657360: Call_ListTestGridSessions_402657345; body: JsonNode;
           nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   nextToken: string
                                                               ##            : Pagination token
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## maxResult: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## limit
  var query_402657361 = newJObject()
  var body_402657362 = newJObject()
  add(query_402657361, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657362 = body
  add(query_402657361, "maxResult", newJString(maxResult))
  result = call_402657360.call(nil, query_402657361, nil, nil, body_402657362)

var listTestGridSessions* = Call_ListTestGridSessions_402657345(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_402657346, base: "/",
    makeUrl: url_ListTestGridSessions_402657347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_402657363 = ref object of OpenApiRestCall_402656044
proc url_ListTests_402657365(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_402657364(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657366 = query.getOrDefault("nextToken")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "nextToken", valid_402657366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657367 = header.getOrDefault("X-Amz-Target")
  valid_402657367 = validateParameter(valid_402657367, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_402657367 != nil:
    section.add "X-Amz-Target", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Security-Token", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-Signature")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-Signature", valid_402657369
  var valid_402657370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657370 = validateParameter(valid_402657370, JString,
                                      required = false, default = nil)
  if valid_402657370 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657370
  var valid_402657371 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-Algorithm", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-Date")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-Date", valid_402657372
  var valid_402657373 = header.getOrDefault("X-Amz-Credential")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-Credential", valid_402657373
  var valid_402657374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657374
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

proc call*(call_402657376: Call_ListTests_402657363; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about tests in a given test suite.
                                                                                         ## 
  let valid = call_402657376.validator(path, query, header, formData, body, _)
  let scheme = call_402657376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657376.makeUrl(scheme.get, call_402657376.host, call_402657376.base,
                                   call_402657376.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657376, uri, valid, _)

proc call*(call_402657377: Call_ListTests_402657363; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
                                                        ##            : Pagination token
  ##   
                                                                                        ## body: JObject (required)
  var query_402657378 = newJObject()
  var body_402657379 = newJObject()
  add(query_402657378, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657379 = body
  result = call_402657377.call(nil, query_402657378, nil, nil, body_402657379)

var listTests* = Call_ListTests_402657363(name: "listTests",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
    validator: validate_ListTests_402657364, base: "/", makeUrl: url_ListTests_402657365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_402657380 = ref object of OpenApiRestCall_402656044
proc url_ListUniqueProblems_402657382(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUniqueProblems_402657381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657383 = query.getOrDefault("nextToken")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "nextToken", valid_402657383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657384 = header.getOrDefault("X-Amz-Target")
  valid_402657384 = validateParameter(valid_402657384, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_402657384 != nil:
    section.add "X-Amz-Target", valid_402657384
  var valid_402657385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657385 = validateParameter(valid_402657385, JString,
                                      required = false, default = nil)
  if valid_402657385 != nil:
    section.add "X-Amz-Security-Token", valid_402657385
  var valid_402657386 = header.getOrDefault("X-Amz-Signature")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-Signature", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Algorithm", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-Date")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-Date", valid_402657389
  var valid_402657390 = header.getOrDefault("X-Amz-Credential")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-Credential", valid_402657390
  var valid_402657391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657391 = validateParameter(valid_402657391, JString,
                                      required = false, default = nil)
  if valid_402657391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657391
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

proc call*(call_402657393: Call_ListUniqueProblems_402657380;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
                                                                                         ## 
  let valid = call_402657393.validator(path, query, header, formData, body, _)
  let scheme = call_402657393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657393.makeUrl(scheme.get, call_402657393.host, call_402657393.base,
                                   call_402657393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657393, uri, valid, _)

proc call*(call_402657394: Call_ListUniqueProblems_402657380; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var query_402657395 = newJObject()
  var body_402657396 = newJObject()
  add(query_402657395, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657396 = body
  result = call_402657394.call(nil, query_402657395, nil, nil, body_402657396)

var listUniqueProblems* = Call_ListUniqueProblems_402657380(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_402657381, base: "/",
    makeUrl: url_ListUniqueProblems_402657382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_402657397 = ref object of OpenApiRestCall_402656044
proc url_ListUploads_402657399(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUploads_402657398(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657400 = query.getOrDefault("nextToken")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "nextToken", valid_402657400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657401 = header.getOrDefault("X-Amz-Target")
  valid_402657401 = validateParameter(valid_402657401, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_402657401 != nil:
    section.add "X-Amz-Target", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Security-Token", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-Signature")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Signature", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Algorithm", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Date")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Date", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-Credential")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-Credential", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657408
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

proc call*(call_402657410: Call_ListUploads_402657397; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
                                                                                         ## 
  let valid = call_402657410.validator(path, query, header, formData, body, _)
  let scheme = call_402657410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657410.makeUrl(scheme.get, call_402657410.host, call_402657410.base,
                                   call_402657410.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657410, uri, valid, _)

proc call*(call_402657411: Call_ListUploads_402657397; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   
                                                                          ## nextToken: string
                                                                          ##            
                                                                          ## : 
                                                                          ## Pagination 
                                                                          ## token
  ##   
                                                                                  ## body: JObject (required)
  var query_402657412 = newJObject()
  var body_402657413 = newJObject()
  add(query_402657412, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657413 = body
  result = call_402657411.call(nil, query_402657412, nil, nil, body_402657413)

var listUploads* = Call_ListUploads_402657397(name: "listUploads",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
    validator: validate_ListUploads_402657398, base: "/",
    makeUrl: url_ListUploads_402657399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_402657414 = ref object of OpenApiRestCall_402656044
proc url_ListVPCEConfigurations_402657416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVPCEConfigurations_402657415(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657417 = header.getOrDefault("X-Amz-Target")
  valid_402657417 = validateParameter(valid_402657417, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_402657417 != nil:
    section.add "X-Amz-Target", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Security-Token", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Signature")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Signature", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Algorithm", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Date")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Date", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Credential")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Credential", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657424
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

proc call*(call_402657426: Call_ListVPCEConfigurations_402657414;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
                                                                                         ## 
  let valid = call_402657426.validator(path, query, header, formData, body, _)
  let scheme = call_402657426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657426.makeUrl(scheme.get, call_402657426.host, call_402657426.base,
                                   call_402657426.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657426, uri, valid, _)

proc call*(call_402657427: Call_ListVPCEConfigurations_402657414; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   
                                                                                                                 ## body: JObject (required)
  var body_402657428 = newJObject()
  if body != nil:
    body_402657428 = body
  result = call_402657427.call(nil, nil, nil, nil, body_402657428)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_402657414(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_402657415, base: "/",
    makeUrl: url_ListVPCEConfigurations_402657416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_402657429 = ref object of OpenApiRestCall_402656044
proc url_PurchaseOffering_402657431(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseOffering_402657430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657432 = header.getOrDefault("X-Amz-Target")
  valid_402657432 = validateParameter(valid_402657432, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_402657432 != nil:
    section.add "X-Amz-Target", valid_402657432
  var valid_402657433 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657433 = validateParameter(valid_402657433, JString,
                                      required = false, default = nil)
  if valid_402657433 != nil:
    section.add "X-Amz-Security-Token", valid_402657433
  var valid_402657434 = header.getOrDefault("X-Amz-Signature")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Signature", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657435
  var valid_402657436 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "X-Amz-Algorithm", valid_402657436
  var valid_402657437 = header.getOrDefault("X-Amz-Date")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Date", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Credential")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Credential", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657439
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

proc call*(call_402657441: Call_PurchaseOffering_402657429;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
                                                                                         ## 
  let valid = call_402657441.validator(path, query, header, formData, body, _)
  let scheme = call_402657441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657441.makeUrl(scheme.get, call_402657441.host, call_402657441.base,
                                   call_402657441.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657441, uri, valid, _)

proc call*(call_402657442: Call_PurchaseOffering_402657429; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402657443 = newJObject()
  if body != nil:
    body_402657443 = body
  result = call_402657442.call(nil, nil, nil, nil, body_402657443)

var purchaseOffering* = Call_PurchaseOffering_402657429(
    name: "purchaseOffering", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_402657430, base: "/",
    makeUrl: url_PurchaseOffering_402657431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_402657444 = ref object of OpenApiRestCall_402656044
proc url_RenewOffering_402657446(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenewOffering_402657445(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657447 = header.getOrDefault("X-Amz-Target")
  valid_402657447 = validateParameter(valid_402657447, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_402657447 != nil:
    section.add "X-Amz-Target", valid_402657447
  var valid_402657448 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Security-Token", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Signature")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Signature", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Algorithm", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Date")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Date", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Credential")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Credential", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657454
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

proc call*(call_402657456: Call_RenewOffering_402657444; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
                                                                                         ## 
  let valid = call_402657456.validator(path, query, header, formData, body, _)
  let scheme = call_402657456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657456.makeUrl(scheme.get, call_402657456.host, call_402657456.base,
                                   call_402657456.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657456, uri, valid, _)

proc call*(call_402657457: Call_RenewOffering_402657444; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657458 = newJObject()
  if body != nil:
    body_402657458 = body
  result = call_402657457.call(nil, nil, nil, nil, body_402657458)

var renewOffering* = Call_RenewOffering_402657444(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_402657445, base: "/",
    makeUrl: url_RenewOffering_402657446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_402657459 = ref object of OpenApiRestCall_402656044
proc url_ScheduleRun_402657461(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleRun_402657460(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657462 = header.getOrDefault("X-Amz-Target")
  valid_402657462 = validateParameter(valid_402657462, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_402657462 != nil:
    section.add "X-Amz-Target", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Security-Token", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Signature")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Signature", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Algorithm", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Date")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Date", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Credential")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Credential", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657469
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

proc call*(call_402657471: Call_ScheduleRun_402657459; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Schedules a run.
                                                                                         ## 
  let valid = call_402657471.validator(path, query, header, formData, body, _)
  let scheme = call_402657471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657471.makeUrl(scheme.get, call_402657471.host, call_402657471.base,
                                   call_402657471.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657471, uri, valid, _)

proc call*(call_402657472: Call_ScheduleRun_402657459; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_402657473 = newJObject()
  if body != nil:
    body_402657473 = body
  result = call_402657472.call(nil, nil, nil, nil, body_402657473)

var scheduleRun* = Call_ScheduleRun_402657459(name: "scheduleRun",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
    validator: validate_ScheduleRun_402657460, base: "/",
    makeUrl: url_ScheduleRun_402657461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_402657474 = ref object of OpenApiRestCall_402656044
proc url_StopJob_402657476(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_402657475(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657477 = header.getOrDefault("X-Amz-Target")
  valid_402657477 = validateParameter(valid_402657477, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_402657477 != nil:
    section.add "X-Amz-Target", valid_402657477
  var valid_402657478 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "X-Amz-Security-Token", valid_402657478
  var valid_402657479 = header.getOrDefault("X-Amz-Signature")
  valid_402657479 = validateParameter(valid_402657479, JString,
                                      required = false, default = nil)
  if valid_402657479 != nil:
    section.add "X-Amz-Signature", valid_402657479
  var valid_402657480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657480 = validateParameter(valid_402657480, JString,
                                      required = false, default = nil)
  if valid_402657480 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657480
  var valid_402657481 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657481 = validateParameter(valid_402657481, JString,
                                      required = false, default = nil)
  if valid_402657481 != nil:
    section.add "X-Amz-Algorithm", valid_402657481
  var valid_402657482 = header.getOrDefault("X-Amz-Date")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "X-Amz-Date", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Credential")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Credential", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657484
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

proc call*(call_402657486: Call_StopJob_402657474; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
                                                                                         ## 
  let valid = call_402657486.validator(path, query, header, formData, body, _)
  let scheme = call_402657486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657486.makeUrl(scheme.get, call_402657486.host, call_402657486.base,
                                   call_402657486.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657486, uri, valid, _)

proc call*(call_402657487: Call_StopJob_402657474; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657488 = newJObject()
  if body != nil:
    body_402657488 = body
  result = call_402657487.call(nil, nil, nil, nil, body_402657488)

var stopJob* = Call_StopJob_402657474(name: "stopJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                      validator: validate_StopJob_402657475,
                                      base: "/", makeUrl: url_StopJob_402657476,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_402657489 = ref object of OpenApiRestCall_402656044
proc url_StopRemoteAccessSession_402657491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRemoteAccessSession_402657490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657492 = header.getOrDefault("X-Amz-Target")
  valid_402657492 = validateParameter(valid_402657492, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_402657492 != nil:
    section.add "X-Amz-Target", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-Security-Token", valid_402657493
  var valid_402657494 = header.getOrDefault("X-Amz-Signature")
  valid_402657494 = validateParameter(valid_402657494, JString,
                                      required = false, default = nil)
  if valid_402657494 != nil:
    section.add "X-Amz-Signature", valid_402657494
  var valid_402657495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657495 = validateParameter(valid_402657495, JString,
                                      required = false, default = nil)
  if valid_402657495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657495
  var valid_402657496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657496 = validateParameter(valid_402657496, JString,
                                      required = false, default = nil)
  if valid_402657496 != nil:
    section.add "X-Amz-Algorithm", valid_402657496
  var valid_402657497 = header.getOrDefault("X-Amz-Date")
  valid_402657497 = validateParameter(valid_402657497, JString,
                                      required = false, default = nil)
  if valid_402657497 != nil:
    section.add "X-Amz-Date", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Credential")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Credential", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657499
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

proc call*(call_402657501: Call_StopRemoteAccessSession_402657489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Ends a specified remote access session.
                                                                                         ## 
  let valid = call_402657501.validator(path, query, header, formData, body, _)
  let scheme = call_402657501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657501.makeUrl(scheme.get, call_402657501.host, call_402657501.base,
                                   call_402657501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657501, uri, valid, _)

proc call*(call_402657502: Call_StopRemoteAccessSession_402657489;
           body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_402657503 = newJObject()
  if body != nil:
    body_402657503 = body
  result = call_402657502.call(nil, nil, nil, nil, body_402657503)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_402657489(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_402657490, base: "/",
    makeUrl: url_StopRemoteAccessSession_402657491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_402657504 = ref object of OpenApiRestCall_402656044
proc url_StopRun_402657506(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_402657505(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657507 = header.getOrDefault("X-Amz-Target")
  valid_402657507 = validateParameter(valid_402657507, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_402657507 != nil:
    section.add "X-Amz-Target", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-Security-Token", valid_402657508
  var valid_402657509 = header.getOrDefault("X-Amz-Signature")
  valid_402657509 = validateParameter(valid_402657509, JString,
                                      required = false, default = nil)
  if valid_402657509 != nil:
    section.add "X-Amz-Signature", valid_402657509
  var valid_402657510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657510 = validateParameter(valid_402657510, JString,
                                      required = false, default = nil)
  if valid_402657510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657510
  var valid_402657511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657511 = validateParameter(valid_402657511, JString,
                                      required = false, default = nil)
  if valid_402657511 != nil:
    section.add "X-Amz-Algorithm", valid_402657511
  var valid_402657512 = header.getOrDefault("X-Amz-Date")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "X-Amz-Date", valid_402657512
  var valid_402657513 = header.getOrDefault("X-Amz-Credential")
  valid_402657513 = validateParameter(valid_402657513, JString,
                                      required = false, default = nil)
  if valid_402657513 != nil:
    section.add "X-Amz-Credential", valid_402657513
  var valid_402657514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657514 = validateParameter(valid_402657514, JString,
                                      required = false, default = nil)
  if valid_402657514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657514
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

proc call*(call_402657516: Call_StopRun_402657504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
                                                                                         ## 
  let valid = call_402657516.validator(path, query, header, formData, body, _)
  let scheme = call_402657516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657516.makeUrl(scheme.get, call_402657516.host, call_402657516.base,
                                   call_402657516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657516, uri, valid, _)

proc call*(call_402657517: Call_StopRun_402657504; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657518 = newJObject()
  if body != nil:
    body_402657518 = body
  result = call_402657517.call(nil, nil, nil, nil, body_402657518)

var stopRun* = Call_StopRun_402657504(name: "stopRun",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                      validator: validate_StopRun_402657505,
                                      base: "/", makeUrl: url_StopRun_402657506,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657519 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657521(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657520(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657522 = header.getOrDefault("X-Amz-Target")
  valid_402657522 = validateParameter(valid_402657522, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_402657522 != nil:
    section.add "X-Amz-Target", valid_402657522
  var valid_402657523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657523 = validateParameter(valid_402657523, JString,
                                      required = false, default = nil)
  if valid_402657523 != nil:
    section.add "X-Amz-Security-Token", valid_402657523
  var valid_402657524 = header.getOrDefault("X-Amz-Signature")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Signature", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Algorithm", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Date")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Date", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Credential")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Credential", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657529
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

proc call*(call_402657531: Call_TagResource_402657519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
                                                                                         ## 
  let valid = call_402657531.validator(path, query, header, formData, body, _)
  let scheme = call_402657531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657531.makeUrl(scheme.get, call_402657531.host, call_402657531.base,
                                   call_402657531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657531, uri, valid, _)

proc call*(call_402657532: Call_TagResource_402657519; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   
                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657533 = newJObject()
  if body != nil:
    body_402657533 = body
  result = call_402657532.call(nil, nil, nil, nil, body_402657533)

var tagResource* = Call_TagResource_402657519(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
    validator: validate_TagResource_402657520, base: "/",
    makeUrl: url_TagResource_402657521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657534 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657536(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657535(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657537 = header.getOrDefault("X-Amz-Target")
  valid_402657537 = validateParameter(valid_402657537, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_402657537 != nil:
    section.add "X-Amz-Target", valid_402657537
  var valid_402657538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657538 = validateParameter(valid_402657538, JString,
                                      required = false, default = nil)
  if valid_402657538 != nil:
    section.add "X-Amz-Security-Token", valid_402657538
  var valid_402657539 = header.getOrDefault("X-Amz-Signature")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "X-Amz-Signature", valid_402657539
  var valid_402657540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657540
  var valid_402657541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Algorithm", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Date")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Date", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Credential")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Credential", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657544
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

proc call*(call_402657546: Call_UntagResource_402657534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified tags from a resource.
                                                                                         ## 
  let valid = call_402657546.validator(path, query, header, formData, body, _)
  let scheme = call_402657546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657546.makeUrl(scheme.get, call_402657546.host, call_402657546.base,
                                   call_402657546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657546, uri, valid, _)

proc call*(call_402657547: Call_UntagResource_402657534; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_402657548 = newJObject()
  if body != nil:
    body_402657548 = body
  result = call_402657547.call(nil, nil, nil, nil, body_402657548)

var untagResource* = Call_UntagResource_402657534(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_402657535, base: "/",
    makeUrl: url_UntagResource_402657536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_402657549 = ref object of OpenApiRestCall_402656044
proc url_UpdateDeviceInstance_402657551(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceInstance_402657550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657552 = header.getOrDefault("X-Amz-Target")
  valid_402657552 = validateParameter(valid_402657552, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_402657552 != nil:
    section.add "X-Amz-Target", valid_402657552
  var valid_402657553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657553 = validateParameter(valid_402657553, JString,
                                      required = false, default = nil)
  if valid_402657553 != nil:
    section.add "X-Amz-Security-Token", valid_402657553
  var valid_402657554 = header.getOrDefault("X-Amz-Signature")
  valid_402657554 = validateParameter(valid_402657554, JString,
                                      required = false, default = nil)
  if valid_402657554 != nil:
    section.add "X-Amz-Signature", valid_402657554
  var valid_402657555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657555 = validateParameter(valid_402657555, JString,
                                      required = false, default = nil)
  if valid_402657555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657555
  var valid_402657556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657556 = validateParameter(valid_402657556, JString,
                                      required = false, default = nil)
  if valid_402657556 != nil:
    section.add "X-Amz-Algorithm", valid_402657556
  var valid_402657557 = header.getOrDefault("X-Amz-Date")
  valid_402657557 = validateParameter(valid_402657557, JString,
                                      required = false, default = nil)
  if valid_402657557 != nil:
    section.add "X-Amz-Date", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-Credential")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-Credential", valid_402657558
  var valid_402657559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657559
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

proc call*(call_402657561: Call_UpdateDeviceInstance_402657549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about a private device instance.
                                                                                         ## 
  let valid = call_402657561.validator(path, query, header, formData, body, _)
  let scheme = call_402657561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657561.makeUrl(scheme.get, call_402657561.host, call_402657561.base,
                                   call_402657561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657561, uri, valid, _)

proc call*(call_402657562: Call_UpdateDeviceInstance_402657549; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_402657563 = newJObject()
  if body != nil:
    body_402657563 = body
  result = call_402657562.call(nil, nil, nil, nil, body_402657563)

var updateDeviceInstance* = Call_UpdateDeviceInstance_402657549(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_402657550, base: "/",
    makeUrl: url_UpdateDeviceInstance_402657551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_402657564 = ref object of OpenApiRestCall_402656044
proc url_UpdateDevicePool_402657566(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePool_402657565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657567 = header.getOrDefault("X-Amz-Target")
  valid_402657567 = validateParameter(valid_402657567, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_402657567 != nil:
    section.add "X-Amz-Target", valid_402657567
  var valid_402657568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657568 = validateParameter(valid_402657568, JString,
                                      required = false, default = nil)
  if valid_402657568 != nil:
    section.add "X-Amz-Security-Token", valid_402657568
  var valid_402657569 = header.getOrDefault("X-Amz-Signature")
  valid_402657569 = validateParameter(valid_402657569, JString,
                                      required = false, default = nil)
  if valid_402657569 != nil:
    section.add "X-Amz-Signature", valid_402657569
  var valid_402657570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657570 = validateParameter(valid_402657570, JString,
                                      required = false, default = nil)
  if valid_402657570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657570
  var valid_402657571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657571 = validateParameter(valid_402657571, JString,
                                      required = false, default = nil)
  if valid_402657571 != nil:
    section.add "X-Amz-Algorithm", valid_402657571
  var valid_402657572 = header.getOrDefault("X-Amz-Date")
  valid_402657572 = validateParameter(valid_402657572, JString,
                                      required = false, default = nil)
  if valid_402657572 != nil:
    section.add "X-Amz-Date", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-Credential")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-Credential", valid_402657573
  var valid_402657574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657574
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

proc call*(call_402657576: Call_UpdateDevicePool_402657564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
                                                                                         ## 
  let valid = call_402657576.validator(path, query, header, formData, body, _)
  let scheme = call_402657576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657576.makeUrl(scheme.get, call_402657576.host, call_402657576.base,
                                   call_402657576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657576, uri, valid, _)

proc call*(call_402657577: Call_UpdateDevicePool_402657564; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   
                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657578 = newJObject()
  if body != nil:
    body_402657578 = body
  result = call_402657577.call(nil, nil, nil, nil, body_402657578)

var updateDevicePool* = Call_UpdateDevicePool_402657564(
    name: "updateDevicePool", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_402657565, base: "/",
    makeUrl: url_UpdateDevicePool_402657566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_402657579 = ref object of OpenApiRestCall_402656044
proc url_UpdateInstanceProfile_402657581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceProfile_402657580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657582 = header.getOrDefault("X-Amz-Target")
  valid_402657582 = validateParameter(valid_402657582, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_402657582 != nil:
    section.add "X-Amz-Target", valid_402657582
  var valid_402657583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657583 = validateParameter(valid_402657583, JString,
                                      required = false, default = nil)
  if valid_402657583 != nil:
    section.add "X-Amz-Security-Token", valid_402657583
  var valid_402657584 = header.getOrDefault("X-Amz-Signature")
  valid_402657584 = validateParameter(valid_402657584, JString,
                                      required = false, default = nil)
  if valid_402657584 != nil:
    section.add "X-Amz-Signature", valid_402657584
  var valid_402657585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657585 = validateParameter(valid_402657585, JString,
                                      required = false, default = nil)
  if valid_402657585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657585
  var valid_402657586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657586 = validateParameter(valid_402657586, JString,
                                      required = false, default = nil)
  if valid_402657586 != nil:
    section.add "X-Amz-Algorithm", valid_402657586
  var valid_402657587 = header.getOrDefault("X-Amz-Date")
  valid_402657587 = validateParameter(valid_402657587, JString,
                                      required = false, default = nil)
  if valid_402657587 != nil:
    section.add "X-Amz-Date", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-Credential")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-Credential", valid_402657588
  var valid_402657589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657589
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

proc call*(call_402657591: Call_UpdateInstanceProfile_402657579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about an existing private device instance profile.
                                                                                         ## 
  let valid = call_402657591.validator(path, query, header, formData, body, _)
  let scheme = call_402657591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657591.makeUrl(scheme.get, call_402657591.host, call_402657591.base,
                                   call_402657591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657591, uri, valid, _)

proc call*(call_402657592: Call_UpdateInstanceProfile_402657579; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657593 = newJObject()
  if body != nil:
    body_402657593 = body
  result = call_402657592.call(nil, nil, nil, nil, body_402657593)

var updateInstanceProfile* = Call_UpdateInstanceProfile_402657579(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_402657580, base: "/",
    makeUrl: url_UpdateInstanceProfile_402657581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_402657594 = ref object of OpenApiRestCall_402656044
proc url_UpdateNetworkProfile_402657596(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_402657595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657597 = header.getOrDefault("X-Amz-Target")
  valid_402657597 = validateParameter(valid_402657597, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_402657597 != nil:
    section.add "X-Amz-Target", valid_402657597
  var valid_402657598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657598 = validateParameter(valid_402657598, JString,
                                      required = false, default = nil)
  if valid_402657598 != nil:
    section.add "X-Amz-Security-Token", valid_402657598
  var valid_402657599 = header.getOrDefault("X-Amz-Signature")
  valid_402657599 = validateParameter(valid_402657599, JString,
                                      required = false, default = nil)
  if valid_402657599 != nil:
    section.add "X-Amz-Signature", valid_402657599
  var valid_402657600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657600 = validateParameter(valid_402657600, JString,
                                      required = false, default = nil)
  if valid_402657600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657600
  var valid_402657601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657601 = validateParameter(valid_402657601, JString,
                                      required = false, default = nil)
  if valid_402657601 != nil:
    section.add "X-Amz-Algorithm", valid_402657601
  var valid_402657602 = header.getOrDefault("X-Amz-Date")
  valid_402657602 = validateParameter(valid_402657602, JString,
                                      required = false, default = nil)
  if valid_402657602 != nil:
    section.add "X-Amz-Date", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Credential")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Credential", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657604
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

proc call*(call_402657606: Call_UpdateNetworkProfile_402657594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the network profile.
                                                                                         ## 
  let valid = call_402657606.validator(path, query, header, formData, body, _)
  let scheme = call_402657606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657606.makeUrl(scheme.get, call_402657606.host, call_402657606.base,
                                   call_402657606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657606, uri, valid, _)

proc call*(call_402657607: Call_UpdateNetworkProfile_402657594; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_402657608 = newJObject()
  if body != nil:
    body_402657608 = body
  result = call_402657607.call(nil, nil, nil, nil, body_402657608)

var updateNetworkProfile* = Call_UpdateNetworkProfile_402657594(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_402657595, base: "/",
    makeUrl: url_UpdateNetworkProfile_402657596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_402657609 = ref object of OpenApiRestCall_402656044
proc url_UpdateProject_402657611(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_402657610(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657612 = header.getOrDefault("X-Amz-Target")
  valid_402657612 = validateParameter(valid_402657612, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_402657612 != nil:
    section.add "X-Amz-Target", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Security-Token", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-Signature")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-Signature", valid_402657614
  var valid_402657615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657615 = validateParameter(valid_402657615, JString,
                                      required = false, default = nil)
  if valid_402657615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657615
  var valid_402657616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657616 = validateParameter(valid_402657616, JString,
                                      required = false, default = nil)
  if valid_402657616 != nil:
    section.add "X-Amz-Algorithm", valid_402657616
  var valid_402657617 = header.getOrDefault("X-Amz-Date")
  valid_402657617 = validateParameter(valid_402657617, JString,
                                      required = false, default = nil)
  if valid_402657617 != nil:
    section.add "X-Amz-Date", valid_402657617
  var valid_402657618 = header.getOrDefault("X-Amz-Credential")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "X-Amz-Credential", valid_402657618
  var valid_402657619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657619 = validateParameter(valid_402657619, JString,
                                      required = false, default = nil)
  if valid_402657619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657619
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

proc call*(call_402657621: Call_UpdateProject_402657609; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
                                                                                         ## 
  let valid = call_402657621.validator(path, query, header, formData, body, _)
  let scheme = call_402657621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657621.makeUrl(scheme.get, call_402657621.host, call_402657621.base,
                                   call_402657621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657621, uri, valid, _)

proc call*(call_402657622: Call_UpdateProject_402657609; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   
                                                                               ## body: JObject (required)
  var body_402657623 = newJObject()
  if body != nil:
    body_402657623 = body
  result = call_402657622.call(nil, nil, nil, nil, body_402657623)

var updateProject* = Call_UpdateProject_402657609(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_402657610, base: "/",
    makeUrl: url_UpdateProject_402657611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_402657624 = ref object of OpenApiRestCall_402656044
proc url_UpdateTestGridProject_402657626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTestGridProject_402657625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657627 = header.getOrDefault("X-Amz-Target")
  valid_402657627 = validateParameter(valid_402657627, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_402657627 != nil:
    section.add "X-Amz-Target", valid_402657627
  var valid_402657628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657628 = validateParameter(valid_402657628, JString,
                                      required = false, default = nil)
  if valid_402657628 != nil:
    section.add "X-Amz-Security-Token", valid_402657628
  var valid_402657629 = header.getOrDefault("X-Amz-Signature")
  valid_402657629 = validateParameter(valid_402657629, JString,
                                      required = false, default = nil)
  if valid_402657629 != nil:
    section.add "X-Amz-Signature", valid_402657629
  var valid_402657630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657630 = validateParameter(valid_402657630, JString,
                                      required = false, default = nil)
  if valid_402657630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657630
  var valid_402657631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657631 = validateParameter(valid_402657631, JString,
                                      required = false, default = nil)
  if valid_402657631 != nil:
    section.add "X-Amz-Algorithm", valid_402657631
  var valid_402657632 = header.getOrDefault("X-Amz-Date")
  valid_402657632 = validateParameter(valid_402657632, JString,
                                      required = false, default = nil)
  if valid_402657632 != nil:
    section.add "X-Amz-Date", valid_402657632
  var valid_402657633 = header.getOrDefault("X-Amz-Credential")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "X-Amz-Credential", valid_402657633
  var valid_402657634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657634 = validateParameter(valid_402657634, JString,
                                      required = false, default = nil)
  if valid_402657634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657634
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

proc call*(call_402657636: Call_UpdateTestGridProject_402657624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Change details of a project.
                                                                                         ## 
  let valid = call_402657636.validator(path, query, header, formData, body, _)
  let scheme = call_402657636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657636.makeUrl(scheme.get, call_402657636.host, call_402657636.base,
                                   call_402657636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657636, uri, valid, _)

proc call*(call_402657637: Call_UpdateTestGridProject_402657624; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_402657638 = newJObject()
  if body != nil:
    body_402657638 = body
  result = call_402657637.call(nil, nil, nil, nil, body_402657638)

var updateTestGridProject* = Call_UpdateTestGridProject_402657624(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_402657625, base: "/",
    makeUrl: url_UpdateTestGridProject_402657626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_402657639 = ref object of OpenApiRestCall_402656044
proc url_UpdateUpload_402657641(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUpload_402657640(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657642 = header.getOrDefault("X-Amz-Target")
  valid_402657642 = validateParameter(valid_402657642, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_402657642 != nil:
    section.add "X-Amz-Target", valid_402657642
  var valid_402657643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657643 = validateParameter(valid_402657643, JString,
                                      required = false, default = nil)
  if valid_402657643 != nil:
    section.add "X-Amz-Security-Token", valid_402657643
  var valid_402657644 = header.getOrDefault("X-Amz-Signature")
  valid_402657644 = validateParameter(valid_402657644, JString,
                                      required = false, default = nil)
  if valid_402657644 != nil:
    section.add "X-Amz-Signature", valid_402657644
  var valid_402657645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657645 = validateParameter(valid_402657645, JString,
                                      required = false, default = nil)
  if valid_402657645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657645
  var valid_402657646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657646 = validateParameter(valid_402657646, JString,
                                      required = false, default = nil)
  if valid_402657646 != nil:
    section.add "X-Amz-Algorithm", valid_402657646
  var valid_402657647 = header.getOrDefault("X-Amz-Date")
  valid_402657647 = validateParameter(valid_402657647, JString,
                                      required = false, default = nil)
  if valid_402657647 != nil:
    section.add "X-Amz-Date", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Credential")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Credential", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657649
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

proc call*(call_402657651: Call_UpdateUpload_402657639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an uploaded test spec.
                                                                                         ## 
  let valid = call_402657651.validator(path, query, header, formData, body, _)
  let scheme = call_402657651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657651.makeUrl(scheme.get, call_402657651.host, call_402657651.base,
                                   call_402657651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657651, uri, valid, _)

proc call*(call_402657652: Call_UpdateUpload_402657639; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_402657653 = newJObject()
  if body != nil:
    body_402657653 = body
  result = call_402657652.call(nil, nil, nil, nil, body_402657653)

var updateUpload* = Call_UpdateUpload_402657639(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_402657640, base: "/",
    makeUrl: url_UpdateUpload_402657641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_402657654 = ref object of OpenApiRestCall_402656044
proc url_UpdateVPCEConfiguration_402657656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVPCEConfiguration_402657655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657657 = header.getOrDefault("X-Amz-Target")
  valid_402657657 = validateParameter(valid_402657657, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_402657657 != nil:
    section.add "X-Amz-Target", valid_402657657
  var valid_402657658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657658 = validateParameter(valid_402657658, JString,
                                      required = false, default = nil)
  if valid_402657658 != nil:
    section.add "X-Amz-Security-Token", valid_402657658
  var valid_402657659 = header.getOrDefault("X-Amz-Signature")
  valid_402657659 = validateParameter(valid_402657659, JString,
                                      required = false, default = nil)
  if valid_402657659 != nil:
    section.add "X-Amz-Signature", valid_402657659
  var valid_402657660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657660 = validateParameter(valid_402657660, JString,
                                      required = false, default = nil)
  if valid_402657660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657660
  var valid_402657661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657661 = validateParameter(valid_402657661, JString,
                                      required = false, default = nil)
  if valid_402657661 != nil:
    section.add "X-Amz-Algorithm", valid_402657661
  var valid_402657662 = header.getOrDefault("X-Amz-Date")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "X-Amz-Date", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Credential")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Credential", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657664
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

proc call*(call_402657666: Call_UpdateVPCEConfiguration_402657654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
                                                                                         ## 
  let valid = call_402657666.validator(path, query, header, formData, body, _)
  let scheme = call_402657666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657666.makeUrl(scheme.get, call_402657666.host, call_402657666.base,
                                   call_402657666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657666, uri, valid, _)

proc call*(call_402657667: Call_UpdateVPCEConfiguration_402657654;
           body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   
                                                                                            ## body: JObject (required)
  var body_402657668 = newJObject()
  if body != nil:
    body_402657668 = body
  result = call_402657667.call(nil, nil, nil, nil, body_402657668)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_402657654(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_402657655, base: "/",
    makeUrl: url_UpdateVPCEConfiguration_402657656,
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