
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
## AWS Device Farm is a service that enables mobile app developers to test Android, iOS, and Fire OS apps on physical phones, tablets, and other devices in the cloud.
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
  ## Creates a new project.
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
  ## Creates a new project.
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
  ## Creates a new project.
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
  Call_CreateUpload_600035 = ref object of OpenApiRestCall_599369
proc url_CreateUpload_600037(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUpload_600036(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.CreateUpload"))
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

proc call*(call_600047: Call_CreateUpload_600035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_CreateUpload_600035; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_600049 = newJObject()
  if body != nil:
    body_600049 = body
  result = call_600048.call(nil, nil, nil, nil, body_600049)

var createUpload* = Call_CreateUpload_600035(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_600036, base: "/", url: url_CreateUpload_600037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_600050 = ref object of OpenApiRestCall_599369
proc url_CreateVPCEConfiguration_600052(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVPCEConfiguration_600051(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
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

proc call*(call_600062: Call_CreateVPCEConfiguration_600050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_CreateVPCEConfiguration_600050; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600064 = newJObject()
  if body != nil:
    body_600064 = body
  result = call_600063.call(nil, nil, nil, nil, body_600064)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_600050(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_600051, base: "/",
    url: url_CreateVPCEConfiguration_600052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_600065 = ref object of OpenApiRestCall_599369
proc url_DeleteDevicePool_600067(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevicePool_600066(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.DeleteDevicePool"))
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

proc call*(call_600077: Call_DeleteDevicePool_600065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_DeleteDevicePool_600065; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_600079 = newJObject()
  if body != nil:
    body_600079 = body
  result = call_600078.call(nil, nil, nil, nil, body_600079)

var deleteDevicePool* = Call_DeleteDevicePool_600065(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_600066, base: "/",
    url: url_DeleteDevicePool_600067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_600080 = ref object of OpenApiRestCall_599369
proc url_DeleteInstanceProfile_600082(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceProfile_600081(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.DeleteInstanceProfile"))
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

proc call*(call_600092: Call_DeleteInstanceProfile_600080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_DeleteInstanceProfile_600080; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_600094 = newJObject()
  if body != nil:
    body_600094 = body
  result = call_600093.call(nil, nil, nil, nil, body_600094)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_600080(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_600081, base: "/",
    url: url_DeleteInstanceProfile_600082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_600095 = ref object of OpenApiRestCall_599369
proc url_DeleteNetworkProfile_600097(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_600096(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.DeleteNetworkProfile"))
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

proc call*(call_600107: Call_DeleteNetworkProfile_600095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_600107.validator(path, query, header, formData, body)
  let scheme = call_600107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600107.url(scheme.get, call_600107.host, call_600107.base,
                         call_600107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600107, url, valid)

proc call*(call_600108: Call_DeleteNetworkProfile_600095; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_600109 = newJObject()
  if body != nil:
    body_600109 = body
  result = call_600108.call(nil, nil, nil, nil, body_600109)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_600095(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_600096, base: "/",
    url: url_DeleteNetworkProfile_600097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_600110 = ref object of OpenApiRestCall_599369
proc url_DeleteProject_600112(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_600111(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
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
      "DeviceFarm_20150623.DeleteProject"))
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

proc call*(call_600122: Call_DeleteProject_600110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_600122.validator(path, query, header, formData, body)
  let scheme = call_600122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600122.url(scheme.get, call_600122.host, call_600122.base,
                         call_600122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600122, url, valid)

proc call*(call_600123: Call_DeleteProject_600110; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_600124 = newJObject()
  if body != nil:
    body_600124 = body
  result = call_600123.call(nil, nil, nil, nil, body_600124)

var deleteProject* = Call_DeleteProject_600110(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_600111, base: "/", url: url_DeleteProject_600112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_600125 = ref object of OpenApiRestCall_599369
proc url_DeleteRemoteAccessSession_600127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemoteAccessSession_600126(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
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

proc call*(call_600137: Call_DeleteRemoteAccessSession_600125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_DeleteRemoteAccessSession_600125; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_600139 = newJObject()
  if body != nil:
    body_600139 = body
  result = call_600138.call(nil, nil, nil, nil, body_600139)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_600125(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_600126, base: "/",
    url: url_DeleteRemoteAccessSession_600127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_600140 = ref object of OpenApiRestCall_599369
proc url_DeleteRun_600142(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRun_600141(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
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
      "DeviceFarm_20150623.DeleteRun"))
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

proc call*(call_600152: Call_DeleteRun_600140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_600152.validator(path, query, header, formData, body)
  let scheme = call_600152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600152.url(scheme.get, call_600152.host, call_600152.base,
                         call_600152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600152, url, valid)

proc call*(call_600153: Call_DeleteRun_600140; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_600154 = newJObject()
  if body != nil:
    body_600154 = body
  result = call_600153.call(nil, nil, nil, nil, body_600154)

var deleteRun* = Call_DeleteRun_600140(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_600141,
                                    base: "/", url: url_DeleteRun_600142,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_600155 = ref object of OpenApiRestCall_599369
proc url_DeleteUpload_600157(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUpload_600156(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.DeleteUpload"))
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

proc call*(call_600167: Call_DeleteUpload_600155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_600167.validator(path, query, header, formData, body)
  let scheme = call_600167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600167.url(scheme.get, call_600167.host, call_600167.base,
                         call_600167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600167, url, valid)

proc call*(call_600168: Call_DeleteUpload_600155; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_600169 = newJObject()
  if body != nil:
    body_600169 = body
  result = call_600168.call(nil, nil, nil, nil, body_600169)

var deleteUpload* = Call_DeleteUpload_600155(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_600156, base: "/", url: url_DeleteUpload_600157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_600170 = ref object of OpenApiRestCall_599369
proc url_DeleteVPCEConfiguration_600172(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVPCEConfiguration_600171(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
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

proc call*(call_600182: Call_DeleteVPCEConfiguration_600170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600182.validator(path, query, header, formData, body)
  let scheme = call_600182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600182.url(scheme.get, call_600182.host, call_600182.base,
                         call_600182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600182, url, valid)

proc call*(call_600183: Call_DeleteVPCEConfiguration_600170; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600184 = newJObject()
  if body != nil:
    body_600184 = body
  result = call_600183.call(nil, nil, nil, nil, body_600184)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_600170(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_600171, base: "/",
    url: url_DeleteVPCEConfiguration_600172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_600185 = ref object of OpenApiRestCall_599369
proc url_GetAccountSettings_600187(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_600186(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
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
      "DeviceFarm_20150623.GetAccountSettings"))
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

proc call*(call_600197: Call_GetAccountSettings_600185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_GetAccountSettings_600185; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_600199 = newJObject()
  if body != nil:
    body_600199 = body
  result = call_600198.call(nil, nil, nil, nil, body_600199)

var getAccountSettings* = Call_GetAccountSettings_600185(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_600186, base: "/",
    url: url_GetAccountSettings_600187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_600200 = ref object of OpenApiRestCall_599369
proc url_GetDevice_600202(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_600201(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetDevice"))
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

proc call*(call_600212: Call_GetDevice_600200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_GetDevice_600200; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_600214 = newJObject()
  if body != nil:
    body_600214 = body
  result = call_600213.call(nil, nil, nil, nil, body_600214)

var getDevice* = Call_GetDevice_600200(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_600201,
                                    base: "/", url: url_GetDevice_600202,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_600215 = ref object of OpenApiRestCall_599369
proc url_GetDeviceInstance_600217(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeviceInstance_600216(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about a device instance belonging to a private device fleet.
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
      "DeviceFarm_20150623.GetDeviceInstance"))
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

proc call*(call_600227: Call_GetDeviceInstance_600215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance belonging to a private device fleet.
  ## 
  let valid = call_600227.validator(path, query, header, formData, body)
  let scheme = call_600227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600227.url(scheme.get, call_600227.host, call_600227.base,
                         call_600227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600227, url, valid)

proc call*(call_600228: Call_GetDeviceInstance_600215; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance belonging to a private device fleet.
  ##   body: JObject (required)
  var body_600229 = newJObject()
  if body != nil:
    body_600229 = body
  result = call_600228.call(nil, nil, nil, nil, body_600229)

var getDeviceInstance* = Call_GetDeviceInstance_600215(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_600216, base: "/",
    url: url_GetDeviceInstance_600217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_600230 = ref object of OpenApiRestCall_599369
proc url_GetDevicePool_600232(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePool_600231(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetDevicePool"))
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

proc call*(call_600242: Call_GetDevicePool_600230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_600242.validator(path, query, header, formData, body)
  let scheme = call_600242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600242.url(scheme.get, call_600242.host, call_600242.base,
                         call_600242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600242, url, valid)

proc call*(call_600243: Call_GetDevicePool_600230; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_600244 = newJObject()
  if body != nil:
    body_600244 = body
  result = call_600243.call(nil, nil, nil, nil, body_600244)

var getDevicePool* = Call_GetDevicePool_600230(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_600231, base: "/", url: url_GetDevicePool_600232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_600245 = ref object of OpenApiRestCall_599369
proc url_GetDevicePoolCompatibility_600247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevicePoolCompatibility_600246(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
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

proc call*(call_600257: Call_GetDevicePoolCompatibility_600245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_600257.validator(path, query, header, formData, body)
  let scheme = call_600257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600257.url(scheme.get, call_600257.host, call_600257.base,
                         call_600257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600257, url, valid)

proc call*(call_600258: Call_GetDevicePoolCompatibility_600245; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_600259 = newJObject()
  if body != nil:
    body_600259 = body
  result = call_600258.call(nil, nil, nil, nil, body_600259)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_600245(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_600246, base: "/",
    url: url_GetDevicePoolCompatibility_600247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_600260 = ref object of OpenApiRestCall_599369
proc url_GetInstanceProfile_600262(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceProfile_600261(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.GetInstanceProfile"))
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

proc call*(call_600272: Call_GetInstanceProfile_600260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_600272.validator(path, query, header, formData, body)
  let scheme = call_600272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600272.url(scheme.get, call_600272.host, call_600272.base,
                         call_600272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600272, url, valid)

proc call*(call_600273: Call_GetInstanceProfile_600260; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_600274 = newJObject()
  if body != nil:
    body_600274 = body
  result = call_600273.call(nil, nil, nil, nil, body_600274)

var getInstanceProfile* = Call_GetInstanceProfile_600260(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_600261, base: "/",
    url: url_GetInstanceProfile_600262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_600275 = ref object of OpenApiRestCall_599369
proc url_GetJob_600277(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJob_600276(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetJob"))
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

proc call*(call_600287: Call_GetJob_600275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_GetJob_600275; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_600289 = newJObject()
  if body != nil:
    body_600289 = body
  result = call_600288.call(nil, nil, nil, nil, body_600289)

var getJob* = Call_GetJob_600275(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_600276, base: "/",
                              url: url_GetJob_600277,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_600290 = ref object of OpenApiRestCall_599369
proc url_GetNetworkProfile_600292(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_600291(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.GetNetworkProfile"))
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

proc call*(call_600302: Call_GetNetworkProfile_600290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_GetNetworkProfile_600290; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_600304 = newJObject()
  if body != nil:
    body_600304 = body
  result = call_600303.call(nil, nil, nil, nil, body_600304)

var getNetworkProfile* = Call_GetNetworkProfile_600290(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_600291, base: "/",
    url: url_GetNetworkProfile_600292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_600305 = ref object of OpenApiRestCall_599369
proc url_GetOfferingStatus_600307(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOfferingStatus_600306(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600308 = query.getOrDefault("nextToken")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "nextToken", valid_600308
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
  var valid_600309 = header.getOrDefault("X-Amz-Date")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Date", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Security-Token")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Security-Token", valid_600310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600311 = header.getOrDefault("X-Amz-Target")
  valid_600311 = validateParameter(valid_600311, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_600311 != nil:
    section.add "X-Amz-Target", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Content-Sha256", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Algorithm")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Algorithm", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Signature")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Signature", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-SignedHeaders", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Credential")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Credential", valid_600316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600318: Call_GetOfferingStatus_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600318.validator(path, query, header, formData, body)
  let scheme = call_600318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600318.url(scheme.get, call_600318.host, call_600318.base,
                         call_600318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600318, url, valid)

proc call*(call_600319: Call_GetOfferingStatus_600305; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600320 = newJObject()
  var body_600321 = newJObject()
  add(query_600320, "nextToken", newJString(nextToken))
  if body != nil:
    body_600321 = body
  result = call_600319.call(nil, query_600320, nil, nil, body_600321)

var getOfferingStatus* = Call_GetOfferingStatus_600305(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_600306, base: "/",
    url: url_GetOfferingStatus_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_600323 = ref object of OpenApiRestCall_599369
proc url_GetProject_600325(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProject_600324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600326 = header.getOrDefault("X-Amz-Date")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Date", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Security-Token")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Security-Token", valid_600327
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600328 = header.getOrDefault("X-Amz-Target")
  valid_600328 = validateParameter(valid_600328, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_600328 != nil:
    section.add "X-Amz-Target", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Content-Sha256", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Algorithm")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Algorithm", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Signature")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Signature", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-SignedHeaders", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Credential")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Credential", valid_600333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600335: Call_GetProject_600323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_600335.validator(path, query, header, formData, body)
  let scheme = call_600335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600335.url(scheme.get, call_600335.host, call_600335.base,
                         call_600335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600335, url, valid)

proc call*(call_600336: Call_GetProject_600323; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_600337 = newJObject()
  if body != nil:
    body_600337 = body
  result = call_600336.call(nil, nil, nil, nil, body_600337)

var getProject* = Call_GetProject_600323(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_600324,
                                      base: "/", url: url_GetProject_600325,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_600338 = ref object of OpenApiRestCall_599369
proc url_GetRemoteAccessSession_600340(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoteAccessSession_600339(path: JsonNode; query: JsonNode;
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
  var valid_600341 = header.getOrDefault("X-Amz-Date")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Date", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Security-Token")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Security-Token", valid_600342
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600343 = header.getOrDefault("X-Amz-Target")
  valid_600343 = validateParameter(valid_600343, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_600343 != nil:
    section.add "X-Amz-Target", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Content-Sha256", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Algorithm")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Algorithm", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Signature")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Signature", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-SignedHeaders", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Credential")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Credential", valid_600348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600350: Call_GetRemoteAccessSession_600338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_600350.validator(path, query, header, formData, body)
  let scheme = call_600350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600350.url(scheme.get, call_600350.host, call_600350.base,
                         call_600350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600350, url, valid)

proc call*(call_600351: Call_GetRemoteAccessSession_600338; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_600352 = newJObject()
  if body != nil:
    body_600352 = body
  result = call_600351.call(nil, nil, nil, nil, body_600352)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_600338(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_600339, base: "/",
    url: url_GetRemoteAccessSession_600340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_600353 = ref object of OpenApiRestCall_599369
proc url_GetRun_600355(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRun_600354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600356 = header.getOrDefault("X-Amz-Date")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Date", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Security-Token")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Security-Token", valid_600357
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600358 = header.getOrDefault("X-Amz-Target")
  valid_600358 = validateParameter(valid_600358, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_600358 != nil:
    section.add "X-Amz-Target", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Content-Sha256", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Algorithm")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Algorithm", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Signature")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Signature", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-SignedHeaders", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Credential")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Credential", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600365: Call_GetRun_600353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_600365.validator(path, query, header, formData, body)
  let scheme = call_600365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600365.url(scheme.get, call_600365.host, call_600365.base,
                         call_600365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600365, url, valid)

proc call*(call_600366: Call_GetRun_600353; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_600367 = newJObject()
  if body != nil:
    body_600367 = body
  result = call_600366.call(nil, nil, nil, nil, body_600367)

var getRun* = Call_GetRun_600353(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_600354, base: "/",
                              url: url_GetRun_600355,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_600368 = ref object of OpenApiRestCall_599369
proc url_GetSuite_600370(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSuite_600369(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetSuite"))
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

proc call*(call_600380: Call_GetSuite_600368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_GetSuite_600368; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_600382 = newJObject()
  if body != nil:
    body_600382 = body
  result = call_600381.call(nil, nil, nil, nil, body_600382)

var getSuite* = Call_GetSuite_600368(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_600369, base: "/",
                                  url: url_GetSuite_600370,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_600383 = ref object of OpenApiRestCall_599369
proc url_GetTest_600385(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTest_600384(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetTest"))
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

proc call*(call_600395: Call_GetTest_600383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_GetTest_600383; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_600397 = newJObject()
  if body != nil:
    body_600397 = body
  result = call_600396.call(nil, nil, nil, nil, body_600397)

var getTest* = Call_GetTest_600383(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_600384, base: "/",
                                url: url_GetTest_600385,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_600398 = ref object of OpenApiRestCall_599369
proc url_GetUpload_600400(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpload_600399(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "DeviceFarm_20150623.GetUpload"))
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

proc call*(call_600410: Call_GetUpload_600398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_600410.validator(path, query, header, formData, body)
  let scheme = call_600410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600410.url(scheme.get, call_600410.host, call_600410.base,
                         call_600410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600410, url, valid)

proc call*(call_600411: Call_GetUpload_600398; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_600412 = newJObject()
  if body != nil:
    body_600412 = body
  result = call_600411.call(nil, nil, nil, nil, body_600412)

var getUpload* = Call_GetUpload_600398(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_600399,
                                    base: "/", url: url_GetUpload_600400,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_600413 = ref object of OpenApiRestCall_599369
proc url_GetVPCEConfiguration_600415(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVPCEConfiguration_600414(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.GetVPCEConfiguration"))
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

proc call*(call_600425: Call_GetVPCEConfiguration_600413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_600425.validator(path, query, header, formData, body)
  let scheme = call_600425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600425.url(scheme.get, call_600425.host, call_600425.base,
                         call_600425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600425, url, valid)

proc call*(call_600426: Call_GetVPCEConfiguration_600413; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_600427 = newJObject()
  if body != nil:
    body_600427 = body
  result = call_600426.call(nil, nil, nil, nil, body_600427)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_600413(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_600414, base: "/",
    url: url_GetVPCEConfiguration_600415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_600428 = ref object of OpenApiRestCall_599369
proc url_InstallToRemoteAccessSession_600430(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InstallToRemoteAccessSession_600429(path: JsonNode; query: JsonNode;
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
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
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

proc call*(call_600440: Call_InstallToRemoteAccessSession_600428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_InstallToRemoteAccessSession_600428; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_600442 = newJObject()
  if body != nil:
    body_600442 = body
  result = call_600441.call(nil, nil, nil, nil, body_600442)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_600428(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_600429, base: "/",
    url: url_InstallToRemoteAccessSession_600430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_600443 = ref object of OpenApiRestCall_599369
proc url_ListArtifacts_600445(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListArtifacts_600444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600446 = query.getOrDefault("nextToken")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "nextToken", valid_600446
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
  var valid_600447 = header.getOrDefault("X-Amz-Date")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Date", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Security-Token")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Security-Token", valid_600448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600449 = header.getOrDefault("X-Amz-Target")
  valid_600449 = validateParameter(valid_600449, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_600449 != nil:
    section.add "X-Amz-Target", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Content-Sha256", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Algorithm")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Algorithm", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Signature")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Signature", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-SignedHeaders", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Credential")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Credential", valid_600454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600456: Call_ListArtifacts_600443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_600456.validator(path, query, header, formData, body)
  let scheme = call_600456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600456.url(scheme.get, call_600456.host, call_600456.base,
                         call_600456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600456, url, valid)

proc call*(call_600457: Call_ListArtifacts_600443; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600458 = newJObject()
  var body_600459 = newJObject()
  add(query_600458, "nextToken", newJString(nextToken))
  if body != nil:
    body_600459 = body
  result = call_600457.call(nil, query_600458, nil, nil, body_600459)

var listArtifacts* = Call_ListArtifacts_600443(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_600444, base: "/", url: url_ListArtifacts_600445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_600460 = ref object of OpenApiRestCall_599369
proc url_ListDeviceInstances_600462(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceInstances_600461(path: JsonNode; query: JsonNode;
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
  var valid_600463 = header.getOrDefault("X-Amz-Date")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Date", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Security-Token")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Security-Token", valid_600464
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600465 = header.getOrDefault("X-Amz-Target")
  valid_600465 = validateParameter(valid_600465, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_600465 != nil:
    section.add "X-Amz-Target", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Content-Sha256", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Algorithm")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Algorithm", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Signature")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Signature", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-SignedHeaders", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Credential")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Credential", valid_600470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600472: Call_ListDeviceInstances_600460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_600472.validator(path, query, header, formData, body)
  let scheme = call_600472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600472.url(scheme.get, call_600472.host, call_600472.base,
                         call_600472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600472, url, valid)

proc call*(call_600473: Call_ListDeviceInstances_600460; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_600474 = newJObject()
  if body != nil:
    body_600474 = body
  result = call_600473.call(nil, nil, nil, nil, body_600474)

var listDeviceInstances* = Call_ListDeviceInstances_600460(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_600461, base: "/",
    url: url_ListDeviceInstances_600462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_600475 = ref object of OpenApiRestCall_599369
proc url_ListDevicePools_600477(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevicePools_600476(path: JsonNode; query: JsonNode;
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
  var valid_600478 = query.getOrDefault("nextToken")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "nextToken", valid_600478
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
  var valid_600479 = header.getOrDefault("X-Amz-Date")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Date", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Security-Token")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Security-Token", valid_600480
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600481 = header.getOrDefault("X-Amz-Target")
  valid_600481 = validateParameter(valid_600481, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_600481 != nil:
    section.add "X-Amz-Target", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Content-Sha256", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Algorithm")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Algorithm", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Signature")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Signature", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-SignedHeaders", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Credential")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Credential", valid_600486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600488: Call_ListDevicePools_600475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_600488.validator(path, query, header, formData, body)
  let scheme = call_600488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600488.url(scheme.get, call_600488.host, call_600488.base,
                         call_600488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600488, url, valid)

proc call*(call_600489: Call_ListDevicePools_600475; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600490 = newJObject()
  var body_600491 = newJObject()
  add(query_600490, "nextToken", newJString(nextToken))
  if body != nil:
    body_600491 = body
  result = call_600489.call(nil, query_600490, nil, nil, body_600491)

var listDevicePools* = Call_ListDevicePools_600475(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_600476, base: "/", url: url_ListDevicePools_600477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_600492 = ref object of OpenApiRestCall_599369
proc url_ListDevices_600494(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_600493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600495 = query.getOrDefault("nextToken")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "nextToken", valid_600495
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
  var valid_600496 = header.getOrDefault("X-Amz-Date")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Date", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Security-Token")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Security-Token", valid_600497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600498 = header.getOrDefault("X-Amz-Target")
  valid_600498 = validateParameter(valid_600498, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_600498 != nil:
    section.add "X-Amz-Target", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Content-Sha256", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Algorithm")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Algorithm", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Signature")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Signature", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-SignedHeaders", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Credential")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Credential", valid_600503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600505: Call_ListDevices_600492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_600505.validator(path, query, header, formData, body)
  let scheme = call_600505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600505.url(scheme.get, call_600505.host, call_600505.base,
                         call_600505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600505, url, valid)

proc call*(call_600506: Call_ListDevices_600492; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600507 = newJObject()
  var body_600508 = newJObject()
  add(query_600507, "nextToken", newJString(nextToken))
  if body != nil:
    body_600508 = body
  result = call_600506.call(nil, query_600507, nil, nil, body_600508)

var listDevices* = Call_ListDevices_600492(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_600493,
                                        base: "/", url: url_ListDevices_600494,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_600509 = ref object of OpenApiRestCall_599369
proc url_ListInstanceProfiles_600511(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstanceProfiles_600510(path: JsonNode; query: JsonNode;
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
  var valid_600512 = header.getOrDefault("X-Amz-Date")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Date", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Security-Token")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Security-Token", valid_600513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600514 = header.getOrDefault("X-Amz-Target")
  valid_600514 = validateParameter(valid_600514, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_600514 != nil:
    section.add "X-Amz-Target", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Content-Sha256", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Algorithm")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Algorithm", valid_600516
  var valid_600517 = header.getOrDefault("X-Amz-Signature")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Signature", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-SignedHeaders", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Credential")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Credential", valid_600519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600521: Call_ListInstanceProfiles_600509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_600521.validator(path, query, header, formData, body)
  let scheme = call_600521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600521.url(scheme.get, call_600521.host, call_600521.base,
                         call_600521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600521, url, valid)

proc call*(call_600522: Call_ListInstanceProfiles_600509; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_600523 = newJObject()
  if body != nil:
    body_600523 = body
  result = call_600522.call(nil, nil, nil, nil, body_600523)

var listInstanceProfiles* = Call_ListInstanceProfiles_600509(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_600510, base: "/",
    url: url_ListInstanceProfiles_600511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600524 = ref object of OpenApiRestCall_599369
proc url_ListJobs_600526(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_600525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600527 = query.getOrDefault("nextToken")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "nextToken", valid_600527
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
  var valid_600528 = header.getOrDefault("X-Amz-Date")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Date", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Security-Token")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Security-Token", valid_600529
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600530 = header.getOrDefault("X-Amz-Target")
  valid_600530 = validateParameter(valid_600530, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_600530 != nil:
    section.add "X-Amz-Target", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Content-Sha256", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Algorithm")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Algorithm", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Signature")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Signature", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-SignedHeaders", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Credential")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Credential", valid_600535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600537: Call_ListJobs_600524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_600537.validator(path, query, header, formData, body)
  let scheme = call_600537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600537.url(scheme.get, call_600537.host, call_600537.base,
                         call_600537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600537, url, valid)

proc call*(call_600538: Call_ListJobs_600524; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600539 = newJObject()
  var body_600540 = newJObject()
  add(query_600539, "nextToken", newJString(nextToken))
  if body != nil:
    body_600540 = body
  result = call_600538.call(nil, query_600539, nil, nil, body_600540)

var listJobs* = Call_ListJobs_600524(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_600525, base: "/",
                                  url: url_ListJobs_600526,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_600541 = ref object of OpenApiRestCall_599369
proc url_ListNetworkProfiles_600543(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNetworkProfiles_600542(path: JsonNode; query: JsonNode;
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
  var valid_600544 = header.getOrDefault("X-Amz-Date")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Date", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Security-Token")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Security-Token", valid_600545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600546 = header.getOrDefault("X-Amz-Target")
  valid_600546 = validateParameter(valid_600546, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_600546 != nil:
    section.add "X-Amz-Target", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Content-Sha256", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Algorithm")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Algorithm", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Signature")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Signature", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-SignedHeaders", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Credential")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Credential", valid_600551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600553: Call_ListNetworkProfiles_600541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_600553.validator(path, query, header, formData, body)
  let scheme = call_600553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600553.url(scheme.get, call_600553.host, call_600553.base,
                         call_600553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600553, url, valid)

proc call*(call_600554: Call_ListNetworkProfiles_600541; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_600555 = newJObject()
  if body != nil:
    body_600555 = body
  result = call_600554.call(nil, nil, nil, nil, body_600555)

var listNetworkProfiles* = Call_ListNetworkProfiles_600541(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_600542, base: "/",
    url: url_ListNetworkProfiles_600543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_600556 = ref object of OpenApiRestCall_599369
proc url_ListOfferingPromotions_600558(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferingPromotions_600557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
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
  var valid_600559 = header.getOrDefault("X-Amz-Date")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Date", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Security-Token")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Security-Token", valid_600560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600561 = header.getOrDefault("X-Amz-Target")
  valid_600561 = validateParameter(valid_600561, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_600561 != nil:
    section.add "X-Amz-Target", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Content-Sha256", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Algorithm")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Algorithm", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Signature")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Signature", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-SignedHeaders", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Credential")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Credential", valid_600566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600568: Call_ListOfferingPromotions_600556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600568.validator(path, query, header, formData, body)
  let scheme = call_600568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600568.url(scheme.get, call_600568.host, call_600568.base,
                         call_600568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600568, url, valid)

proc call*(call_600569: Call_ListOfferingPromotions_600556; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_600570 = newJObject()
  if body != nil:
    body_600570 = body
  result = call_600569.call(nil, nil, nil, nil, body_600570)

var listOfferingPromotions* = Call_ListOfferingPromotions_600556(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_600557, base: "/",
    url: url_ListOfferingPromotions_600558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_600571 = ref object of OpenApiRestCall_599369
proc url_ListOfferingTransactions_600573(protocol: Scheme; host: string;
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

proc validate_ListOfferingTransactions_600572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600574 = query.getOrDefault("nextToken")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "nextToken", valid_600574
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
  var valid_600575 = header.getOrDefault("X-Amz-Date")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Date", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Security-Token")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Security-Token", valid_600576
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600577 = header.getOrDefault("X-Amz-Target")
  valid_600577 = validateParameter(valid_600577, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_600577 != nil:
    section.add "X-Amz-Target", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Content-Sha256", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Algorithm")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Algorithm", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Signature")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Signature", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-SignedHeaders", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Credential")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Credential", valid_600582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600584: Call_ListOfferingTransactions_600571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600584.validator(path, query, header, formData, body)
  let scheme = call_600584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600584.url(scheme.get, call_600584.host, call_600584.base,
                         call_600584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600584, url, valid)

proc call*(call_600585: Call_ListOfferingTransactions_600571; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600586 = newJObject()
  var body_600587 = newJObject()
  add(query_600586, "nextToken", newJString(nextToken))
  if body != nil:
    body_600587 = body
  result = call_600585.call(nil, query_600586, nil, nil, body_600587)

var listOfferingTransactions* = Call_ListOfferingTransactions_600571(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_600572, base: "/",
    url: url_ListOfferingTransactions_600573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_600588 = ref object of OpenApiRestCall_599369
proc url_ListOfferings_600590(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_600589(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600591 = query.getOrDefault("nextToken")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "nextToken", valid_600591
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
  var valid_600592 = header.getOrDefault("X-Amz-Date")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Date", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Security-Token")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Security-Token", valid_600593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600594 = header.getOrDefault("X-Amz-Target")
  valid_600594 = validateParameter(valid_600594, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_600594 != nil:
    section.add "X-Amz-Target", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Content-Sha256", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Algorithm")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Algorithm", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Signature")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Signature", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-SignedHeaders", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Credential")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Credential", valid_600599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600601: Call_ListOfferings_600588; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600601.validator(path, query, header, formData, body)
  let scheme = call_600601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600601.url(scheme.get, call_600601.host, call_600601.base,
                         call_600601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600601, url, valid)

proc call*(call_600602: Call_ListOfferings_600588; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600603 = newJObject()
  var body_600604 = newJObject()
  add(query_600603, "nextToken", newJString(nextToken))
  if body != nil:
    body_600604 = body
  result = call_600602.call(nil, query_600603, nil, nil, body_600604)

var listOfferings* = Call_ListOfferings_600588(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_600589, base: "/", url: url_ListOfferings_600590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_600605 = ref object of OpenApiRestCall_599369
proc url_ListProjects_600607(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_600606(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600608 = query.getOrDefault("nextToken")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "nextToken", valid_600608
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
  var valid_600609 = header.getOrDefault("X-Amz-Date")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Date", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Security-Token")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Security-Token", valid_600610
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600611 = header.getOrDefault("X-Amz-Target")
  valid_600611 = validateParameter(valid_600611, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_600611 != nil:
    section.add "X-Amz-Target", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Content-Sha256", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Algorithm")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Algorithm", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Signature")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Signature", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-SignedHeaders", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Credential")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Credential", valid_600616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600618: Call_ListProjects_600605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_600618.validator(path, query, header, formData, body)
  let scheme = call_600618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600618.url(scheme.get, call_600618.host, call_600618.base,
                         call_600618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600618, url, valid)

proc call*(call_600619: Call_ListProjects_600605; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600620 = newJObject()
  var body_600621 = newJObject()
  add(query_600620, "nextToken", newJString(nextToken))
  if body != nil:
    body_600621 = body
  result = call_600619.call(nil, query_600620, nil, nil, body_600621)

var listProjects* = Call_ListProjects_600605(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_600606, base: "/", url: url_ListProjects_600607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_600622 = ref object of OpenApiRestCall_599369
proc url_ListRemoteAccessSessions_600624(protocol: Scheme; host: string;
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

proc validate_ListRemoteAccessSessions_600623(path: JsonNode; query: JsonNode;
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
  var valid_600625 = header.getOrDefault("X-Amz-Date")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Date", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Security-Token")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Security-Token", valid_600626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600627 = header.getOrDefault("X-Amz-Target")
  valid_600627 = validateParameter(valid_600627, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_600627 != nil:
    section.add "X-Amz-Target", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Content-Sha256", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Algorithm")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Algorithm", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Signature")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Signature", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-SignedHeaders", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Credential")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Credential", valid_600632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600634: Call_ListRemoteAccessSessions_600622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_600634.validator(path, query, header, formData, body)
  let scheme = call_600634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600634.url(scheme.get, call_600634.host, call_600634.base,
                         call_600634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600634, url, valid)

proc call*(call_600635: Call_ListRemoteAccessSessions_600622; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_600636 = newJObject()
  if body != nil:
    body_600636 = body
  result = call_600635.call(nil, nil, nil, nil, body_600636)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_600622(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_600623, base: "/",
    url: url_ListRemoteAccessSessions_600624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_600637 = ref object of OpenApiRestCall_599369
proc url_ListRuns_600639(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuns_600638(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600640 = query.getOrDefault("nextToken")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "nextToken", valid_600640
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
  var valid_600641 = header.getOrDefault("X-Amz-Date")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Date", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Security-Token")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Security-Token", valid_600642
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600643 = header.getOrDefault("X-Amz-Target")
  valid_600643 = validateParameter(valid_600643, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_600643 != nil:
    section.add "X-Amz-Target", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Content-Sha256", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Algorithm")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Algorithm", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-Signature")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-Signature", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-SignedHeaders", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Credential")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Credential", valid_600648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600650: Call_ListRuns_600637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_600650.validator(path, query, header, formData, body)
  let scheme = call_600650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600650.url(scheme.get, call_600650.host, call_600650.base,
                         call_600650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600650, url, valid)

proc call*(call_600651: Call_ListRuns_600637; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600652 = newJObject()
  var body_600653 = newJObject()
  add(query_600652, "nextToken", newJString(nextToken))
  if body != nil:
    body_600653 = body
  result = call_600651.call(nil, query_600652, nil, nil, body_600653)

var listRuns* = Call_ListRuns_600637(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_600638, base: "/",
                                  url: url_ListRuns_600639,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_600654 = ref object of OpenApiRestCall_599369
proc url_ListSamples_600656(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSamples_600655(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600657 = query.getOrDefault("nextToken")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "nextToken", valid_600657
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
  var valid_600658 = header.getOrDefault("X-Amz-Date")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Date", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Security-Token")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Security-Token", valid_600659
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600660 = header.getOrDefault("X-Amz-Target")
  valid_600660 = validateParameter(valid_600660, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_600660 != nil:
    section.add "X-Amz-Target", valid_600660
  var valid_600661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Content-Sha256", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Algorithm")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Algorithm", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Signature")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Signature", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-SignedHeaders", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Credential")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Credential", valid_600665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600667: Call_ListSamples_600654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_600667.validator(path, query, header, formData, body)
  let scheme = call_600667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600667.url(scheme.get, call_600667.host, call_600667.base,
                         call_600667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600667, url, valid)

proc call*(call_600668: Call_ListSamples_600654; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600669 = newJObject()
  var body_600670 = newJObject()
  add(query_600669, "nextToken", newJString(nextToken))
  if body != nil:
    body_600670 = body
  result = call_600668.call(nil, query_600669, nil, nil, body_600670)

var listSamples* = Call_ListSamples_600654(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_600655,
                                        base: "/", url: url_ListSamples_600656,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_600671 = ref object of OpenApiRestCall_599369
proc url_ListSuites_600673(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuites_600672(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600674 = query.getOrDefault("nextToken")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "nextToken", valid_600674
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
  var valid_600675 = header.getOrDefault("X-Amz-Date")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Date", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Security-Token")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Security-Token", valid_600676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600677 = header.getOrDefault("X-Amz-Target")
  valid_600677 = validateParameter(valid_600677, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_600677 != nil:
    section.add "X-Amz-Target", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Content-Sha256", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Algorithm")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Algorithm", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Signature")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Signature", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-SignedHeaders", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Credential")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Credential", valid_600682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600684: Call_ListSuites_600671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_600684.validator(path, query, header, formData, body)
  let scheme = call_600684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600684.url(scheme.get, call_600684.host, call_600684.base,
                         call_600684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600684, url, valid)

proc call*(call_600685: Call_ListSuites_600671; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600686 = newJObject()
  var body_600687 = newJObject()
  add(query_600686, "nextToken", newJString(nextToken))
  if body != nil:
    body_600687 = body
  result = call_600685.call(nil, query_600686, nil, nil, body_600687)

var listSuites* = Call_ListSuites_600671(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_600672,
                                      base: "/", url: url_ListSuites_600673,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600688 = ref object of OpenApiRestCall_599369
proc url_ListTagsForResource_600690(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600689(path: JsonNode; query: JsonNode;
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
  var valid_600691 = header.getOrDefault("X-Amz-Date")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Date", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Security-Token")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Security-Token", valid_600692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600693 = header.getOrDefault("X-Amz-Target")
  valid_600693 = validateParameter(valid_600693, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_600693 != nil:
    section.add "X-Amz-Target", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Content-Sha256", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Algorithm")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Algorithm", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Signature")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Signature", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-SignedHeaders", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Credential")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Credential", valid_600698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600700: Call_ListTagsForResource_600688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_600700.validator(path, query, header, formData, body)
  let scheme = call_600700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600700.url(scheme.get, call_600700.host, call_600700.base,
                         call_600700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600700, url, valid)

proc call*(call_600701: Call_ListTagsForResource_600688; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_600702 = newJObject()
  if body != nil:
    body_600702 = body
  result = call_600701.call(nil, nil, nil, nil, body_600702)

var listTagsForResource* = Call_ListTagsForResource_600688(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_600689, base: "/",
    url: url_ListTagsForResource_600690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_600703 = ref object of OpenApiRestCall_599369
proc url_ListTests_600705(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTests_600704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600706 = query.getOrDefault("nextToken")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "nextToken", valid_600706
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
  var valid_600707 = header.getOrDefault("X-Amz-Date")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Date", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Security-Token")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Security-Token", valid_600708
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600709 = header.getOrDefault("X-Amz-Target")
  valid_600709 = validateParameter(valid_600709, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_600709 != nil:
    section.add "X-Amz-Target", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Content-Sha256", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Algorithm")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Algorithm", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Signature")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Signature", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-SignedHeaders", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-Credential")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Credential", valid_600714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600716: Call_ListTests_600703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_600716.validator(path, query, header, formData, body)
  let scheme = call_600716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600716.url(scheme.get, call_600716.host, call_600716.base,
                         call_600716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600716, url, valid)

proc call*(call_600717: Call_ListTests_600703; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600718 = newJObject()
  var body_600719 = newJObject()
  add(query_600718, "nextToken", newJString(nextToken))
  if body != nil:
    body_600719 = body
  result = call_600717.call(nil, query_600718, nil, nil, body_600719)

var listTests* = Call_ListTests_600703(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_600704,
                                    base: "/", url: url_ListTests_600705,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_600720 = ref object of OpenApiRestCall_599369
proc url_ListUniqueProblems_600722(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUniqueProblems_600721(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about unique problems.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600723 = query.getOrDefault("nextToken")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "nextToken", valid_600723
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
  var valid_600724 = header.getOrDefault("X-Amz-Date")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Date", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Security-Token")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Security-Token", valid_600725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600726 = header.getOrDefault("X-Amz-Target")
  valid_600726 = validateParameter(valid_600726, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_600726 != nil:
    section.add "X-Amz-Target", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Content-Sha256", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Algorithm")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Algorithm", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Signature")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Signature", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-SignedHeaders", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Credential")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Credential", valid_600731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600733: Call_ListUniqueProblems_600720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique problems.
  ## 
  let valid = call_600733.validator(path, query, header, formData, body)
  let scheme = call_600733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600733.url(scheme.get, call_600733.host, call_600733.base,
                         call_600733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600733, url, valid)

proc call*(call_600734: Call_ListUniqueProblems_600720; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## Gets information about unique problems.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600735 = newJObject()
  var body_600736 = newJObject()
  add(query_600735, "nextToken", newJString(nextToken))
  if body != nil:
    body_600736 = body
  result = call_600734.call(nil, query_600735, nil, nil, body_600736)

var listUniqueProblems* = Call_ListUniqueProblems_600720(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_600721, base: "/",
    url: url_ListUniqueProblems_600722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_600737 = ref object of OpenApiRestCall_599369
proc url_ListUploads_600739(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUploads_600738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600740 = query.getOrDefault("nextToken")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "nextToken", valid_600740
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
  var valid_600741 = header.getOrDefault("X-Amz-Date")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Date", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Security-Token")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Security-Token", valid_600742
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600743 = header.getOrDefault("X-Amz-Target")
  valid_600743 = validateParameter(valid_600743, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_600743 != nil:
    section.add "X-Amz-Target", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-Content-Sha256", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Algorithm")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Algorithm", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Signature")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Signature", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-SignedHeaders", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Credential")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Credential", valid_600748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600750: Call_ListUploads_600737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_600750.validator(path, query, header, formData, body)
  let scheme = call_600750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600750.url(scheme.get, call_600750.host, call_600750.base,
                         call_600750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600750, url, valid)

proc call*(call_600751: Call_ListUploads_600737; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600752 = newJObject()
  var body_600753 = newJObject()
  add(query_600752, "nextToken", newJString(nextToken))
  if body != nil:
    body_600753 = body
  result = call_600751.call(nil, query_600752, nil, nil, body_600753)

var listUploads* = Call_ListUploads_600737(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_600738,
                                        base: "/", url: url_ListUploads_600739,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_600754 = ref object of OpenApiRestCall_599369
proc url_ListVPCEConfigurations_600756(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVPCEConfigurations_600755(path: JsonNode; query: JsonNode;
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
  var valid_600757 = header.getOrDefault("X-Amz-Date")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Date", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Security-Token")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Security-Token", valid_600758
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600759 = header.getOrDefault("X-Amz-Target")
  valid_600759 = validateParameter(valid_600759, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_600759 != nil:
    section.add "X-Amz-Target", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Content-Sha256", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Algorithm")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Algorithm", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Signature")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Signature", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-SignedHeaders", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Credential")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Credential", valid_600764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600766: Call_ListVPCEConfigurations_600754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_600766.validator(path, query, header, formData, body)
  let scheme = call_600766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600766.url(scheme.get, call_600766.host, call_600766.base,
                         call_600766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600766, url, valid)

proc call*(call_600767: Call_ListVPCEConfigurations_600754; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_600768 = newJObject()
  if body != nil:
    body_600768 = body
  result = call_600767.call(nil, nil, nil, nil, body_600768)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_600754(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_600755, base: "/",
    url: url_ListVPCEConfigurations_600756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_600769 = ref object of OpenApiRestCall_599369
proc url_PurchaseOffering_600771(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseOffering_600770(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
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
  var valid_600772 = header.getOrDefault("X-Amz-Date")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Date", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Security-Token")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Security-Token", valid_600773
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600774 = header.getOrDefault("X-Amz-Target")
  valid_600774 = validateParameter(valid_600774, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_600774 != nil:
    section.add "X-Amz-Target", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Content-Sha256", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Algorithm")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Algorithm", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Signature")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Signature", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-SignedHeaders", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Credential")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Credential", valid_600779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_PurchaseOffering_600769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_PurchaseOffering_600769; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_600783 = newJObject()
  if body != nil:
    body_600783 = body
  result = call_600782.call(nil, nil, nil, nil, body_600783)

var purchaseOffering* = Call_PurchaseOffering_600769(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_600770, base: "/",
    url: url_PurchaseOffering_600771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_600784 = ref object of OpenApiRestCall_599369
proc url_RenewOffering_600786(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenewOffering_600785(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
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
  var valid_600787 = header.getOrDefault("X-Amz-Date")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Date", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Security-Token")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Security-Token", valid_600788
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600789 = header.getOrDefault("X-Amz-Target")
  valid_600789 = validateParameter(valid_600789, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_600789 != nil:
    section.add "X-Amz-Target", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Content-Sha256", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-Algorithm")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Algorithm", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-Signature")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Signature", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-SignedHeaders", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Credential")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Credential", valid_600794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600796: Call_RenewOffering_600784; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_600796.validator(path, query, header, formData, body)
  let scheme = call_600796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600796.url(scheme.get, call_600796.host, call_600796.base,
                         call_600796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600796, url, valid)

proc call*(call_600797: Call_RenewOffering_600784; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_600798 = newJObject()
  if body != nil:
    body_600798 = body
  result = call_600797.call(nil, nil, nil, nil, body_600798)

var renewOffering* = Call_RenewOffering_600784(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_600785, base: "/", url: url_RenewOffering_600786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_600799 = ref object of OpenApiRestCall_599369
proc url_ScheduleRun_600801(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleRun_600800(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600802 = header.getOrDefault("X-Amz-Date")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Date", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Security-Token")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Security-Token", valid_600803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600804 = header.getOrDefault("X-Amz-Target")
  valid_600804 = validateParameter(valid_600804, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_600804 != nil:
    section.add "X-Amz-Target", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Content-Sha256", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Algorithm")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Algorithm", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Signature")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Signature", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-SignedHeaders", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-Credential")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Credential", valid_600809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600811: Call_ScheduleRun_600799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_600811.validator(path, query, header, formData, body)
  let scheme = call_600811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600811.url(scheme.get, call_600811.host, call_600811.base,
                         call_600811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600811, url, valid)

proc call*(call_600812: Call_ScheduleRun_600799; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_600813 = newJObject()
  if body != nil:
    body_600813 = body
  result = call_600812.call(nil, nil, nil, nil, body_600813)

var scheduleRun* = Call_ScheduleRun_600799(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_600800,
                                        base: "/", url: url_ScheduleRun_600801,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_600814 = ref object of OpenApiRestCall_599369
proc url_StopJob_600816(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopJob_600815(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
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
  var valid_600817 = header.getOrDefault("X-Amz-Date")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Date", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Security-Token")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Security-Token", valid_600818
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600819 = header.getOrDefault("X-Amz-Target")
  valid_600819 = validateParameter(valid_600819, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_600819 != nil:
    section.add "X-Amz-Target", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Content-Sha256", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-Algorithm")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Algorithm", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Signature")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Signature", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-SignedHeaders", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Credential")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Credential", valid_600824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600826: Call_StopJob_600814; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_600826.validator(path, query, header, formData, body)
  let scheme = call_600826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600826.url(scheme.get, call_600826.host, call_600826.base,
                         call_600826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600826, url, valid)

proc call*(call_600827: Call_StopJob_600814; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_600828 = newJObject()
  if body != nil:
    body_600828 = body
  result = call_600827.call(nil, nil, nil, nil, body_600828)

var stopJob* = Call_StopJob_600814(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_600815, base: "/",
                                url: url_StopJob_600816,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_600829 = ref object of OpenApiRestCall_599369
proc url_StopRemoteAccessSession_600831(protocol: Scheme; host: string; base: string;
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

proc validate_StopRemoteAccessSession_600830(path: JsonNode; query: JsonNode;
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
  var valid_600832 = header.getOrDefault("X-Amz-Date")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-Date", valid_600832
  var valid_600833 = header.getOrDefault("X-Amz-Security-Token")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Security-Token", valid_600833
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600834 = header.getOrDefault("X-Amz-Target")
  valid_600834 = validateParameter(valid_600834, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_600834 != nil:
    section.add "X-Amz-Target", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Content-Sha256", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Algorithm")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Algorithm", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Signature")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Signature", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-SignedHeaders", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Credential")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Credential", valid_600839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600841: Call_StopRemoteAccessSession_600829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_600841.validator(path, query, header, formData, body)
  let scheme = call_600841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600841.url(scheme.get, call_600841.host, call_600841.base,
                         call_600841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600841, url, valid)

proc call*(call_600842: Call_StopRemoteAccessSession_600829; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_600843 = newJObject()
  if body != nil:
    body_600843 = body
  result = call_600842.call(nil, nil, nil, nil, body_600843)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_600829(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_600830, base: "/",
    url: url_StopRemoteAccessSession_600831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_600844 = ref object of OpenApiRestCall_599369
proc url_StopRun_600846(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRun_600845(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
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
  var valid_600847 = header.getOrDefault("X-Amz-Date")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Date", valid_600847
  var valid_600848 = header.getOrDefault("X-Amz-Security-Token")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "X-Amz-Security-Token", valid_600848
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600849 = header.getOrDefault("X-Amz-Target")
  valid_600849 = validateParameter(valid_600849, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_600849 != nil:
    section.add "X-Amz-Target", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Content-Sha256", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Algorithm")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Algorithm", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Signature")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Signature", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-SignedHeaders", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Credential")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Credential", valid_600854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600856: Call_StopRun_600844; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_600856.validator(path, query, header, formData, body)
  let scheme = call_600856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600856.url(scheme.get, call_600856.host, call_600856.base,
                         call_600856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600856, url, valid)

proc call*(call_600857: Call_StopRun_600844; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_600858 = newJObject()
  if body != nil:
    body_600858 = body
  result = call_600857.call(nil, nil, nil, nil, body_600858)

var stopRun* = Call_StopRun_600844(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_600845, base: "/",
                                url: url_StopRun_600846,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600859 = ref object of OpenApiRestCall_599369
proc url_TagResource_600861(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600860(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
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
  var valid_600862 = header.getOrDefault("X-Amz-Date")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Date", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-Security-Token")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-Security-Token", valid_600863
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600864 = header.getOrDefault("X-Amz-Target")
  valid_600864 = validateParameter(valid_600864, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_600864 != nil:
    section.add "X-Amz-Target", valid_600864
  var valid_600865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Content-Sha256", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-Algorithm")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Algorithm", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Signature")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Signature", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-SignedHeaders", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Credential")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Credential", valid_600869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600871: Call_TagResource_600859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_600871.validator(path, query, header, formData, body)
  let scheme = call_600871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600871.url(scheme.get, call_600871.host, call_600871.base,
                         call_600871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600871, url, valid)

proc call*(call_600872: Call_TagResource_600859; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_600873 = newJObject()
  if body != nil:
    body_600873 = body
  result = call_600872.call(nil, nil, nil, nil, body_600873)

var tagResource* = Call_TagResource_600859(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_600860,
                                        base: "/", url: url_TagResource_600861,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600874 = ref object of OpenApiRestCall_599369
proc url_UntagResource_600876(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600875(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600877 = header.getOrDefault("X-Amz-Date")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Date", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Security-Token")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Security-Token", valid_600878
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600879 = header.getOrDefault("X-Amz-Target")
  valid_600879 = validateParameter(valid_600879, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_600879 != nil:
    section.add "X-Amz-Target", valid_600879
  var valid_600880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Content-Sha256", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Algorithm")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Algorithm", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Signature")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Signature", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-SignedHeaders", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Credential")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Credential", valid_600884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600886: Call_UntagResource_600874; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_600886.validator(path, query, header, formData, body)
  let scheme = call_600886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600886.url(scheme.get, call_600886.host, call_600886.base,
                         call_600886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600886, url, valid)

proc call*(call_600887: Call_UntagResource_600874; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_600888 = newJObject()
  if body != nil:
    body_600888 = body
  result = call_600887.call(nil, nil, nil, nil, body_600888)

var untagResource* = Call_UntagResource_600874(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_600875, base: "/", url: url_UntagResource_600876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_600889 = ref object of OpenApiRestCall_599369
proc url_UpdateDeviceInstance_600891(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeviceInstance_600890(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about an existing private device instance.
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
  var valid_600892 = header.getOrDefault("X-Amz-Date")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Date", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Security-Token")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Security-Token", valid_600893
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600894 = header.getOrDefault("X-Amz-Target")
  valid_600894 = validateParameter(valid_600894, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_600894 != nil:
    section.add "X-Amz-Target", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Content-Sha256", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Algorithm")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Algorithm", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Signature")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Signature", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-SignedHeaders", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Credential")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Credential", valid_600899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600901: Call_UpdateDeviceInstance_600889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance.
  ## 
  let valid = call_600901.validator(path, query, header, formData, body)
  let scheme = call_600901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600901.url(scheme.get, call_600901.host, call_600901.base,
                         call_600901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600901, url, valid)

proc call*(call_600902: Call_UpdateDeviceInstance_600889; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about an existing private device instance.
  ##   body: JObject (required)
  var body_600903 = newJObject()
  if body != nil:
    body_600903 = body
  result = call_600902.call(nil, nil, nil, nil, body_600903)

var updateDeviceInstance* = Call_UpdateDeviceInstance_600889(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_600890, base: "/",
    url: url_UpdateDeviceInstance_600891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_600904 = ref object of OpenApiRestCall_599369
proc url_UpdateDevicePool_600906(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevicePool_600905(path: JsonNode; query: JsonNode;
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
  var valid_600907 = header.getOrDefault("X-Amz-Date")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Date", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Security-Token")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Security-Token", valid_600908
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600909 = header.getOrDefault("X-Amz-Target")
  valid_600909 = validateParameter(valid_600909, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_600909 != nil:
    section.add "X-Amz-Target", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Content-Sha256", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Algorithm")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Algorithm", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Signature")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Signature", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-SignedHeaders", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Credential")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Credential", valid_600914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_UpdateDevicePool_600904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600916, url, valid)

proc call*(call_600917: Call_UpdateDevicePool_600904; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_600918 = newJObject()
  if body != nil:
    body_600918 = body
  result = call_600917.call(nil, nil, nil, nil, body_600918)

var updateDevicePool* = Call_UpdateDevicePool_600904(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_600905, base: "/",
    url: url_UpdateDevicePool_600906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_600919 = ref object of OpenApiRestCall_599369
proc url_UpdateInstanceProfile_600921(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceProfile_600920(path: JsonNode; query: JsonNode;
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
  var valid_600922 = header.getOrDefault("X-Amz-Date")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Date", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Security-Token")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Security-Token", valid_600923
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600924 = header.getOrDefault("X-Amz-Target")
  valid_600924 = validateParameter(valid_600924, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_600924 != nil:
    section.add "X-Amz-Target", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Content-Sha256", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Algorithm")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Algorithm", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Signature")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Signature", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-SignedHeaders", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Credential")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Credential", valid_600929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600931: Call_UpdateInstanceProfile_600919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_600931.validator(path, query, header, formData, body)
  let scheme = call_600931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600931.url(scheme.get, call_600931.host, call_600931.base,
                         call_600931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600931, url, valid)

proc call*(call_600932: Call_UpdateInstanceProfile_600919; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_600933 = newJObject()
  if body != nil:
    body_600933 = body
  result = call_600932.call(nil, nil, nil, nil, body_600933)

var updateInstanceProfile* = Call_UpdateInstanceProfile_600919(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_600920, base: "/",
    url: url_UpdateInstanceProfile_600921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_600934 = ref object of OpenApiRestCall_599369
proc url_UpdateNetworkProfile_600936(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_600935(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the network profile with specific settings.
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
  var valid_600937 = header.getOrDefault("X-Amz-Date")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Date", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Security-Token")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Security-Token", valid_600938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600939 = header.getOrDefault("X-Amz-Target")
  valid_600939 = validateParameter(valid_600939, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_600939 != nil:
    section.add "X-Amz-Target", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Content-Sha256", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Algorithm")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Algorithm", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Signature")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Signature", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-SignedHeaders", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Credential")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Credential", valid_600944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_UpdateNetworkProfile_600934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile with specific settings.
  ## 
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600946, url, valid)

proc call*(call_600947: Call_UpdateNetworkProfile_600934; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile with specific settings.
  ##   body: JObject (required)
  var body_600948 = newJObject()
  if body != nil:
    body_600948 = body
  result = call_600947.call(nil, nil, nil, nil, body_600948)

var updateNetworkProfile* = Call_UpdateNetworkProfile_600934(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_600935, base: "/",
    url: url_UpdateNetworkProfile_600936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_600949 = ref object of OpenApiRestCall_599369
proc url_UpdateProject_600951(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_600950(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600952 = header.getOrDefault("X-Amz-Date")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Date", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Security-Token")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Security-Token", valid_600953
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600954 = header.getOrDefault("X-Amz-Target")
  valid_600954 = validateParameter(valid_600954, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_600954 != nil:
    section.add "X-Amz-Target", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Content-Sha256", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Algorithm")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Algorithm", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-Signature")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-Signature", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-SignedHeaders", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-Credential")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Credential", valid_600959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600961: Call_UpdateProject_600949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_600961.validator(path, query, header, formData, body)
  let scheme = call_600961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600961.url(scheme.get, call_600961.host, call_600961.base,
                         call_600961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600961, url, valid)

proc call*(call_600962: Call_UpdateProject_600949; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_600963 = newJObject()
  if body != nil:
    body_600963 = body
  result = call_600962.call(nil, nil, nil, nil, body_600963)

var updateProject* = Call_UpdateProject_600949(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_600950, base: "/", url: url_UpdateProject_600951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_600964 = ref object of OpenApiRestCall_599369
proc url_UpdateUpload_600966(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUpload_600965(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an uploaded test specification (test spec).
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
  var valid_600967 = header.getOrDefault("X-Amz-Date")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Date", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Security-Token")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Security-Token", valid_600968
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600969 = header.getOrDefault("X-Amz-Target")
  valid_600969 = validateParameter(valid_600969, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_600969 != nil:
    section.add "X-Amz-Target", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Content-Sha256", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Algorithm")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Algorithm", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Signature")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Signature", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-SignedHeaders", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Credential")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Credential", valid_600974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600976: Call_UpdateUpload_600964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an uploaded test specification (test spec).
  ## 
  let valid = call_600976.validator(path, query, header, formData, body)
  let scheme = call_600976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600976.url(scheme.get, call_600976.host, call_600976.base,
                         call_600976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600976, url, valid)

proc call*(call_600977: Call_UpdateUpload_600964; body: JsonNode): Recallable =
  ## updateUpload
  ## Update an uploaded test specification (test spec).
  ##   body: JObject (required)
  var body_600978 = newJObject()
  if body != nil:
    body_600978 = body
  result = call_600977.call(nil, nil, nil, nil, body_600978)

var updateUpload* = Call_UpdateUpload_600964(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_600965, base: "/", url: url_UpdateUpload_600966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_600979 = ref object of OpenApiRestCall_599369
proc url_UpdateVPCEConfiguration_600981(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVPCEConfiguration_600980(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
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
  var valid_600982 = header.getOrDefault("X-Amz-Date")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Date", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Security-Token")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Security-Token", valid_600983
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600984 = header.getOrDefault("X-Amz-Target")
  valid_600984 = validateParameter(valid_600984, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_600984 != nil:
    section.add "X-Amz-Target", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Content-Sha256", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Algorithm")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Algorithm", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-Signature")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Signature", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-SignedHeaders", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Credential")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Credential", valid_600989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600991: Call_UpdateVPCEConfiguration_600979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_600991.validator(path, query, header, formData, body)
  let scheme = call_600991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600991.url(scheme.get, call_600991.host, call_600991.base,
                         call_600991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600991, url, valid)

proc call*(call_600992: Call_UpdateVPCEConfiguration_600979; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_600993 = newJObject()
  if body != nil:
    body_600993 = body
  result = call_600992.call(nil, nil, nil, nil, body_600993)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_600979(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_600980, base: "/",
    url: url_UpdateVPCEConfiguration_600981, schemes: {Scheme.Https, Scheme.Http})
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
