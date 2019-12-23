
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

  OpenApiRestCall_599369 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599369](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599369): Option[Scheme] {.used.} =
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
  Call_CreateDevicePool_599706 = ref object of OpenApiRestCall_599369
proc url_CreateDevicePool_599708(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDevicePool_599707(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599820 = header.getOrDefault("X-Amz-Date")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Date", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Security-Token")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Security-Token", valid_599821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599835 = header.getOrDefault("X-Amz-Target")
  valid_599835 = validateParameter(valid_599835, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_599835 != nil:
    section.add "X-Amz-Target", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_CreateDevicePool_599706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_CreateDevicePool_599706; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_599936 = newJObject()
  if body != nil:
    body_599936 = body
  result = call_599935.call(nil, nil, nil, nil, body_599936)

var createDevicePool* = Call_CreateDevicePool_599706(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_599707, base: "/",
    url: url_CreateDevicePool_599708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_599975 = ref object of OpenApiRestCall_599369
proc url_CreateInstanceProfile_599977(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceProfile_599976(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599978 = header.getOrDefault("X-Amz-Date")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Date", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Security-Token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Security-Token", valid_599979
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599980 = header.getOrDefault("X-Amz-Target")
  valid_599980 = validateParameter(valid_599980, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_599980 != nil:
    section.add "X-Amz-Target", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_CreateInstanceProfile_599975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_CreateInstanceProfile_599975; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_599989 = newJObject()
  if body != nil:
    body_599989 = body
  result = call_599988.call(nil, nil, nil, nil, body_599989)

var createInstanceProfile* = Call_CreateInstanceProfile_599975(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_599976, base: "/",
    url: url_CreateInstanceProfile_599977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_599990 = ref object of OpenApiRestCall_599369
proc url_CreateNetworkProfile_599992(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_599991(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599995 = header.getOrDefault("X-Amz-Target")
  valid_599995 = validateParameter(valid_599995, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_599995 != nil:
    section.add "X-Amz-Target", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_CreateNetworkProfile_599990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_CreateNetworkProfile_599990; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_600004 = newJObject()
  if body != nil:
    body_600004 = body
  result = call_600003.call(nil, nil, nil, nil, body_600004)

var createNetworkProfile* = Call_CreateNetworkProfile_599990(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_599991, base: "/",
    url: url_CreateNetworkProfile_599992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_600005 = ref object of OpenApiRestCall_599369
proc url_CreateProject_600007(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_600006(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600008 = header.getOrDefault("X-Amz-Date")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Date", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Security-Token")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Security-Token", valid_600009
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600010 = header.getOrDefault("X-Amz-Target")
  valid_600010 = validateParameter(valid_600010, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_600010 != nil:
    section.add "X-Amz-Target", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Content-Sha256", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Algorithm")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Algorithm", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Signature")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Signature", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-SignedHeaders", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Credential")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Credential", valid_600015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_CreateProject_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a project.
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_CreateProject_600005; body: JsonNode): Recallable =
  ## createProject
  ## Creates a project.
  ##   body: JObject (required)
  var body_600019 = newJObject()
  if body != nil:
    body_600019 = body
  result = call_600018.call(nil, nil, nil, nil, body_600019)

var createProject* = Call_CreateProject_600005(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_600006, base: "/", url: url_CreateProject_600007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_600020 = ref object of OpenApiRestCall_599369
proc url_CreateRemoteAccessSession_600022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRemoteAccessSession_600021(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600025 = header.getOrDefault("X-Amz-Target")
  valid_600025 = validateParameter(valid_600025, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_600025 != nil:
    section.add "X-Amz-Target", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_CreateRemoteAccessSession_600020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_CreateRemoteAccessSession_600020; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_600034 = newJObject()
  if body != nil:
    body_600034 = body
  result = call_600033.call(nil, nil, nil, nil, body_600034)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_600020(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_600021, base: "/",
    url: url_CreateRemoteAccessSession_600022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridProject_600035 = ref object of OpenApiRestCall_599369
proc url_CreateTestGridProject_600037(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridProject_600036(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600038 = header.getOrDefault("X-Amz-Date")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Date", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Security-Token")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Security-Token", valid_600039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600040 = header.getOrDefault("X-Amz-Target")
  valid_600040 = validateParameter(valid_600040, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridProject"))
  if valid_600040 != nil:
    section.add "X-Amz-Target", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_CreateTestGridProject_600035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_CreateTestGridProject_600035; body: JsonNode): Recallable =
  ## createTestGridProject
  ## Creates a Selenium testing project. Projects are used to track <a>TestGridSession</a> instances.
  ##   body: JObject (required)
  var body_600049 = newJObject()
  if body != nil:
    body_600049 = body
  result = call_600048.call(nil, nil, nil, nil, body_600049)

var createTestGridProject* = Call_CreateTestGridProject_600035(
    name: "createTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridProject",
    validator: validate_CreateTestGridProject_600036, base: "/",
    url: url_CreateTestGridProject_600037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTestGridUrl_600050 = ref object of OpenApiRestCall_599369
proc url_CreateTestGridUrl_600052(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTestGridUrl_600051(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600055 = header.getOrDefault("X-Amz-Target")
  valid_600055 = validateParameter(valid_600055, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateTestGridUrl"))
  if valid_600055 != nil:
    section.add "X-Amz-Target", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Content-Sha256", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Algorithm")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Algorithm", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Signature", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-SignedHeaders", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Credential")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Credential", valid_600060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_CreateTestGridUrl_600050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_CreateTestGridUrl_600050; body: JsonNode): Recallable =
  ## createTestGridUrl
  ## Creates a signed, short-term URL that can be passed to a Selenium <code>RemoteWebDriver</code> constructor.
  ##   body: JObject (required)
  var body_600064 = newJObject()
  if body != nil:
    body_600064 = body
  result = call_600063.call(nil, nil, nil, nil, body_600064)

var createTestGridUrl* = Call_CreateTestGridUrl_600050(name: "createTestGridUrl",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateTestGridUrl",
    validator: validate_CreateTestGridUrl_600051, base: "/",
    url: url_CreateTestGridUrl_600052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_600065 = ref object of OpenApiRestCall_599369
proc url_CreateUpload_600067(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUpload_600066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600070 = header.getOrDefault("X-Amz-Target")
  valid_600070 = validateParameter(valid_600070, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_600070 != nil:
    section.add "X-Amz-Target", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Content-Sha256", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Algorithm")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Algorithm", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Signature")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Signature", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-SignedHeaders", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Credential")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Credential", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_CreateUpload_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_CreateUpload_600065; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_600079 = newJObject()
  if body != nil:
    body_600079 = body
  result = call_600078.call(nil, nil, nil, nil, body_600079)

var createUpload* = Call_CreateUpload_600065(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_600066, base: "/", url: url_CreateUpload_600067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_600080 = ref object of OpenApiRestCall_599369
proc url_CreateVPCEConfiguration_600082(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVPCEConfiguration_600081(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600085 = header.getOrDefault("X-Amz-Target")
  valid_600085 = validateParameter(valid_600085, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_600085 != nil:
    section.add "X-Amz-Target", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Content-Sha256", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Algorithm")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Algorithm", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Signature")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Signature", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-SignedHeaders", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Credential")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Credential", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_CreateVPCEConfiguration_600080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_CreateVPCEConfiguration_600080; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600094 = newJObject()
  if body != nil:
    body_600094 = body
  result = call_600093.call(nil, nil, nil, nil, body_600094)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_600080(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_600081, base: "/",
    url: url_CreateVPCEConfiguration_600082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_600095 = ref object of OpenApiRestCall_599369
proc url_DeleteDevicePool_600097(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevicePool_600096(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600098 = header.getOrDefault("X-Amz-Date")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Date", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Security-Token")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Security-Token", valid_600099
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600100 = header.getOrDefault("X-Amz-Target")
  valid_600100 = validateParameter(valid_600100, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_600100 != nil:
    section.add "X-Amz-Target", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600107: Call_DeleteDevicePool_600095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_600107.validator(path, query, header, formData, body)
  let scheme = call_600107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600107.url(scheme.get, call_600107.host, call_600107.base,
                         call_600107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600107, url, valid)

proc call*(call_600108: Call_DeleteDevicePool_600095; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_600109 = newJObject()
  if body != nil:
    body_600109 = body
  result = call_600108.call(nil, nil, nil, nil, body_600109)

var deleteDevicePool* = Call_DeleteDevicePool_600095(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_600096, base: "/",
    url: url_DeleteDevicePool_600097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_600110 = ref object of OpenApiRestCall_599369
proc url_DeleteInstanceProfile_600112(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceProfile_600111(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600113 = header.getOrDefault("X-Amz-Date")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Date", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Security-Token")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Security-Token", valid_600114
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600115 = header.getOrDefault("X-Amz-Target")
  valid_600115 = validateParameter(valid_600115, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_600115 != nil:
    section.add "X-Amz-Target", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Content-Sha256", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Algorithm")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Algorithm", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Signature")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Signature", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-SignedHeaders", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Credential")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Credential", valid_600120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600122: Call_DeleteInstanceProfile_600110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_600122.validator(path, query, header, formData, body)
  let scheme = call_600122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600122.url(scheme.get, call_600122.host, call_600122.base,
                         call_600122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600122, url, valid)

proc call*(call_600123: Call_DeleteInstanceProfile_600110; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_600124 = newJObject()
  if body != nil:
    body_600124 = body
  result = call_600123.call(nil, nil, nil, nil, body_600124)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_600110(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_600111, base: "/",
    url: url_DeleteInstanceProfile_600112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_600125 = ref object of OpenApiRestCall_599369
proc url_DeleteNetworkProfile_600127(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_600126(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600130 = header.getOrDefault("X-Amz-Target")
  valid_600130 = validateParameter(valid_600130, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_600130 != nil:
    section.add "X-Amz-Target", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Content-Sha256", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Algorithm")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Algorithm", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Signature")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Signature", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-SignedHeaders", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Credential")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Credential", valid_600135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_DeleteNetworkProfile_600125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_DeleteNetworkProfile_600125; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_600139 = newJObject()
  if body != nil:
    body_600139 = body
  result = call_600138.call(nil, nil, nil, nil, body_600139)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_600125(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_600126, base: "/",
    url: url_DeleteNetworkProfile_600127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_600140 = ref object of OpenApiRestCall_599369
proc url_DeleteProject_600142(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_600141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600145 = header.getOrDefault("X-Amz-Target")
  valid_600145 = validateParameter(valid_600145, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_600145 != nil:
    section.add "X-Amz-Target", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Content-Sha256", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Algorithm")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Algorithm", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Signature")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Signature", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-SignedHeaders", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Credential")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Credential", valid_600150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600152: Call_DeleteProject_600140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_600152.validator(path, query, header, formData, body)
  let scheme = call_600152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600152.url(scheme.get, call_600152.host, call_600152.base,
                         call_600152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600152, url, valid)

proc call*(call_600153: Call_DeleteProject_600140; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_600154 = newJObject()
  if body != nil:
    body_600154 = body
  result = call_600153.call(nil, nil, nil, nil, body_600154)

var deleteProject* = Call_DeleteProject_600140(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_600141, base: "/", url: url_DeleteProject_600142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_600155 = ref object of OpenApiRestCall_599369
proc url_DeleteRemoteAccessSession_600157(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_600156(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600158 = header.getOrDefault("X-Amz-Date")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Date", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Security-Token")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Security-Token", valid_600159
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600160 = header.getOrDefault("X-Amz-Target")
  valid_600160 = validateParameter(valid_600160, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_600160 != nil:
    section.add "X-Amz-Target", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Content-Sha256", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Algorithm")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Algorithm", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Signature")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Signature", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-SignedHeaders", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Credential")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Credential", valid_600165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600167: Call_DeleteRemoteAccessSession_600155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_600167.validator(path, query, header, formData, body)
  let scheme = call_600167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600167.url(scheme.get, call_600167.host, call_600167.base,
                         call_600167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600167, url, valid)

proc call*(call_600168: Call_DeleteRemoteAccessSession_600155; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_600169 = newJObject()
  if body != nil:
    body_600169 = body
  result = call_600168.call(nil, nil, nil, nil, body_600169)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_600155(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_600156, base: "/",
    url: url_DeleteRemoteAccessSession_600157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_600170 = ref object of OpenApiRestCall_599369
proc url_DeleteRun_600172(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_600171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600173 = header.getOrDefault("X-Amz-Date")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Date", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Security-Token")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Security-Token", valid_600174
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600175 = header.getOrDefault("X-Amz-Target")
  valid_600175 = validateParameter(valid_600175, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_600175 != nil:
    section.add "X-Amz-Target", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Content-Sha256", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Algorithm")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Algorithm", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Signature")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Signature", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-SignedHeaders", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Credential")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Credential", valid_600180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600182: Call_DeleteRun_600170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_600182.validator(path, query, header, formData, body)
  let scheme = call_600182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600182.url(scheme.get, call_600182.host, call_600182.base,
                         call_600182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600182, url, valid)

proc call*(call_600183: Call_DeleteRun_600170; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_600184 = newJObject()
  if body != nil:
    body_600184 = body
  result = call_600183.call(nil, nil, nil, nil, body_600184)

var deleteRun* = Call_DeleteRun_600170(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_600171,
                                    base: "/", url: url_DeleteRun_600172,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTestGridProject_600185 = ref object of OpenApiRestCall_599369
proc url_DeleteTestGridProject_600187(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTestGridProject_600186(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600188 = header.getOrDefault("X-Amz-Date")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Date", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Security-Token")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Security-Token", valid_600189
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600190 = header.getOrDefault("X-Amz-Target")
  valid_600190 = validateParameter(valid_600190, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteTestGridProject"))
  if valid_600190 != nil:
    section.add "X-Amz-Target", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Content-Sha256", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Algorithm")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Algorithm", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Signature")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Signature", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-SignedHeaders", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Credential")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Credential", valid_600195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600197: Call_DeleteTestGridProject_600185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_DeleteTestGridProject_600185; body: JsonNode): Recallable =
  ## deleteTestGridProject
  ## <p> Deletes a Selenium testing project and all content generated under it. </p> <important> <p>You cannot undo this operation.</p> </important> <note> <p>You cannot delete a project if it has active sessions.</p> </note>
  ##   body: JObject (required)
  var body_600199 = newJObject()
  if body != nil:
    body_600199 = body
  result = call_600198.call(nil, nil, nil, nil, body_600199)

var deleteTestGridProject* = Call_DeleteTestGridProject_600185(
    name: "deleteTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteTestGridProject",
    validator: validate_DeleteTestGridProject_600186, base: "/",
    url: url_DeleteTestGridProject_600187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_600200 = ref object of OpenApiRestCall_599369
proc url_DeleteUpload_600202(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUpload_600201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600205 = header.getOrDefault("X-Amz-Target")
  valid_600205 = validateParameter(valid_600205, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_600205 != nil:
    section.add "X-Amz-Target", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Content-Sha256", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Algorithm")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Algorithm", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Signature")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Signature", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-SignedHeaders", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Credential")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Credential", valid_600210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600212: Call_DeleteUpload_600200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_DeleteUpload_600200; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_600214 = newJObject()
  if body != nil:
    body_600214 = body
  result = call_600213.call(nil, nil, nil, nil, body_600214)

var deleteUpload* = Call_DeleteUpload_600200(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_600201, base: "/", url: url_DeleteUpload_600202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_600215 = ref object of OpenApiRestCall_599369
proc url_DeleteVPCEConfiguration_600217(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVPCEConfiguration_600216(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600218 = header.getOrDefault("X-Amz-Date")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Date", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Security-Token")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Security-Token", valid_600219
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600220 = header.getOrDefault("X-Amz-Target")
  valid_600220 = validateParameter(valid_600220, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_600220 != nil:
    section.add "X-Amz-Target", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Content-Sha256", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Algorithm")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Algorithm", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Signature")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Signature", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-SignedHeaders", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Credential")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Credential", valid_600225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600227: Call_DeleteVPCEConfiguration_600215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600227.validator(path, query, header, formData, body)
  let scheme = call_600227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600227.url(scheme.get, call_600227.host, call_600227.base,
                         call_600227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600227, url, valid)

proc call*(call_600228: Call_DeleteVPCEConfiguration_600215; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600229 = newJObject()
  if body != nil:
    body_600229 = body
  result = call_600228.call(nil, nil, nil, nil, body_600229)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_600215(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_600216, base: "/",
    url: url_DeleteVPCEConfiguration_600217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_600230 = ref object of OpenApiRestCall_599369
proc url_GetAccountSettings_600232(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_600231(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600233 = header.getOrDefault("X-Amz-Date")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Date", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Security-Token")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Security-Token", valid_600234
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600235 = header.getOrDefault("X-Amz-Target")
  valid_600235 = validateParameter(valid_600235, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_600235 != nil:
    section.add "X-Amz-Target", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Content-Sha256", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Algorithm")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Algorithm", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Signature")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Signature", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-SignedHeaders", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Credential")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Credential", valid_600240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600242: Call_GetAccountSettings_600230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_600242.validator(path, query, header, formData, body)
  let scheme = call_600242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600242.url(scheme.get, call_600242.host, call_600242.base,
                         call_600242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600242, url, valid)

proc call*(call_600243: Call_GetAccountSettings_600230; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_600244 = newJObject()
  if body != nil:
    body_600244 = body
  result = call_600243.call(nil, nil, nil, nil, body_600244)

var getAccountSettings* = Call_GetAccountSettings_600230(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_600231, base: "/",
    url: url_GetAccountSettings_600232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_600245 = ref object of OpenApiRestCall_599369
proc url_GetDevice_600247(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_600246(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600248 = header.getOrDefault("X-Amz-Date")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Date", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Security-Token")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Security-Token", valid_600249
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600250 = header.getOrDefault("X-Amz-Target")
  valid_600250 = validateParameter(valid_600250, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_600250 != nil:
    section.add "X-Amz-Target", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Content-Sha256", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Algorithm")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Algorithm", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Signature")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Signature", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-SignedHeaders", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Credential")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Credential", valid_600255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600257: Call_GetDevice_600245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_600257.validator(path, query, header, formData, body)
  let scheme = call_600257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600257.url(scheme.get, call_600257.host, call_600257.base,
                         call_600257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600257, url, valid)

proc call*(call_600258: Call_GetDevice_600245; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_600259 = newJObject()
  if body != nil:
    body_600259 = body
  result = call_600258.call(nil, nil, nil, nil, body_600259)

var getDevice* = Call_GetDevice_600245(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_600246,
                                    base: "/", url: url_GetDevice_600247,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_600260 = ref object of OpenApiRestCall_599369
proc url_GetDeviceInstance_600262(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeviceInstance_600261(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600263 = header.getOrDefault("X-Amz-Date")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Date", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Security-Token")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Security-Token", valid_600264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600265 = header.getOrDefault("X-Amz-Target")
  valid_600265 = validateParameter(valid_600265, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_600265 != nil:
    section.add "X-Amz-Target", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Content-Sha256", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Algorithm")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Algorithm", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Signature")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Signature", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-SignedHeaders", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Credential")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Credential", valid_600270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600272: Call_GetDeviceInstance_600260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance that belongs to a private device fleet.
  ## 
  let valid = call_600272.validator(path, query, header, formData, body)
  let scheme = call_600272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600272.url(scheme.get, call_600272.host, call_600272.base,
                         call_600272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600272, url, valid)

proc call*(call_600273: Call_GetDeviceInstance_600260; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance that belongs to a private device fleet.
  ##   body: JObject (required)
  var body_600274 = newJObject()
  if body != nil:
    body_600274 = body
  result = call_600273.call(nil, nil, nil, nil, body_600274)

var getDeviceInstance* = Call_GetDeviceInstance_600260(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_600261, base: "/",
    url: url_GetDeviceInstance_600262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_600275 = ref object of OpenApiRestCall_599369
proc url_GetDevicePool_600277(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePool_600276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600280 = header.getOrDefault("X-Amz-Target")
  valid_600280 = validateParameter(valid_600280, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_600280 != nil:
    section.add "X-Amz-Target", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Content-Sha256", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Algorithm")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Algorithm", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Signature")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Signature", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-SignedHeaders", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Credential")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Credential", valid_600285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600287: Call_GetDevicePool_600275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_GetDevicePool_600275; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_600289 = newJObject()
  if body != nil:
    body_600289 = body
  result = call_600288.call(nil, nil, nil, nil, body_600289)

var getDevicePool* = Call_GetDevicePool_600275(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_600276, base: "/", url: url_GetDevicePool_600277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_600290 = ref object of OpenApiRestCall_599369
proc url_GetDevicePoolCompatibility_600292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_600291(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600295 = header.getOrDefault("X-Amz-Target")
  valid_600295 = validateParameter(valid_600295, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_600295 != nil:
    section.add "X-Amz-Target", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Content-Sha256", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Algorithm")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Algorithm", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Signature")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Signature", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-SignedHeaders", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Credential")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Credential", valid_600300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600302: Call_GetDevicePoolCompatibility_600290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_GetDevicePoolCompatibility_600290; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_600304 = newJObject()
  if body != nil:
    body_600304 = body
  result = call_600303.call(nil, nil, nil, nil, body_600304)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_600290(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_600291, base: "/",
    url: url_GetDevicePoolCompatibility_600292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_600305 = ref object of OpenApiRestCall_599369
proc url_GetInstanceProfile_600307(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceProfile_600306(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600310 = header.getOrDefault("X-Amz-Target")
  valid_600310 = validateParameter(valid_600310, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_600310 != nil:
    section.add "X-Amz-Target", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Content-Sha256", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Algorithm")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Algorithm", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Signature")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Signature", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-SignedHeaders", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Credential")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Credential", valid_600315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600317: Call_GetInstanceProfile_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_600317.validator(path, query, header, formData, body)
  let scheme = call_600317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600317.url(scheme.get, call_600317.host, call_600317.base,
                         call_600317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600317, url, valid)

proc call*(call_600318: Call_GetInstanceProfile_600305; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_600319 = newJObject()
  if body != nil:
    body_600319 = body
  result = call_600318.call(nil, nil, nil, nil, body_600319)

var getInstanceProfile* = Call_GetInstanceProfile_600305(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_600306, base: "/",
    url: url_GetInstanceProfile_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_600320 = ref object of OpenApiRestCall_599369
proc url_GetJob_600322(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_600321(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600325 = header.getOrDefault("X-Amz-Target")
  valid_600325 = validateParameter(valid_600325, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_600325 != nil:
    section.add "X-Amz-Target", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Content-Sha256", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Algorithm")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Algorithm", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Signature")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Signature", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-SignedHeaders", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Credential")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Credential", valid_600330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_GetJob_600320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_GetJob_600320; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_600334 = newJObject()
  if body != nil:
    body_600334 = body
  result = call_600333.call(nil, nil, nil, nil, body_600334)

var getJob* = Call_GetJob_600320(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_600321, base: "/",
                              url: url_GetJob_600322,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_600335 = ref object of OpenApiRestCall_599369
proc url_GetNetworkProfile_600337(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_600336(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600338 = header.getOrDefault("X-Amz-Date")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Date", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Security-Token")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Security-Token", valid_600339
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600340 = header.getOrDefault("X-Amz-Target")
  valid_600340 = validateParameter(valid_600340, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_600340 != nil:
    section.add "X-Amz-Target", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Content-Sha256", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Algorithm")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Algorithm", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Signature")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Signature", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-SignedHeaders", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Credential")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Credential", valid_600345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_GetNetworkProfile_600335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_GetNetworkProfile_600335; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_600349 = newJObject()
  if body != nil:
    body_600349 = body
  result = call_600348.call(nil, nil, nil, nil, body_600349)

var getNetworkProfile* = Call_GetNetworkProfile_600335(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_600336, base: "/",
    url: url_GetNetworkProfile_600337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_600350 = ref object of OpenApiRestCall_599369
proc url_GetOfferingStatus_600352(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOfferingStatus_600351(path: JsonNode; query: JsonNode;
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
  var valid_600353 = query.getOrDefault("nextToken")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "nextToken", valid_600353
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
  var valid_600354 = header.getOrDefault("X-Amz-Date")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Date", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Security-Token")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Security-Token", valid_600355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600356 = header.getOrDefault("X-Amz-Target")
  valid_600356 = validateParameter(valid_600356, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_600356 != nil:
    section.add "X-Amz-Target", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Content-Sha256", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Algorithm")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Algorithm", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Signature")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Signature", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-SignedHeaders", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Credential")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Credential", valid_600361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600363: Call_GetOfferingStatus_600350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_600363.validator(path, query, header, formData, body)
  let scheme = call_600363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600363.url(scheme.get, call_600363.host, call_600363.base,
                         call_600363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600363, url, valid)

proc call*(call_600364: Call_GetOfferingStatus_600350; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600365 = newJObject()
  var body_600366 = newJObject()
  add(query_600365, "nextToken", newJString(nextToken))
  if body != nil:
    body_600366 = body
  result = call_600364.call(nil, query_600365, nil, nil, body_600366)

var getOfferingStatus* = Call_GetOfferingStatus_600350(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_600351, base: "/",
    url: url_GetOfferingStatus_600352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_600368 = ref object of OpenApiRestCall_599369
proc url_GetProject_600370(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_600369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600373 = header.getOrDefault("X-Amz-Target")
  valid_600373 = validateParameter(valid_600373, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_600373 != nil:
    section.add "X-Amz-Target", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600380: Call_GetProject_600368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_GetProject_600368; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_600382 = newJObject()
  if body != nil:
    body_600382 = body
  result = call_600381.call(nil, nil, nil, nil, body_600382)

var getProject* = Call_GetProject_600368(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_600369,
                                      base: "/", url: url_GetProject_600370,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_600383 = ref object of OpenApiRestCall_599369
proc url_GetRemoteAccessSession_600385(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoteAccessSession_600384(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600386 = header.getOrDefault("X-Amz-Date")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Date", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Security-Token")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Security-Token", valid_600387
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600388 = header.getOrDefault("X-Amz-Target")
  valid_600388 = validateParameter(valid_600388, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_600388 != nil:
    section.add "X-Amz-Target", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Content-Sha256", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Algorithm")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Algorithm", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Signature")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Signature", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-SignedHeaders", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Credential")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Credential", valid_600393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600395: Call_GetRemoteAccessSession_600383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_GetRemoteAccessSession_600383; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_600397 = newJObject()
  if body != nil:
    body_600397 = body
  result = call_600396.call(nil, nil, nil, nil, body_600397)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_600383(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_600384, base: "/",
    url: url_GetRemoteAccessSession_600385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_600398 = ref object of OpenApiRestCall_599369
proc url_GetRun_600400(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_600399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600401 = header.getOrDefault("X-Amz-Date")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Date", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Security-Token")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Security-Token", valid_600402
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600403 = header.getOrDefault("X-Amz-Target")
  valid_600403 = validateParameter(valid_600403, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_600403 != nil:
    section.add "X-Amz-Target", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Content-Sha256", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Algorithm")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Algorithm", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Signature")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Signature", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-SignedHeaders", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Credential")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Credential", valid_600408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600410: Call_GetRun_600398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_600410.validator(path, query, header, formData, body)
  let scheme = call_600410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600410.url(scheme.get, call_600410.host, call_600410.base,
                         call_600410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600410, url, valid)

proc call*(call_600411: Call_GetRun_600398; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_600412 = newJObject()
  if body != nil:
    body_600412 = body
  result = call_600411.call(nil, nil, nil, nil, body_600412)

var getRun* = Call_GetRun_600398(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_600399, base: "/",
                              url: url_GetRun_600400,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_600413 = ref object of OpenApiRestCall_599369
proc url_GetSuite_600415(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_600414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600416 = header.getOrDefault("X-Amz-Date")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Date", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Security-Token")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Security-Token", valid_600417
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600418 = header.getOrDefault("X-Amz-Target")
  valid_600418 = validateParameter(valid_600418, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_600418 != nil:
    section.add "X-Amz-Target", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Content-Sha256", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Algorithm")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Algorithm", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Signature")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Signature", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-SignedHeaders", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Credential")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Credential", valid_600423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600425: Call_GetSuite_600413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_600425.validator(path, query, header, formData, body)
  let scheme = call_600425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600425.url(scheme.get, call_600425.host, call_600425.base,
                         call_600425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600425, url, valid)

proc call*(call_600426: Call_GetSuite_600413; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_600427 = newJObject()
  if body != nil:
    body_600427 = body
  result = call_600426.call(nil, nil, nil, nil, body_600427)

var getSuite* = Call_GetSuite_600413(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_600414, base: "/",
                                  url: url_GetSuite_600415,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_600428 = ref object of OpenApiRestCall_599369
proc url_GetTest_600430(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_600429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600431 = header.getOrDefault("X-Amz-Date")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Date", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Security-Token")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Security-Token", valid_600432
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600433 = header.getOrDefault("X-Amz-Target")
  valid_600433 = validateParameter(valid_600433, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_600433 != nil:
    section.add "X-Amz-Target", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Content-Sha256", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Algorithm")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Algorithm", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Signature")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Signature", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-SignedHeaders", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Credential")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Credential", valid_600438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600440: Call_GetTest_600428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_GetTest_600428; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_600442 = newJObject()
  if body != nil:
    body_600442 = body
  result = call_600441.call(nil, nil, nil, nil, body_600442)

var getTest* = Call_GetTest_600428(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_600429, base: "/",
                                url: url_GetTest_600430,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridProject_600443 = ref object of OpenApiRestCall_599369
proc url_GetTestGridProject_600445(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridProject_600444(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600446 = header.getOrDefault("X-Amz-Date")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Date", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Security-Token")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Security-Token", valid_600447
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600448 = header.getOrDefault("X-Amz-Target")
  valid_600448 = validateParameter(valid_600448, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridProject"))
  if valid_600448 != nil:
    section.add "X-Amz-Target", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Content-Sha256", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Algorithm")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Algorithm", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Signature")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Signature", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-SignedHeaders", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Credential")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Credential", valid_600453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600455: Call_GetTestGridProject_600443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Selenium testing project.
  ## 
  let valid = call_600455.validator(path, query, header, formData, body)
  let scheme = call_600455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600455.url(scheme.get, call_600455.host, call_600455.base,
                         call_600455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600455, url, valid)

proc call*(call_600456: Call_GetTestGridProject_600443; body: JsonNode): Recallable =
  ## getTestGridProject
  ## Retrieves information about a Selenium testing project.
  ##   body: JObject (required)
  var body_600457 = newJObject()
  if body != nil:
    body_600457 = body
  result = call_600456.call(nil, nil, nil, nil, body_600457)

var getTestGridProject* = Call_GetTestGridProject_600443(
    name: "getTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridProject",
    validator: validate_GetTestGridProject_600444, base: "/",
    url: url_GetTestGridProject_600445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTestGridSession_600458 = ref object of OpenApiRestCall_599369
proc url_GetTestGridSession_600460(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTestGridSession_600459(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600461 = header.getOrDefault("X-Amz-Date")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Date", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Security-Token")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Security-Token", valid_600462
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600463 = header.getOrDefault("X-Amz-Target")
  valid_600463 = validateParameter(valid_600463, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTestGridSession"))
  if valid_600463 != nil:
    section.add "X-Amz-Target", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Content-Sha256", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Algorithm")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Algorithm", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Signature")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Signature", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-SignedHeaders", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Credential")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Credential", valid_600468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600470: Call_GetTestGridSession_600458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ## 
  let valid = call_600470.validator(path, query, header, formData, body)
  let scheme = call_600470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600470.url(scheme.get, call_600470.host, call_600470.base,
                         call_600470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600470, url, valid)

proc call*(call_600471: Call_GetTestGridSession_600458; body: JsonNode): Recallable =
  ## getTestGridSession
  ## <p>A session is an instance of a browser created through a <code>RemoteWebDriver</code> with the URL from <a>CreateTestGridUrlResult$url</a>. You can use the following to look up sessions:</p> <ul> <li> <p>The session ARN (<a>GetTestGridSessionRequest$sessionArn</a>).</p> </li> <li> <p>The project ARN and a session ID (<a>GetTestGridSessionRequest$projectArn</a> and <a>GetTestGridSessionRequest$sessionId</a>).</p> </li> </ul> <p/>
  ##   body: JObject (required)
  var body_600472 = newJObject()
  if body != nil:
    body_600472 = body
  result = call_600471.call(nil, nil, nil, nil, body_600472)

var getTestGridSession* = Call_GetTestGridSession_600458(
    name: "getTestGridSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetTestGridSession",
    validator: validate_GetTestGridSession_600459, base: "/",
    url: url_GetTestGridSession_600460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_600473 = ref object of OpenApiRestCall_599369
proc url_GetUpload_600475(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_600474(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600476 = header.getOrDefault("X-Amz-Date")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Date", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Security-Token")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Security-Token", valid_600477
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600478 = header.getOrDefault("X-Amz-Target")
  valid_600478 = validateParameter(valid_600478, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_600478 != nil:
    section.add "X-Amz-Target", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Content-Sha256", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Algorithm")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Algorithm", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Signature")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Signature", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-SignedHeaders", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Credential")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Credential", valid_600483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600485: Call_GetUpload_600473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_600485.validator(path, query, header, formData, body)
  let scheme = call_600485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600485.url(scheme.get, call_600485.host, call_600485.base,
                         call_600485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600485, url, valid)

proc call*(call_600486: Call_GetUpload_600473; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_600487 = newJObject()
  if body != nil:
    body_600487 = body
  result = call_600486.call(nil, nil, nil, nil, body_600487)

var getUpload* = Call_GetUpload_600473(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_600474,
                                    base: "/", url: url_GetUpload_600475,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_600488 = ref object of OpenApiRestCall_599369
proc url_GetVPCEConfiguration_600490(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVPCEConfiguration_600489(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600491 = header.getOrDefault("X-Amz-Date")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Date", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Security-Token")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Security-Token", valid_600492
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600493 = header.getOrDefault("X-Amz-Target")
  valid_600493 = validateParameter(valid_600493, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_600493 != nil:
    section.add "X-Amz-Target", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Content-Sha256", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Algorithm")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Algorithm", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-Signature")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Signature", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-SignedHeaders", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Credential")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Credential", valid_600498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600500: Call_GetVPCEConfiguration_600488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600500.validator(path, query, header, formData, body)
  let scheme = call_600500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600500.url(scheme.get, call_600500.host, call_600500.base,
                         call_600500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600500, url, valid)

proc call*(call_600501: Call_GetVPCEConfiguration_600488; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600502 = newJObject()
  if body != nil:
    body_600502 = body
  result = call_600501.call(nil, nil, nil, nil, body_600502)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_600488(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_600489, base: "/",
    url: url_GetVPCEConfiguration_600490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_600503 = ref object of OpenApiRestCall_599369
proc url_InstallToRemoteAccessSession_600505(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_600504(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600506 = header.getOrDefault("X-Amz-Date")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Date", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Security-Token")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Security-Token", valid_600507
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600508 = header.getOrDefault("X-Amz-Target")
  valid_600508 = validateParameter(valid_600508, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_600508 != nil:
    section.add "X-Amz-Target", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Content-Sha256", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Algorithm")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Algorithm", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Signature")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Signature", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-SignedHeaders", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Credential")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Credential", valid_600513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600515: Call_InstallToRemoteAccessSession_600503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_600515.validator(path, query, header, formData, body)
  let scheme = call_600515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600515.url(scheme.get, call_600515.host, call_600515.base,
                         call_600515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600515, url, valid)

proc call*(call_600516: Call_InstallToRemoteAccessSession_600503; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_600517 = newJObject()
  if body != nil:
    body_600517 = body
  result = call_600516.call(nil, nil, nil, nil, body_600517)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_600503(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_600504, base: "/",
    url: url_InstallToRemoteAccessSession_600505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_600518 = ref object of OpenApiRestCall_599369
proc url_ListArtifacts_600520(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListArtifacts_600519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600521 = query.getOrDefault("nextToken")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "nextToken", valid_600521
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
  var valid_600522 = header.getOrDefault("X-Amz-Date")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Date", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Security-Token")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Security-Token", valid_600523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600524 = header.getOrDefault("X-Amz-Target")
  valid_600524 = validateParameter(valid_600524, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_600524 != nil:
    section.add "X-Amz-Target", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Content-Sha256", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Algorithm")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Algorithm", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Signature")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Signature", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-SignedHeaders", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Credential")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Credential", valid_600529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600531: Call_ListArtifacts_600518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_600531.validator(path, query, header, formData, body)
  let scheme = call_600531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600531.url(scheme.get, call_600531.host, call_600531.base,
                         call_600531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600531, url, valid)

proc call*(call_600532: Call_ListArtifacts_600518; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600533 = newJObject()
  var body_600534 = newJObject()
  add(query_600533, "nextToken", newJString(nextToken))
  if body != nil:
    body_600534 = body
  result = call_600532.call(nil, query_600533, nil, nil, body_600534)

var listArtifacts* = Call_ListArtifacts_600518(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_600519, base: "/", url: url_ListArtifacts_600520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_600535 = ref object of OpenApiRestCall_599369
proc url_ListDeviceInstances_600537(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceInstances_600536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600538 = header.getOrDefault("X-Amz-Date")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Date", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Security-Token")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Security-Token", valid_600539
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600540 = header.getOrDefault("X-Amz-Target")
  valid_600540 = validateParameter(valid_600540, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_600540 != nil:
    section.add "X-Amz-Target", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Content-Sha256", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Algorithm")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Algorithm", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Signature")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Signature", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-SignedHeaders", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Credential")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Credential", valid_600545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600547: Call_ListDeviceInstances_600535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_600547.validator(path, query, header, formData, body)
  let scheme = call_600547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600547.url(scheme.get, call_600547.host, call_600547.base,
                         call_600547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600547, url, valid)

proc call*(call_600548: Call_ListDeviceInstances_600535; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_600549 = newJObject()
  if body != nil:
    body_600549 = body
  result = call_600548.call(nil, nil, nil, nil, body_600549)

var listDeviceInstances* = Call_ListDeviceInstances_600535(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_600536, base: "/",
    url: url_ListDeviceInstances_600537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_600550 = ref object of OpenApiRestCall_599369
proc url_ListDevicePools_600552(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevicePools_600551(path: JsonNode; query: JsonNode;
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
  var valid_600553 = query.getOrDefault("nextToken")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "nextToken", valid_600553
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
  var valid_600554 = header.getOrDefault("X-Amz-Date")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Date", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Security-Token")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Security-Token", valid_600555
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600556 = header.getOrDefault("X-Amz-Target")
  valid_600556 = validateParameter(valid_600556, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_600556 != nil:
    section.add "X-Amz-Target", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Content-Sha256", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Algorithm")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Algorithm", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Signature")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Signature", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-SignedHeaders", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Credential")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Credential", valid_600561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600563: Call_ListDevicePools_600550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_600563.validator(path, query, header, formData, body)
  let scheme = call_600563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600563.url(scheme.get, call_600563.host, call_600563.base,
                         call_600563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600563, url, valid)

proc call*(call_600564: Call_ListDevicePools_600550; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600565 = newJObject()
  var body_600566 = newJObject()
  add(query_600565, "nextToken", newJString(nextToken))
  if body != nil:
    body_600566 = body
  result = call_600564.call(nil, query_600565, nil, nil, body_600566)

var listDevicePools* = Call_ListDevicePools_600550(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_600551, base: "/", url: url_ListDevicePools_600552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_600567 = ref object of OpenApiRestCall_599369
proc url_ListDevices_600569(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_600568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600570 = query.getOrDefault("nextToken")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "nextToken", valid_600570
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
  var valid_600571 = header.getOrDefault("X-Amz-Date")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Date", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Security-Token")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Security-Token", valid_600572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600573 = header.getOrDefault("X-Amz-Target")
  valid_600573 = validateParameter(valid_600573, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_600573 != nil:
    section.add "X-Amz-Target", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Content-Sha256", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Algorithm")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Algorithm", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Signature")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Signature", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-SignedHeaders", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Credential")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Credential", valid_600578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600580: Call_ListDevices_600567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_600580.validator(path, query, header, formData, body)
  let scheme = call_600580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600580.url(scheme.get, call_600580.host, call_600580.base,
                         call_600580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600580, url, valid)

proc call*(call_600581: Call_ListDevices_600567; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600582 = newJObject()
  var body_600583 = newJObject()
  add(query_600582, "nextToken", newJString(nextToken))
  if body != nil:
    body_600583 = body
  result = call_600581.call(nil, query_600582, nil, nil, body_600583)

var listDevices* = Call_ListDevices_600567(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_600568,
                                        base: "/", url: url_ListDevices_600569,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_600584 = ref object of OpenApiRestCall_599369
proc url_ListInstanceProfiles_600586(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstanceProfiles_600585(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600587 = header.getOrDefault("X-Amz-Date")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Date", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Security-Token")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Security-Token", valid_600588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600589 = header.getOrDefault("X-Amz-Target")
  valid_600589 = validateParameter(valid_600589, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_600589 != nil:
    section.add "X-Amz-Target", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Content-Sha256", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Algorithm")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Algorithm", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Signature")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Signature", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-SignedHeaders", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Credential")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Credential", valid_600594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600596: Call_ListInstanceProfiles_600584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_ListInstanceProfiles_600584; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_600598 = newJObject()
  if body != nil:
    body_600598 = body
  result = call_600597.call(nil, nil, nil, nil, body_600598)

var listInstanceProfiles* = Call_ListInstanceProfiles_600584(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_600585, base: "/",
    url: url_ListInstanceProfiles_600586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600599 = ref object of OpenApiRestCall_599369
proc url_ListJobs_600601(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_600600(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600602 = query.getOrDefault("nextToken")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "nextToken", valid_600602
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
  var valid_600603 = header.getOrDefault("X-Amz-Date")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Date", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Security-Token")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Security-Token", valid_600604
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600605 = header.getOrDefault("X-Amz-Target")
  valid_600605 = validateParameter(valid_600605, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_600605 != nil:
    section.add "X-Amz-Target", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Content-Sha256", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Algorithm")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Algorithm", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Signature")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Signature", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-SignedHeaders", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Credential")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Credential", valid_600610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600612: Call_ListJobs_600599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_600612.validator(path, query, header, formData, body)
  let scheme = call_600612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600612.url(scheme.get, call_600612.host, call_600612.base,
                         call_600612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600612, url, valid)

proc call*(call_600613: Call_ListJobs_600599; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600614 = newJObject()
  var body_600615 = newJObject()
  add(query_600614, "nextToken", newJString(nextToken))
  if body != nil:
    body_600615 = body
  result = call_600613.call(nil, query_600614, nil, nil, body_600615)

var listJobs* = Call_ListJobs_600599(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_600600, base: "/",
                                  url: url_ListJobs_600601,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_600616 = ref object of OpenApiRestCall_599369
proc url_ListNetworkProfiles_600618(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworkProfiles_600617(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600619 = header.getOrDefault("X-Amz-Date")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Date", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Security-Token")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Security-Token", valid_600620
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600621 = header.getOrDefault("X-Amz-Target")
  valid_600621 = validateParameter(valid_600621, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_600621 != nil:
    section.add "X-Amz-Target", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Content-Sha256", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Algorithm")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Algorithm", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Signature")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Signature", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-SignedHeaders", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Credential")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Credential", valid_600626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600628: Call_ListNetworkProfiles_600616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_600628.validator(path, query, header, formData, body)
  let scheme = call_600628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600628.url(scheme.get, call_600628.host, call_600628.base,
                         call_600628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600628, url, valid)

proc call*(call_600629: Call_ListNetworkProfiles_600616; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_600630 = newJObject()
  if body != nil:
    body_600630 = body
  result = call_600629.call(nil, nil, nil, nil, body_600630)

var listNetworkProfiles* = Call_ListNetworkProfiles_600616(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_600617, base: "/",
    url: url_ListNetworkProfiles_600618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_600631 = ref object of OpenApiRestCall_599369
proc url_ListOfferingPromotions_600633(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingPromotions_600632(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600634 = header.getOrDefault("X-Amz-Date")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Date", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Security-Token")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Security-Token", valid_600635
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600636 = header.getOrDefault("X-Amz-Target")
  valid_600636 = validateParameter(valid_600636, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_600636 != nil:
    section.add "X-Amz-Target", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Content-Sha256", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Algorithm")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Algorithm", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Signature")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Signature", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-SignedHeaders", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Credential")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Credential", valid_600641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600643: Call_ListOfferingPromotions_600631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ## 
  let valid = call_600643.validator(path, query, header, formData, body)
  let scheme = call_600643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600643.url(scheme.get, call_600643.host, call_600643.base,
                         call_600643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600643, url, valid)

proc call*(call_600644: Call_ListOfferingPromotions_600631; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you must be able to invoke this operation.
  ##   body: JObject (required)
  var body_600645 = newJObject()
  if body != nil:
    body_600645 = body
  result = call_600644.call(nil, nil, nil, nil, body_600645)

var listOfferingPromotions* = Call_ListOfferingPromotions_600631(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_600632, base: "/",
    url: url_ListOfferingPromotions_600633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_600646 = ref object of OpenApiRestCall_599369
proc url_ListOfferingTransactions_600648(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingTransactions_600647(path: JsonNode; query: JsonNode;
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
  var valid_600649 = query.getOrDefault("nextToken")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "nextToken", valid_600649
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
  var valid_600650 = header.getOrDefault("X-Amz-Date")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Date", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Security-Token")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Security-Token", valid_600651
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600652 = header.getOrDefault("X-Amz-Target")
  valid_600652 = validateParameter(valid_600652, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_600652 != nil:
    section.add "X-Amz-Target", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Content-Sha256", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Algorithm")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Algorithm", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Signature")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Signature", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-SignedHeaders", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Credential")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Credential", valid_600657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600659: Call_ListOfferingTransactions_600646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_600659.validator(path, query, header, formData, body)
  let scheme = call_600659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600659.url(scheme.get, call_600659.host, call_600659.base,
                         call_600659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600659, url, valid)

proc call*(call_600660: Call_ListOfferingTransactions_600646; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600661 = newJObject()
  var body_600662 = newJObject()
  add(query_600661, "nextToken", newJString(nextToken))
  if body != nil:
    body_600662 = body
  result = call_600660.call(nil, query_600661, nil, nil, body_600662)

var listOfferingTransactions* = Call_ListOfferingTransactions_600646(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_600647, base: "/",
    url: url_ListOfferingTransactions_600648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_600663 = ref object of OpenApiRestCall_599369
proc url_ListOfferings_600665(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_600664(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600666 = query.getOrDefault("nextToken")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "nextToken", valid_600666
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
  var valid_600667 = header.getOrDefault("X-Amz-Date")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Date", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Security-Token")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Security-Token", valid_600668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600669 = header.getOrDefault("X-Amz-Target")
  valid_600669 = validateParameter(valid_600669, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_600669 != nil:
    section.add "X-Amz-Target", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Content-Sha256", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Algorithm")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Algorithm", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Signature")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Signature", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-SignedHeaders", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Credential")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Credential", valid_600674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600676: Call_ListOfferings_600663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_600676.validator(path, query, header, formData, body)
  let scheme = call_600676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600676.url(scheme.get, call_600676.host, call_600676.base,
                         call_600676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600676, url, valid)

proc call*(call_600677: Call_ListOfferings_600663; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600678 = newJObject()
  var body_600679 = newJObject()
  add(query_600678, "nextToken", newJString(nextToken))
  if body != nil:
    body_600679 = body
  result = call_600677.call(nil, query_600678, nil, nil, body_600679)

var listOfferings* = Call_ListOfferings_600663(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_600664, base: "/", url: url_ListOfferings_600665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_600680 = ref object of OpenApiRestCall_599369
proc url_ListProjects_600682(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_600681(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600683 = query.getOrDefault("nextToken")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "nextToken", valid_600683
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
  var valid_600684 = header.getOrDefault("X-Amz-Date")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Date", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Security-Token")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Security-Token", valid_600685
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600686 = header.getOrDefault("X-Amz-Target")
  valid_600686 = validateParameter(valid_600686, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_600686 != nil:
    section.add "X-Amz-Target", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Content-Sha256", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Algorithm")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Algorithm", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Signature")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Signature", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-SignedHeaders", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Credential")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Credential", valid_600691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600693: Call_ListProjects_600680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_600693.validator(path, query, header, formData, body)
  let scheme = call_600693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600693.url(scheme.get, call_600693.host, call_600693.base,
                         call_600693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600693, url, valid)

proc call*(call_600694: Call_ListProjects_600680; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600695 = newJObject()
  var body_600696 = newJObject()
  add(query_600695, "nextToken", newJString(nextToken))
  if body != nil:
    body_600696 = body
  result = call_600694.call(nil, query_600695, nil, nil, body_600696)

var listProjects* = Call_ListProjects_600680(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_600681, base: "/", url: url_ListProjects_600682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_600697 = ref object of OpenApiRestCall_599369
proc url_ListRemoteAccessSessions_600699(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRemoteAccessSessions_600698(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600700 = header.getOrDefault("X-Amz-Date")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Date", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Security-Token")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Security-Token", valid_600701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600702 = header.getOrDefault("X-Amz-Target")
  valid_600702 = validateParameter(valid_600702, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_600702 != nil:
    section.add "X-Amz-Target", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Content-Sha256", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Algorithm")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Algorithm", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Signature")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Signature", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-SignedHeaders", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Credential")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Credential", valid_600707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600709: Call_ListRemoteAccessSessions_600697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_600709.validator(path, query, header, formData, body)
  let scheme = call_600709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600709.url(scheme.get, call_600709.host, call_600709.base,
                         call_600709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600709, url, valid)

proc call*(call_600710: Call_ListRemoteAccessSessions_600697; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_600711 = newJObject()
  if body != nil:
    body_600711 = body
  result = call_600710.call(nil, nil, nil, nil, body_600711)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_600697(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_600698, base: "/",
    url: url_ListRemoteAccessSessions_600699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_600712 = ref object of OpenApiRestCall_599369
proc url_ListRuns_600714(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_600713(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600715 = query.getOrDefault("nextToken")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "nextToken", valid_600715
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
  var valid_600716 = header.getOrDefault("X-Amz-Date")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Date", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Security-Token")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Security-Token", valid_600717
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600718 = header.getOrDefault("X-Amz-Target")
  valid_600718 = validateParameter(valid_600718, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_600718 != nil:
    section.add "X-Amz-Target", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Content-Sha256", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Algorithm")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Algorithm", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Signature")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Signature", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-SignedHeaders", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Credential")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Credential", valid_600723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600725: Call_ListRuns_600712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_600725.validator(path, query, header, formData, body)
  let scheme = call_600725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600725.url(scheme.get, call_600725.host, call_600725.base,
                         call_600725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600725, url, valid)

proc call*(call_600726: Call_ListRuns_600712; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600727 = newJObject()
  var body_600728 = newJObject()
  add(query_600727, "nextToken", newJString(nextToken))
  if body != nil:
    body_600728 = body
  result = call_600726.call(nil, query_600727, nil, nil, body_600728)

var listRuns* = Call_ListRuns_600712(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_600713, base: "/",
                                  url: url_ListRuns_600714,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_600729 = ref object of OpenApiRestCall_599369
proc url_ListSamples_600731(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSamples_600730(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600732 = query.getOrDefault("nextToken")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "nextToken", valid_600732
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
  var valid_600733 = header.getOrDefault("X-Amz-Date")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Date", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Security-Token")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Security-Token", valid_600734
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600735 = header.getOrDefault("X-Amz-Target")
  valid_600735 = validateParameter(valid_600735, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_600735 != nil:
    section.add "X-Amz-Target", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Content-Sha256", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Algorithm")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Algorithm", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Signature")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Signature", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-SignedHeaders", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Credential")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Credential", valid_600740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600742: Call_ListSamples_600729; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_600742.validator(path, query, header, formData, body)
  let scheme = call_600742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600742.url(scheme.get, call_600742.host, call_600742.base,
                         call_600742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600742, url, valid)

proc call*(call_600743: Call_ListSamples_600729; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600744 = newJObject()
  var body_600745 = newJObject()
  add(query_600744, "nextToken", newJString(nextToken))
  if body != nil:
    body_600745 = body
  result = call_600743.call(nil, query_600744, nil, nil, body_600745)

var listSamples* = Call_ListSamples_600729(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_600730,
                                        base: "/", url: url_ListSamples_600731,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_600746 = ref object of OpenApiRestCall_599369
proc url_ListSuites_600748(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_600747(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600749 = query.getOrDefault("nextToken")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "nextToken", valid_600749
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
  var valid_600750 = header.getOrDefault("X-Amz-Date")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Date", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Security-Token")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Security-Token", valid_600751
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600752 = header.getOrDefault("X-Amz-Target")
  valid_600752 = validateParameter(valid_600752, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_600752 != nil:
    section.add "X-Amz-Target", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Content-Sha256", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Algorithm")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Algorithm", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-Signature")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-Signature", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-SignedHeaders", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-Credential")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Credential", valid_600757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600759: Call_ListSuites_600746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_600759.validator(path, query, header, formData, body)
  let scheme = call_600759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600759.url(scheme.get, call_600759.host, call_600759.base,
                         call_600759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600759, url, valid)

proc call*(call_600760: Call_ListSuites_600746; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600761 = newJObject()
  var body_600762 = newJObject()
  add(query_600761, "nextToken", newJString(nextToken))
  if body != nil:
    body_600762 = body
  result = call_600760.call(nil, query_600761, nil, nil, body_600762)

var listSuites* = Call_ListSuites_600746(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_600747,
                                      base: "/", url: url_ListSuites_600748,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600763 = ref object of OpenApiRestCall_599369
proc url_ListTagsForResource_600765(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600764(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600766 = header.getOrDefault("X-Amz-Date")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Date", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Security-Token")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Security-Token", valid_600767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600768 = header.getOrDefault("X-Amz-Target")
  valid_600768 = validateParameter(valid_600768, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_600768 != nil:
    section.add "X-Amz-Target", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Content-Sha256", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Algorithm")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Algorithm", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Signature")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Signature", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-SignedHeaders", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Credential")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Credential", valid_600773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600775: Call_ListTagsForResource_600763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_600775.validator(path, query, header, formData, body)
  let scheme = call_600775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600775.url(scheme.get, call_600775.host, call_600775.base,
                         call_600775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600775, url, valid)

proc call*(call_600776: Call_ListTagsForResource_600763; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_600777 = newJObject()
  if body != nil:
    body_600777 = body
  result = call_600776.call(nil, nil, nil, nil, body_600777)

var listTagsForResource* = Call_ListTagsForResource_600763(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_600764, base: "/",
    url: url_ListTagsForResource_600765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridProjects_600778 = ref object of OpenApiRestCall_599369
proc url_ListTestGridProjects_600780(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridProjects_600779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600781 = query.getOrDefault("maxResult")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "maxResult", valid_600781
  var valid_600782 = query.getOrDefault("nextToken")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "nextToken", valid_600782
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
  var valid_600783 = header.getOrDefault("X-Amz-Date")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Date", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Security-Token")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Security-Token", valid_600784
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600785 = header.getOrDefault("X-Amz-Target")
  valid_600785 = validateParameter(valid_600785, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridProjects"))
  if valid_600785 != nil:
    section.add "X-Amz-Target", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Content-Sha256", valid_600786
  var valid_600787 = header.getOrDefault("X-Amz-Algorithm")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Algorithm", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Signature")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Signature", valid_600788
  var valid_600789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "X-Amz-SignedHeaders", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Credential")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Credential", valid_600790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600792: Call_ListTestGridProjects_600778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all Selenium testing projects in your account.
  ## 
  let valid = call_600792.validator(path, query, header, formData, body)
  let scheme = call_600792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600792.url(scheme.get, call_600792.host, call_600792.base,
                         call_600792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600792, url, valid)

proc call*(call_600793: Call_ListTestGridProjects_600778; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridProjects
  ## Gets a list of all Selenium testing projects in your account.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600794 = newJObject()
  var body_600795 = newJObject()
  add(query_600794, "maxResult", newJString(maxResult))
  add(query_600794, "nextToken", newJString(nextToken))
  if body != nil:
    body_600795 = body
  result = call_600793.call(nil, query_600794, nil, nil, body_600795)

var listTestGridProjects* = Call_ListTestGridProjects_600778(
    name: "listTestGridProjects", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridProjects",
    validator: validate_ListTestGridProjects_600779, base: "/",
    url: url_ListTestGridProjects_600780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionActions_600796 = ref object of OpenApiRestCall_599369
proc url_ListTestGridSessionActions_600798(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionActions_600797(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600799 = query.getOrDefault("maxResult")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "maxResult", valid_600799
  var valid_600800 = query.getOrDefault("nextToken")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "nextToken", valid_600800
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
  var valid_600801 = header.getOrDefault("X-Amz-Date")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Date", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Security-Token")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Security-Token", valid_600802
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600803 = header.getOrDefault("X-Amz-Target")
  valid_600803 = validateParameter(valid_600803, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionActions"))
  if valid_600803 != nil:
    section.add "X-Amz-Target", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Content-Sha256", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Algorithm")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Algorithm", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Signature")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Signature", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-SignedHeaders", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Credential")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Credential", valid_600808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600810: Call_ListTestGridSessionActions_600796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ## 
  let valid = call_600810.validator(path, query, header, formData, body)
  let scheme = call_600810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600810.url(scheme.get, call_600810.host, call_600810.base,
                         call_600810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600810, url, valid)

proc call*(call_600811: Call_ListTestGridSessionActions_600796; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessionActions
  ## Returns a list of the actions taken in a <a>TestGridSession</a>.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600812 = newJObject()
  var body_600813 = newJObject()
  add(query_600812, "maxResult", newJString(maxResult))
  add(query_600812, "nextToken", newJString(nextToken))
  if body != nil:
    body_600813 = body
  result = call_600811.call(nil, query_600812, nil, nil, body_600813)

var listTestGridSessionActions* = Call_ListTestGridSessionActions_600796(
    name: "listTestGridSessionActions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionActions",
    validator: validate_ListTestGridSessionActions_600797, base: "/",
    url: url_ListTestGridSessionActions_600798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessionArtifacts_600814 = ref object of OpenApiRestCall_599369
proc url_ListTestGridSessionArtifacts_600816(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessionArtifacts_600815(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600817 = query.getOrDefault("maxResult")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "maxResult", valid_600817
  var valid_600818 = query.getOrDefault("nextToken")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "nextToken", valid_600818
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
  var valid_600819 = header.getOrDefault("X-Amz-Date")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-Date", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Security-Token")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Security-Token", valid_600820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600821 = header.getOrDefault("X-Amz-Target")
  valid_600821 = validateParameter(valid_600821, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessionArtifacts"))
  if valid_600821 != nil:
    section.add "X-Amz-Target", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Content-Sha256", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Algorithm")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Algorithm", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Signature")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Signature", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-SignedHeaders", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-Credential")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-Credential", valid_600826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600828: Call_ListTestGridSessionArtifacts_600814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of artifacts created during the session.
  ## 
  let valid = call_600828.validator(path, query, header, formData, body)
  let scheme = call_600828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600828.url(scheme.get, call_600828.host, call_600828.base,
                         call_600828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600828, url, valid)

proc call*(call_600829: Call_ListTestGridSessionArtifacts_600814; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessionArtifacts
  ## Retrieves a list of artifacts created during the session.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600830 = newJObject()
  var body_600831 = newJObject()
  add(query_600830, "maxResult", newJString(maxResult))
  add(query_600830, "nextToken", newJString(nextToken))
  if body != nil:
    body_600831 = body
  result = call_600829.call(nil, query_600830, nil, nil, body_600831)

var listTestGridSessionArtifacts* = Call_ListTestGridSessionArtifacts_600814(
    name: "listTestGridSessionArtifacts", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessionArtifacts",
    validator: validate_ListTestGridSessionArtifacts_600815, base: "/",
    url: url_ListTestGridSessionArtifacts_600816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTestGridSessions_600832 = ref object of OpenApiRestCall_599369
proc url_ListTestGridSessions_600834(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTestGridSessions_600833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600835 = query.getOrDefault("maxResult")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "maxResult", valid_600835
  var valid_600836 = query.getOrDefault("nextToken")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "nextToken", valid_600836
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
  var valid_600837 = header.getOrDefault("X-Amz-Date")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Date", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Security-Token")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Security-Token", valid_600838
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600839 = header.getOrDefault("X-Amz-Target")
  valid_600839 = validateParameter(valid_600839, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTestGridSessions"))
  if valid_600839 != nil:
    section.add "X-Amz-Target", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Content-Sha256", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Algorithm")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Algorithm", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Signature")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Signature", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-SignedHeaders", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Credential")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Credential", valid_600844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600846: Call_ListTestGridSessions_600832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ## 
  let valid = call_600846.validator(path, query, header, formData, body)
  let scheme = call_600846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600846.url(scheme.get, call_600846.host, call_600846.base,
                         call_600846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600846, url, valid)

proc call*(call_600847: Call_ListTestGridSessions_600832; body: JsonNode;
          maxResult: string = ""; nextToken: string = ""): Recallable =
  ## listTestGridSessions
  ## Retrieves a list of sessions for a <a>TestGridProject</a>.
  ##   maxResult: string
  ##            : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600848 = newJObject()
  var body_600849 = newJObject()
  add(query_600848, "maxResult", newJString(maxResult))
  add(query_600848, "nextToken", newJString(nextToken))
  if body != nil:
    body_600849 = body
  result = call_600847.call(nil, query_600848, nil, nil, body_600849)

var listTestGridSessions* = Call_ListTestGridSessions_600832(
    name: "listTestGridSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTestGridSessions",
    validator: validate_ListTestGridSessions_600833, base: "/",
    url: url_ListTestGridSessions_600834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_600850 = ref object of OpenApiRestCall_599369
proc url_ListTests_600852(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_600851(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600853 = query.getOrDefault("nextToken")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "nextToken", valid_600853
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
  var valid_600854 = header.getOrDefault("X-Amz-Date")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Date", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Security-Token")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Security-Token", valid_600855
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600856 = header.getOrDefault("X-Amz-Target")
  valid_600856 = validateParameter(valid_600856, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_600856 != nil:
    section.add "X-Amz-Target", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Content-Sha256", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Algorithm")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Algorithm", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Signature")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Signature", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-SignedHeaders", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Credential")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Credential", valid_600861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600863: Call_ListTests_600850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_600863.validator(path, query, header, formData, body)
  let scheme = call_600863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600863.url(scheme.get, call_600863.host, call_600863.base,
                         call_600863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600863, url, valid)

proc call*(call_600864: Call_ListTests_600850; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600865 = newJObject()
  var body_600866 = newJObject()
  add(query_600865, "nextToken", newJString(nextToken))
  if body != nil:
    body_600866 = body
  result = call_600864.call(nil, query_600865, nil, nil, body_600866)

var listTests* = Call_ListTests_600850(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_600851,
                                    base: "/", url: url_ListTests_600852,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_600867 = ref object of OpenApiRestCall_599369
proc url_ListUniqueProblems_600869(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUniqueProblems_600868(path: JsonNode; query: JsonNode;
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
  var valid_600870 = query.getOrDefault("nextToken")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "nextToken", valid_600870
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
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600873 = header.getOrDefault("X-Amz-Target")
  valid_600873 = validateParameter(valid_600873, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_600873 != nil:
    section.add "X-Amz-Target", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Content-Sha256", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Algorithm")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Algorithm", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Signature")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Signature", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-SignedHeaders", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Credential")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Credential", valid_600878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600880: Call_ListUniqueProblems_600867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ## 
  let valid = call_600880.validator(path, query, header, formData, body)
  let scheme = call_600880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600880.url(scheme.get, call_600880.host, call_600880.base,
                         call_600880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600880, url, valid)

proc call*(call_600881: Call_ListUniqueProblems_600867; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## <p>Gets information about unique problems, such as exceptions or crashes.</p> <p>Unique problems are defined as a single instance of an error across a run, job, or suite. For example, if a call in your application consistently raises an exception (<code>OutOfBoundsException in MyActivity.java:386</code>), <code>ListUniqueProblems</code> returns a single entry instead of many individual entries for that exception.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600882 = newJObject()
  var body_600883 = newJObject()
  add(query_600882, "nextToken", newJString(nextToken))
  if body != nil:
    body_600883 = body
  result = call_600881.call(nil, query_600882, nil, nil, body_600883)

var listUniqueProblems* = Call_ListUniqueProblems_600867(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_600868, base: "/",
    url: url_ListUniqueProblems_600869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_600884 = ref object of OpenApiRestCall_599369
proc url_ListUploads_600886(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUploads_600885(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600887 = query.getOrDefault("nextToken")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "nextToken", valid_600887
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600890 = header.getOrDefault("X-Amz-Target")
  valid_600890 = validateParameter(valid_600890, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_600890 != nil:
    section.add "X-Amz-Target", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Content-Sha256", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Algorithm")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Algorithm", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Signature")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Signature", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-SignedHeaders", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Credential")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Credential", valid_600895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600897: Call_ListUploads_600884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_600897.validator(path, query, header, formData, body)
  let scheme = call_600897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600897.url(scheme.get, call_600897.host, call_600897.base,
                         call_600897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600897, url, valid)

proc call*(call_600898: Call_ListUploads_600884; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600899 = newJObject()
  var body_600900 = newJObject()
  add(query_600899, "nextToken", newJString(nextToken))
  if body != nil:
    body_600900 = body
  result = call_600898.call(nil, query_600899, nil, nil, body_600900)

var listUploads* = Call_ListUploads_600884(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_600885,
                                        base: "/", url: url_ListUploads_600886,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_600901 = ref object of OpenApiRestCall_599369
proc url_ListVPCEConfigurations_600903(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVPCEConfigurations_600902(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600904 = header.getOrDefault("X-Amz-Date")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Date", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Security-Token")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Security-Token", valid_600905
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600906 = header.getOrDefault("X-Amz-Target")
  valid_600906 = validateParameter(valid_600906, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_600906 != nil:
    section.add "X-Amz-Target", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Content-Sha256", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Algorithm")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Algorithm", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Signature")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Signature", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-SignedHeaders", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Credential")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Credential", valid_600911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_ListVPCEConfigurations_600901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600913, url, valid)

proc call*(call_600914: Call_ListVPCEConfigurations_600901; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_600915 = newJObject()
  if body != nil:
    body_600915 = body
  result = call_600914.call(nil, nil, nil, nil, body_600915)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_600901(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_600902, base: "/",
    url: url_ListVPCEConfigurations_600903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_600916 = ref object of OpenApiRestCall_599369
proc url_PurchaseOffering_600918(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseOffering_600917(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600919 = header.getOrDefault("X-Amz-Date")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Date", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Security-Token")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Security-Token", valid_600920
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600921 = header.getOrDefault("X-Amz-Target")
  valid_600921 = validateParameter(valid_600921, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_600921 != nil:
    section.add "X-Amz-Target", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Content-Sha256", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Algorithm")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Algorithm", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Signature")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Signature", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-SignedHeaders", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Credential")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Credential", valid_600926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600928: Call_PurchaseOffering_600916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_600928.validator(path, query, header, formData, body)
  let scheme = call_600928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600928.url(scheme.get, call_600928.host, call_600928.base,
                         call_600928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600928, url, valid)

proc call*(call_600929: Call_PurchaseOffering_600916; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_600930 = newJObject()
  if body != nil:
    body_600930 = body
  result = call_600929.call(nil, nil, nil, nil, body_600930)

var purchaseOffering* = Call_PurchaseOffering_600916(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_600917, base: "/",
    url: url_PurchaseOffering_600918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_600931 = ref object of OpenApiRestCall_599369
proc url_RenewOffering_600933(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenewOffering_600932(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600934 = header.getOrDefault("X-Amz-Date")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Date", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Security-Token")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Security-Token", valid_600935
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600936 = header.getOrDefault("X-Amz-Target")
  valid_600936 = validateParameter(valid_600936, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_600936 != nil:
    section.add "X-Amz-Target", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Content-Sha256", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Algorithm")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Algorithm", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Signature")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Signature", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-SignedHeaders", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Credential")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Credential", valid_600941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600943: Call_RenewOffering_600931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ## 
  let valid = call_600943.validator(path, query, header, formData, body)
  let scheme = call_600943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600943.url(scheme.get, call_600943.host, call_600943.base,
                         call_600943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600943, url, valid)

proc call*(call_600944: Call_RenewOffering_600931; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. If you must be able to invoke this operation, contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a>.
  ##   body: JObject (required)
  var body_600945 = newJObject()
  if body != nil:
    body_600945 = body
  result = call_600944.call(nil, nil, nil, nil, body_600945)

var renewOffering* = Call_RenewOffering_600931(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_600932, base: "/", url: url_RenewOffering_600933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_600946 = ref object of OpenApiRestCall_599369
proc url_ScheduleRun_600948(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleRun_600947(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600949 = header.getOrDefault("X-Amz-Date")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Date", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-Security-Token")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Security-Token", valid_600950
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600951 = header.getOrDefault("X-Amz-Target")
  valid_600951 = validateParameter(valid_600951, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_600951 != nil:
    section.add "X-Amz-Target", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Content-Sha256", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Algorithm")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Algorithm", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Signature")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Signature", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-SignedHeaders", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Credential")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Credential", valid_600956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600958: Call_ScheduleRun_600946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_600958.validator(path, query, header, formData, body)
  let scheme = call_600958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600958.url(scheme.get, call_600958.host, call_600958.base,
                         call_600958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600958, url, valid)

proc call*(call_600959: Call_ScheduleRun_600946; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_600960 = newJObject()
  if body != nil:
    body_600960 = body
  result = call_600959.call(nil, nil, nil, nil, body_600960)

var scheduleRun* = Call_ScheduleRun_600946(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_600947,
                                        base: "/", url: url_ScheduleRun_600948,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_600961 = ref object of OpenApiRestCall_599369
proc url_StopJob_600963(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_600962(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600964 = header.getOrDefault("X-Amz-Date")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Date", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Security-Token")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Security-Token", valid_600965
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600966 = header.getOrDefault("X-Amz-Target")
  valid_600966 = validateParameter(valid_600966, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_600966 != nil:
    section.add "X-Amz-Target", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Content-Sha256", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Algorithm")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Algorithm", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Signature")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Signature", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-SignedHeaders", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Credential")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Credential", valid_600971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600973: Call_StopJob_600961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_600973.validator(path, query, header, formData, body)
  let scheme = call_600973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600973.url(scheme.get, call_600973.host, call_600973.base,
                         call_600973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600973, url, valid)

proc call*(call_600974: Call_StopJob_600961; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm immediately stops the job on the device where tests have not started. You are not billed for this device. On the device where tests have started, setup suite and teardown suite tests run to completion on the device. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_600975 = newJObject()
  if body != nil:
    body_600975 = body
  result = call_600974.call(nil, nil, nil, nil, body_600975)

var stopJob* = Call_StopJob_600961(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_600962, base: "/",
                                url: url_StopJob_600963,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_600976 = ref object of OpenApiRestCall_599369
proc url_StopRemoteAccessSession_600978(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRemoteAccessSession_600977(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600979 = header.getOrDefault("X-Amz-Date")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Date", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-Security-Token")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Security-Token", valid_600980
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600981 = header.getOrDefault("X-Amz-Target")
  valid_600981 = validateParameter(valid_600981, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_600981 != nil:
    section.add "X-Amz-Target", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Content-Sha256", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Algorithm")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Algorithm", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Signature")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Signature", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-SignedHeaders", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Credential")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Credential", valid_600986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600988: Call_StopRemoteAccessSession_600976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_600988.validator(path, query, header, formData, body)
  let scheme = call_600988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600988.url(scheme.get, call_600988.host, call_600988.base,
                         call_600988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600988, url, valid)

proc call*(call_600989: Call_StopRemoteAccessSession_600976; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_600990 = newJObject()
  if body != nil:
    body_600990 = body
  result = call_600989.call(nil, nil, nil, nil, body_600990)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_600976(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_600977, base: "/",
    url: url_StopRemoteAccessSession_600978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_600991 = ref object of OpenApiRestCall_599369
proc url_StopRun_600993(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_600992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600994 = header.getOrDefault("X-Amz-Date")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Date", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-Security-Token")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Security-Token", valid_600995
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600996 = header.getOrDefault("X-Amz-Target")
  valid_600996 = validateParameter(valid_600996, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_600996 != nil:
    section.add "X-Amz-Target", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Content-Sha256", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Algorithm")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Algorithm", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-Signature")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Signature", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-SignedHeaders", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Credential")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Credential", valid_601001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601003: Call_StopRun_600991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_601003.validator(path, query, header, formData, body)
  let scheme = call_601003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601003.url(scheme.get, call_601003.host, call_601003.base,
                         call_601003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601003, url, valid)

proc call*(call_601004: Call_StopRun_600991; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm immediately stops the run on devices where tests have not started. You are not billed for these devices. On devices where tests have started executing, setup suite and teardown suite tests run to completion on those devices. You are billed for setup, teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_601005 = newJObject()
  if body != nil:
    body_601005 = body
  result = call_601004.call(nil, nil, nil, nil, body_601005)

var stopRun* = Call_StopRun_600991(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_600992, base: "/",
                                url: url_StopRun_600993,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601006 = ref object of OpenApiRestCall_599369
proc url_TagResource_601008(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_601007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601009 = header.getOrDefault("X-Amz-Date")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Date", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Security-Token")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Security-Token", valid_601010
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601011 = header.getOrDefault("X-Amz-Target")
  valid_601011 = validateParameter(valid_601011, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_601011 != nil:
    section.add "X-Amz-Target", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Content-Sha256", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Algorithm")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Algorithm", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Signature")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Signature", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-SignedHeaders", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Credential")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Credential", valid_601016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601018: Call_TagResource_601006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ## 
  let valid = call_601018.validator(path, query, header, formData, body)
  let scheme = call_601018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601018.url(scheme.get, call_601018.host, call_601018.base,
                         call_601018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601018, url, valid)

proc call*(call_601019: Call_TagResource_601006; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
  ##   body: JObject (required)
  var body_601020 = newJObject()
  if body != nil:
    body_601020 = body
  result = call_601019.call(nil, nil, nil, nil, body_601020)

var tagResource* = Call_TagResource_601006(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_601007,
                                        base: "/", url: url_TagResource_601008,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601021 = ref object of OpenApiRestCall_599369
proc url_UntagResource_601023(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_601022(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601024 = header.getOrDefault("X-Amz-Date")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Date", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Security-Token")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Security-Token", valid_601025
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601026 = header.getOrDefault("X-Amz-Target")
  valid_601026 = validateParameter(valid_601026, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_601026 != nil:
    section.add "X-Amz-Target", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Content-Sha256", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Algorithm")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Algorithm", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Signature")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Signature", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-SignedHeaders", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Credential")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Credential", valid_601031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601033: Call_UntagResource_601021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_601033.validator(path, query, header, formData, body)
  let scheme = call_601033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601033.url(scheme.get, call_601033.host, call_601033.base,
                         call_601033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601033, url, valid)

proc call*(call_601034: Call_UntagResource_601021; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_601035 = newJObject()
  if body != nil:
    body_601035 = body
  result = call_601034.call(nil, nil, nil, nil, body_601035)

var untagResource* = Call_UntagResource_601021(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_601022, base: "/", url: url_UntagResource_601023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_601036 = ref object of OpenApiRestCall_599369
proc url_UpdateDeviceInstance_601038(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceInstance_601037(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601039 = header.getOrDefault("X-Amz-Date")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Date", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Security-Token")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Security-Token", valid_601040
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601041 = header.getOrDefault("X-Amz-Target")
  valid_601041 = validateParameter(valid_601041, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_601041 != nil:
    section.add "X-Amz-Target", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_UpdateDeviceInstance_601036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about a private device instance.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601048, url, valid)

proc call*(call_601049: Call_UpdateDeviceInstance_601036; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about a private device instance.
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var updateDeviceInstance* = Call_UpdateDeviceInstance_601036(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_601037, base: "/",
    url: url_UpdateDeviceInstance_601038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_601051 = ref object of OpenApiRestCall_599369
proc url_UpdateDevicePool_601053(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePool_601052(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601054 = header.getOrDefault("X-Amz-Date")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Date", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Security-Token")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Security-Token", valid_601055
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601056 = header.getOrDefault("X-Amz-Target")
  valid_601056 = validateParameter(valid_601056, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_601056 != nil:
    section.add "X-Amz-Target", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601063: Call_UpdateDevicePool_601051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_601063.validator(path, query, header, formData, body)
  let scheme = call_601063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601063.url(scheme.get, call_601063.host, call_601063.base,
                         call_601063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601063, url, valid)

proc call*(call_601064: Call_UpdateDevicePool_601051; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_601065 = newJObject()
  if body != nil:
    body_601065 = body
  result = call_601064.call(nil, nil, nil, nil, body_601065)

var updateDevicePool* = Call_UpdateDevicePool_601051(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_601052, base: "/",
    url: url_UpdateDevicePool_601053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_601066 = ref object of OpenApiRestCall_599369
proc url_UpdateInstanceProfile_601068(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceProfile_601067(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601071 = header.getOrDefault("X-Amz-Target")
  valid_601071 = validateParameter(valid_601071, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_601071 != nil:
    section.add "X-Amz-Target", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601078: Call_UpdateInstanceProfile_601066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_601078.validator(path, query, header, formData, body)
  let scheme = call_601078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601078.url(scheme.get, call_601078.host, call_601078.base,
                         call_601078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601078, url, valid)

proc call*(call_601079: Call_UpdateInstanceProfile_601066; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_601080 = newJObject()
  if body != nil:
    body_601080 = body
  result = call_601079.call(nil, nil, nil, nil, body_601080)

var updateInstanceProfile* = Call_UpdateInstanceProfile_601066(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_601067, base: "/",
    url: url_UpdateInstanceProfile_601068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_601081 = ref object of OpenApiRestCall_599369
proc url_UpdateNetworkProfile_601083(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_601082(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601084 = header.getOrDefault("X-Amz-Date")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Date", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Security-Token")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Security-Token", valid_601085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601086 = header.getOrDefault("X-Amz-Target")
  valid_601086 = validateParameter(valid_601086, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_601086 != nil:
    section.add "X-Amz-Target", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Content-Sha256", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Algorithm")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Algorithm", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Signature")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Signature", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-SignedHeaders", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_UpdateNetworkProfile_601081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile.
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601093, url, valid)

proc call*(call_601094: Call_UpdateNetworkProfile_601081; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile.
  ##   body: JObject (required)
  var body_601095 = newJObject()
  if body != nil:
    body_601095 = body
  result = call_601094.call(nil, nil, nil, nil, body_601095)

var updateNetworkProfile* = Call_UpdateNetworkProfile_601081(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_601082, base: "/",
    url: url_UpdateNetworkProfile_601083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_601096 = ref object of OpenApiRestCall_599369
proc url_UpdateProject_601098(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_601097(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601101 = header.getOrDefault("X-Amz-Target")
  valid_601101 = validateParameter(valid_601101, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_601101 != nil:
    section.add "X-Amz-Target", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Content-Sha256", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Algorithm", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Signature", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-SignedHeaders", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Credential")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Credential", valid_601106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601108: Call_UpdateProject_601096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_601108.validator(path, query, header, formData, body)
  let scheme = call_601108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601108.url(scheme.get, call_601108.host, call_601108.base,
                         call_601108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601108, url, valid)

proc call*(call_601109: Call_UpdateProject_601096; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_601110 = newJObject()
  if body != nil:
    body_601110 = body
  result = call_601109.call(nil, nil, nil, nil, body_601110)

var updateProject* = Call_UpdateProject_601096(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_601097, base: "/", url: url_UpdateProject_601098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTestGridProject_601111 = ref object of OpenApiRestCall_599369
proc url_UpdateTestGridProject_601113(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTestGridProject_601112(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601116 = header.getOrDefault("X-Amz-Target")
  valid_601116 = validateParameter(valid_601116, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateTestGridProject"))
  if valid_601116 != nil:
    section.add "X-Amz-Target", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Content-Sha256", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Algorithm")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Algorithm", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Signature")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Signature", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-SignedHeaders", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Credential")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Credential", valid_601121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601123: Call_UpdateTestGridProject_601111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Change details of a project.
  ## 
  let valid = call_601123.validator(path, query, header, formData, body)
  let scheme = call_601123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601123.url(scheme.get, call_601123.host, call_601123.base,
                         call_601123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601123, url, valid)

proc call*(call_601124: Call_UpdateTestGridProject_601111; body: JsonNode): Recallable =
  ## updateTestGridProject
  ## Change details of a project.
  ##   body: JObject (required)
  var body_601125 = newJObject()
  if body != nil:
    body_601125 = body
  result = call_601124.call(nil, nil, nil, nil, body_601125)

var updateTestGridProject* = Call_UpdateTestGridProject_601111(
    name: "updateTestGridProject", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateTestGridProject",
    validator: validate_UpdateTestGridProject_601112, base: "/",
    url: url_UpdateTestGridProject_601113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_601126 = ref object of OpenApiRestCall_599369
proc url_UpdateUpload_601128(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUpload_601127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601131 = header.getOrDefault("X-Amz-Target")
  valid_601131 = validateParameter(valid_601131, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_601131 != nil:
    section.add "X-Amz-Target", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_UpdateUpload_601126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an uploaded test spec.
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601138, url, valid)

proc call*(call_601139: Call_UpdateUpload_601126; body: JsonNode): Recallable =
  ## updateUpload
  ## Updates an uploaded test spec.
  ##   body: JObject (required)
  var body_601140 = newJObject()
  if body != nil:
    body_601140 = body
  result = call_601139.call(nil, nil, nil, nil, body_601140)

var updateUpload* = Call_UpdateUpload_601126(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_601127, base: "/", url: url_UpdateUpload_601128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_601141 = ref object of OpenApiRestCall_599369
proc url_UpdateVPCEConfiguration_601143(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVPCEConfiguration_601142(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601146 = header.getOrDefault("X-Amz-Target")
  valid_601146 = validateParameter(valid_601146, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_601146 != nil:
    section.add "X-Amz-Target", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Content-Sha256", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Algorithm")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Algorithm", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Signature")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Signature", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-SignedHeaders", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Credential")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Credential", valid_601151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601153: Call_UpdateVPCEConfiguration_601141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_601153.validator(path, query, header, formData, body)
  let scheme = call_601153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601153.url(scheme.get, call_601153.host, call_601153.base,
                         call_601153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601153, url, valid)

proc call*(call_601154: Call_UpdateVPCEConfiguration_601141; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_601155 = newJObject()
  if body != nil:
    body_601155 = body
  result = call_601154.call(nil, nil, nil, nil, body_601155)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_601141(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_601142, base: "/",
    url: url_UpdateVPCEConfiguration_601143, schemes: {Scheme.Https, Scheme.Http})
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
