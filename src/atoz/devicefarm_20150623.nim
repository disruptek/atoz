
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateDevicePool_21625781 = ref object of OpenApiRestCall_21625437
proc url_CreateDevicePool_21625783(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevicePool_21625782(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625900 = header.getOrDefault("X-Amz-Target")
  valid_21625900 = validateParameter(valid_21625900, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_21625900 != nil:
    section.add "X-Amz-Target", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
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

proc call*(call_21625931: Call_CreateDevicePool_21625781; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_CreateDevicePool_21625781; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_21625995 = newJObject()
  if body != nil:
    body_21625995 = body
  result = call_21625994.call(nil, nil, nil, nil, body_21625995)

var createDevicePool* = Call_CreateDevicePool_21625781(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_21625782, base: "/",
    makeUrl: url_CreateDevicePool_21625783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_21626031 = ref object of OpenApiRestCall_21625437
proc url_CreateInstanceProfile_21626033(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceProfile_21626032(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Target")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_21626036 != nil:
    section.add "X-Amz-Target", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Algorithm", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Signature")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Signature", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Credential")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Credential", valid_21626041
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

proc call*(call_21626043: Call_CreateInstanceProfile_21626031;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_21626043.validator(path, query, header, formData, body, _)
  let scheme = call_21626043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626043.makeUrl(scheme.get, call_21626043.host, call_21626043.base,
                               call_21626043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626043, uri, valid, _)

proc call*(call_21626044: Call_CreateInstanceProfile_21626031; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_21626045 = newJObject()
  if body != nil:
    body_21626045 = body
  result = call_21626044.call(nil, nil, nil, nil, body_21626045)

var createInstanceProfile* = Call_CreateInstanceProfile_21626031(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_21626032, base: "/",
    makeUrl: url_CreateInstanceProfile_21626033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_21626046 = ref object of OpenApiRestCall_21625437
proc url_CreateNetworkProfile_21626048(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_21626047(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626049 = header.getOrDefault("X-Amz-Date")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Date", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Security-Token", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Target")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_21626051 != nil:
    section.add "X-Amz-Target", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
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

proc call*(call_21626058: Call_CreateNetworkProfile_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_CreateNetworkProfile_21626046; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_21626060 = newJObject()
  if body != nil:
    body_21626060 = body
  result = call_21626059.call(nil, nil, nil, nil, body_21626060)

var createNetworkProfile* = Call_CreateNetworkProfile_21626046(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_21626047, base: "/",
    makeUrl: url_CreateNetworkProfile_21626048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_21626061 = ref object of OpenApiRestCall_21625437
proc url_CreateProject_21626063(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_21626062(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Target")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_21626066 != nil:
    section.add "X-Amz-Target", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Algorithm", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Signature")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Signature", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Credential")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Credential", valid_21626071
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

proc call*(call_21626073: Call_CreateProject_21626061; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a project.
  ## 
  let valid = call_21626073.validator(path, query, header, formData, body, _)
  let scheme = call_21626073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626073.makeUrl(scheme.get, call_21626073.host, call_21626073.base,
                               call_21626073.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626073, uri, valid, _)

proc call*(call_21626074: Call_CreateProject_21626061; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_21626075 = newJObject()
  if body != nil:
    body_21626075 = body
  result = call_21626074.call(nil, nil, nil, nil, body_21626075)

var createProject* = Call_CreateProject_21626061(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_21626062, base: "/",
    makeUrl: url_CreateProject_21626063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_21626076 = ref object of OpenApiRestCall_21625437
proc url_CreateRemoteAccessSession_21626078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRemoteAccessSession_21626077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Specifies and starts a remote access session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Target")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_21626081 != nil:
    section.add "X-Amz-Target", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
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

proc call*(call_21626088: Call_CreateRemoteAccessSession_21626076;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_CreateRemoteAccessSession_21626076; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_21626090 = newJObject()
  if body != nil:
    body_21626090 = body
  result = call_21626089.call(nil, nil, nil, nil, body_21626090)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_21626076(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_21626077, base: "/",
    makeUrl: url_CreateRemoteAccessSession_21626078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_21626091 = ref object of OpenApiRestCall_21625437
proc url_CreateTestGridProject_21626093(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridProject_21626092(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626094 = header.getOrDefault("X-Amz-Date")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Date", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Security-Token", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Target")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_21626096 != nil:
    section.add "X-Amz-Target", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Algorithm", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Signature")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Signature", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Credential")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Credential", valid_21626101
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

proc call*(call_21626103: Call_CreateTestGridProject_21626091;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_CreateTestGridProject_21626091; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   body: JObject (required)
  var body_21626105 = newJObject()
  if body != nil:
    body_21626105 = body
  result = call_21626104.call(nil, nil, nil, nil, body_21626105)

var createTestGridProject* = Call_CreateTestGridProject_21626091(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_21626092, base: "/",
    makeUrl: url_CreateTestGridProject_21626093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_21626106 = ref object of OpenApiRestCall_21625437
proc url_CreateTestGridUrl_21626108(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridUrl_21626107(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Target")
  valid_21626111 = validateParameter(valid_21626111, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_21626111 != nil:
    section.add "X-Amz-Target", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
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

proc call*(call_21626118: Call_CreateTestGridUrl_21626106; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  let valid = call_21626118.validator(path, query, header, formData, body, _)
  let scheme = call_21626118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626118.makeUrl(scheme.get, call_21626118.host, call_21626118.base,
                               call_21626118.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626118, uri, valid, _)

proc call*(call_21626119: Call_CreateTestGridUrl_21626106; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   body: JObject (required)
  var body_21626120 = newJObject()
  if body != nil:
    body_21626120 = body
  result = call_21626119.call(nil, nil, nil, nil, body_21626120)

var createTestGridUrl* = Call_CreateTestGridUrl_21626106(name: "createTestGridUrl",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_21626107, base: "/",
    makeUrl: url_CreateTestGridUrl_21626108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_21626121 = ref object of OpenApiRestCall_21625437
proc url_CreateUpload_21626123(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUpload_21626122(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Uploads an app or test scripts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626124 = header.getOrDefault("X-Amz-Date")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Date", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Security-Token", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Target")
  valid_21626126 = validateParameter(valid_21626126, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_21626126 != nil:
    section.add "X-Amz-Target", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Algorithm", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Signature")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Signature", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Credential")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Credential", valid_21626131
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

proc call*(call_21626133: Call_CreateUpload_21626121; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_CreateUpload_21626121; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_21626135 = newJObject()
  if body != nil:
    body_21626135 = body
  result = call_21626134.call(nil, nil, nil, nil, body_21626135)

var createUpload* = Call_CreateUpload_21626121(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_21626122, base: "/", makeUrl: url_CreateUpload_21626123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_21626136 = ref object of OpenApiRestCall_21625437
proc url_CreateVPCEConfiguration_21626138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVPCEConfiguration_21626137(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
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

proc call*(call_21626148: Call_CreateVPCEConfiguration_21626136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_CreateVPCEConfiguration_21626136; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_21626150 = newJObject()
  if body != nil:
    body_21626150 = body
  result = call_21626149.call(nil, nil, nil, nil, body_21626150)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_21626136(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_21626137, base: "/",
    makeUrl: url_CreateVPCEConfiguration_21626138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_21626151 = ref object of OpenApiRestCall_21625437
proc url_DeleteDevicePool_21626153(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevicePool_21626152(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626154 = header.getOrDefault("X-Amz-Date")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Date", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Security-Token", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Target")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_21626156 != nil:
    section.add "X-Amz-Target", valid_21626156
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626163: Call_DeleteDevicePool_21626151; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_21626163.validator(path, query, header, formData, body, _)
  let scheme = call_21626163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626163.makeUrl(scheme.get, call_21626163.host, call_21626163.base,
                               call_21626163.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626163, uri, valid, _)

proc call*(call_21626164: Call_DeleteDevicePool_21626151; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_21626165 = newJObject()
  if body != nil:
    body_21626165 = body
  result = call_21626164.call(nil, nil, nil, nil, body_21626165)

var deleteDevicePool* = Call_DeleteDevicePool_21626151(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_21626152, base: "/",
    makeUrl: url_DeleteDevicePool_21626153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_21626166 = ref object of OpenApiRestCall_21625437
proc url_DeleteInstanceProfile_21626168(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceProfile_21626167(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626169 = header.getOrDefault("X-Amz-Date")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Date", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Security-Token", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Target")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_21626171 != nil:
    section.add "X-Amz-Target", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Algorithm", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Signature")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Signature", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Credential")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Credential", valid_21626176
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

proc call*(call_21626178: Call_DeleteInstanceProfile_21626166;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_DeleteInstanceProfile_21626166; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_21626180 = newJObject()
  if body != nil:
    body_21626180 = body
  result = call_21626179.call(nil, nil, nil, nil, body_21626180)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_21626166(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_21626167, base: "/",
    makeUrl: url_DeleteInstanceProfile_21626168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_21626181 = ref object of OpenApiRestCall_21625437
proc url_DeleteNetworkProfile_21626183(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_21626182(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Target")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_21626186 != nil:
    section.add "X-Amz-Target", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Algorithm", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Signature")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Signature", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Credential")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Credential", valid_21626191
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

proc call*(call_21626193: Call_DeleteNetworkProfile_21626181; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_21626193.validator(path, query, header, formData, body, _)
  let scheme = call_21626193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626193.makeUrl(scheme.get, call_21626193.host, call_21626193.base,
                               call_21626193.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626193, uri, valid, _)

proc call*(call_21626194: Call_DeleteNetworkProfile_21626181; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_21626195 = newJObject()
  if body != nil:
    body_21626195 = body
  result = call_21626194.call(nil, nil, nil, nil, body_21626195)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_21626181(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_21626182, base: "/",
    makeUrl: url_DeleteNetworkProfile_21626183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_21626196 = ref object of OpenApiRestCall_21625437
proc url_DeleteProject_21626198(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_21626197(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626199 = header.getOrDefault("X-Amz-Date")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Date", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Security-Token", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Target")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_21626201 != nil:
    section.add "X-Amz-Target", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Algorithm", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Signature")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Signature", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Credential")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Credential", valid_21626206
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

proc call*(call_21626208: Call_DeleteProject_21626196; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_DeleteProject_21626196; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_21626210 = newJObject()
  if body != nil:
    body_21626210 = body
  result = call_21626209.call(nil, nil, nil, nil, body_21626210)

var deleteProject* = Call_DeleteProject_21626196(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_21626197, base: "/",
    makeUrl: url_DeleteProject_21626198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_21626211 = ref object of OpenApiRestCall_21625437
proc url_DeleteRemoteAccessSession_21626213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_21626212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a completed remote access session and its results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626214 = header.getOrDefault("X-Amz-Date")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Date", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Security-Token", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Target")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_21626216 != nil:
    section.add "X-Amz-Target", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Algorithm", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Signature")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Signature", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Credential")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Credential", valid_21626221
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

proc call*(call_21626223: Call_DeleteRemoteAccessSession_21626211;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_DeleteRemoteAccessSession_21626211; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_21626225 = newJObject()
  if body != nil:
    body_21626225 = body
  result = call_21626224.call(nil, nil, nil, nil, body_21626225)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_21626211(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_21626212, base: "/",
    makeUrl: url_DeleteRemoteAccessSession_21626213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_21626226 = ref object of OpenApiRestCall_21625437
proc url_DeleteRun_21626228(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_21626227(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626229 = header.getOrDefault("X-Amz-Date")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Date", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Security-Token", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Target")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_21626231 != nil:
    section.add "X-Amz-Target", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Algorithm", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Signature")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Signature", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Credential")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Credential", valid_21626236
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

proc call*(call_21626238: Call_DeleteRun_21626226; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_21626238.validator(path, query, header, formData, body, _)
  let scheme = call_21626238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626238.makeUrl(scheme.get, call_21626238.host, call_21626238.base,
                               call_21626238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626238, uri, valid, _)

proc call*(call_21626239: Call_DeleteRun_21626226; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_21626240 = newJObject()
  if body != nil:
    body_21626240 = body
  result = call_21626239.call(nil, nil, nil, nil, body_21626240)

var deleteRun* = Call_DeleteRun_21626226(name: "deleteRun",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                      validator: validate_DeleteRun_21626227,
                                      base: "/", makeUrl: url_DeleteRun_21626228,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_21626241 = ref object of OpenApiRestCall_21625437
proc url_DeleteTestGridProject_21626243(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTestGridProject_21626242(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Target")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_21626246 != nil:
    section.add "X-Amz-Target", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
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

proc call*(call_21626253: Call_DeleteTestGridProject_21626241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_DeleteTestGridProject_21626241; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   body: JObject (required)
  var body_21626255 = newJObject()
  if body != nil:
    body_21626255 = body
  result = call_21626254.call(nil, nil, nil, nil, body_21626255)

var deleteTestGridProject* = Call_DeleteTestGridProject_21626241(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_21626242, base: "/",
    makeUrl: url_DeleteTestGridProject_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_21626256 = ref object of OpenApiRestCall_21625437
proc url_DeleteUpload_21626258(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUpload_21626257(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an upload given the upload ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Target")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_21626261 != nil:
    section.add "X-Amz-Target", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Algorithm", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Signature")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Signature", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Credential")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Credential", valid_21626266
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

proc call*(call_21626268: Call_DeleteUpload_21626256; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_21626268.validator(path, query, header, formData, body, _)
  let scheme = call_21626268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626268.makeUrl(scheme.get, call_21626268.host, call_21626268.base,
                               call_21626268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626268, uri, valid, _)

proc call*(call_21626269: Call_DeleteUpload_21626256; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_21626270 = newJObject()
  if body != nil:
    body_21626270 = body
  result = call_21626269.call(nil, nil, nil, nil, body_21626270)

var deleteUpload* = Call_DeleteUpload_21626256(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_21626257, base: "/", makeUrl: url_DeleteUpload_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_21626271 = ref object of OpenApiRestCall_21625437
proc url_DeleteVPCEConfiguration_21626273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVPCEConfiguration_21626272(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626274 = header.getOrDefault("X-Amz-Date")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Date", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Security-Token", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Target")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_21626276 != nil:
    section.add "X-Amz-Target", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Algorithm", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Signature")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Signature", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Credential")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Credential", valid_21626281
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

proc call*(call_21626283: Call_DeleteVPCEConfiguration_21626271;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_DeleteVPCEConfiguration_21626271; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_21626285 = newJObject()
  if body != nil:
    body_21626285 = body
  result = call_21626284.call(nil, nil, nil, nil, body_21626285)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_21626271(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_21626272, base: "/",
    makeUrl: url_DeleteVPCEConfiguration_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_21626286 = ref object of OpenApiRestCall_21625437
proc url_GetAccountSettings_21626288(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_21626287(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626289 = header.getOrDefault("X-Amz-Date")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Date", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Security-Token", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Target")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_21626291 != nil:
    section.add "X-Amz-Target", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Algorithm", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Signature")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Signature", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Credential")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Credential", valid_21626296
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

proc call*(call_21626298: Call_GetAccountSettings_21626286; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_21626298.validator(path, query, header, formData, body, _)
  let scheme = call_21626298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626298.makeUrl(scheme.get, call_21626298.host, call_21626298.base,
                               call_21626298.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626298, uri, valid, _)

proc call*(call_21626299: Call_GetAccountSettings_21626286; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_21626300 = newJObject()
  if body != nil:
    body_21626300 = body
  result = call_21626299.call(nil, nil, nil, nil, body_21626300)

var getAccountSettings* = Call_GetAccountSettings_21626286(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_21626287, base: "/",
    makeUrl: url_GetAccountSettings_21626288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_21626301 = ref object of OpenApiRestCall_21625437
proc url_GetDevice_21626303(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_21626302(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626304 = header.getOrDefault("X-Amz-Date")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Date", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Security-Token", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Target")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_21626306 != nil:
    section.add "X-Amz-Target", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Algorithm", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Signature")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Signature", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Credential")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Credential", valid_21626311
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

proc call*(call_21626313: Call_GetDevice_21626301; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_21626313.validator(path, query, header, formData, body, _)
  let scheme = call_21626313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626313.makeUrl(scheme.get, call_21626313.host, call_21626313.base,
                               call_21626313.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626313, uri, valid, _)

proc call*(call_21626314: Call_GetDevice_21626301; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_21626315 = newJObject()
  if body != nil:
    body_21626315 = body
  result = call_21626314.call(nil, nil, nil, nil, body_21626315)

var getDevice* = Call_GetDevice_21626301(name: "getDevice",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                      validator: validate_GetDevice_21626302,
                                      base: "/", makeUrl: url_GetDevice_21626303,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_21626316 = ref object of OpenApiRestCall_21625437
proc url_GetDeviceInstance_21626318(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeviceInstance_21626317(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626319 = header.getOrDefault("X-Amz-Date")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Date", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Security-Token", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Target")
  valid_21626321 = validateParameter(valid_21626321, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_21626321 != nil:
    section.add "X-Amz-Target", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
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

proc call*(call_21626328: Call_GetDeviceInstance_21626316; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_GetDeviceInstance_21626316; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   body: JObject (required)
  var body_21626330 = newJObject()
  if body != nil:
    body_21626330 = body
  result = call_21626329.call(nil, nil, nil, nil, body_21626330)

var getDeviceInstance* = Call_GetDeviceInstance_21626316(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_21626317, base: "/",
    makeUrl: url_GetDeviceInstance_21626318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_21626331 = ref object of OpenApiRestCall_21625437
proc url_GetDevicePool_21626333(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePool_21626332(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about a device pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626334 = header.getOrDefault("X-Amz-Date")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Date", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Security-Token", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Target")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_21626336 != nil:
    section.add "X-Amz-Target", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
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

proc call*(call_21626343: Call_GetDevicePool_21626331; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_GetDevicePool_21626331; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_21626345 = newJObject()
  if body != nil:
    body_21626345 = body
  result = call_21626344.call(nil, nil, nil, nil, body_21626345)

var getDevicePool* = Call_GetDevicePool_21626331(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_21626332, base: "/",
    makeUrl: url_GetDevicePool_21626333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_21626346 = ref object of OpenApiRestCall_21625437
proc url_GetDevicePoolCompatibility_21626348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_21626347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about compatibility with a device pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626349 = header.getOrDefault("X-Amz-Date")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Date", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Security-Token", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Target")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_21626351 != nil:
    section.add "X-Amz-Target", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Algorithm", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Signature")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Signature", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Credential")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Credential", valid_21626356
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

proc call*(call_21626358: Call_GetDevicePoolCompatibility_21626346;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_21626358.validator(path, query, header, formData, body, _)
  let scheme = call_21626358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626358.makeUrl(scheme.get, call_21626358.host, call_21626358.base,
                               call_21626358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626358, uri, valid, _)

proc call*(call_21626359: Call_GetDevicePoolCompatibility_21626346; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_21626360 = newJObject()
  if body != nil:
    body_21626360 = body
  result = call_21626359.call(nil, nil, nil, nil, body_21626360)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_21626346(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_21626347, base: "/",
    makeUrl: url_GetDevicePoolCompatibility_21626348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_21626361 = ref object of OpenApiRestCall_21625437
proc url_GetInstanceProfile_21626363(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceProfile_21626362(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626364 = header.getOrDefault("X-Amz-Date")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Date", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Security-Token", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Target")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_21626366 != nil:
    section.add "X-Amz-Target", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
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

proc call*(call_21626373: Call_GetInstanceProfile_21626361; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_GetInstanceProfile_21626361; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_21626375 = newJObject()
  if body != nil:
    body_21626375 = body
  result = call_21626374.call(nil, nil, nil, nil, body_21626375)

var getInstanceProfile* = Call_GetInstanceProfile_21626361(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_21626362, base: "/",
    makeUrl: url_GetInstanceProfile_21626363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_21626376 = ref object of OpenApiRestCall_21625437
proc url_GetJob_21626378(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_21626377(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626379 = header.getOrDefault("X-Amz-Date")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Date", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Security-Token", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Target")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_21626381 != nil:
    section.add "X-Amz-Target", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Algorithm", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Signature")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Signature", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Credential")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Credential", valid_21626386
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

proc call*(call_21626388: Call_GetJob_21626376; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_21626388.validator(path, query, header, formData, body, _)
  let scheme = call_21626388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626388.makeUrl(scheme.get, call_21626388.host, call_21626388.base,
                               call_21626388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626388, uri, valid, _)

proc call*(call_21626389: Call_GetJob_21626376; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_21626390 = newJObject()
  if body != nil:
    body_21626390 = body
  result = call_21626389.call(nil, nil, nil, nil, body_21626390)

var getJob* = Call_GetJob_21626376(name: "getJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                                validator: validate_GetJob_21626377, base: "/",
                                makeUrl: url_GetJob_21626378,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_21626391 = ref object of OpenApiRestCall_21625437
proc url_GetNetworkProfile_21626393(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_21626392(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Target")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_21626396 != nil:
    section.add "X-Amz-Target", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Algorithm", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Signature")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Signature", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Credential")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Credential", valid_21626401
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

proc call*(call_21626403: Call_GetNetworkProfile_21626391; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_21626403.validator(path, query, header, formData, body, _)
  let scheme = call_21626403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626403.makeUrl(scheme.get, call_21626403.host, call_21626403.base,
                               call_21626403.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626403, uri, valid, _)

proc call*(call_21626404: Call_GetNetworkProfile_21626391; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_21626405 = newJObject()
  if body != nil:
    body_21626405 = body
  result = call_21626404.call(nil, nil, nil, nil, body_21626405)

var getNetworkProfile* = Call_GetNetworkProfile_21626391(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_21626392, base: "/",
    makeUrl: url_GetNetworkProfile_21626393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_21626406 = ref object of OpenApiRestCall_21625437
proc url_GetOfferingStatus_21626408(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOfferingStatus_21626407(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626409 = query.getOrDefault("nextToken")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "nextToken", valid_21626409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626410 = header.getOrDefault("X-Amz-Date")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Date", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Security-Token", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Target")
  valid_21626412 = validateParameter(valid_21626412, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_21626412 != nil:
    section.add "X-Amz-Target", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Algorithm", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Signature")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Signature", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Credential")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Credential", valid_21626417
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

proc call*(call_21626419: Call_GetOfferingStatus_21626406; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_21626419.validator(path, query, header, formData, body, _)
  let scheme = call_21626419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626419.makeUrl(scheme.get, call_21626419.host, call_21626419.base,
                               call_21626419.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626419, uri, valid, _)

proc call*(call_21626420: Call_GetOfferingStatus_21626406; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626422 = newJObject()
  var body_21626423 = newJObject()
  add(query_21626422, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626423 = body
  result = call_21626420.call(nil, query_21626422, nil, nil, body_21626423)

var getOfferingStatus* = Call_GetOfferingStatus_21626406(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_21626407, base: "/",
    makeUrl: url_GetOfferingStatus_21626408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_21626427 = ref object of OpenApiRestCall_21625437
proc url_GetProject_21626429(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_21626428(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626430 = header.getOrDefault("X-Amz-Date")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Date", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Security-Token", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Target")
  valid_21626432 = validateParameter(valid_21626432, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_21626432 != nil:
    section.add "X-Amz-Target", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Algorithm", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Signature")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Signature", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Credential")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Credential", valid_21626437
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

proc call*(call_21626439: Call_GetProject_21626427; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_21626439.validator(path, query, header, formData, body, _)
  let scheme = call_21626439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626439.makeUrl(scheme.get, call_21626439.host, call_21626439.base,
                               call_21626439.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626439, uri, valid, _)

proc call*(call_21626440: Call_GetProject_21626427; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_21626441 = newJObject()
  if body != nil:
    body_21626441 = body
  result = call_21626440.call(nil, nil, nil, nil, body_21626441)

var getProject* = Call_GetProject_21626427(name: "getProject",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                        validator: validate_GetProject_21626428,
                                        base: "/", makeUrl: url_GetProject_21626429,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_21626442 = ref object of OpenApiRestCall_21625437
proc url_GetRemoteAccessSession_21626444(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoteAccessSession_21626443(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626445 = header.getOrDefault("X-Amz-Date")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Date", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Security-Token", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Target")
  valid_21626447 = validateParameter(valid_21626447, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_21626447 != nil:
    section.add "X-Amz-Target", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Algorithm", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Signature")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Signature", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Credential")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Credential", valid_21626452
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

proc call*(call_21626454: Call_GetRemoteAccessSession_21626442;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_21626454.validator(path, query, header, formData, body, _)
  let scheme = call_21626454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626454.makeUrl(scheme.get, call_21626454.host, call_21626454.base,
                               call_21626454.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626454, uri, valid, _)

proc call*(call_21626455: Call_GetRemoteAccessSession_21626442; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_21626456 = newJObject()
  if body != nil:
    body_21626456 = body
  result = call_21626455.call(nil, nil, nil, nil, body_21626456)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_21626442(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_21626443, base: "/",
    makeUrl: url_GetRemoteAccessSession_21626444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_21626457 = ref object of OpenApiRestCall_21625437
proc url_GetRun_21626459(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_21626458(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626460 = header.getOrDefault("X-Amz-Date")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Date", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Security-Token", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Target")
  valid_21626462 = validateParameter(valid_21626462, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_21626462 != nil:
    section.add "X-Amz-Target", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Algorithm", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Signature")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Signature", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Credential")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Credential", valid_21626467
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

proc call*(call_21626469: Call_GetRun_21626457; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_21626469.validator(path, query, header, formData, body, _)
  let scheme = call_21626469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626469.makeUrl(scheme.get, call_21626469.host, call_21626469.base,
                               call_21626469.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626469, uri, valid, _)

proc call*(call_21626470: Call_GetRun_21626457; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_21626471 = newJObject()
  if body != nil:
    body_21626471 = body
  result = call_21626470.call(nil, nil, nil, nil, body_21626471)

var getRun* = Call_GetRun_21626457(name: "getRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                                validator: validate_GetRun_21626458, base: "/",
                                makeUrl: url_GetRun_21626459,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_21626472 = ref object of OpenApiRestCall_21625437
proc url_GetSuite_21626474(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_21626473(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626475 = header.getOrDefault("X-Amz-Date")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Date", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Security-Token", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Target")
  valid_21626477 = validateParameter(valid_21626477, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_21626477 != nil:
    section.add "X-Amz-Target", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Algorithm", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Signature")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Signature", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Credential")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Credential", valid_21626482
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

proc call*(call_21626484: Call_GetSuite_21626472; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_21626484.validator(path, query, header, formData, body, _)
  let scheme = call_21626484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626484.makeUrl(scheme.get, call_21626484.host, call_21626484.base,
                               call_21626484.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626484, uri, valid, _)

proc call*(call_21626485: Call_GetSuite_21626472; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_21626486 = newJObject()
  if body != nil:
    body_21626486 = body
  result = call_21626485.call(nil, nil, nil, nil, body_21626486)

var getSuite* = Call_GetSuite_21626472(name: "getSuite", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                    validator: validate_GetSuite_21626473,
                                    base: "/", makeUrl: url_GetSuite_21626474,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_21626487 = ref object of OpenApiRestCall_21625437
proc url_GetTest_21626489(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_21626488(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626490 = header.getOrDefault("X-Amz-Date")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Date", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Security-Token", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Target")
  valid_21626492 = validateParameter(valid_21626492, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_21626492 != nil:
    section.add "X-Amz-Target", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Algorithm", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Signature")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Signature", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Credential")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Credential", valid_21626497
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

proc call*(call_21626499: Call_GetTest_21626487; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_21626499.validator(path, query, header, formData, body, _)
  let scheme = call_21626499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626499.makeUrl(scheme.get, call_21626499.host, call_21626499.base,
                               call_21626499.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626499, uri, valid, _)

proc call*(call_21626500: Call_GetTest_21626487; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_21626501 = newJObject()
  if body != nil:
    body_21626501 = body
  result = call_21626500.call(nil, nil, nil, nil, body_21626501)

var getTest* = Call_GetTest_21626487(name: "getTest", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                  validator: validate_GetTest_21626488, base: "/",
                                  makeUrl: url_GetTest_21626489,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_21626502 = ref object of OpenApiRestCall_21625437
proc url_GetTestGridProject_21626504(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridProject_21626503(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626505 = header.getOrDefault("X-Amz-Date")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Date", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Security-Token", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Target")
  valid_21626507 = validateParameter(valid_21626507, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_21626507 != nil:
    section.add "X-Amz-Target", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Algorithm", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Signature")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Signature", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Credential")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Credential", valid_21626512
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

proc call*(call_21626514: Call_GetTestGridProject_21626502; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Selenium testing project.
  ## 
  let valid = call_21626514.validator(path, query, header, formData, body, _)
  let scheme = call_21626514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626514.makeUrl(scheme.get, call_21626514.host, call_21626514.base,
                               call_21626514.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626514, uri, valid, _)

proc call*(call_21626515: Call_GetTestGridProject_21626502; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_21626516 = newJObject()
  if body != nil:
    body_21626516 = body
  result = call_21626515.call(nil, nil, nil, nil, body_21626516)

var getTestGridProject* = Call_GetTestGridProject_21626502(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_21626503, base: "/",
    makeUrl: url_GetTestGridProject_21626504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_21626517 = ref object of OpenApiRestCall_21625437
proc url_GetTestGridSession_21626519(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridSession_21626518(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626520 = header.getOrDefault("X-Amz-Date")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Date", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Security-Token", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Target")
  valid_21626522 = validateParameter(valid_21626522, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_21626522 != nil:
    section.add "X-Amz-Target", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Algorithm", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Signature")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Signature", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Credential")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Credential", valid_21626527
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

proc call*(call_21626529: Call_GetTestGridSession_21626517; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  let valid = call_21626529.validator(path, query, header, formData, body, _)
  let scheme = call_21626529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626529.makeUrl(scheme.get, call_21626529.host, call_21626529.base,
                               call_21626529.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626529, uri, valid, _)

proc call*(call_21626530: Call_GetTestGridSession_21626517; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   body: JObject (required)
  var body_21626531 = newJObject()
  if body != nil:
    body_21626531 = body
  result = call_21626530.call(nil, nil, nil, nil, body_21626531)

var getTestGridSession* = Call_GetTestGridSession_21626517(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_21626518, base: "/",
    makeUrl: url_GetTestGridSession_21626519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_21626532 = ref object of OpenApiRestCall_21625437
proc url_GetUpload_21626534(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_21626533(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626535 = header.getOrDefault("X-Amz-Date")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Date", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Security-Token", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Target")
  valid_21626537 = validateParameter(valid_21626537, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_21626537 != nil:
    section.add "X-Amz-Target", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Algorithm", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Signature")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Signature", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Credential")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Credential", valid_21626542
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

proc call*(call_21626544: Call_GetUpload_21626532; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_21626544.validator(path, query, header, formData, body, _)
  let scheme = call_21626544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626544.makeUrl(scheme.get, call_21626544.host, call_21626544.base,
                               call_21626544.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626544, uri, valid, _)

proc call*(call_21626545: Call_GetUpload_21626532; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_21626546 = newJObject()
  if body != nil:
    body_21626546 = body
  result = call_21626545.call(nil, nil, nil, nil, body_21626546)

var getUpload* = Call_GetUpload_21626532(name: "getUpload",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                      validator: validate_GetUpload_21626533,
                                      base: "/", makeUrl: url_GetUpload_21626534,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_21626547 = ref object of OpenApiRestCall_21625437
proc url_GetVPCEConfiguration_21626549(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVPCEConfiguration_21626548(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626550 = header.getOrDefault("X-Amz-Date")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Date", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Security-Token", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Target")
  valid_21626552 = validateParameter(valid_21626552, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_21626552 != nil:
    section.add "X-Amz-Target", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Algorithm", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Signature")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Signature", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Credential")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Credential", valid_21626557
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

proc call*(call_21626559: Call_GetVPCEConfiguration_21626547; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_21626559.validator(path, query, header, formData, body, _)
  let scheme = call_21626559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626559.makeUrl(scheme.get, call_21626559.host, call_21626559.base,
                               call_21626559.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626559, uri, valid, _)

proc call*(call_21626560: Call_GetVPCEConfiguration_21626547; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_21626561 = newJObject()
  if body != nil:
    body_21626561 = body
  result = call_21626560.call(nil, nil, nil, nil, body_21626561)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_21626547(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_21626548, base: "/",
    makeUrl: url_GetVPCEConfiguration_21626549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_21626562 = ref object of OpenApiRestCall_21625437
proc url_InstallToRemoteAccessSession_21626564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_21626563(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626565 = header.getOrDefault("X-Amz-Date")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Date", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Security-Token", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Target")
  valid_21626567 = validateParameter(valid_21626567, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_21626567 != nil:
    section.add "X-Amz-Target", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Algorithm", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Signature")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Signature", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Credential")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Credential", valid_21626572
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

proc call*(call_21626574: Call_InstallToRemoteAccessSession_21626562;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_21626574.validator(path, query, header, formData, body, _)
  let scheme = call_21626574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626574.makeUrl(scheme.get, call_21626574.host, call_21626574.base,
                               call_21626574.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626574, uri, valid, _)

proc call*(call_21626575: Call_InstallToRemoteAccessSession_21626562;
          body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_21626576 = newJObject()
  if body != nil:
    body_21626576 = body
  result = call_21626575.call(nil, nil, nil, nil, body_21626576)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_21626562(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_21626563, base: "/",
    makeUrl: url_InstallToRemoteAccessSession_21626564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_21626577 = ref object of OpenApiRestCall_21625437
proc url_ListArtifacts_21626579(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListArtifacts_21626578(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626580 = query.getOrDefault("nextToken")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "nextToken", valid_21626580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626581 = header.getOrDefault("X-Amz-Date")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Date", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Security-Token", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Target")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_21626583 != nil:
    section.add "X-Amz-Target", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Algorithm", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Signature")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Signature", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Credential")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Credential", valid_21626588
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

proc call*(call_21626590: Call_ListArtifacts_21626577; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_21626590.validator(path, query, header, formData, body, _)
  let scheme = call_21626590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626590.makeUrl(scheme.get, call_21626590.host, call_21626590.base,
                               call_21626590.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626590, uri, valid, _)

proc call*(call_21626591: Call_ListArtifacts_21626577; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626592 = newJObject()
  var body_21626593 = newJObject()
  add(query_21626592, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626593 = body
  result = call_21626591.call(nil, query_21626592, nil, nil, body_21626593)

var listArtifacts* = Call_ListArtifacts_21626577(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_21626578, base: "/",
    makeUrl: url_ListArtifacts_21626579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_21626594 = ref object of OpenApiRestCall_21625437
proc url_ListDeviceInstances_21626596(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceInstances_21626595(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626597 = header.getOrDefault("X-Amz-Date")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Date", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Security-Token", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Target")
  valid_21626599 = validateParameter(valid_21626599, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_21626599 != nil:
    section.add "X-Amz-Target", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Algorithm", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Signature")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Signature", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Credential")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Credential", valid_21626604
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

proc call*(call_21626606: Call_ListDeviceInstances_21626594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_21626606.validator(path, query, header, formData, body, _)
  let scheme = call_21626606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626606.makeUrl(scheme.get, call_21626606.host, call_21626606.base,
                               call_21626606.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626606, uri, valid, _)

proc call*(call_21626607: Call_ListDeviceInstances_21626594; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_21626608 = newJObject()
  if body != nil:
    body_21626608 = body
  result = call_21626607.call(nil, nil, nil, nil, body_21626608)

var listDeviceInstances* = Call_ListDeviceInstances_21626594(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_21626595, base: "/",
    makeUrl: url_ListDeviceInstances_21626596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_21626609 = ref object of OpenApiRestCall_21625437
proc url_ListDevicePools_21626611(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevicePools_21626610(path: JsonNode; query: JsonNode;
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
  var valid_21626612 = query.getOrDefault("nextToken")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "nextToken", valid_21626612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626613 = header.getOrDefault("X-Amz-Date")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Date", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Security-Token", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Target")
  valid_21626615 = validateParameter(valid_21626615, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_21626615 != nil:
    section.add "X-Amz-Target", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Algorithm", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Signature")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Signature", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Credential")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Credential", valid_21626620
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

proc call*(call_21626622: Call_ListDevicePools_21626609; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_21626622.validator(path, query, header, formData, body, _)
  let scheme = call_21626622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626622.makeUrl(scheme.get, call_21626622.host, call_21626622.base,
                               call_21626622.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626622, uri, valid, _)

proc call*(call_21626623: Call_ListDevicePools_21626609; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626624 = newJObject()
  var body_21626625 = newJObject()
  add(query_21626624, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626625 = body
  result = call_21626623.call(nil, query_21626624, nil, nil, body_21626625)

var listDevicePools* = Call_ListDevicePools_21626609(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_21626610, base: "/",
    makeUrl: url_ListDevicePools_21626611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_21626626 = ref object of OpenApiRestCall_21625437
proc url_ListDevices_21626628(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_21626627(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626629 = query.getOrDefault("nextToken")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "nextToken", valid_21626629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626630 = header.getOrDefault("X-Amz-Date")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Date", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Security-Token", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Target")
  valid_21626632 = validateParameter(valid_21626632, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_21626632 != nil:
    section.add "X-Amz-Target", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
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

proc call*(call_21626639: Call_ListDevices_21626626; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_21626639.validator(path, query, header, formData, body, _)
  let scheme = call_21626639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626639.makeUrl(scheme.get, call_21626639.host, call_21626639.base,
                               call_21626639.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626639, uri, valid, _)

proc call*(call_21626640: Call_ListDevices_21626626; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626641 = newJObject()
  var body_21626642 = newJObject()
  add(query_21626641, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626642 = body
  result = call_21626640.call(nil, query_21626641, nil, nil, body_21626642)

var listDevices* = Call_ListDevices_21626626(name: "listDevices",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
    validator: validate_ListDevices_21626627, base: "/", makeUrl: url_ListDevices_21626628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_21626643 = ref object of OpenApiRestCall_21625437
proc url_ListInstanceProfiles_21626645(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstanceProfiles_21626644(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626646 = header.getOrDefault("X-Amz-Date")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Date", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Security-Token", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Target")
  valid_21626648 = validateParameter(valid_21626648, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_21626648 != nil:
    section.add "X-Amz-Target", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Algorithm", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Signature")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Signature", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Credential")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Credential", valid_21626653
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

proc call*(call_21626655: Call_ListInstanceProfiles_21626643; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_21626655.validator(path, query, header, formData, body, _)
  let scheme = call_21626655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626655.makeUrl(scheme.get, call_21626655.host, call_21626655.base,
                               call_21626655.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626655, uri, valid, _)

proc call*(call_21626656: Call_ListInstanceProfiles_21626643; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_21626657 = newJObject()
  if body != nil:
    body_21626657 = body
  result = call_21626656.call(nil, nil, nil, nil, body_21626657)

var listInstanceProfiles* = Call_ListInstanceProfiles_21626643(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_21626644, base: "/",
    makeUrl: url_ListInstanceProfiles_21626645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_21626658 = ref object of OpenApiRestCall_21625437
proc url_ListJobs_21626660(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_21626659(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626661 = query.getOrDefault("nextToken")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "nextToken", valid_21626661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
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

proc call*(call_21626671: Call_ListJobs_21626658; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_ListJobs_21626658; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626673 = newJObject()
  var body_21626674 = newJObject()
  add(query_21626673, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626674 = body
  result = call_21626672.call(nil, query_21626673, nil, nil, body_21626674)

var listJobs* = Call_ListJobs_21626658(name: "listJobs", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                    validator: validate_ListJobs_21626659,
                                    base: "/", makeUrl: url_ListJobs_21626660,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_21626675 = ref object of OpenApiRestCall_21625437
proc url_ListNetworkProfiles_21626677(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworkProfiles_21626676(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626678 = header.getOrDefault("X-Amz-Date")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Date", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Security-Token", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Target")
  valid_21626680 = validateParameter(valid_21626680, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_21626680 != nil:
    section.add "X-Amz-Target", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Algorithm", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Signature")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Signature", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Credential")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Credential", valid_21626685
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

proc call*(call_21626687: Call_ListNetworkProfiles_21626675; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_21626687.validator(path, query, header, formData, body, _)
  let scheme = call_21626687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626687.makeUrl(scheme.get, call_21626687.host, call_21626687.base,
                               call_21626687.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626687, uri, valid, _)

proc call*(call_21626688: Call_ListNetworkProfiles_21626675; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_21626689 = newJObject()
  if body != nil:
    body_21626689 = body
  result = call_21626688.call(nil, nil, nil, nil, body_21626689)

var listNetworkProfiles* = Call_ListNetworkProfiles_21626675(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_21626676, base: "/",
    makeUrl: url_ListNetworkProfiles_21626677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_21626690 = ref object of OpenApiRestCall_21625437
proc url_ListOfferingPromotions_21626692(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingPromotions_21626691(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626693 = header.getOrDefault("X-Amz-Date")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Date", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Security-Token", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Target")
  valid_21626695 = validateParameter(valid_21626695, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_21626695 != nil:
    section.add "X-Amz-Target", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Algorithm", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Signature")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Signature", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Credential")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Credential", valid_21626700
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

proc call*(call_21626702: Call_ListOfferingPromotions_21626690;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  let valid = call_21626702.validator(path, query, header, formData, body, _)
  let scheme = call_21626702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626702.makeUrl(scheme.get, call_21626702.host, call_21626702.base,
                               call_21626702.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626702, uri, valid, _)

proc call*(call_21626703: Call_ListOfferingPromotions_21626690; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   body: JObject (required)
  var body_21626704 = newJObject()
  if body != nil:
    body_21626704 = body
  result = call_21626703.call(nil, nil, nil, nil, body_21626704)

var listOfferingPromotions* = Call_ListOfferingPromotions_21626690(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_21626691, base: "/",
    makeUrl: url_ListOfferingPromotions_21626692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_21626705 = ref object of OpenApiRestCall_21625437
proc url_ListOfferingTransactions_21626707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingTransactions_21626706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626708 = query.getOrDefault("nextToken")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "nextToken", valid_21626708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626709 = header.getOrDefault("X-Amz-Date")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Date", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Security-Token", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Target")
  valid_21626711 = validateParameter(valid_21626711, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_21626711 != nil:
    section.add "X-Amz-Target", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Algorithm", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Signature")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Signature", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Credential")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Credential", valid_21626716
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

proc call*(call_21626718: Call_ListOfferingTransactions_21626705;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_21626718.validator(path, query, header, formData, body, _)
  let scheme = call_21626718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626718.makeUrl(scheme.get, call_21626718.host, call_21626718.base,
                               call_21626718.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626718, uri, valid, _)

proc call*(call_21626719: Call_ListOfferingTransactions_21626705; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626720 = newJObject()
  var body_21626721 = newJObject()
  add(query_21626720, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626721 = body
  result = call_21626719.call(nil, query_21626720, nil, nil, body_21626721)

var listOfferingTransactions* = Call_ListOfferingTransactions_21626705(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_21626706, base: "/",
    makeUrl: url_ListOfferingTransactions_21626707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_21626722 = ref object of OpenApiRestCall_21625437
proc url_ListOfferings_21626724(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_21626723(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626725 = query.getOrDefault("nextToken")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "nextToken", valid_21626725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626726 = header.getOrDefault("X-Amz-Date")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Date", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Security-Token", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Target")
  valid_21626728 = validateParameter(valid_21626728, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_21626728 != nil:
    section.add "X-Amz-Target", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Algorithm", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Signature")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Signature", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Credential")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Credential", valid_21626733
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

proc call*(call_21626735: Call_ListOfferings_21626722; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_21626735.validator(path, query, header, formData, body, _)
  let scheme = call_21626735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626735.makeUrl(scheme.get, call_21626735.host, call_21626735.base,
                               call_21626735.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626735, uri, valid, _)

proc call*(call_21626736: Call_ListOfferings_21626722; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626737 = newJObject()
  var body_21626738 = newJObject()
  add(query_21626737, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626738 = body
  result = call_21626736.call(nil, query_21626737, nil, nil, body_21626738)

var listOfferings* = Call_ListOfferings_21626722(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_21626723, base: "/",
    makeUrl: url_ListOfferings_21626724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_21626739 = ref object of OpenApiRestCall_21625437
proc url_ListProjects_21626741(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_21626740(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626742 = query.getOrDefault("nextToken")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "nextToken", valid_21626742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626743 = header.getOrDefault("X-Amz-Date")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Date", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Security-Token", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Target")
  valid_21626745 = validateParameter(valid_21626745, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_21626745 != nil:
    section.add "X-Amz-Target", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Algorithm", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Signature")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Signature", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Credential")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Credential", valid_21626750
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

proc call*(call_21626752: Call_ListProjects_21626739; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_21626752.validator(path, query, header, formData, body, _)
  let scheme = call_21626752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626752.makeUrl(scheme.get, call_21626752.host, call_21626752.base,
                               call_21626752.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626752, uri, valid, _)

proc call*(call_21626753: Call_ListProjects_21626739; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626754 = newJObject()
  var body_21626755 = newJObject()
  add(query_21626754, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626755 = body
  result = call_21626753.call(nil, query_21626754, nil, nil, body_21626755)

var listProjects* = Call_ListProjects_21626739(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_21626740, base: "/", makeUrl: url_ListProjects_21626741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_21626756 = ref object of OpenApiRestCall_21625437
proc url_ListRemoteAccessSessions_21626758(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRemoteAccessSessions_21626757(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all currently running remote access sessions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626759 = header.getOrDefault("X-Amz-Date")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Date", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Security-Token", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Target")
  valid_21626761 = validateParameter(valid_21626761, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_21626761 != nil:
    section.add "X-Amz-Target", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Algorithm", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Signature")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Signature", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Credential")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Credential", valid_21626766
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

proc call*(call_21626768: Call_ListRemoteAccessSessions_21626756;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_21626768.validator(path, query, header, formData, body, _)
  let scheme = call_21626768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626768.makeUrl(scheme.get, call_21626768.host, call_21626768.base,
                               call_21626768.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626768, uri, valid, _)

proc call*(call_21626769: Call_ListRemoteAccessSessions_21626756; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_21626770 = newJObject()
  if body != nil:
    body_21626770 = body
  result = call_21626769.call(nil, nil, nil, nil, body_21626770)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_21626756(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_21626757, base: "/",
    makeUrl: url_ListRemoteAccessSessions_21626758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_21626771 = ref object of OpenApiRestCall_21625437
proc url_ListRuns_21626773(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_21626772(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626774 = query.getOrDefault("nextToken")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "nextToken", valid_21626774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626775 = header.getOrDefault("X-Amz-Date")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Date", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Security-Token", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Target")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_21626777 != nil:
    section.add "X-Amz-Target", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Algorithm", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Signature")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Signature", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Credential")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Credential", valid_21626782
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

proc call*(call_21626784: Call_ListRuns_21626771; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_21626784.validator(path, query, header, formData, body, _)
  let scheme = call_21626784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626784.makeUrl(scheme.get, call_21626784.host, call_21626784.base,
                               call_21626784.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626784, uri, valid, _)

proc call*(call_21626785: Call_ListRuns_21626771; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626786 = newJObject()
  var body_21626787 = newJObject()
  add(query_21626786, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626787 = body
  result = call_21626785.call(nil, query_21626786, nil, nil, body_21626787)

var listRuns* = Call_ListRuns_21626771(name: "listRuns", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                    validator: validate_ListRuns_21626772,
                                    base: "/", makeUrl: url_ListRuns_21626773,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_21626788 = ref object of OpenApiRestCall_21625437
proc url_ListSamples_21626790(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSamples_21626789(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626791 = query.getOrDefault("nextToken")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "nextToken", valid_21626791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626792 = header.getOrDefault("X-Amz-Date")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Date", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Security-Token", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Target")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_21626794 != nil:
    section.add "X-Amz-Target", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Algorithm", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Signature")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Signature", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Credential")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Credential", valid_21626799
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

proc call*(call_21626801: Call_ListSamples_21626788; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_21626801.validator(path, query, header, formData, body, _)
  let scheme = call_21626801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626801.makeUrl(scheme.get, call_21626801.host, call_21626801.base,
                               call_21626801.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626801, uri, valid, _)

proc call*(call_21626802: Call_ListSamples_21626788; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626803 = newJObject()
  var body_21626804 = newJObject()
  add(query_21626803, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626804 = body
  result = call_21626802.call(nil, query_21626803, nil, nil, body_21626804)

var listSamples* = Call_ListSamples_21626788(name: "listSamples",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
    validator: validate_ListSamples_21626789, base: "/", makeUrl: url_ListSamples_21626790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_21626805 = ref object of OpenApiRestCall_21625437
proc url_ListSuites_21626807(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_21626806(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626808 = query.getOrDefault("nextToken")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "nextToken", valid_21626808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626809 = header.getOrDefault("X-Amz-Date")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Date", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Security-Token", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Target")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_21626811 != nil:
    section.add "X-Amz-Target", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Algorithm", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Signature")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Signature", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Credential")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Credential", valid_21626816
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

proc call*(call_21626818: Call_ListSuites_21626805; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_21626818.validator(path, query, header, formData, body, _)
  let scheme = call_21626818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626818.makeUrl(scheme.get, call_21626818.host, call_21626818.base,
                               call_21626818.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626818, uri, valid, _)

proc call*(call_21626819: Call_ListSuites_21626805; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626820 = newJObject()
  var body_21626821 = newJObject()
  add(query_21626820, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626821 = body
  result = call_21626819.call(nil, query_21626820, nil, nil, body_21626821)

var listSuites* = Call_ListSuites_21626805(name: "listSuites",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                        validator: validate_ListSuites_21626806,
                                        base: "/", makeUrl: url_ListSuites_21626807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626822 = ref object of OpenApiRestCall_21625437
proc url_ListTagsForResource_21626824(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626823(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626825 = header.getOrDefault("X-Amz-Date")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Date", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Security-Token", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Target")
  valid_21626827 = validateParameter(valid_21626827, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_21626827 != nil:
    section.add "X-Amz-Target", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Algorithm", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Signature")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Signature", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Credential")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Credential", valid_21626832
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

proc call*(call_21626834: Call_ListTagsForResource_21626822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_21626834.validator(path, query, header, formData, body, _)
  let scheme = call_21626834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626834.makeUrl(scheme.get, call_21626834.host, call_21626834.base,
                               call_21626834.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626834, uri, valid, _)

proc call*(call_21626835: Call_ListTagsForResource_21626822; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_21626836 = newJObject()
  if body != nil:
    body_21626836 = body
  result = call_21626835.call(nil, nil, nil, nil, body_21626836)

var listTagsForResource* = Call_ListTagsForResource_21626822(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_21626823, base: "/",
    makeUrl: url_ListTagsForResource_21626824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_21626837 = ref object of OpenApiRestCall_21625437
proc url_ListTestGridProjects_21626839(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridProjects_21626838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResult: JString
  ##            : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626840 = query.getOrDefault("maxResult")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "maxResult", valid_21626840
  var valid_21626841 = query.getOrDefault("nextToken")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "nextToken", valid_21626841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626842 = header.getOrDefault("X-Amz-Date")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Date", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Security-Token", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Target")
  valid_21626844 = validateParameter(valid_21626844, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_21626844 != nil:
    section.add "X-Amz-Target", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Algorithm", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Signature")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Signature", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Credential")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Credential", valid_21626849
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

proc call*(call_21626851: Call_ListTestGridProjects_21626837; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  let valid = call_21626851.validator(path, query, header, formData, body, _)
  let scheme = call_21626851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626851.makeUrl(scheme.get, call_21626851.host, call_21626851.base,
                               call_21626851.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626851, uri, valid, _)

proc call*(call_21626852: Call_ListTestGridProjects_21626837; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626853 = newJObject()
  var body_21626854 = newJObject()
  add(query_21626853, "maxResult", newJString(maxResult))
  add(query_21626853, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626854 = body
  result = call_21626852.call(nil, query_21626853, nil, nil, body_21626854)

var listTestGridProjects* = Call_ListTestGridProjects_21626837(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_21626838, base: "/",
    makeUrl: url_ListTestGridProjects_21626839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_21626855 = ref object of OpenApiRestCall_21625437
proc url_ListTestGridSessionActions_21626857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionActions_21626856(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResult: JString
  ##            : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626858 = query.getOrDefault("maxResult")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "maxResult", valid_21626858
  var valid_21626859 = query.getOrDefault("nextToken")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "nextToken", valid_21626859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626860 = header.getOrDefault("X-Amz-Date")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Date", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Security-Token", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Target")
  valid_21626862 = validateParameter(valid_21626862, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_21626862 != nil:
    section.add "X-Amz-Target", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Algorithm", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Signature")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Signature", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Credential")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Credential", valid_21626867
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

proc call*(call_21626869: Call_ListTestGridSessionActions_21626855;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  let valid = call_21626869.validator(path, query, header, formData, body, _)
  let scheme = call_21626869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626869.makeUrl(scheme.get, call_21626869.host, call_21626869.base,
                               call_21626869.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626869, uri, valid, _)

proc call*(call_21626870: Call_ListTestGridSessionActions_21626855; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626871 = newJObject()
  var body_21626872 = newJObject()
  add(query_21626871, "maxResult", newJString(maxResult))
  add(query_21626871, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626872 = body
  result = call_21626870.call(nil, query_21626871, nil, nil, body_21626872)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_21626855(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_21626856, base: "/",
    makeUrl: url_ListTestGridSessionActions_21626857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_21626873 = ref object of OpenApiRestCall_21625437
proc url_ListTestGridSessionArtifacts_21626875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionArtifacts_21626874(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a list of artifacts created during the session.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResult: JString
  ##            : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626876 = query.getOrDefault("maxResult")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "maxResult", valid_21626876
  var valid_21626877 = query.getOrDefault("nextToken")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "nextToken", valid_21626877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626878 = header.getOrDefault("X-Amz-Date")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-Date", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Security-Token", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Target")
  valid_21626880 = validateParameter(valid_21626880, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_21626880 != nil:
    section.add "X-Amz-Target", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Algorithm", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Signature")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Signature", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Credential")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Credential", valid_21626885
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

proc call*(call_21626887: Call_ListTestGridSessionArtifacts_21626873;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of artifacts created during the session.
  ## 
  let valid = call_21626887.validator(path, query, header, formData, body, _)
  let scheme = call_21626887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626887.makeUrl(scheme.get, call_21626887.host, call_21626887.base,
                               call_21626887.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626887, uri, valid, _)

proc call*(call_21626888: Call_ListTestGridSessionArtifacts_21626873;
          body: JsonNode; maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626889 = newJObject()
  var body_21626890 = newJObject()
  add(query_21626889, "maxResult", newJString(maxResult))
  add(query_21626889, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626890 = body
  result = call_21626888.call(nil, query_21626889, nil, nil, body_21626890)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_21626873(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_21626874, base: "/",
    makeUrl: url_ListTestGridSessionArtifacts_21626875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_21626891 = ref object of OpenApiRestCall_21625437
proc url_ListTestGridSessions_21626893(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessions_21626892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResult: JString
  ##            : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626894 = query.getOrDefault("maxResult")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "maxResult", valid_21626894
  var valid_21626895 = query.getOrDefault("nextToken")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "nextToken", valid_21626895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626896 = header.getOrDefault("X-Amz-Date")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Date", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Security-Token", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Target")
  valid_21626898 = validateParameter(valid_21626898, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_21626898 != nil:
    section.add "X-Amz-Target", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Algorithm", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Signature")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Signature", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Credential")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Credential", valid_21626903
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

proc call*(call_21626905: Call_ListTestGridSessions_21626891; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  let valid = call_21626905.validator(path, query, header, formData, body, _)
  let scheme = call_21626905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626905.makeUrl(scheme.get, call_21626905.host, call_21626905.base,
                               call_21626905.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626905, uri, valid, _)

proc call*(call_21626906: Call_ListTestGridSessions_21626891; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626907 = newJObject()
  var body_21626908 = newJObject()
  add(query_21626907, "maxResult", newJString(maxResult))
  add(query_21626907, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626908 = body
  result = call_21626906.call(nil, query_21626907, nil, nil, body_21626908)

var listTestGridSessions* = Call_ListTestGridSessions_21626891(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_21626892, base: "/",
    makeUrl: url_ListTestGridSessions_21626893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_21626909 = ref object of OpenApiRestCall_21625437
proc url_ListTests_21626911(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_21626910(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626912 = query.getOrDefault("nextToken")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "nextToken", valid_21626912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626913 = header.getOrDefault("X-Amz-Date")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Date", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Security-Token", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Target")
  valid_21626915 = validateParameter(valid_21626915, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_21626915 != nil:
    section.add "X-Amz-Target", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Algorithm", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Signature")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Signature", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Credential")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Credential", valid_21626920
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

proc call*(call_21626922: Call_ListTests_21626909; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_21626922.validator(path, query, header, formData, body, _)
  let scheme = call_21626922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626922.makeUrl(scheme.get, call_21626922.host, call_21626922.base,
                               call_21626922.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626922, uri, valid, _)

proc call*(call_21626923: Call_ListTests_21626909; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626924 = newJObject()
  var body_21626925 = newJObject()
  add(query_21626924, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626925 = body
  result = call_21626923.call(nil, query_21626924, nil, nil, body_21626925)

var listTests* = Call_ListTests_21626909(name: "listTests",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                      validator: validate_ListTests_21626910,
                                      base: "/", makeUrl: url_ListTests_21626911,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_21626926 = ref object of OpenApiRestCall_21625437
proc url_ListUniqueProblems_21626928(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUniqueProblems_21626927(path: JsonNode; query: JsonNode;
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
  var valid_21626929 = query.getOrDefault("nextToken")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "nextToken", valid_21626929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626930 = header.getOrDefault("X-Amz-Date")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Date", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Security-Token", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Target")
  valid_21626932 = validateParameter(valid_21626932, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_21626932 != nil:
    section.add "X-Amz-Target", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Algorithm", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Signature")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Signature", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Credential")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Credential", valid_21626937
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

proc call*(call_21626939: Call_ListUniqueProblems_21626926; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  let valid = call_21626939.validator(path, query, header, formData, body, _)
  let scheme = call_21626939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626939.makeUrl(scheme.get, call_21626939.host, call_21626939.base,
                               call_21626939.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626939, uri, valid, _)

proc call*(call_21626940: Call_ListUniqueProblems_21626926; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626941 = newJObject()
  var body_21626942 = newJObject()
  add(query_21626941, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626942 = body
  result = call_21626940.call(nil, query_21626941, nil, nil, body_21626942)

var listUniqueProblems* = Call_ListUniqueProblems_21626926(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_21626927, base: "/",
    makeUrl: url_ListUniqueProblems_21626928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_21626943 = ref object of OpenApiRestCall_21625437
proc url_ListUploads_21626945(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUploads_21626944(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626946 = query.getOrDefault("nextToken")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "nextToken", valid_21626946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626947 = header.getOrDefault("X-Amz-Date")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Date", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Security-Token", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Target")
  valid_21626949 = validateParameter(valid_21626949, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_21626949 != nil:
    section.add "X-Amz-Target", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Algorithm", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Signature")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Signature", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Credential")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Credential", valid_21626954
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

proc call*(call_21626956: Call_ListUploads_21626943; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_21626956.validator(path, query, header, formData, body, _)
  let scheme = call_21626956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626956.makeUrl(scheme.get, call_21626956.host, call_21626956.base,
                               call_21626956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626956, uri, valid, _)

proc call*(call_21626957: Call_ListUploads_21626943; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626958 = newJObject()
  var body_21626959 = newJObject()
  add(query_21626958, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626959 = body
  result = call_21626957.call(nil, query_21626958, nil, nil, body_21626959)

var listUploads* = Call_ListUploads_21626943(name: "listUploads",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
    validator: validate_ListUploads_21626944, base: "/", makeUrl: url_ListUploads_21626945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_21626960 = ref object of OpenApiRestCall_21625437
proc url_ListVPCEConfigurations_21626962(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVPCEConfigurations_21626961(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626963 = header.getOrDefault("X-Amz-Date")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Date", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Security-Token", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Target")
  valid_21626965 = validateParameter(valid_21626965, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_21626965 != nil:
    section.add "X-Amz-Target", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Algorithm", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Signature")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Signature", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Credential")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Credential", valid_21626970
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

proc call*(call_21626972: Call_ListVPCEConfigurations_21626960;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_21626972.validator(path, query, header, formData, body, _)
  let scheme = call_21626972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626972.makeUrl(scheme.get, call_21626972.host, call_21626972.base,
                               call_21626972.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626972, uri, valid, _)

proc call*(call_21626973: Call_ListVPCEConfigurations_21626960; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_21626974 = newJObject()
  if body != nil:
    body_21626974 = body
  result = call_21626973.call(nil, nil, nil, nil, body_21626974)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_21626960(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_21626961, base: "/",
    makeUrl: url_ListVPCEConfigurations_21626962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_21626975 = ref object of OpenApiRestCall_21625437
proc url_PurchaseOffering_21626977(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseOffering_21626976(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626978 = header.getOrDefault("X-Amz-Date")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Date", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Security-Token", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Target")
  valid_21626980 = validateParameter(valid_21626980, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_21626980 != nil:
    section.add "X-Amz-Target", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Algorithm", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Signature")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Signature", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Credential")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Credential", valid_21626985
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

proc call*(call_21626987: Call_PurchaseOffering_21626975; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_21626987.validator(path, query, header, formData, body, _)
  let scheme = call_21626987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626987.makeUrl(scheme.get, call_21626987.host, call_21626987.base,
                               call_21626987.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626987, uri, valid, _)

proc call*(call_21626988: Call_PurchaseOffering_21626975; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_21626989 = newJObject()
  if body != nil:
    body_21626989 = body
  result = call_21626988.call(nil, nil, nil, nil, body_21626989)

var purchaseOffering* = Call_PurchaseOffering_21626975(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_21626976, base: "/",
    makeUrl: url_PurchaseOffering_21626977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_21626990 = ref object of OpenApiRestCall_21625437
proc url_RenewOffering_21626992(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenewOffering_21626991(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626993 = header.getOrDefault("X-Amz-Date")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Date", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Security-Token", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Target")
  valid_21626995 = validateParameter(valid_21626995, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_21626995 != nil:
    section.add "X-Amz-Target", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Algorithm", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Signature")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Signature", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Credential")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Credential", valid_21627000
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

proc call*(call_21627002: Call_RenewOffering_21626990; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_21627002.validator(path, query, header, formData, body, _)
  let scheme = call_21627002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627002.makeUrl(scheme.get, call_21627002.host, call_21627002.base,
                               call_21627002.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627002, uri, valid, _)

proc call*(call_21627003: Call_RenewOffering_21626990; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_21627004 = newJObject()
  if body != nil:
    body_21627004 = body
  result = call_21627003.call(nil, nil, nil, nil, body_21627004)

var renewOffering* = Call_RenewOffering_21626990(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_21626991, base: "/",
    makeUrl: url_RenewOffering_21626992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_21627005 = ref object of OpenApiRestCall_21625437
proc url_ScheduleRun_21627007(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleRun_21627006(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627008 = header.getOrDefault("X-Amz-Date")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Date", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Security-Token", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Target")
  valid_21627010 = validateParameter(valid_21627010, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_21627010 != nil:
    section.add "X-Amz-Target", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Algorithm", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Signature")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Signature", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Credential")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Credential", valid_21627015
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

proc call*(call_21627017: Call_ScheduleRun_21627005; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_21627017.validator(path, query, header, formData, body, _)
  let scheme = call_21627017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627017.makeUrl(scheme.get, call_21627017.host, call_21627017.base,
                               call_21627017.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627017, uri, valid, _)

proc call*(call_21627018: Call_ScheduleRun_21627005; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_21627019 = newJObject()
  if body != nil:
    body_21627019 = body
  result = call_21627018.call(nil, nil, nil, nil, body_21627019)

var scheduleRun* = Call_ScheduleRun_21627005(name: "scheduleRun",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
    validator: validate_ScheduleRun_21627006, base: "/", makeUrl: url_ScheduleRun_21627007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_21627020 = ref object of OpenApiRestCall_21625437
proc url_StopJob_21627022(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_21627021(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627023 = header.getOrDefault("X-Amz-Date")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Date", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Security-Token", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Target")
  valid_21627025 = validateParameter(valid_21627025, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_21627025 != nil:
    section.add "X-Amz-Target", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Algorithm", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Signature")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Signature", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Credential")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Credential", valid_21627030
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

proc call*(call_21627032: Call_StopJob_21627020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_21627032.validator(path, query, header, formData, body, _)
  let scheme = call_21627032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627032.makeUrl(scheme.get, call_21627032.host, call_21627032.base,
                               call_21627032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627032, uri, valid, _)

proc call*(call_21627033: Call_StopJob_21627020; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_21627034 = newJObject()
  if body != nil:
    body_21627034 = body
  result = call_21627033.call(nil, nil, nil, nil, body_21627034)

var stopJob* = Call_StopJob_21627020(name: "stopJob", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                  validator: validate_StopJob_21627021, base: "/",
                                  makeUrl: url_StopJob_21627022,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_21627035 = ref object of OpenApiRestCall_21625437
proc url_StopRemoteAccessSession_21627037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRemoteAccessSession_21627036(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627038 = header.getOrDefault("X-Amz-Date")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Date", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Security-Token", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Target")
  valid_21627040 = validateParameter(valid_21627040, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_21627040 != nil:
    section.add "X-Amz-Target", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Algorithm", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Signature")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Signature", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Credential")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Credential", valid_21627045
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

proc call*(call_21627047: Call_StopRemoteAccessSession_21627035;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_21627047.validator(path, query, header, formData, body, _)
  let scheme = call_21627047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627047.makeUrl(scheme.get, call_21627047.host, call_21627047.base,
                               call_21627047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627047, uri, valid, _)

proc call*(call_21627048: Call_StopRemoteAccessSession_21627035; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_21627049 = newJObject()
  if body != nil:
    body_21627049 = body
  result = call_21627048.call(nil, nil, nil, nil, body_21627049)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_21627035(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_21627036, base: "/",
    makeUrl: url_StopRemoteAccessSession_21627037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_21627050 = ref object of OpenApiRestCall_21625437
proc url_StopRun_21627052(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_21627051(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627053 = header.getOrDefault("X-Amz-Date")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Date", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Security-Token", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Target")
  valid_21627055 = validateParameter(valid_21627055, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_21627055 != nil:
    section.add "X-Amz-Target", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Algorithm", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Signature")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Signature", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Credential")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Credential", valid_21627060
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

proc call*(call_21627062: Call_StopRun_21627050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_21627062.validator(path, query, header, formData, body, _)
  let scheme = call_21627062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627062.makeUrl(scheme.get, call_21627062.host, call_21627062.base,
                               call_21627062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627062, uri, valid, _)

proc call*(call_21627063: Call_StopRun_21627050; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_21627064 = newJObject()
  if body != nil:
    body_21627064 = body
  result = call_21627063.call(nil, nil, nil, nil, body_21627064)

var stopRun* = Call_StopRun_21627050(name: "stopRun", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                  validator: validate_StopRun_21627051, base: "/",
                                  makeUrl: url_StopRun_21627052,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627065 = ref object of OpenApiRestCall_21625437
proc url_TagResource_21627067(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627066(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627068 = header.getOrDefault("X-Amz-Date")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Date", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Security-Token", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Target")
  valid_21627070 = validateParameter(valid_21627070, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_21627070 != nil:
    section.add "X-Amz-Target", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Algorithm", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-Signature")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Signature", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Credential")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Credential", valid_21627075
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

proc call*(call_21627077: Call_TagResource_21627065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  let valid = call_21627077.validator(path, query, header, formData, body, _)
  let scheme = call_21627077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627077.makeUrl(scheme.get, call_21627077.host, call_21627077.base,
                               call_21627077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627077, uri, valid, _)

proc call*(call_21627078: Call_TagResource_21627065; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   body: JObject (required)
  var body_21627079 = newJObject()
  if body != nil:
    body_21627079 = body
  result = call_21627078.call(nil, nil, nil, nil, body_21627079)

var tagResource* = Call_TagResource_21627065(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
    validator: validate_TagResource_21627066, base: "/", makeUrl: url_TagResource_21627067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627080 = ref object of OpenApiRestCall_21625437
proc url_UntagResource_21627082(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627081(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627083 = header.getOrDefault("X-Amz-Date")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Date", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Security-Token", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Target")
  valid_21627085 = validateParameter(valid_21627085, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_21627085 != nil:
    section.add "X-Amz-Target", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Algorithm", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Signature")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Signature", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Credential")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Credential", valid_21627090
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

proc call*(call_21627092: Call_UntagResource_21627080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_21627092.validator(path, query, header, formData, body, _)
  let scheme = call_21627092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627092.makeUrl(scheme.get, call_21627092.host, call_21627092.base,
                               call_21627092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627092, uri, valid, _)

proc call*(call_21627093: Call_UntagResource_21627080; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_21627094 = newJObject()
  if body != nil:
    body_21627094 = body
  result = call_21627093.call(nil, nil, nil, nil, body_21627094)

var untagResource* = Call_UntagResource_21627080(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_21627081, base: "/",
    makeUrl: url_UntagResource_21627082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_21627095 = ref object of OpenApiRestCall_21625437
proc url_UpdateDeviceInstance_21627097(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceInstance_21627096(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627098 = header.getOrDefault("X-Amz-Date")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Date", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Security-Token", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Target")
  valid_21627100 = validateParameter(valid_21627100, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_21627100 != nil:
    section.add "X-Amz-Target", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Algorithm", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Signature")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Signature", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Credential")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Credential", valid_21627105
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

proc call*(call_21627107: Call_UpdateDeviceInstance_21627095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about a private device instance.
  ## 
  let valid = call_21627107.validator(path, query, header, formData, body, _)
  let scheme = call_21627107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627107.makeUrl(scheme.get, call_21627107.host, call_21627107.base,
                               call_21627107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627107, uri, valid, _)

proc call*(call_21627108: Call_UpdateDeviceInstance_21627095; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_21627109 = newJObject()
  if body != nil:
    body_21627109 = body
  result = call_21627108.call(nil, nil, nil, nil, body_21627109)

var updateDeviceInstance* = Call_UpdateDeviceInstance_21627095(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_21627096, base: "/",
    makeUrl: url_UpdateDeviceInstance_21627097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_21627110 = ref object of OpenApiRestCall_21625437
proc url_UpdateDevicePool_21627112(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePool_21627111(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627113 = header.getOrDefault("X-Amz-Date")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Date", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Security-Token", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Target")
  valid_21627115 = validateParameter(valid_21627115, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_21627115 != nil:
    section.add "X-Amz-Target", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Algorithm", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Signature")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Signature", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Credential")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Credential", valid_21627120
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

proc call*(call_21627122: Call_UpdateDevicePool_21627110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_21627122.validator(path, query, header, formData, body, _)
  let scheme = call_21627122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627122.makeUrl(scheme.get, call_21627122.host, call_21627122.base,
                               call_21627122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627122, uri, valid, _)

proc call*(call_21627123: Call_UpdateDevicePool_21627110; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_21627124 = newJObject()
  if body != nil:
    body_21627124 = body
  result = call_21627123.call(nil, nil, nil, nil, body_21627124)

var updateDevicePool* = Call_UpdateDevicePool_21627110(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_21627111, base: "/",
    makeUrl: url_UpdateDevicePool_21627112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_21627125 = ref object of OpenApiRestCall_21625437
proc url_UpdateInstanceProfile_21627127(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceProfile_21627126(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627128 = header.getOrDefault("X-Amz-Date")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Date", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "X-Amz-Security-Token", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Target")
  valid_21627130 = validateParameter(valid_21627130, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_21627130 != nil:
    section.add "X-Amz-Target", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Algorithm", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Signature")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Signature", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Credential")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Credential", valid_21627135
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

proc call*(call_21627137: Call_UpdateInstanceProfile_21627125;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_21627137.validator(path, query, header, formData, body, _)
  let scheme = call_21627137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627137.makeUrl(scheme.get, call_21627137.host, call_21627137.base,
                               call_21627137.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627137, uri, valid, _)

proc call*(call_21627138: Call_UpdateInstanceProfile_21627125; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_21627139 = newJObject()
  if body != nil:
    body_21627139 = body
  result = call_21627138.call(nil, nil, nil, nil, body_21627139)

var updateInstanceProfile* = Call_UpdateInstanceProfile_21627125(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_21627126, base: "/",
    makeUrl: url_UpdateInstanceProfile_21627127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_21627140 = ref object of OpenApiRestCall_21625437
proc url_UpdateNetworkProfile_21627142(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_21627141(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627143 = header.getOrDefault("X-Amz-Date")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Date", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Security-Token", valid_21627144
  var valid_21627145 = header.getOrDefault("X-Amz-Target")
  valid_21627145 = validateParameter(valid_21627145, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_21627145 != nil:
    section.add "X-Amz-Target", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "X-Amz-Algorithm", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-Signature")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Signature", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-Credential")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Credential", valid_21627150
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

proc call*(call_21627152: Call_UpdateNetworkProfile_21627140; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the network profile.
  ## 
  let valid = call_21627152.validator(path, query, header, formData, body, _)
  let scheme = call_21627152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627152.makeUrl(scheme.get, call_21627152.host, call_21627152.base,
                               call_21627152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627152, uri, valid, _)

proc call*(call_21627153: Call_UpdateNetworkProfile_21627140; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_21627154 = newJObject()
  if body != nil:
    body_21627154 = body
  result = call_21627153.call(nil, nil, nil, nil, body_21627154)

var updateNetworkProfile* = Call_UpdateNetworkProfile_21627140(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_21627141, base: "/",
    makeUrl: url_UpdateNetworkProfile_21627142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_21627155 = ref object of OpenApiRestCall_21625437
proc url_UpdateProject_21627157(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_21627156(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627158 = header.getOrDefault("X-Amz-Date")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Date", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Security-Token", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Target")
  valid_21627160 = validateParameter(valid_21627160, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_21627160 != nil:
    section.add "X-Amz-Target", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Algorithm", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-Signature")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Signature", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-Credential")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-Credential", valid_21627165
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

proc call*(call_21627167: Call_UpdateProject_21627155; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_21627167.validator(path, query, header, formData, body, _)
  let scheme = call_21627167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627167.makeUrl(scheme.get, call_21627167.host, call_21627167.base,
                               call_21627167.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627167, uri, valid, _)

proc call*(call_21627168: Call_UpdateProject_21627155; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_21627169 = newJObject()
  if body != nil:
    body_21627169 = body
  result = call_21627168.call(nil, nil, nil, nil, body_21627169)

var updateProject* = Call_UpdateProject_21627155(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_21627156, base: "/",
    makeUrl: url_UpdateProject_21627157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_21627170 = ref object of OpenApiRestCall_21625437
proc url_UpdateTestGridProject_21627172(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTestGridProject_21627171(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627173 = header.getOrDefault("X-Amz-Date")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Date", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Security-Token", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Target")
  valid_21627175 = validateParameter(valid_21627175, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_21627175 != nil:
    section.add "X-Amz-Target", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Algorithm", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-Signature")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-Signature", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627179
  var valid_21627180 = header.getOrDefault("X-Amz-Credential")
  valid_21627180 = validateParameter(valid_21627180, JString, required = false,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "X-Amz-Credential", valid_21627180
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

proc call*(call_21627182: Call_UpdateTestGridProject_21627170;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Change details of a project.
  ## 
  let valid = call_21627182.validator(path, query, header, formData, body, _)
  let scheme = call_21627182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627182.makeUrl(scheme.get, call_21627182.host, call_21627182.base,
                               call_21627182.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627182, uri, valid, _)

proc call*(call_21627183: Call_UpdateTestGridProject_21627170; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_21627184 = newJObject()
  if body != nil:
    body_21627184 = body
  result = call_21627183.call(nil, nil, nil, nil, body_21627184)

var updateTestGridProject* = Call_UpdateTestGridProject_21627170(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_21627171, base: "/",
    makeUrl: url_UpdateTestGridProject_21627172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_21627185 = ref object of OpenApiRestCall_21625437
proc url_UpdateUpload_21627187(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUpload_21627186(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates an uploaded test spec.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627188 = header.getOrDefault("X-Amz-Date")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Date", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Security-Token", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Target")
  valid_21627190 = validateParameter(valid_21627190, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_21627190 != nil:
    section.add "X-Amz-Target", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Algorithm", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Signature")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-Signature", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627194
  var valid_21627195 = header.getOrDefault("X-Amz-Credential")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "X-Amz-Credential", valid_21627195
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

proc call*(call_21627197: Call_UpdateUpload_21627185; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an uploaded test spec.
  ## 
  let valid = call_21627197.validator(path, query, header, formData, body, _)
  let scheme = call_21627197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627197.makeUrl(scheme.get, call_21627197.host, call_21627197.base,
                               call_21627197.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627197, uri, valid, _)

proc call*(call_21627198: Call_UpdateUpload_21627185; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_21627199 = newJObject()
  if body != nil:
    body_21627199 = body
  result = call_21627198.call(nil, nil, nil, nil, body_21627199)

var updateUpload* = Call_UpdateUpload_21627185(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_21627186, base: "/", makeUrl: url_UpdateUpload_21627187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_21627200 = ref object of OpenApiRestCall_21625437
proc url_UpdateVPCEConfiguration_21627202(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVPCEConfiguration_21627201(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627203 = header.getOrDefault("X-Amz-Date")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Date", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Security-Token", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Target")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_21627205 != nil:
    section.add "X-Amz-Target", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Algorithm", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Signature")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Signature", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Credential")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Credential", valid_21627210
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

proc call*(call_21627212: Call_UpdateVPCEConfiguration_21627200;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_21627212.validator(path, query, header, formData, body, _)
  let scheme = call_21627212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627212.makeUrl(scheme.get, call_21627212.host, call_21627212.base,
                               call_21627212.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627212, uri, valid, _)

proc call*(call_21627213: Call_UpdateVPCEConfiguration_21627200; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_21627214 = newJObject()
  if body != nil:
    body_21627214 = body
  result = call_21627213.call(nil, nil, nil, nil, body_21627214)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_21627200(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_21627201, base: "/",
    makeUrl: url_UpdateVPCEConfiguration_21627202,
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