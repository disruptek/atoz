
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

  OpenApiRestCall_605590 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605590](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605590): Option[Scheme] {.used.} =
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
  Call_CreateDevicePool_605928 = ref object of OpenApiRestCall_605590
proc url_CreateDevicePool_605930(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevicePool_605929(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606055 = header.getOrDefault("X-Amz-Target")
  valid_606055 = validateParameter(valid_606055, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_606055 != nil:
    section.add "X-Amz-Target", valid_606055
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

proc call*(call_606086: Call_CreateDevicePool_605928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_CreateDevicePool_605928; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_606158 = newJObject()
  if body != nil:
    body_606158 = body
  result = call_606157.call(nil, nil, nil, nil, body_606158)

var createDevicePool* = Call_CreateDevicePool_605928(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_605929, base: "/",
    url: url_CreateDevicePool_605930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_606197 = ref object of OpenApiRestCall_605590
proc url_CreateInstanceProfile_606199(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstanceProfile_606198(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606200 = header.getOrDefault("X-Amz-Target")
  valid_606200 = validateParameter(valid_606200, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_606200 != nil:
    section.add "X-Amz-Target", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_CreateInstanceProfile_606197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_CreateInstanceProfile_606197; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_606211 = newJObject()
  if body != nil:
    body_606211 = body
  result = call_606210.call(nil, nil, nil, nil, body_606211)

var createInstanceProfile* = Call_CreateInstanceProfile_606197(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_606198, base: "/",
    url: url_CreateInstanceProfile_606199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_606212 = ref object of OpenApiRestCall_605590
proc url_CreateNetworkProfile_606214(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetworkProfile_606213(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606215 = header.getOrDefault("X-Amz-Target")
  valid_606215 = validateParameter(valid_606215, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_606215 != nil:
    section.add "X-Amz-Target", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-SignedHeaders", valid_606222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_CreateNetworkProfile_606212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_CreateNetworkProfile_606212; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_606226 = newJObject()
  if body != nil:
    body_606226 = body
  result = call_606225.call(nil, nil, nil, nil, body_606226)

var createNetworkProfile* = Call_CreateNetworkProfile_606212(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_606213, base: "/",
    url: url_CreateNetworkProfile_606214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_606227 = ref object of OpenApiRestCall_605590
proc url_CreateProject_606229(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_606228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606230 = header.getOrDefault("X-Amz-Target")
  valid_606230 = validateParameter(valid_606230, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_606230 != nil:
    section.add "X-Amz-Target", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Signature")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Signature", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Content-Sha256", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Date")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Date", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Credential")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Credential", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Security-Token")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Security-Token", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Algorithm")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Algorithm", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-SignedHeaders", valid_606237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_CreateProject_606227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a project.
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_CreateProject_606227; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_606241 = newJObject()
  if body != nil:
    body_606241 = body
  result = call_606240.call(nil, nil, nil, nil, body_606241)

var createProject* = Call_CreateProject_606227(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_606228, base: "/", url: url_CreateProject_606229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_606242 = ref object of OpenApiRestCall_605590
proc url_CreateRemoteAccessSession_606244(protocol: Scheme; host: string;
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

proc validate_CreateRemoteAccessSession_606243(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606245 = header.getOrDefault("X-Amz-Target")
  valid_606245 = validateParameter(valid_606245, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_606245 != nil:
    section.add "X-Amz-Target", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_CreateRemoteAccessSession_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_CreateRemoteAccessSession_606242; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_606256 = newJObject()
  if body != nil:
    body_606256 = body
  result = call_606255.call(nil, nil, nil, nil, body_606256)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_606242(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_606243, base: "/",
    url: url_CreateRemoteAccessSession_606244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_606257 = ref object of OpenApiRestCall_605590
proc url_CreateTestGridProject_606259(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTestGridProject_606258(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606260 = header.getOrDefault("X-Amz-Target")
  valid_606260 = validateParameter(valid_606260, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_606260 != nil:
    section.add "X-Amz-Target", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606269: Call_CreateTestGridProject_606257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  let valid = call_606269.validator(path, query, header, formData, body)
  let scheme = call_606269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606269.url(scheme.get, call_606269.host, call_606269.base,
                         call_606269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606269, url, valid)

proc call*(call_606270: Call_CreateTestGridProject_606257; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   body: JObject (required)
  var body_606271 = newJObject()
  if body != nil:
    body_606271 = body
  result = call_606270.call(nil, nil, nil, nil, body_606271)

var createTestGridProject* = Call_CreateTestGridProject_606257(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_606258, base: "/",
    url: url_CreateTestGridProject_606259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_606272 = ref object of OpenApiRestCall_605590
proc url_CreateTestGridUrl_606274(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTestGridUrl_606273(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606275 = header.getOrDefault("X-Amz-Target")
  valid_606275 = validateParameter(valid_606275, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_606275 != nil:
    section.add "X-Amz-Target", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Signature")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Signature", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Content-Sha256", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Date")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Date", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Credential")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Credential", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Security-Token")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Security-Token", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Algorithm")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Algorithm", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-SignedHeaders", valid_606282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606284: Call_CreateTestGridUrl_606272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  let valid = call_606284.validator(path, query, header, formData, body)
  let scheme = call_606284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606284.url(scheme.get, call_606284.host, call_606284.base,
                         call_606284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606284, url, valid)

proc call*(call_606285: Call_CreateTestGridUrl_606272; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   body: JObject (required)
  var body_606286 = newJObject()
  if body != nil:
    body_606286 = body
  result = call_606285.call(nil, nil, nil, nil, body_606286)

var createTestGridUrl* = Call_CreateTestGridUrl_606272(name: "createTestGridUrl",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_606273, base: "/",
    url: url_CreateTestGridUrl_606274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_606287 = ref object of OpenApiRestCall_605590
proc url_CreateUpload_606289(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUpload_606288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606290 = header.getOrDefault("X-Amz-Target")
  valid_606290 = validateParameter(valid_606290, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_606290 != nil:
    section.add "X-Amz-Target", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Signature")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Signature", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Content-Sha256", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Date")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Date", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Credential")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Credential", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Security-Token")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Security-Token", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Algorithm")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Algorithm", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-SignedHeaders", valid_606297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606299: Call_CreateUpload_606287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_606299.validator(path, query, header, formData, body)
  let scheme = call_606299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606299.url(scheme.get, call_606299.host, call_606299.base,
                         call_606299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606299, url, valid)

proc call*(call_606300: Call_CreateUpload_606287; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_606301 = newJObject()
  if body != nil:
    body_606301 = body
  result = call_606300.call(nil, nil, nil, nil, body_606301)

var createUpload* = Call_CreateUpload_606287(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_606288, base: "/", url: url_CreateUpload_606289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_606302 = ref object of OpenApiRestCall_605590
proc url_CreateVPCEConfiguration_606304(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVPCEConfiguration_606303(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606305 = header.getOrDefault("X-Amz-Target")
  valid_606305 = validateParameter(valid_606305, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_606305 != nil:
    section.add "X-Amz-Target", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Signature")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Signature", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Content-Sha256", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Date")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Date", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Credential")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Credential", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Security-Token")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Security-Token", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Algorithm")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Algorithm", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-SignedHeaders", valid_606312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_CreateVPCEConfiguration_606302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_CreateVPCEConfiguration_606302; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_606316 = newJObject()
  if body != nil:
    body_606316 = body
  result = call_606315.call(nil, nil, nil, nil, body_606316)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_606302(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_606303, base: "/",
    url: url_CreateVPCEConfiguration_606304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_606317 = ref object of OpenApiRestCall_605590
proc url_DeleteDevicePool_606319(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevicePool_606318(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606320 = header.getOrDefault("X-Amz-Target")
  valid_606320 = validateParameter(valid_606320, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_606320 != nil:
    section.add "X-Amz-Target", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Signature")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Signature", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Content-Sha256", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Date")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Date", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Credential")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Credential", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Security-Token")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Security-Token", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606329: Call_DeleteDevicePool_606317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_606329.validator(path, query, header, formData, body)
  let scheme = call_606329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606329.url(scheme.get, call_606329.host, call_606329.base,
                         call_606329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606329, url, valid)

proc call*(call_606330: Call_DeleteDevicePool_606317; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_606331 = newJObject()
  if body != nil:
    body_606331 = body
  result = call_606330.call(nil, nil, nil, nil, body_606331)

var deleteDevicePool* = Call_DeleteDevicePool_606317(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_606318, base: "/",
    url: url_DeleteDevicePool_606319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_606332 = ref object of OpenApiRestCall_605590
proc url_DeleteInstanceProfile_606334(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstanceProfile_606333(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606335 = header.getOrDefault("X-Amz-Target")
  valid_606335 = validateParameter(valid_606335, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_606335 != nil:
    section.add "X-Amz-Target", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Signature")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Signature", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Content-Sha256", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Date")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Date", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Credential")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Credential", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Security-Token")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Security-Token", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Algorithm")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Algorithm", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-SignedHeaders", valid_606342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606344: Call_DeleteInstanceProfile_606332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_606344.validator(path, query, header, formData, body)
  let scheme = call_606344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606344.url(scheme.get, call_606344.host, call_606344.base,
                         call_606344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606344, url, valid)

proc call*(call_606345: Call_DeleteInstanceProfile_606332; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_606346 = newJObject()
  if body != nil:
    body_606346 = body
  result = call_606345.call(nil, nil, nil, nil, body_606346)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_606332(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_606333, base: "/",
    url: url_DeleteInstanceProfile_606334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_606347 = ref object of OpenApiRestCall_605590
proc url_DeleteNetworkProfile_606349(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNetworkProfile_606348(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606350 = header.getOrDefault("X-Amz-Target")
  valid_606350 = validateParameter(valid_606350, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_606350 != nil:
    section.add "X-Amz-Target", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Signature")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Signature", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Content-Sha256", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Date")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Date", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Credential")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Credential", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Security-Token")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Security-Token", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Algorithm")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Algorithm", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-SignedHeaders", valid_606357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_DeleteNetworkProfile_606347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_DeleteNetworkProfile_606347; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_606361 = newJObject()
  if body != nil:
    body_606361 = body
  result = call_606360.call(nil, nil, nil, nil, body_606361)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_606347(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_606348, base: "/",
    url: url_DeleteNetworkProfile_606349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_606362 = ref object of OpenApiRestCall_605590
proc url_DeleteProject_606364(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_606363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606365 = header.getOrDefault("X-Amz-Target")
  valid_606365 = validateParameter(valid_606365, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_606365 != nil:
    section.add "X-Amz-Target", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Signature")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Signature", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Content-Sha256", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Date")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Date", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Credential")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Credential", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Security-Token")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Security-Token", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Algorithm")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Algorithm", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-SignedHeaders", valid_606372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606374: Call_DeleteProject_606362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_606374.validator(path, query, header, formData, body)
  let scheme = call_606374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606374.url(scheme.get, call_606374.host, call_606374.base,
                         call_606374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606374, url, valid)

proc call*(call_606375: Call_DeleteProject_606362; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_606376 = newJObject()
  if body != nil:
    body_606376 = body
  result = call_606375.call(nil, nil, nil, nil, body_606376)

var deleteProject* = Call_DeleteProject_606362(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_606363, base: "/", url: url_DeleteProject_606364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_606377 = ref object of OpenApiRestCall_605590
proc url_DeleteRemoteAccessSession_606379(protocol: Scheme; host: string;
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

proc validate_DeleteRemoteAccessSession_606378(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606380 = header.getOrDefault("X-Amz-Target")
  valid_606380 = validateParameter(valid_606380, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_606380 != nil:
    section.add "X-Amz-Target", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Signature")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Signature", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Content-Sha256", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Date")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Date", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Credential")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Credential", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Security-Token")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Security-Token", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Algorithm")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Algorithm", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-SignedHeaders", valid_606387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606389: Call_DeleteRemoteAccessSession_606377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_606389.validator(path, query, header, formData, body)
  let scheme = call_606389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606389.url(scheme.get, call_606389.host, call_606389.base,
                         call_606389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606389, url, valid)

proc call*(call_606390: Call_DeleteRemoteAccessSession_606377; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_606391 = newJObject()
  if body != nil:
    body_606391 = body
  result = call_606390.call(nil, nil, nil, nil, body_606391)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_606377(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_606378, base: "/",
    url: url_DeleteRemoteAccessSession_606379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_606392 = ref object of OpenApiRestCall_605590
proc url_DeleteRun_606394(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRun_606393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606395 = header.getOrDefault("X-Amz-Target")
  valid_606395 = validateParameter(valid_606395, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_606395 != nil:
    section.add "X-Amz-Target", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Signature")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Signature", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Content-Sha256", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Date")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Date", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Credential")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Credential", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Security-Token")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Security-Token", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Algorithm")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Algorithm", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-SignedHeaders", valid_606402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606404: Call_DeleteRun_606392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_606404.validator(path, query, header, formData, body)
  let scheme = call_606404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606404.url(scheme.get, call_606404.host, call_606404.base,
                         call_606404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606404, url, valid)

proc call*(call_606405: Call_DeleteRun_606392; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_606406 = newJObject()
  if body != nil:
    body_606406 = body
  result = call_606405.call(nil, nil, nil, nil, body_606406)

var deleteRun* = Call_DeleteRun_606392(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_606393,
                                    base: "/", url: url_DeleteRun_606394,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_606407 = ref object of OpenApiRestCall_605590
proc url_DeleteTestGridProject_606409(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTestGridProject_606408(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606410 = header.getOrDefault("X-Amz-Target")
  valid_606410 = validateParameter(valid_606410, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_606410 != nil:
    section.add "X-Amz-Target", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Security-Token")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Security-Token", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Algorithm")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Algorithm", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-SignedHeaders", valid_606417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606419: Call_DeleteTestGridProject_606407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  let valid = call_606419.validator(path, query, header, formData, body)
  let scheme = call_606419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606419.url(scheme.get, call_606419.host, call_606419.base,
                         call_606419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606419, url, valid)

proc call*(call_606420: Call_DeleteTestGridProject_606407; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   body: JObject (required)
  var body_606421 = newJObject()
  if body != nil:
    body_606421 = body
  result = call_606420.call(nil, nil, nil, nil, body_606421)

var deleteTestGridProject* = Call_DeleteTestGridProject_606407(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_606408, base: "/",
    url: url_DeleteTestGridProject_606409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_606422 = ref object of OpenApiRestCall_605590
proc url_DeleteUpload_606424(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUpload_606423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606425 = header.getOrDefault("X-Amz-Target")
  valid_606425 = validateParameter(valid_606425, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_606425 != nil:
    section.add "X-Amz-Target", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Signature")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Signature", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Content-Sha256", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Date")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Date", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Credential")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Credential", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Security-Token")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Security-Token", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Algorithm")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Algorithm", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-SignedHeaders", valid_606432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606434: Call_DeleteUpload_606422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_606434.validator(path, query, header, formData, body)
  let scheme = call_606434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606434.url(scheme.get, call_606434.host, call_606434.base,
                         call_606434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606434, url, valid)

proc call*(call_606435: Call_DeleteUpload_606422; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_606436 = newJObject()
  if body != nil:
    body_606436 = body
  result = call_606435.call(nil, nil, nil, nil, body_606436)

var deleteUpload* = Call_DeleteUpload_606422(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_606423, base: "/", url: url_DeleteUpload_606424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_606437 = ref object of OpenApiRestCall_605590
proc url_DeleteVPCEConfiguration_606439(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVPCEConfiguration_606438(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606440 = header.getOrDefault("X-Amz-Target")
  valid_606440 = validateParameter(valid_606440, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_606440 != nil:
    section.add "X-Amz-Target", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Signature")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Signature", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Content-Sha256", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Date")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Date", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Credential")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Credential", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Security-Token")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Security-Token", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Algorithm")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Algorithm", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-SignedHeaders", valid_606447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606449: Call_DeleteVPCEConfiguration_606437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_606449.validator(path, query, header, formData, body)
  let scheme = call_606449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606449.url(scheme.get, call_606449.host, call_606449.base,
                         call_606449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606449, url, valid)

proc call*(call_606450: Call_DeleteVPCEConfiguration_606437; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_606451 = newJObject()
  if body != nil:
    body_606451 = body
  result = call_606450.call(nil, nil, nil, nil, body_606451)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_606437(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_606438, base: "/",
    url: url_DeleteVPCEConfiguration_606439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_606452 = ref object of OpenApiRestCall_605590
proc url_GetAccountSettings_606454(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_606453(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606455 = header.getOrDefault("X-Amz-Target")
  valid_606455 = validateParameter(valid_606455, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_606455 != nil:
    section.add "X-Amz-Target", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Signature")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Signature", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Content-Sha256", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Date")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Date", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Credential")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Credential", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Security-Token")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Security-Token", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Algorithm")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Algorithm", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-SignedHeaders", valid_606462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606464: Call_GetAccountSettings_606452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_606464.validator(path, query, header, formData, body)
  let scheme = call_606464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606464.url(scheme.get, call_606464.host, call_606464.base,
                         call_606464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606464, url, valid)

proc call*(call_606465: Call_GetAccountSettings_606452; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_606466 = newJObject()
  if body != nil:
    body_606466 = body
  result = call_606465.call(nil, nil, nil, nil, body_606466)

var getAccountSettings* = Call_GetAccountSettings_606452(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_606453, base: "/",
    url: url_GetAccountSettings_606454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_606467 = ref object of OpenApiRestCall_605590
proc url_GetDevice_606469(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevice_606468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606470 = header.getOrDefault("X-Amz-Target")
  valid_606470 = validateParameter(valid_606470, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_606470 != nil:
    section.add "X-Amz-Target", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Signature")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Signature", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Content-Sha256", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Date")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Date", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Credential")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Credential", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Security-Token")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Security-Token", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Algorithm")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Algorithm", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-SignedHeaders", valid_606477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606479: Call_GetDevice_606467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_606479.validator(path, query, header, formData, body)
  let scheme = call_606479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606479.url(scheme.get, call_606479.host, call_606479.base,
                         call_606479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606479, url, valid)

proc call*(call_606480: Call_GetDevice_606467; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_606481 = newJObject()
  if body != nil:
    body_606481 = body
  result = call_606480.call(nil, nil, nil, nil, body_606481)

var getDevice* = Call_GetDevice_606467(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_606468,
                                    base: "/", url: url_GetDevice_606469,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_606482 = ref object of OpenApiRestCall_605590
proc url_GetDeviceInstance_606484(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceInstance_606483(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606485 = header.getOrDefault("X-Amz-Target")
  valid_606485 = validateParameter(valid_606485, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_606485 != nil:
    section.add "X-Amz-Target", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Signature")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Signature", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Content-Sha256", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Date")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Date", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Credential")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Credential", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Security-Token")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Security-Token", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Algorithm")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Algorithm", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-SignedHeaders", valid_606492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_GetDeviceInstance_606482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_GetDeviceInstance_606482; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   body: JObject (required)
  var body_606496 = newJObject()
  if body != nil:
    body_606496 = body
  result = call_606495.call(nil, nil, nil, nil, body_606496)

var getDeviceInstance* = Call_GetDeviceInstance_606482(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_606483, base: "/",
    url: url_GetDeviceInstance_606484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_606497 = ref object of OpenApiRestCall_605590
proc url_GetDevicePool_606499(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevicePool_606498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606500 = header.getOrDefault("X-Amz-Target")
  valid_606500 = validateParameter(valid_606500, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_606500 != nil:
    section.add "X-Amz-Target", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Signature")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Signature", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Content-Sha256", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Date")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Date", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Credential")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Credential", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Security-Token")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Security-Token", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Algorithm")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Algorithm", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-SignedHeaders", valid_606507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606509: Call_GetDevicePool_606497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_606509.validator(path, query, header, formData, body)
  let scheme = call_606509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606509.url(scheme.get, call_606509.host, call_606509.base,
                         call_606509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606509, url, valid)

proc call*(call_606510: Call_GetDevicePool_606497; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_606511 = newJObject()
  if body != nil:
    body_606511 = body
  result = call_606510.call(nil, nil, nil, nil, body_606511)

var getDevicePool* = Call_GetDevicePool_606497(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_606498, base: "/", url: url_GetDevicePool_606499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_606512 = ref object of OpenApiRestCall_605590
proc url_GetDevicePoolCompatibility_606514(protocol: Scheme; host: string;
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

proc validate_GetDevicePoolCompatibility_606513(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606515 = header.getOrDefault("X-Amz-Target")
  valid_606515 = validateParameter(valid_606515, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_606515 != nil:
    section.add "X-Amz-Target", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Signature")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Signature", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Content-Sha256", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Date")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Date", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Credential")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Credential", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Security-Token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Security-Token", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Algorithm")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Algorithm", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-SignedHeaders", valid_606522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606524: Call_GetDevicePoolCompatibility_606512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_606524.validator(path, query, header, formData, body)
  let scheme = call_606524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606524.url(scheme.get, call_606524.host, call_606524.base,
                         call_606524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606524, url, valid)

proc call*(call_606525: Call_GetDevicePoolCompatibility_606512; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_606526 = newJObject()
  if body != nil:
    body_606526 = body
  result = call_606525.call(nil, nil, nil, nil, body_606526)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_606512(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_606513, base: "/",
    url: url_GetDevicePoolCompatibility_606514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_606527 = ref object of OpenApiRestCall_605590
proc url_GetInstanceProfile_606529(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceProfile_606528(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606530 = header.getOrDefault("X-Amz-Target")
  valid_606530 = validateParameter(valid_606530, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_606530 != nil:
    section.add "X-Amz-Target", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Security-Token")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Security-Token", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Algorithm")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Algorithm", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-SignedHeaders", valid_606537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_GetInstanceProfile_606527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_GetInstanceProfile_606527; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_606541 = newJObject()
  if body != nil:
    body_606541 = body
  result = call_606540.call(nil, nil, nil, nil, body_606541)

var getInstanceProfile* = Call_GetInstanceProfile_606527(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_606528, base: "/",
    url: url_GetInstanceProfile_606529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_606542 = ref object of OpenApiRestCall_605590
proc url_GetJob_606544(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_606543(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606545 = header.getOrDefault("X-Amz-Target")
  valid_606545 = validateParameter(valid_606545, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_606545 != nil:
    section.add "X-Amz-Target", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_GetJob_606542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_GetJob_606542; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_606556 = newJObject()
  if body != nil:
    body_606556 = body
  result = call_606555.call(nil, nil, nil, nil, body_606556)

var getJob* = Call_GetJob_606542(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_606543, base: "/",
                              url: url_GetJob_606544,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_606557 = ref object of OpenApiRestCall_605590
proc url_GetNetworkProfile_606559(protocol: Scheme; host: string; base: string;
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

proc validate_GetNetworkProfile_606558(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606560 = header.getOrDefault("X-Amz-Target")
  valid_606560 = validateParameter(valid_606560, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_606560 != nil:
    section.add "X-Amz-Target", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Signature")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Signature", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Content-Sha256", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Date")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Date", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Credential")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Credential", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Security-Token")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Security-Token", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Algorithm")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Algorithm", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-SignedHeaders", valid_606567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_GetNetworkProfile_606557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_GetNetworkProfile_606557; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_606571 = newJObject()
  if body != nil:
    body_606571 = body
  result = call_606570.call(nil, nil, nil, nil, body_606571)

var getNetworkProfile* = Call_GetNetworkProfile_606557(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_606558, base: "/",
    url: url_GetNetworkProfile_606559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_606572 = ref object of OpenApiRestCall_605590
proc url_GetOfferingStatus_606574(protocol: Scheme; host: string; base: string;
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

proc validate_GetOfferingStatus_606573(path: JsonNode; query: JsonNode;
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
  var valid_606575 = query.getOrDefault("nextToken")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "nextToken", valid_606575
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606576 = header.getOrDefault("X-Amz-Target")
  valid_606576 = validateParameter(valid_606576, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_606576 != nil:
    section.add "X-Amz-Target", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Signature")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Signature", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Content-Sha256", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Date")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Date", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Credential")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Credential", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Security-Token")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Security-Token", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Algorithm")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Algorithm", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-SignedHeaders", valid_606583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606585: Call_GetOfferingStatus_606572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_606585.validator(path, query, header, formData, body)
  let scheme = call_606585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606585.url(scheme.get, call_606585.host, call_606585.base,
                         call_606585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606585, url, valid)

proc call*(call_606586: Call_GetOfferingStatus_606572; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606587 = newJObject()
  var body_606588 = newJObject()
  add(query_606587, "nextToken", newJString(nextToken))
  if body != nil:
    body_606588 = body
  result = call_606586.call(nil, query_606587, nil, nil, body_606588)

var getOfferingStatus* = Call_GetOfferingStatus_606572(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_606573, base: "/",
    url: url_GetOfferingStatus_606574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_606590 = ref object of OpenApiRestCall_605590
proc url_GetProject_606592(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProject_606591(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606593 = header.getOrDefault("X-Amz-Target")
  valid_606593 = validateParameter(valid_606593, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_606593 != nil:
    section.add "X-Amz-Target", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606602: Call_GetProject_606590; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_606602.validator(path, query, header, formData, body)
  let scheme = call_606602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606602.url(scheme.get, call_606602.host, call_606602.base,
                         call_606602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606602, url, valid)

proc call*(call_606603: Call_GetProject_606590; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_606604 = newJObject()
  if body != nil:
    body_606604 = body
  result = call_606603.call(nil, nil, nil, nil, body_606604)

var getProject* = Call_GetProject_606590(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_606591,
                                      base: "/", url: url_GetProject_606592,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_606605 = ref object of OpenApiRestCall_605590
proc url_GetRemoteAccessSession_606607(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoteAccessSession_606606(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606608 = header.getOrDefault("X-Amz-Target")
  valid_606608 = validateParameter(valid_606608, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_606608 != nil:
    section.add "X-Amz-Target", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Signature")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Signature", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Content-Sha256", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Date")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Date", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Credential")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Credential", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Security-Token")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Security-Token", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Algorithm")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Algorithm", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-SignedHeaders", valid_606615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606617: Call_GetRemoteAccessSession_606605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_606617.validator(path, query, header, formData, body)
  let scheme = call_606617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606617.url(scheme.get, call_606617.host, call_606617.base,
                         call_606617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606617, url, valid)

proc call*(call_606618: Call_GetRemoteAccessSession_606605; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_606619 = newJObject()
  if body != nil:
    body_606619 = body
  result = call_606618.call(nil, nil, nil, nil, body_606619)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_606605(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_606606, base: "/",
    url: url_GetRemoteAccessSession_606607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_606620 = ref object of OpenApiRestCall_605590
proc url_GetRun_606622(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRun_606621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606623 = header.getOrDefault("X-Amz-Target")
  valid_606623 = validateParameter(valid_606623, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_606623 != nil:
    section.add "X-Amz-Target", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Signature")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Signature", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Content-Sha256", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Date")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Date", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Credential")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Credential", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Security-Token")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Security-Token", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Algorithm")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Algorithm", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-SignedHeaders", valid_606630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606632: Call_GetRun_606620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_606632.validator(path, query, header, formData, body)
  let scheme = call_606632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606632.url(scheme.get, call_606632.host, call_606632.base,
                         call_606632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606632, url, valid)

proc call*(call_606633: Call_GetRun_606620; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_606634 = newJObject()
  if body != nil:
    body_606634 = body
  result = call_606633.call(nil, nil, nil, nil, body_606634)

var getRun* = Call_GetRun_606620(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_606621, base: "/",
                              url: url_GetRun_606622,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_606635 = ref object of OpenApiRestCall_605590
proc url_GetSuite_606637(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSuite_606636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606638 = header.getOrDefault("X-Amz-Target")
  valid_606638 = validateParameter(valid_606638, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_606638 != nil:
    section.add "X-Amz-Target", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Signature")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Signature", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Content-Sha256", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Date")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Date", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Credential")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Credential", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Security-Token")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Security-Token", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Algorithm")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Algorithm", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-SignedHeaders", valid_606645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_GetSuite_606635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_GetSuite_606635; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_606649 = newJObject()
  if body != nil:
    body_606649 = body
  result = call_606648.call(nil, nil, nil, nil, body_606649)

var getSuite* = Call_GetSuite_606635(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_606636, base: "/",
                                  url: url_GetSuite_606637,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_606650 = ref object of OpenApiRestCall_605590
proc url_GetTest_606652(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTest_606651(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606653 = header.getOrDefault("X-Amz-Target")
  valid_606653 = validateParameter(valid_606653, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_606653 != nil:
    section.add "X-Amz-Target", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Signature")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Signature", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Content-Sha256", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Date")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Date", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Credential")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Credential", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Security-Token")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Security-Token", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Algorithm")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Algorithm", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-SignedHeaders", valid_606660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606662: Call_GetTest_606650; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_606662.validator(path, query, header, formData, body)
  let scheme = call_606662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606662.url(scheme.get, call_606662.host, call_606662.base,
                         call_606662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606662, url, valid)

proc call*(call_606663: Call_GetTest_606650; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_606664 = newJObject()
  if body != nil:
    body_606664 = body
  result = call_606663.call(nil, nil, nil, nil, body_606664)

var getTest* = Call_GetTest_606650(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_606651, base: "/",
                                url: url_GetTest_606652,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_606665 = ref object of OpenApiRestCall_605590
proc url_GetTestGridProject_606667(protocol: Scheme; host: string; base: string;
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

proc validate_GetTestGridProject_606666(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606668 = header.getOrDefault("X-Amz-Target")
  valid_606668 = validateParameter(valid_606668, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_606668 != nil:
    section.add "X-Amz-Target", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Signature")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Signature", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Content-Sha256", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Date")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Date", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Credential")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Credential", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Security-Token")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Security-Token", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Algorithm")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Algorithm", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-SignedHeaders", valid_606675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606677: Call_GetTestGridProject_606665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Selenium testing project.
  ## 
  let valid = call_606677.validator(path, query, header, formData, body)
  let scheme = call_606677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606677.url(scheme.get, call_606677.host, call_606677.base,
                         call_606677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606677, url, valid)

proc call*(call_606678: Call_GetTestGridProject_606665; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_606679 = newJObject()
  if body != nil:
    body_606679 = body
  result = call_606678.call(nil, nil, nil, nil, body_606679)

var getTestGridProject* = Call_GetTestGridProject_606665(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_606666, base: "/",
    url: url_GetTestGridProject_606667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_606680 = ref object of OpenApiRestCall_605590
proc url_GetTestGridSession_606682(protocol: Scheme; host: string; base: string;
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

proc validate_GetTestGridSession_606681(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606683 = header.getOrDefault("X-Amz-Target")
  valid_606683 = validateParameter(valid_606683, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_606683 != nil:
    section.add "X-Amz-Target", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Signature")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Signature", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Content-Sha256", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Date")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Date", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Credential")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Credential", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Security-Token")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Security-Token", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Algorithm")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Algorithm", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-SignedHeaders", valid_606690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606692: Call_GetTestGridSession_606680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  let valid = call_606692.validator(path, query, header, formData, body)
  let scheme = call_606692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606692.url(scheme.get, call_606692.host, call_606692.base,
                         call_606692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606692, url, valid)

proc call*(call_606693: Call_GetTestGridSession_606680; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   body: JObject (required)
  var body_606694 = newJObject()
  if body != nil:
    body_606694 = body
  result = call_606693.call(nil, nil, nil, nil, body_606694)

var getTestGridSession* = Call_GetTestGridSession_606680(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_606681, base: "/",
    url: url_GetTestGridSession_606682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_606695 = ref object of OpenApiRestCall_605590
proc url_GetUpload_606697(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUpload_606696(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606698 = header.getOrDefault("X-Amz-Target")
  valid_606698 = validateParameter(valid_606698, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_606698 != nil:
    section.add "X-Amz-Target", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Signature")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Signature", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Content-Sha256", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Date")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Date", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Credential")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Credential", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Security-Token")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Security-Token", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Algorithm")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Algorithm", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-SignedHeaders", valid_606705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606707: Call_GetUpload_606695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_606707.validator(path, query, header, formData, body)
  let scheme = call_606707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606707.url(scheme.get, call_606707.host, call_606707.base,
                         call_606707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606707, url, valid)

proc call*(call_606708: Call_GetUpload_606695; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_606709 = newJObject()
  if body != nil:
    body_606709 = body
  result = call_606708.call(nil, nil, nil, nil, body_606709)

var getUpload* = Call_GetUpload_606695(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_606696,
                                    base: "/", url: url_GetUpload_606697,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_606710 = ref object of OpenApiRestCall_605590
proc url_GetVPCEConfiguration_606712(protocol: Scheme; host: string; base: string;
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

proc validate_GetVPCEConfiguration_606711(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606713 = header.getOrDefault("X-Amz-Target")
  valid_606713 = validateParameter(valid_606713, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_606713 != nil:
    section.add "X-Amz-Target", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Signature")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Signature", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Content-Sha256", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Date")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Date", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Credential")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Credential", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Security-Token")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Security-Token", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Algorithm")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Algorithm", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-SignedHeaders", valid_606720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606722: Call_GetVPCEConfiguration_606710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_606722.validator(path, query, header, formData, body)
  let scheme = call_606722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606722.url(scheme.get, call_606722.host, call_606722.base,
                         call_606722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606722, url, valid)

proc call*(call_606723: Call_GetVPCEConfiguration_606710; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_606724 = newJObject()
  if body != nil:
    body_606724 = body
  result = call_606723.call(nil, nil, nil, nil, body_606724)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_606710(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_606711, base: "/",
    url: url_GetVPCEConfiguration_606712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_606725 = ref object of OpenApiRestCall_605590
proc url_InstallToRemoteAccessSession_606727(protocol: Scheme; host: string;
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

proc validate_InstallToRemoteAccessSession_606726(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606728 = header.getOrDefault("X-Amz-Target")
  valid_606728 = validateParameter(valid_606728, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_606728 != nil:
    section.add "X-Amz-Target", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Signature")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Signature", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Content-Sha256", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Date")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Date", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Credential")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Credential", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Security-Token")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Security-Token", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Algorithm")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Algorithm", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-SignedHeaders", valid_606735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606737: Call_InstallToRemoteAccessSession_606725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_606737.validator(path, query, header, formData, body)
  let scheme = call_606737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606737.url(scheme.get, call_606737.host, call_606737.base,
                         call_606737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606737, url, valid)

proc call*(call_606738: Call_InstallToRemoteAccessSession_606725; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_606739 = newJObject()
  if body != nil:
    body_606739 = body
  result = call_606738.call(nil, nil, nil, nil, body_606739)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_606725(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_606726, base: "/",
    url: url_InstallToRemoteAccessSession_606727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_606740 = ref object of OpenApiRestCall_605590
proc url_ListArtifacts_606742(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_606741(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606743 = query.getOrDefault("nextToken")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "nextToken", valid_606743
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606744 = header.getOrDefault("X-Amz-Target")
  valid_606744 = validateParameter(valid_606744, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_606744 != nil:
    section.add "X-Amz-Target", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Signature")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Signature", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Content-Sha256", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Date")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Date", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Credential")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Credential", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Security-Token")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Security-Token", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Algorithm")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Algorithm", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-SignedHeaders", valid_606751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606753: Call_ListArtifacts_606740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_606753.validator(path, query, header, formData, body)
  let scheme = call_606753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606753.url(scheme.get, call_606753.host, call_606753.base,
                         call_606753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606753, url, valid)

proc call*(call_606754: Call_ListArtifacts_606740; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606755 = newJObject()
  var body_606756 = newJObject()
  add(query_606755, "nextToken", newJString(nextToken))
  if body != nil:
    body_606756 = body
  result = call_606754.call(nil, query_606755, nil, nil, body_606756)

var listArtifacts* = Call_ListArtifacts_606740(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_606741, base: "/", url: url_ListArtifacts_606742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_606757 = ref object of OpenApiRestCall_605590
proc url_ListDeviceInstances_606759(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceInstances_606758(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606760 = header.getOrDefault("X-Amz-Target")
  valid_606760 = validateParameter(valid_606760, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_606760 != nil:
    section.add "X-Amz-Target", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Signature")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Signature", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Content-Sha256", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Date")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Date", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Credential")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Credential", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Security-Token")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Security-Token", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Algorithm")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Algorithm", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-SignedHeaders", valid_606767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606769: Call_ListDeviceInstances_606757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_606769.validator(path, query, header, formData, body)
  let scheme = call_606769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606769.url(scheme.get, call_606769.host, call_606769.base,
                         call_606769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606769, url, valid)

proc call*(call_606770: Call_ListDeviceInstances_606757; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_606771 = newJObject()
  if body != nil:
    body_606771 = body
  result = call_606770.call(nil, nil, nil, nil, body_606771)

var listDeviceInstances* = Call_ListDeviceInstances_606757(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_606758, base: "/",
    url: url_ListDeviceInstances_606759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_606772 = ref object of OpenApiRestCall_605590
proc url_ListDevicePools_606774(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevicePools_606773(path: JsonNode; query: JsonNode;
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
  var valid_606775 = query.getOrDefault("nextToken")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "nextToken", valid_606775
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606776 = header.getOrDefault("X-Amz-Target")
  valid_606776 = validateParameter(valid_606776, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_606776 != nil:
    section.add "X-Amz-Target", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Signature")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Signature", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Content-Sha256", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Date")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Date", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Credential")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Credential", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Security-Token")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Security-Token", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Algorithm")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Algorithm", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-SignedHeaders", valid_606783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_ListDevicePools_606772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_ListDevicePools_606772; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606787 = newJObject()
  var body_606788 = newJObject()
  add(query_606787, "nextToken", newJString(nextToken))
  if body != nil:
    body_606788 = body
  result = call_606786.call(nil, query_606787, nil, nil, body_606788)

var listDevicePools* = Call_ListDevicePools_606772(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_606773, base: "/", url: url_ListDevicePools_606774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_606789 = ref object of OpenApiRestCall_605590
proc url_ListDevices_606791(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_606790(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606792 = query.getOrDefault("nextToken")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "nextToken", valid_606792
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606793 = header.getOrDefault("X-Amz-Target")
  valid_606793 = validateParameter(valid_606793, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_606793 != nil:
    section.add "X-Amz-Target", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Signature")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Signature", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Content-Sha256", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Date")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Date", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Credential")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Credential", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Security-Token")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Security-Token", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Algorithm")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Algorithm", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-SignedHeaders", valid_606800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_ListDevices_606789; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_ListDevices_606789; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606804 = newJObject()
  var body_606805 = newJObject()
  add(query_606804, "nextToken", newJString(nextToken))
  if body != nil:
    body_606805 = body
  result = call_606803.call(nil, query_606804, nil, nil, body_606805)

var listDevices* = Call_ListDevices_606789(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_606790,
                                        base: "/", url: url_ListDevices_606791,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_606806 = ref object of OpenApiRestCall_605590
proc url_ListInstanceProfiles_606808(protocol: Scheme; host: string; base: string;
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

proc validate_ListInstanceProfiles_606807(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606809 = header.getOrDefault("X-Amz-Target")
  valid_606809 = validateParameter(valid_606809, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_606809 != nil:
    section.add "X-Amz-Target", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Signature")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Signature", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Content-Sha256", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Date")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Date", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Credential")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Credential", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Security-Token")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Security-Token", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Algorithm")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Algorithm", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-SignedHeaders", valid_606816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_ListInstanceProfiles_606806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_ListInstanceProfiles_606806; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_606820 = newJObject()
  if body != nil:
    body_606820 = body
  result = call_606819.call(nil, nil, nil, nil, body_606820)

var listInstanceProfiles* = Call_ListInstanceProfiles_606806(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_606807, base: "/",
    url: url_ListInstanceProfiles_606808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_606821 = ref object of OpenApiRestCall_605590
proc url_ListJobs_606823(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_606822(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606824 = query.getOrDefault("nextToken")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "nextToken", valid_606824
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606825 = header.getOrDefault("X-Amz-Target")
  valid_606825 = validateParameter(valid_606825, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_606825 != nil:
    section.add "X-Amz-Target", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Signature")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Signature", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Content-Sha256", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Date")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Date", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Credential")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Credential", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Security-Token")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Security-Token", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Algorithm")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Algorithm", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-SignedHeaders", valid_606832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606834: Call_ListJobs_606821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_606834.validator(path, query, header, formData, body)
  let scheme = call_606834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606834.url(scheme.get, call_606834.host, call_606834.base,
                         call_606834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606834, url, valid)

proc call*(call_606835: Call_ListJobs_606821; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606836 = newJObject()
  var body_606837 = newJObject()
  add(query_606836, "nextToken", newJString(nextToken))
  if body != nil:
    body_606837 = body
  result = call_606835.call(nil, query_606836, nil, nil, body_606837)

var listJobs* = Call_ListJobs_606821(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_606822, base: "/",
                                  url: url_ListJobs_606823,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_606838 = ref object of OpenApiRestCall_605590
proc url_ListNetworkProfiles_606840(protocol: Scheme; host: string; base: string;
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

proc validate_ListNetworkProfiles_606839(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606841 = header.getOrDefault("X-Amz-Target")
  valid_606841 = validateParameter(valid_606841, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_606841 != nil:
    section.add "X-Amz-Target", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Signature")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Signature", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Content-Sha256", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Date")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Date", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Credential")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Credential", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Security-Token")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Security-Token", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Algorithm")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Algorithm", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-SignedHeaders", valid_606848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606850: Call_ListNetworkProfiles_606838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_606850.validator(path, query, header, formData, body)
  let scheme = call_606850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606850.url(scheme.get, call_606850.host, call_606850.base,
                         call_606850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606850, url, valid)

proc call*(call_606851: Call_ListNetworkProfiles_606838; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_606852 = newJObject()
  if body != nil:
    body_606852 = body
  result = call_606851.call(nil, nil, nil, nil, body_606852)

var listNetworkProfiles* = Call_ListNetworkProfiles_606838(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_606839, base: "/",
    url: url_ListNetworkProfiles_606840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_606853 = ref object of OpenApiRestCall_605590
proc url_ListOfferingPromotions_606855(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferingPromotions_606854(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606856 = header.getOrDefault("X-Amz-Target")
  valid_606856 = validateParameter(valid_606856, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_606856 != nil:
    section.add "X-Amz-Target", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Signature")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Signature", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Content-Sha256", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Date")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Date", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Credential")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Credential", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Security-Token")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Security-Token", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Algorithm")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Algorithm", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-SignedHeaders", valid_606863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606865: Call_ListOfferingPromotions_606853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  let valid = call_606865.validator(path, query, header, formData, body)
  let scheme = call_606865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606865.url(scheme.get, call_606865.host, call_606865.base,
                         call_606865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606865, url, valid)

proc call*(call_606866: Call_ListOfferingPromotions_606853; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   body: JObject (required)
  var body_606867 = newJObject()
  if body != nil:
    body_606867 = body
  result = call_606866.call(nil, nil, nil, nil, body_606867)

var listOfferingPromotions* = Call_ListOfferingPromotions_606853(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_606854, base: "/",
    url: url_ListOfferingPromotions_606855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_606868 = ref object of OpenApiRestCall_605590
proc url_ListOfferingTransactions_606870(protocol: Scheme; host: string;
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

proc validate_ListOfferingTransactions_606869(path: JsonNode; query: JsonNode;
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
  var valid_606871 = query.getOrDefault("nextToken")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "nextToken", valid_606871
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606872 = header.getOrDefault("X-Amz-Target")
  valid_606872 = validateParameter(valid_606872, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_606872 != nil:
    section.add "X-Amz-Target", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Signature")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Signature", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Content-Sha256", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Date")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Date", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Credential")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Credential", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Security-Token")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Security-Token", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Algorithm")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Algorithm", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-SignedHeaders", valid_606879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606881: Call_ListOfferingTransactions_606868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_606881.validator(path, query, header, formData, body)
  let scheme = call_606881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606881.url(scheme.get, call_606881.host, call_606881.base,
                         call_606881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606881, url, valid)

proc call*(call_606882: Call_ListOfferingTransactions_606868; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606883 = newJObject()
  var body_606884 = newJObject()
  add(query_606883, "nextToken", newJString(nextToken))
  if body != nil:
    body_606884 = body
  result = call_606882.call(nil, query_606883, nil, nil, body_606884)

var listOfferingTransactions* = Call_ListOfferingTransactions_606868(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_606869, base: "/",
    url: url_ListOfferingTransactions_606870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_606885 = ref object of OpenApiRestCall_605590
proc url_ListOfferings_606887(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferings_606886(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606888 = query.getOrDefault("nextToken")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "nextToken", valid_606888
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606889 = header.getOrDefault("X-Amz-Target")
  valid_606889 = validateParameter(valid_606889, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_606889 != nil:
    section.add "X-Amz-Target", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Signature")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Signature", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Content-Sha256", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Date")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Date", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Credential")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Credential", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Security-Token")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Security-Token", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Algorithm")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Algorithm", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-SignedHeaders", valid_606896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606898: Call_ListOfferings_606885; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_606898.validator(path, query, header, formData, body)
  let scheme = call_606898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606898.url(scheme.get, call_606898.host, call_606898.base,
                         call_606898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606898, url, valid)

proc call*(call_606899: Call_ListOfferings_606885; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606900 = newJObject()
  var body_606901 = newJObject()
  add(query_606900, "nextToken", newJString(nextToken))
  if body != nil:
    body_606901 = body
  result = call_606899.call(nil, query_606900, nil, nil, body_606901)

var listOfferings* = Call_ListOfferings_606885(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_606886, base: "/", url: url_ListOfferings_606887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_606902 = ref object of OpenApiRestCall_605590
proc url_ListProjects_606904(protocol: Scheme; host: string; base: string;
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

proc validate_ListProjects_606903(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606905 = query.getOrDefault("nextToken")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "nextToken", valid_606905
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606906 = header.getOrDefault("X-Amz-Target")
  valid_606906 = validateParameter(valid_606906, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_606906 != nil:
    section.add "X-Amz-Target", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Signature")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Signature", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Content-Sha256", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Date")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Date", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Credential")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Credential", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Security-Token")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Security-Token", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Algorithm")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Algorithm", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-SignedHeaders", valid_606913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606915: Call_ListProjects_606902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_606915.validator(path, query, header, formData, body)
  let scheme = call_606915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606915.url(scheme.get, call_606915.host, call_606915.base,
                         call_606915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606915, url, valid)

proc call*(call_606916: Call_ListProjects_606902; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606917 = newJObject()
  var body_606918 = newJObject()
  add(query_606917, "nextToken", newJString(nextToken))
  if body != nil:
    body_606918 = body
  result = call_606916.call(nil, query_606917, nil, nil, body_606918)

var listProjects* = Call_ListProjects_606902(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_606903, base: "/", url: url_ListProjects_606904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_606919 = ref object of OpenApiRestCall_605590
proc url_ListRemoteAccessSessions_606921(protocol: Scheme; host: string;
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

proc validate_ListRemoteAccessSessions_606920(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606922 = header.getOrDefault("X-Amz-Target")
  valid_606922 = validateParameter(valid_606922, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_606922 != nil:
    section.add "X-Amz-Target", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Signature")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Signature", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Content-Sha256", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Date")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Date", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Credential")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Credential", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Security-Token")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Security-Token", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Algorithm")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Algorithm", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-SignedHeaders", valid_606929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606931: Call_ListRemoteAccessSessions_606919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_606931.validator(path, query, header, formData, body)
  let scheme = call_606931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606931.url(scheme.get, call_606931.host, call_606931.base,
                         call_606931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606931, url, valid)

proc call*(call_606932: Call_ListRemoteAccessSessions_606919; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_606933 = newJObject()
  if body != nil:
    body_606933 = body
  result = call_606932.call(nil, nil, nil, nil, body_606933)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_606919(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_606920, base: "/",
    url: url_ListRemoteAccessSessions_606921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_606934 = ref object of OpenApiRestCall_605590
proc url_ListRuns_606936(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRuns_606935(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606937 = query.getOrDefault("nextToken")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "nextToken", valid_606937
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606938 = header.getOrDefault("X-Amz-Target")
  valid_606938 = validateParameter(valid_606938, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_606938 != nil:
    section.add "X-Amz-Target", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Signature")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Signature", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Content-Sha256", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Date")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Date", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Credential")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Credential", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Security-Token")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Security-Token", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Algorithm")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Algorithm", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-SignedHeaders", valid_606945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606947: Call_ListRuns_606934; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_606947.validator(path, query, header, formData, body)
  let scheme = call_606947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606947.url(scheme.get, call_606947.host, call_606947.base,
                         call_606947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606947, url, valid)

proc call*(call_606948: Call_ListRuns_606934; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606949 = newJObject()
  var body_606950 = newJObject()
  add(query_606949, "nextToken", newJString(nextToken))
  if body != nil:
    body_606950 = body
  result = call_606948.call(nil, query_606949, nil, nil, body_606950)

var listRuns* = Call_ListRuns_606934(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_606935, base: "/",
                                  url: url_ListRuns_606936,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_606951 = ref object of OpenApiRestCall_605590
proc url_ListSamples_606953(protocol: Scheme; host: string; base: string;
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

proc validate_ListSamples_606952(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606954 = query.getOrDefault("nextToken")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "nextToken", valid_606954
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606955 = header.getOrDefault("X-Amz-Target")
  valid_606955 = validateParameter(valid_606955, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_606955 != nil:
    section.add "X-Amz-Target", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Signature")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Signature", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Content-Sha256", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Date")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Date", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Credential")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Credential", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Security-Token")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Security-Token", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Algorithm")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Algorithm", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-SignedHeaders", valid_606962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606964: Call_ListSamples_606951; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_606964.validator(path, query, header, formData, body)
  let scheme = call_606964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606964.url(scheme.get, call_606964.host, call_606964.base,
                         call_606964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606964, url, valid)

proc call*(call_606965: Call_ListSamples_606951; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606966 = newJObject()
  var body_606967 = newJObject()
  add(query_606966, "nextToken", newJString(nextToken))
  if body != nil:
    body_606967 = body
  result = call_606965.call(nil, query_606966, nil, nil, body_606967)

var listSamples* = Call_ListSamples_606951(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_606952,
                                        base: "/", url: url_ListSamples_606953,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_606968 = ref object of OpenApiRestCall_605590
proc url_ListSuites_606970(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListSuites_606969(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606971 = query.getOrDefault("nextToken")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "nextToken", valid_606971
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606972 = header.getOrDefault("X-Amz-Target")
  valid_606972 = validateParameter(valid_606972, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_606972 != nil:
    section.add "X-Amz-Target", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Signature")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Signature", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Content-Sha256", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Date")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Date", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Credential")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Credential", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Security-Token")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Security-Token", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Algorithm")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Algorithm", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-SignedHeaders", valid_606979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606981: Call_ListSuites_606968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_606981.validator(path, query, header, formData, body)
  let scheme = call_606981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606981.url(scheme.get, call_606981.host, call_606981.base,
                         call_606981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606981, url, valid)

proc call*(call_606982: Call_ListSuites_606968; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606983 = newJObject()
  var body_606984 = newJObject()
  add(query_606983, "nextToken", newJString(nextToken))
  if body != nil:
    body_606984 = body
  result = call_606982.call(nil, query_606983, nil, nil, body_606984)

var listSuites* = Call_ListSuites_606968(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_606969,
                                      base: "/", url: url_ListSuites_606970,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606985 = ref object of OpenApiRestCall_605590
proc url_ListTagsForResource_606987(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606986(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606988 = header.getOrDefault("X-Amz-Target")
  valid_606988 = validateParameter(valid_606988, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_606988 != nil:
    section.add "X-Amz-Target", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Signature")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Signature", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Content-Sha256", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Date")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Date", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Credential")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Credential", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Security-Token")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Security-Token", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Algorithm")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Algorithm", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-SignedHeaders", valid_606995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606997: Call_ListTagsForResource_606985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_606997.validator(path, query, header, formData, body)
  let scheme = call_606997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606997.url(scheme.get, call_606997.host, call_606997.base,
                         call_606997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606997, url, valid)

proc call*(call_606998: Call_ListTagsForResource_606985; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_606999 = newJObject()
  if body != nil:
    body_606999 = body
  result = call_606998.call(nil, nil, nil, nil, body_606999)

var listTagsForResource* = Call_ListTagsForResource_606985(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_606986, base: "/",
    url: url_ListTagsForResource_606987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_607000 = ref object of OpenApiRestCall_605590
proc url_ListTestGridProjects_607002(protocol: Scheme; host: string; base: string;
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

proc validate_ListTestGridProjects_607001(path: JsonNode; query: JsonNode;
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
  var valid_607003 = query.getOrDefault("nextToken")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "nextToken", valid_607003
  var valid_607004 = query.getOrDefault("maxResult")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "maxResult", valid_607004
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607005 = header.getOrDefault("X-Amz-Target")
  valid_607005 = validateParameter(valid_607005, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_607005 != nil:
    section.add "X-Amz-Target", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Signature")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Signature", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Content-Sha256", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Date")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Date", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Credential")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Credential", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Security-Token")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Security-Token", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Algorithm")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Algorithm", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-SignedHeaders", valid_607012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607014: Call_ListTestGridProjects_607000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  let valid = call_607014.validator(path, query, header, formData, body)
  let scheme = call_607014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607014.url(scheme.get, call_607014.host, call_607014.base,
                         call_607014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607014, url, valid)

proc call*(call_607015: Call_ListTestGridProjects_607000; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_607016 = newJObject()
  var body_607017 = newJObject()
  add(query_607016, "nextToken", newJString(nextToken))
  add(query_607016, "maxResult", newJString(maxResult))
  if body != nil:
    body_607017 = body
  result = call_607015.call(nil, query_607016, nil, nil, body_607017)

var listTestGridProjects* = Call_ListTestGridProjects_607000(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_607001, base: "/",
    url: url_ListTestGridProjects_607002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_607018 = ref object of OpenApiRestCall_605590
proc url_ListTestGridSessionActions_607020(protocol: Scheme; host: string;
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

proc validate_ListTestGridSessionActions_607019(path: JsonNode; query: JsonNode;
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
  var valid_607021 = query.getOrDefault("nextToken")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "nextToken", valid_607021
  var valid_607022 = query.getOrDefault("maxResult")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "maxResult", valid_607022
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607023 = header.getOrDefault("X-Amz-Target")
  valid_607023 = validateParameter(valid_607023, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_607023 != nil:
    section.add "X-Amz-Target", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Signature")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Signature", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Content-Sha256", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Date")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Date", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-Credential")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-Credential", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-Security-Token")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Security-Token", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Algorithm")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Algorithm", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-SignedHeaders", valid_607030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607032: Call_ListTestGridSessionActions_607018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  let valid = call_607032.validator(path, query, header, formData, body)
  let scheme = call_607032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607032.url(scheme.get, call_607032.host, call_607032.base,
                         call_607032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607032, url, valid)

proc call*(call_607033: Call_ListTestGridSessionActions_607018; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_607034 = newJObject()
  var body_607035 = newJObject()
  add(query_607034, "nextToken", newJString(nextToken))
  add(query_607034, "maxResult", newJString(maxResult))
  if body != nil:
    body_607035 = body
  result = call_607033.call(nil, query_607034, nil, nil, body_607035)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_607018(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_607019, base: "/",
    url: url_ListTestGridSessionActions_607020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_607036 = ref object of OpenApiRestCall_605590
proc url_ListTestGridSessionArtifacts_607038(protocol: Scheme; host: string;
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

proc validate_ListTestGridSessionArtifacts_607037(path: JsonNode; query: JsonNode;
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
  var valid_607039 = query.getOrDefault("nextToken")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "nextToken", valid_607039
  var valid_607040 = query.getOrDefault("maxResult")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "maxResult", valid_607040
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607041 = header.getOrDefault("X-Amz-Target")
  valid_607041 = validateParameter(valid_607041, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_607041 != nil:
    section.add "X-Amz-Target", valid_607041
  var valid_607042 = header.getOrDefault("X-Amz-Signature")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Signature", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Content-Sha256", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Date")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Date", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Credential")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Credential", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Security-Token")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Security-Token", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Algorithm")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Algorithm", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-SignedHeaders", valid_607048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607050: Call_ListTestGridSessionArtifacts_607036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of artifacts created during the session.
  ## 
  let valid = call_607050.validator(path, query, header, formData, body)
  let scheme = call_607050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607050.url(scheme.get, call_607050.host, call_607050.base,
                         call_607050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607050, url, valid)

proc call*(call_607051: Call_ListTestGridSessionArtifacts_607036; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_607052 = newJObject()
  var body_607053 = newJObject()
  add(query_607052, "nextToken", newJString(nextToken))
  add(query_607052, "maxResult", newJString(maxResult))
  if body != nil:
    body_607053 = body
  result = call_607051.call(nil, query_607052, nil, nil, body_607053)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_607036(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_607037, base: "/",
    url: url_ListTestGridSessionArtifacts_607038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_607054 = ref object of OpenApiRestCall_605590
proc url_ListTestGridSessions_607056(protocol: Scheme; host: string; base: string;
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

proc validate_ListTestGridSessions_607055(path: JsonNode; query: JsonNode;
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
  var valid_607057 = query.getOrDefault("nextToken")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "nextToken", valid_607057
  var valid_607058 = query.getOrDefault("maxResult")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "maxResult", valid_607058
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607059 = header.getOrDefault("X-Amz-Target")
  valid_607059 = validateParameter(valid_607059, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_607059 != nil:
    section.add "X-Amz-Target", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Signature")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Signature", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Content-Sha256", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Date")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Date", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Credential")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Credential", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Security-Token")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Security-Token", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Algorithm")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Algorithm", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-SignedHeaders", valid_607066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607068: Call_ListTestGridSessions_607054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  let valid = call_607068.validator(path, query, header, formData, body)
  let scheme = call_607068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607068.url(scheme.get, call_607068.host, call_607068.base,
                         call_607068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607068, url, valid)

proc call*(call_607069: Call_ListTestGridSessions_607054; body: JsonNode;
          nextToken: string = ""; maxResult: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxResult: string
  ##            : Pagination limit
  ##   body: JObject (required)
  var query_607070 = newJObject()
  var body_607071 = newJObject()
  add(query_607070, "nextToken", newJString(nextToken))
  add(query_607070, "maxResult", newJString(maxResult))
  if body != nil:
    body_607071 = body
  result = call_607069.call(nil, query_607070, nil, nil, body_607071)

var listTestGridSessions* = Call_ListTestGridSessions_607054(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_607055, base: "/",
    url: url_ListTestGridSessions_607056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_607072 = ref object of OpenApiRestCall_605590
proc url_ListTests_607074(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTests_607073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607075 = query.getOrDefault("nextToken")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "nextToken", valid_607075
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607076 = header.getOrDefault("X-Amz-Target")
  valid_607076 = validateParameter(valid_607076, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_607076 != nil:
    section.add "X-Amz-Target", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Signature")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Signature", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Content-Sha256", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Date")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Date", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Credential")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Credential", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Security-Token")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Security-Token", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Algorithm")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Algorithm", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-SignedHeaders", valid_607083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_ListTests_607072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607086: Call_ListTests_607072; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607087 = newJObject()
  var body_607088 = newJObject()
  add(query_607087, "nextToken", newJString(nextToken))
  if body != nil:
    body_607088 = body
  result = call_607086.call(nil, query_607087, nil, nil, body_607088)

var listTests* = Call_ListTests_607072(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_607073,
                                    base: "/", url: url_ListTests_607074,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_607089 = ref object of OpenApiRestCall_605590
proc url_ListUniqueProblems_607091(protocol: Scheme; host: string; base: string;
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

proc validate_ListUniqueProblems_607090(path: JsonNode; query: JsonNode;
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
  var valid_607092 = query.getOrDefault("nextToken")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "nextToken", valid_607092
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607093 = header.getOrDefault("X-Amz-Target")
  valid_607093 = validateParameter(valid_607093, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_607093 != nil:
    section.add "X-Amz-Target", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Signature")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Signature", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Content-Sha256", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Date")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Date", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Credential")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Credential", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Security-Token")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Security-Token", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-Algorithm")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Algorithm", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-SignedHeaders", valid_607100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607102: Call_ListUniqueProblems_607089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  let valid = call_607102.validator(path, query, header, formData, body)
  let scheme = call_607102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607102.url(scheme.get, call_607102.host, call_607102.base,
                         call_607102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607102, url, valid)

proc call*(call_607103: Call_ListUniqueProblems_607089; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607104 = newJObject()
  var body_607105 = newJObject()
  add(query_607104, "nextToken", newJString(nextToken))
  if body != nil:
    body_607105 = body
  result = call_607103.call(nil, query_607104, nil, nil, body_607105)

var listUniqueProblems* = Call_ListUniqueProblems_607089(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_607090, base: "/",
    url: url_ListUniqueProblems_607091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_607106 = ref object of OpenApiRestCall_605590
proc url_ListUploads_607108(protocol: Scheme; host: string; base: string;
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

proc validate_ListUploads_607107(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607109 = query.getOrDefault("nextToken")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "nextToken", valid_607109
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607110 = header.getOrDefault("X-Amz-Target")
  valid_607110 = validateParameter(valid_607110, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_607110 != nil:
    section.add "X-Amz-Target", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Signature")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Signature", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Content-Sha256", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Date")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Date", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Credential")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Credential", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Security-Token")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Security-Token", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Algorithm")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Algorithm", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-SignedHeaders", valid_607117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607119: Call_ListUploads_607106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_607119.validator(path, query, header, formData, body)
  let scheme = call_607119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607119.url(scheme.get, call_607119.host, call_607119.base,
                         call_607119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607119, url, valid)

proc call*(call_607120: Call_ListUploads_607106; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607121 = newJObject()
  var body_607122 = newJObject()
  add(query_607121, "nextToken", newJString(nextToken))
  if body != nil:
    body_607122 = body
  result = call_607120.call(nil, query_607121, nil, nil, body_607122)

var listUploads* = Call_ListUploads_607106(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_607107,
                                        base: "/", url: url_ListUploads_607108,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_607123 = ref object of OpenApiRestCall_605590
proc url_ListVPCEConfigurations_607125(protocol: Scheme; host: string; base: string;
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

proc validate_ListVPCEConfigurations_607124(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607126 = header.getOrDefault("X-Amz-Target")
  valid_607126 = validateParameter(valid_607126, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_607126 != nil:
    section.add "X-Amz-Target", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Signature")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Signature", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Content-Sha256", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Date")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Date", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Credential")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Credential", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Security-Token")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Security-Token", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Algorithm")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Algorithm", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-SignedHeaders", valid_607133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607135: Call_ListVPCEConfigurations_607123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_607135.validator(path, query, header, formData, body)
  let scheme = call_607135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607135.url(scheme.get, call_607135.host, call_607135.base,
                         call_607135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607135, url, valid)

proc call*(call_607136: Call_ListVPCEConfigurations_607123; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_607137 = newJObject()
  if body != nil:
    body_607137 = body
  result = call_607136.call(nil, nil, nil, nil, body_607137)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_607123(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_607124, base: "/",
    url: url_ListVPCEConfigurations_607125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_607138 = ref object of OpenApiRestCall_605590
proc url_PurchaseOffering_607140(protocol: Scheme; host: string; base: string;
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

proc validate_PurchaseOffering_607139(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607141 = header.getOrDefault("X-Amz-Target")
  valid_607141 = validateParameter(valid_607141, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_607141 != nil:
    section.add "X-Amz-Target", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Signature")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Signature", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Content-Sha256", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Date")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Date", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Credential")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Credential", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Security-Token")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Security-Token", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Algorithm")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Algorithm", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-SignedHeaders", valid_607148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607150: Call_PurchaseOffering_607138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_607150.validator(path, query, header, formData, body)
  let scheme = call_607150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607150.url(scheme.get, call_607150.host, call_607150.base,
                         call_607150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607150, url, valid)

proc call*(call_607151: Call_PurchaseOffering_607138; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_607152 = newJObject()
  if body != nil:
    body_607152 = body
  result = call_607151.call(nil, nil, nil, nil, body_607152)

var purchaseOffering* = Call_PurchaseOffering_607138(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_607139, base: "/",
    url: url_PurchaseOffering_607140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_607153 = ref object of OpenApiRestCall_605590
proc url_RenewOffering_607155(protocol: Scheme; host: string; base: string;
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

proc validate_RenewOffering_607154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607156 = header.getOrDefault("X-Amz-Target")
  valid_607156 = validateParameter(valid_607156, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_607156 != nil:
    section.add "X-Amz-Target", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Signature")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Signature", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Content-Sha256", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Date")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Date", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Credential")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Credential", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Security-Token")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Security-Token", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Algorithm")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Algorithm", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-SignedHeaders", valid_607163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607165: Call_RenewOffering_607153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_607165.validator(path, query, header, formData, body)
  let scheme = call_607165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607165.url(scheme.get, call_607165.host, call_607165.base,
                         call_607165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607165, url, valid)

proc call*(call_607166: Call_RenewOffering_607153; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_607167 = newJObject()
  if body != nil:
    body_607167 = body
  result = call_607166.call(nil, nil, nil, nil, body_607167)

var renewOffering* = Call_RenewOffering_607153(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_607154, base: "/", url: url_RenewOffering_607155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_607168 = ref object of OpenApiRestCall_605590
proc url_ScheduleRun_607170(protocol: Scheme; host: string; base: string;
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

proc validate_ScheduleRun_607169(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607171 = header.getOrDefault("X-Amz-Target")
  valid_607171 = validateParameter(valid_607171, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_607171 != nil:
    section.add "X-Amz-Target", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Signature")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Signature", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Content-Sha256", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Date")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Date", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Credential")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Credential", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Security-Token")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Security-Token", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Algorithm")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Algorithm", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-SignedHeaders", valid_607178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607180: Call_ScheduleRun_607168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_607180.validator(path, query, header, formData, body)
  let scheme = call_607180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607180.url(scheme.get, call_607180.host, call_607180.base,
                         call_607180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607180, url, valid)

proc call*(call_607181: Call_ScheduleRun_607168; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_607182 = newJObject()
  if body != nil:
    body_607182 = body
  result = call_607181.call(nil, nil, nil, nil, body_607182)

var scheduleRun* = Call_ScheduleRun_607168(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_607169,
                                        base: "/", url: url_ScheduleRun_607170,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_607183 = ref object of OpenApiRestCall_605590
proc url_StopJob_607185(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_607184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607186 = header.getOrDefault("X-Amz-Target")
  valid_607186 = validateParameter(valid_607186, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_607186 != nil:
    section.add "X-Amz-Target", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Signature")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Signature", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Content-Sha256", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Date")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Date", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Credential")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Credential", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Security-Token")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Security-Token", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Algorithm")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Algorithm", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-SignedHeaders", valid_607193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607195: Call_StopJob_607183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_607195.validator(path, query, header, formData, body)
  let scheme = call_607195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607195.url(scheme.get, call_607195.host, call_607195.base,
                         call_607195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607195, url, valid)

proc call*(call_607196: Call_StopJob_607183; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_607197 = newJObject()
  if body != nil:
    body_607197 = body
  result = call_607196.call(nil, nil, nil, nil, body_607197)

var stopJob* = Call_StopJob_607183(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_607184, base: "/",
                                url: url_StopJob_607185,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_607198 = ref object of OpenApiRestCall_605590
proc url_StopRemoteAccessSession_607200(protocol: Scheme; host: string; base: string;
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

proc validate_StopRemoteAccessSession_607199(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607201 = header.getOrDefault("X-Amz-Target")
  valid_607201 = validateParameter(valid_607201, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_607201 != nil:
    section.add "X-Amz-Target", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Signature")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Signature", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Content-Sha256", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Date")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Date", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Credential")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Credential", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Security-Token")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Security-Token", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Algorithm")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Algorithm", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-SignedHeaders", valid_607208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607210: Call_StopRemoteAccessSession_607198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_607210.validator(path, query, header, formData, body)
  let scheme = call_607210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607210.url(scheme.get, call_607210.host, call_607210.base,
                         call_607210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607210, url, valid)

proc call*(call_607211: Call_StopRemoteAccessSession_607198; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_607212 = newJObject()
  if body != nil:
    body_607212 = body
  result = call_607211.call(nil, nil, nil, nil, body_607212)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_607198(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_607199, base: "/",
    url: url_StopRemoteAccessSession_607200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_607213 = ref object of OpenApiRestCall_605590
proc url_StopRun_607215(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopRun_607214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607216 = header.getOrDefault("X-Amz-Target")
  valid_607216 = validateParameter(valid_607216, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_607216 != nil:
    section.add "X-Amz-Target", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Signature")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Signature", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Content-Sha256", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Date")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Date", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Credential")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Credential", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Security-Token")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Security-Token", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Algorithm")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Algorithm", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-SignedHeaders", valid_607223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607225: Call_StopRun_607213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_607225.validator(path, query, header, formData, body)
  let scheme = call_607225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607225.url(scheme.get, call_607225.host, call_607225.base,
                         call_607225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607225, url, valid)

proc call*(call_607226: Call_StopRun_607213; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_607227 = newJObject()
  if body != nil:
    body_607227 = body
  result = call_607226.call(nil, nil, nil, nil, body_607227)

var stopRun* = Call_StopRun_607213(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_607214, base: "/",
                                url: url_StopRun_607215,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607228 = ref object of OpenApiRestCall_605590
proc url_TagResource_607230(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607231 = header.getOrDefault("X-Amz-Target")
  valid_607231 = validateParameter(valid_607231, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_607231 != nil:
    section.add "X-Amz-Target", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Signature")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Signature", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Content-Sha256", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Date")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Date", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Credential")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Credential", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Security-Token")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Security-Token", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Algorithm")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Algorithm", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-SignedHeaders", valid_607238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607240: Call_TagResource_607228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  let valid = call_607240.validator(path, query, header, formData, body)
  let scheme = call_607240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607240.url(scheme.get, call_607240.host, call_607240.base,
                         call_607240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607240, url, valid)

proc call*(call_607241: Call_TagResource_607228; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   body: JObject (required)
  var body_607242 = newJObject()
  if body != nil:
    body_607242 = body
  result = call_607241.call(nil, nil, nil, nil, body_607242)

var tagResource* = Call_TagResource_607228(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_607229,
                                        base: "/", url: url_TagResource_607230,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607243 = ref object of OpenApiRestCall_605590
proc url_UntagResource_607245(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607244(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607246 = header.getOrDefault("X-Amz-Target")
  valid_607246 = validateParameter(valid_607246, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_607246 != nil:
    section.add "X-Amz-Target", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Signature")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Signature", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Content-Sha256", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Date")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Date", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Credential")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Credential", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Security-Token")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Security-Token", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Algorithm")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Algorithm", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-SignedHeaders", valid_607253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607255: Call_UntagResource_607243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_607255.validator(path, query, header, formData, body)
  let scheme = call_607255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607255.url(scheme.get, call_607255.host, call_607255.base,
                         call_607255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607255, url, valid)

proc call*(call_607256: Call_UntagResource_607243; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_607257 = newJObject()
  if body != nil:
    body_607257 = body
  result = call_607256.call(nil, nil, nil, nil, body_607257)

var untagResource* = Call_UntagResource_607243(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_607244, base: "/", url: url_UntagResource_607245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_607258 = ref object of OpenApiRestCall_605590
proc url_UpdateDeviceInstance_607260(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceInstance_607259(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607261 = header.getOrDefault("X-Amz-Target")
  valid_607261 = validateParameter(valid_607261, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_607261 != nil:
    section.add "X-Amz-Target", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Signature")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Signature", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Content-Sha256", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Date")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Date", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Credential")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Credential", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Security-Token")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Security-Token", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Algorithm")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Algorithm", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-SignedHeaders", valid_607268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607270: Call_UpdateDeviceInstance_607258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about a private device instance.
  ## 
  let valid = call_607270.validator(path, query, header, formData, body)
  let scheme = call_607270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607270.url(scheme.get, call_607270.host, call_607270.base,
                         call_607270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607270, url, valid)

proc call*(call_607271: Call_UpdateDeviceInstance_607258; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_607272 = newJObject()
  if body != nil:
    body_607272 = body
  result = call_607271.call(nil, nil, nil, nil, body_607272)

var updateDeviceInstance* = Call_UpdateDeviceInstance_607258(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_607259, base: "/",
    url: url_UpdateDeviceInstance_607260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_607273 = ref object of OpenApiRestCall_605590
proc url_UpdateDevicePool_607275(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevicePool_607274(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607276 = header.getOrDefault("X-Amz-Target")
  valid_607276 = validateParameter(valid_607276, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_607276 != nil:
    section.add "X-Amz-Target", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Signature")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Signature", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Content-Sha256", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Date")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Date", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Credential")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Credential", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Security-Token")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Security-Token", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Algorithm")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Algorithm", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-SignedHeaders", valid_607283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607285: Call_UpdateDevicePool_607273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_607285.validator(path, query, header, formData, body)
  let scheme = call_607285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607285.url(scheme.get, call_607285.host, call_607285.base,
                         call_607285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607285, url, valid)

proc call*(call_607286: Call_UpdateDevicePool_607273; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_607287 = newJObject()
  if body != nil:
    body_607287 = body
  result = call_607286.call(nil, nil, nil, nil, body_607287)

var updateDevicePool* = Call_UpdateDevicePool_607273(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_607274, base: "/",
    url: url_UpdateDevicePool_607275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_607288 = ref object of OpenApiRestCall_605590
proc url_UpdateInstanceProfile_607290(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInstanceProfile_607289(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607291 = header.getOrDefault("X-Amz-Target")
  valid_607291 = validateParameter(valid_607291, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_607291 != nil:
    section.add "X-Amz-Target", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Signature")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Signature", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Content-Sha256", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Date")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Date", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Credential")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Credential", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Security-Token")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Security-Token", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Algorithm")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Algorithm", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-SignedHeaders", valid_607298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607300: Call_UpdateInstanceProfile_607288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_607300.validator(path, query, header, formData, body)
  let scheme = call_607300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607300.url(scheme.get, call_607300.host, call_607300.base,
                         call_607300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607300, url, valid)

proc call*(call_607301: Call_UpdateInstanceProfile_607288; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_607302 = newJObject()
  if body != nil:
    body_607302 = body
  result = call_607301.call(nil, nil, nil, nil, body_607302)

var updateInstanceProfile* = Call_UpdateInstanceProfile_607288(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_607289, base: "/",
    url: url_UpdateInstanceProfile_607290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_607303 = ref object of OpenApiRestCall_605590
proc url_UpdateNetworkProfile_607305(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNetworkProfile_607304(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607306 = header.getOrDefault("X-Amz-Target")
  valid_607306 = validateParameter(valid_607306, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_607306 != nil:
    section.add "X-Amz-Target", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Signature")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Signature", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Content-Sha256", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Date")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Date", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Credential")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Credential", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Security-Token")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Security-Token", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Algorithm")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Algorithm", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-SignedHeaders", valid_607313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607315: Call_UpdateNetworkProfile_607303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile.
  ## 
  let valid = call_607315.validator(path, query, header, formData, body)
  let scheme = call_607315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607315.url(scheme.get, call_607315.host, call_607315.base,
                         call_607315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607315, url, valid)

proc call*(call_607316: Call_UpdateNetworkProfile_607303; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_607317 = newJObject()
  if body != nil:
    body_607317 = body
  result = call_607316.call(nil, nil, nil, nil, body_607317)

var updateNetworkProfile* = Call_UpdateNetworkProfile_607303(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_607304, base: "/",
    url: url_UpdateNetworkProfile_607305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_607318 = ref object of OpenApiRestCall_605590
proc url_UpdateProject_607320(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_607319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607321 = header.getOrDefault("X-Amz-Target")
  valid_607321 = validateParameter(valid_607321, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_607321 != nil:
    section.add "X-Amz-Target", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Signature")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Signature", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Content-Sha256", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Date")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Date", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Credential")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Credential", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Security-Token")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Security-Token", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-Algorithm")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-Algorithm", valid_607327
  var valid_607328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "X-Amz-SignedHeaders", valid_607328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607330: Call_UpdateProject_607318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_607330.validator(path, query, header, formData, body)
  let scheme = call_607330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607330.url(scheme.get, call_607330.host, call_607330.base,
                         call_607330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607330, url, valid)

proc call*(call_607331: Call_UpdateProject_607318; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_607332 = newJObject()
  if body != nil:
    body_607332 = body
  result = call_607331.call(nil, nil, nil, nil, body_607332)

var updateProject* = Call_UpdateProject_607318(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_607319, base: "/", url: url_UpdateProject_607320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_607333 = ref object of OpenApiRestCall_605590
proc url_UpdateTestGridProject_607335(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTestGridProject_607334(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607336 = header.getOrDefault("X-Amz-Target")
  valid_607336 = validateParameter(valid_607336, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_607336 != nil:
    section.add "X-Amz-Target", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Signature")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Signature", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Content-Sha256", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Date")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Date", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Credential")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Credential", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-Security-Token")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-Security-Token", valid_607341
  var valid_607342 = header.getOrDefault("X-Amz-Algorithm")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "X-Amz-Algorithm", valid_607342
  var valid_607343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607343 = validateParameter(valid_607343, JString, required = false,
                                 default = nil)
  if valid_607343 != nil:
    section.add "X-Amz-SignedHeaders", valid_607343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607345: Call_UpdateTestGridProject_607333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Change details of a project.
  ## 
  let valid = call_607345.validator(path, query, header, formData, body)
  let scheme = call_607345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607345.url(scheme.get, call_607345.host, call_607345.base,
                         call_607345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607345, url, valid)

proc call*(call_607346: Call_UpdateTestGridProject_607333; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_607347 = newJObject()
  if body != nil:
    body_607347 = body
  result = call_607346.call(nil, nil, nil, nil, body_607347)

var updateTestGridProject* = Call_UpdateTestGridProject_607333(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_607334, base: "/",
    url: url_UpdateTestGridProject_607335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_607348 = ref object of OpenApiRestCall_605590
proc url_UpdateUpload_607350(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUpload_607349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607351 = header.getOrDefault("X-Amz-Target")
  valid_607351 = validateParameter(valid_607351, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_607351 != nil:
    section.add "X-Amz-Target", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Signature")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Signature", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Content-Sha256", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Date")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Date", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Credential")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Credential", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Security-Token")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Security-Token", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Algorithm")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Algorithm", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-SignedHeaders", valid_607358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607360: Call_UpdateUpload_607348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an uploaded test spec.
  ## 
  let valid = call_607360.validator(path, query, header, formData, body)
  let scheme = call_607360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607360.url(scheme.get, call_607360.host, call_607360.base,
                         call_607360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607360, url, valid)

proc call*(call_607361: Call_UpdateUpload_607348; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_607362 = newJObject()
  if body != nil:
    body_607362 = body
  result = call_607361.call(nil, nil, nil, nil, body_607362)

var updateUpload* = Call_UpdateUpload_607348(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_607349, base: "/", url: url_UpdateUpload_607350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_607363 = ref object of OpenApiRestCall_605590
proc url_UpdateVPCEConfiguration_607365(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVPCEConfiguration_607364(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607366 = header.getOrDefault("X-Amz-Target")
  valid_607366 = validateParameter(valid_607366, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_607366 != nil:
    section.add "X-Amz-Target", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Signature")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Signature", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Content-Sha256", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Date")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Date", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Credential")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Credential", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Security-Token")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Security-Token", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Algorithm")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Algorithm", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-SignedHeaders", valid_607373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607375: Call_UpdateVPCEConfiguration_607363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_607375.validator(path, query, header, formData, body)
  let scheme = call_607375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607375.url(scheme.get, call_607375.host, call_607375.base,
                         call_607375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607375, url, valid)

proc call*(call_607376: Call_UpdateVPCEConfiguration_607363; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_607377 = newJObject()
  if body != nil:
    body_607377 = body
  result = call_607376.call(nil, nil, nil, nil, body_607377)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_607363(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_607364, base: "/",
    url: url_UpdateVPCEConfiguration_607365, schemes: {Scheme.Https, Scheme.Http})
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
