
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592365): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDevicePool_592704 = ref object of OpenApiRestCall_592365
proc url_CreateDevicePool_592706(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevicePool_592705(path: JsonNode; query: JsonNode;
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
  var valid_592831 = header.getOrDefault("X-Amz-Target")
  valid_592831 = validateParameter(valid_592831, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_592831 != nil:
    section.add "X-Amz-Target", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_CreateDevicePool_592704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_CreateDevicePool_592704; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_592934 = newJObject()
  if body != nil:
    body_592934 = body
  result = call_592933.call(nil, nil, nil, nil, body_592934)

var createDevicePool* = Call_CreateDevicePool_592704(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_592705, base: "/",
    url: url_CreateDevicePool_592706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_592973 = ref object of OpenApiRestCall_592365
proc url_CreateInstanceProfile_592975(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInstanceProfile_592974(path: JsonNode; query: JsonNode;
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
  var valid_592976 = header.getOrDefault("X-Amz-Target")
  valid_592976 = validateParameter(valid_592976, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_592976 != nil:
    section.add "X-Amz-Target", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592985: Call_CreateInstanceProfile_592973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_592985.validator(path, query, header, formData, body)
  let scheme = call_592985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592985.url(scheme.get, call_592985.host, call_592985.base,
                         call_592985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592985, url, valid)

proc call*(call_592986: Call_CreateInstanceProfile_592973; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_592987 = newJObject()
  if body != nil:
    body_592987 = body
  result = call_592986.call(nil, nil, nil, nil, body_592987)

var createInstanceProfile* = Call_CreateInstanceProfile_592973(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_592974, base: "/",
    url: url_CreateInstanceProfile_592975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_592988 = ref object of OpenApiRestCall_592365
proc url_CreateNetworkProfile_592990(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetworkProfile_592989(path: JsonNode; query: JsonNode;
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
  var valid_592991 = header.getOrDefault("X-Amz-Target")
  valid_592991 = validateParameter(valid_592991, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_592991 != nil:
    section.add "X-Amz-Target", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Signature")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Signature", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Content-Sha256", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Date")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Date", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Credential")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Credential", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Security-Token")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Security-Token", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Algorithm")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Algorithm", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-SignedHeaders", valid_592998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_CreateNetworkProfile_592988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_CreateNetworkProfile_592988; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_593002 = newJObject()
  if body != nil:
    body_593002 = body
  result = call_593001.call(nil, nil, nil, nil, body_593002)

var createNetworkProfile* = Call_CreateNetworkProfile_592988(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_592989, base: "/",
    url: url_CreateNetworkProfile_592990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_593003 = ref object of OpenApiRestCall_592365
proc url_CreateProject_593005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_593004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593006 = header.getOrDefault("X-Amz-Target")
  valid_593006 = validateParameter(valid_593006, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_593006 != nil:
    section.add "X-Amz-Target", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Algorithm")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Algorithm", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-SignedHeaders", valid_593013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_CreateProject_593003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new project.
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_CreateProject_593003; body: JsonNode): Recallable =
  ## createProject
  ## Creates a new project.
  ##   body: JObject (required)
  var body_593017 = newJObject()
  if body != nil:
    body_593017 = body
  result = call_593016.call(nil, nil, nil, nil, body_593017)

var createProject* = Call_CreateProject_593003(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_593004, base: "/", url: url_CreateProject_593005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_593018 = ref object of OpenApiRestCall_592365
proc url_CreateRemoteAccessSession_593020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRemoteAccessSession_593019(path: JsonNode; query: JsonNode;
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
  var valid_593021 = header.getOrDefault("X-Amz-Target")
  valid_593021 = validateParameter(valid_593021, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_593021 != nil:
    section.add "X-Amz-Target", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593030: Call_CreateRemoteAccessSession_593018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_593030.validator(path, query, header, formData, body)
  let scheme = call_593030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593030.url(scheme.get, call_593030.host, call_593030.base,
                         call_593030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593030, url, valid)

proc call*(call_593031: Call_CreateRemoteAccessSession_593018; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_593032 = newJObject()
  if body != nil:
    body_593032 = body
  result = call_593031.call(nil, nil, nil, nil, body_593032)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_593018(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_593019, base: "/",
    url: url_CreateRemoteAccessSession_593020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_593033 = ref object of OpenApiRestCall_592365
proc url_CreateUpload_593035(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUpload_593034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593036 = header.getOrDefault("X-Amz-Target")
  valid_593036 = validateParameter(valid_593036, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_593036 != nil:
    section.add "X-Amz-Target", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_CreateUpload_593033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_CreateUpload_593033; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_593047 = newJObject()
  if body != nil:
    body_593047 = body
  result = call_593046.call(nil, nil, nil, nil, body_593047)

var createUpload* = Call_CreateUpload_593033(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_593034, base: "/", url: url_CreateUpload_593035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_593048 = ref object of OpenApiRestCall_592365
proc url_CreateVPCEConfiguration_593050(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVPCEConfiguration_593049(path: JsonNode; query: JsonNode;
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
  var valid_593051 = header.getOrDefault("X-Amz-Target")
  valid_593051 = validateParameter(valid_593051, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_593051 != nil:
    section.add "X-Amz-Target", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_CreateVPCEConfiguration_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_CreateVPCEConfiguration_593048; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_593062 = newJObject()
  if body != nil:
    body_593062 = body
  result = call_593061.call(nil, nil, nil, nil, body_593062)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_593048(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_593049, base: "/",
    url: url_CreateVPCEConfiguration_593050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_593063 = ref object of OpenApiRestCall_592365
proc url_DeleteDevicePool_593065(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevicePool_593064(path: JsonNode; query: JsonNode;
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
  var valid_593066 = header.getOrDefault("X-Amz-Target")
  valid_593066 = validateParameter(valid_593066, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_593066 != nil:
    section.add "X-Amz-Target", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Signature")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Signature", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Content-Sha256", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Date")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Date", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Credential")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Credential", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Security-Token")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Security-Token", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Algorithm")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Algorithm", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-SignedHeaders", valid_593073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_DeleteDevicePool_593063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_DeleteDevicePool_593063; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_593077 = newJObject()
  if body != nil:
    body_593077 = body
  result = call_593076.call(nil, nil, nil, nil, body_593077)

var deleteDevicePool* = Call_DeleteDevicePool_593063(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_593064, base: "/",
    url: url_DeleteDevicePool_593065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_593078 = ref object of OpenApiRestCall_592365
proc url_DeleteInstanceProfile_593080(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInstanceProfile_593079(path: JsonNode; query: JsonNode;
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
  var valid_593081 = header.getOrDefault("X-Amz-Target")
  valid_593081 = validateParameter(valid_593081, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_593081 != nil:
    section.add "X-Amz-Target", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Signature")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Signature", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Content-Sha256", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Date")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Date", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Credential")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Credential", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Security-Token")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Security-Token", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Algorithm")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Algorithm", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-SignedHeaders", valid_593088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593090: Call_DeleteInstanceProfile_593078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_DeleteInstanceProfile_593078; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_593092 = newJObject()
  if body != nil:
    body_593092 = body
  result = call_593091.call(nil, nil, nil, nil, body_593092)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_593078(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_593079, base: "/",
    url: url_DeleteInstanceProfile_593080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_593093 = ref object of OpenApiRestCall_592365
proc url_DeleteNetworkProfile_593095(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNetworkProfile_593094(path: JsonNode; query: JsonNode;
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
  var valid_593096 = header.getOrDefault("X-Amz-Target")
  valid_593096 = validateParameter(valid_593096, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_593096 != nil:
    section.add "X-Amz-Target", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593105: Call_DeleteNetworkProfile_593093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_593105.validator(path, query, header, formData, body)
  let scheme = call_593105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593105.url(scheme.get, call_593105.host, call_593105.base,
                         call_593105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593105, url, valid)

proc call*(call_593106: Call_DeleteNetworkProfile_593093; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_593107 = newJObject()
  if body != nil:
    body_593107 = body
  result = call_593106.call(nil, nil, nil, nil, body_593107)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_593093(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_593094, base: "/",
    url: url_DeleteNetworkProfile_593095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_593108 = ref object of OpenApiRestCall_592365
proc url_DeleteProject_593110(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProject_593109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593111 = header.getOrDefault("X-Amz-Target")
  valid_593111 = validateParameter(valid_593111, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_593111 != nil:
    section.add "X-Amz-Target", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Signature")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Signature", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Content-Sha256", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Date")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Date", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Credential")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Credential", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Security-Token")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Security-Token", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Algorithm")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Algorithm", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-SignedHeaders", valid_593118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593120: Call_DeleteProject_593108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_593120.validator(path, query, header, formData, body)
  let scheme = call_593120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593120.url(scheme.get, call_593120.host, call_593120.base,
                         call_593120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593120, url, valid)

proc call*(call_593121: Call_DeleteProject_593108; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_593122 = newJObject()
  if body != nil:
    body_593122 = body
  result = call_593121.call(nil, nil, nil, nil, body_593122)

var deleteProject* = Call_DeleteProject_593108(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_593109, base: "/", url: url_DeleteProject_593110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_593123 = ref object of OpenApiRestCall_592365
proc url_DeleteRemoteAccessSession_593125(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRemoteAccessSession_593124(path: JsonNode; query: JsonNode;
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
  var valid_593126 = header.getOrDefault("X-Amz-Target")
  valid_593126 = validateParameter(valid_593126, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_593126 != nil:
    section.add "X-Amz-Target", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Signature")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Signature", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Content-Sha256", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Date")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Date", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Credential")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Credential", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Security-Token")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Security-Token", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Algorithm")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Algorithm", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-SignedHeaders", valid_593133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593135: Call_DeleteRemoteAccessSession_593123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_593135.validator(path, query, header, formData, body)
  let scheme = call_593135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593135.url(scheme.get, call_593135.host, call_593135.base,
                         call_593135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593135, url, valid)

proc call*(call_593136: Call_DeleteRemoteAccessSession_593123; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_593137 = newJObject()
  if body != nil:
    body_593137 = body
  result = call_593136.call(nil, nil, nil, nil, body_593137)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_593123(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_593124, base: "/",
    url: url_DeleteRemoteAccessSession_593125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_593138 = ref object of OpenApiRestCall_592365
proc url_DeleteRun_593140(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRun_593139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593141 = header.getOrDefault("X-Amz-Target")
  valid_593141 = validateParameter(valid_593141, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_593141 != nil:
    section.add "X-Amz-Target", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Signature")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Signature", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Content-Sha256", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Date")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Date", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Credential")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Credential", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Security-Token")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Security-Token", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Algorithm")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Algorithm", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-SignedHeaders", valid_593148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593150: Call_DeleteRun_593138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_593150.validator(path, query, header, formData, body)
  let scheme = call_593150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593150.url(scheme.get, call_593150.host, call_593150.base,
                         call_593150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593150, url, valid)

proc call*(call_593151: Call_DeleteRun_593138; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_593152 = newJObject()
  if body != nil:
    body_593152 = body
  result = call_593151.call(nil, nil, nil, nil, body_593152)

var deleteRun* = Call_DeleteRun_593138(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_593139,
                                    base: "/", url: url_DeleteRun_593140,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_593153 = ref object of OpenApiRestCall_592365
proc url_DeleteUpload_593155(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUpload_593154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593156 = header.getOrDefault("X-Amz-Target")
  valid_593156 = validateParameter(valid_593156, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_593156 != nil:
    section.add "X-Amz-Target", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Signature", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Content-Sha256", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Date")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Date", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Credential")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Credential", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Security-Token")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Security-Token", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Algorithm")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Algorithm", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-SignedHeaders", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_DeleteUpload_593153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_DeleteUpload_593153; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_593167 = newJObject()
  if body != nil:
    body_593167 = body
  result = call_593166.call(nil, nil, nil, nil, body_593167)

var deleteUpload* = Call_DeleteUpload_593153(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_593154, base: "/", url: url_DeleteUpload_593155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_593168 = ref object of OpenApiRestCall_592365
proc url_DeleteVPCEConfiguration_593170(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVPCEConfiguration_593169(path: JsonNode; query: JsonNode;
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
  var valid_593171 = header.getOrDefault("X-Amz-Target")
  valid_593171 = validateParameter(valid_593171, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_593171 != nil:
    section.add "X-Amz-Target", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593180: Call_DeleteVPCEConfiguration_593168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_593180.validator(path, query, header, formData, body)
  let scheme = call_593180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593180.url(scheme.get, call_593180.host, call_593180.base,
                         call_593180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593180, url, valid)

proc call*(call_593181: Call_DeleteVPCEConfiguration_593168; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_593182 = newJObject()
  if body != nil:
    body_593182 = body
  result = call_593181.call(nil, nil, nil, nil, body_593182)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_593168(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_593169, base: "/",
    url: url_DeleteVPCEConfiguration_593170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_593183 = ref object of OpenApiRestCall_592365
proc url_GetAccountSettings_593185(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccountSettings_593184(path: JsonNode; query: JsonNode;
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
  var valid_593186 = header.getOrDefault("X-Amz-Target")
  valid_593186 = validateParameter(valid_593186, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_593186 != nil:
    section.add "X-Amz-Target", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Security-Token")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Security-Token", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Algorithm")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Algorithm", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-SignedHeaders", valid_593193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593195: Call_GetAccountSettings_593183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_593195.validator(path, query, header, formData, body)
  let scheme = call_593195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593195.url(scheme.get, call_593195.host, call_593195.base,
                         call_593195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593195, url, valid)

proc call*(call_593196: Call_GetAccountSettings_593183; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_593197 = newJObject()
  if body != nil:
    body_593197 = body
  result = call_593196.call(nil, nil, nil, nil, body_593197)

var getAccountSettings* = Call_GetAccountSettings_593183(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_593184, base: "/",
    url: url_GetAccountSettings_593185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_593198 = ref object of OpenApiRestCall_592365
proc url_GetDevice_593200(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevice_593199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593201 = header.getOrDefault("X-Amz-Target")
  valid_593201 = validateParameter(valid_593201, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_593201 != nil:
    section.add "X-Amz-Target", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Signature")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Signature", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Content-Sha256", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Date")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Date", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Credential")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Credential", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Security-Token")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Security-Token", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Algorithm")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Algorithm", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-SignedHeaders", valid_593208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593210: Call_GetDevice_593198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_593210.validator(path, query, header, formData, body)
  let scheme = call_593210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593210.url(scheme.get, call_593210.host, call_593210.base,
                         call_593210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593210, url, valid)

proc call*(call_593211: Call_GetDevice_593198; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_593212 = newJObject()
  if body != nil:
    body_593212 = body
  result = call_593211.call(nil, nil, nil, nil, body_593212)

var getDevice* = Call_GetDevice_593198(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_593199,
                                    base: "/", url: url_GetDevice_593200,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_593213 = ref object of OpenApiRestCall_592365
proc url_GetDeviceInstance_593215(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeviceInstance_593214(path: JsonNode; query: JsonNode;
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
  var valid_593216 = header.getOrDefault("X-Amz-Target")
  valid_593216 = validateParameter(valid_593216, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_593216 != nil:
    section.add "X-Amz-Target", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Signature")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Signature", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Content-Sha256", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Date")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Date", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Credential")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Credential", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Security-Token")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Security-Token", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Algorithm")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Algorithm", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-SignedHeaders", valid_593223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593225: Call_GetDeviceInstance_593213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance belonging to a private device fleet.
  ## 
  let valid = call_593225.validator(path, query, header, formData, body)
  let scheme = call_593225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593225.url(scheme.get, call_593225.host, call_593225.base,
                         call_593225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593225, url, valid)

proc call*(call_593226: Call_GetDeviceInstance_593213; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance belonging to a private device fleet.
  ##   body: JObject (required)
  var body_593227 = newJObject()
  if body != nil:
    body_593227 = body
  result = call_593226.call(nil, nil, nil, nil, body_593227)

var getDeviceInstance* = Call_GetDeviceInstance_593213(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_593214, base: "/",
    url: url_GetDeviceInstance_593215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_593228 = ref object of OpenApiRestCall_592365
proc url_GetDevicePool_593230(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevicePool_593229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593231 = header.getOrDefault("X-Amz-Target")
  valid_593231 = validateParameter(valid_593231, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_593231 != nil:
    section.add "X-Amz-Target", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Signature")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Signature", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Content-Sha256", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Date")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Date", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Credential")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Credential", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Security-Token")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Security-Token", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Algorithm")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Algorithm", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-SignedHeaders", valid_593238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593240: Call_GetDevicePool_593228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_593240.validator(path, query, header, formData, body)
  let scheme = call_593240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593240.url(scheme.get, call_593240.host, call_593240.base,
                         call_593240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593240, url, valid)

proc call*(call_593241: Call_GetDevicePool_593228; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_593242 = newJObject()
  if body != nil:
    body_593242 = body
  result = call_593241.call(nil, nil, nil, nil, body_593242)

var getDevicePool* = Call_GetDevicePool_593228(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_593229, base: "/", url: url_GetDevicePool_593230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_593243 = ref object of OpenApiRestCall_592365
proc url_GetDevicePoolCompatibility_593245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevicePoolCompatibility_593244(path: JsonNode; query: JsonNode;
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
  var valid_593246 = header.getOrDefault("X-Amz-Target")
  valid_593246 = validateParameter(valid_593246, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_593246 != nil:
    section.add "X-Amz-Target", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Signature")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Signature", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Content-Sha256", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Date")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Date", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Credential")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Credential", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Security-Token")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Security-Token", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Algorithm")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Algorithm", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-SignedHeaders", valid_593253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593255: Call_GetDevicePoolCompatibility_593243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_593255.validator(path, query, header, formData, body)
  let scheme = call_593255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593255.url(scheme.get, call_593255.host, call_593255.base,
                         call_593255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593255, url, valid)

proc call*(call_593256: Call_GetDevicePoolCompatibility_593243; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_593257 = newJObject()
  if body != nil:
    body_593257 = body
  result = call_593256.call(nil, nil, nil, nil, body_593257)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_593243(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_593244, base: "/",
    url: url_GetDevicePoolCompatibility_593245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_593258 = ref object of OpenApiRestCall_592365
proc url_GetInstanceProfile_593260(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceProfile_593259(path: JsonNode; query: JsonNode;
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
  var valid_593261 = header.getOrDefault("X-Amz-Target")
  valid_593261 = validateParameter(valid_593261, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_593261 != nil:
    section.add "X-Amz-Target", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Signature")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Signature", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Content-Sha256", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Date")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Date", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Credential")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Credential", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Security-Token")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Security-Token", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Algorithm")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Algorithm", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-SignedHeaders", valid_593268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593270: Call_GetInstanceProfile_593258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_593270.validator(path, query, header, formData, body)
  let scheme = call_593270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593270.url(scheme.get, call_593270.host, call_593270.base,
                         call_593270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593270, url, valid)

proc call*(call_593271: Call_GetInstanceProfile_593258; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_593272 = newJObject()
  if body != nil:
    body_593272 = body
  result = call_593271.call(nil, nil, nil, nil, body_593272)

var getInstanceProfile* = Call_GetInstanceProfile_593258(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_593259, base: "/",
    url: url_GetInstanceProfile_593260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_593273 = ref object of OpenApiRestCall_592365
proc url_GetJob_593275(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_593274(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593276 = header.getOrDefault("X-Amz-Target")
  valid_593276 = validateParameter(valid_593276, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_593276 != nil:
    section.add "X-Amz-Target", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Signature")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Signature", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Content-Sha256", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Date")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Date", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Credential")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Credential", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Security-Token")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Security-Token", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-Algorithm")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Algorithm", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-SignedHeaders", valid_593283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593285: Call_GetJob_593273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_593285.validator(path, query, header, formData, body)
  let scheme = call_593285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593285.url(scheme.get, call_593285.host, call_593285.base,
                         call_593285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593285, url, valid)

proc call*(call_593286: Call_GetJob_593273; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_593287 = newJObject()
  if body != nil:
    body_593287 = body
  result = call_593286.call(nil, nil, nil, nil, body_593287)

var getJob* = Call_GetJob_593273(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_593274, base: "/",
                              url: url_GetJob_593275,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_593288 = ref object of OpenApiRestCall_592365
proc url_GetNetworkProfile_593290(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNetworkProfile_593289(path: JsonNode; query: JsonNode;
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
  var valid_593291 = header.getOrDefault("X-Amz-Target")
  valid_593291 = validateParameter(valid_593291, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_593291 != nil:
    section.add "X-Amz-Target", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Signature")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Signature", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Content-Sha256", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Date")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Date", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Credential")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Credential", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Security-Token")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Security-Token", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Algorithm")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Algorithm", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-SignedHeaders", valid_593298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593300: Call_GetNetworkProfile_593288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_593300.validator(path, query, header, formData, body)
  let scheme = call_593300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593300.url(scheme.get, call_593300.host, call_593300.base,
                         call_593300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593300, url, valid)

proc call*(call_593301: Call_GetNetworkProfile_593288; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_593302 = newJObject()
  if body != nil:
    body_593302 = body
  result = call_593301.call(nil, nil, nil, nil, body_593302)

var getNetworkProfile* = Call_GetNetworkProfile_593288(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_593289, base: "/",
    url: url_GetNetworkProfile_593290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_593303 = ref object of OpenApiRestCall_592365
proc url_GetOfferingStatus_593305(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOfferingStatus_593304(path: JsonNode; query: JsonNode;
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
  var valid_593306 = query.getOrDefault("nextToken")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "nextToken", valid_593306
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
  var valid_593307 = header.getOrDefault("X-Amz-Target")
  valid_593307 = validateParameter(valid_593307, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_593307 != nil:
    section.add "X-Amz-Target", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Signature")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Signature", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Content-Sha256", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Date")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Date", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Credential")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Credential", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Security-Token")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Security-Token", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Algorithm")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Algorithm", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-SignedHeaders", valid_593314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593316: Call_GetOfferingStatus_593303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593316.validator(path, query, header, formData, body)
  let scheme = call_593316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593316.url(scheme.get, call_593316.host, call_593316.base,
                         call_593316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593316, url, valid)

proc call*(call_593317: Call_GetOfferingStatus_593303; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593318 = newJObject()
  var body_593319 = newJObject()
  add(query_593318, "nextToken", newJString(nextToken))
  if body != nil:
    body_593319 = body
  result = call_593317.call(nil, query_593318, nil, nil, body_593319)

var getOfferingStatus* = Call_GetOfferingStatus_593303(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_593304, base: "/",
    url: url_GetOfferingStatus_593305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_593321 = ref object of OpenApiRestCall_592365
proc url_GetProject_593323(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetProject_593322(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593324 = header.getOrDefault("X-Amz-Target")
  valid_593324 = validateParameter(valid_593324, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_593324 != nil:
    section.add "X-Amz-Target", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Signature")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Signature", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Content-Sha256", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Date")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Date", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Credential")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Credential", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Security-Token")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Security-Token", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Algorithm")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Algorithm", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-SignedHeaders", valid_593331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593333: Call_GetProject_593321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_593333.validator(path, query, header, formData, body)
  let scheme = call_593333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593333.url(scheme.get, call_593333.host, call_593333.base,
                         call_593333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593333, url, valid)

proc call*(call_593334: Call_GetProject_593321; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_593335 = newJObject()
  if body != nil:
    body_593335 = body
  result = call_593334.call(nil, nil, nil, nil, body_593335)

var getProject* = Call_GetProject_593321(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_593322,
                                      base: "/", url: url_GetProject_593323,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_593336 = ref object of OpenApiRestCall_592365
proc url_GetRemoteAccessSession_593338(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoteAccessSession_593337(path: JsonNode; query: JsonNode;
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
  var valid_593339 = header.getOrDefault("X-Amz-Target")
  valid_593339 = validateParameter(valid_593339, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_593339 != nil:
    section.add "X-Amz-Target", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Signature")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Signature", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Content-Sha256", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Date")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Date", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Credential")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Credential", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Security-Token")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Security-Token", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Algorithm")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Algorithm", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-SignedHeaders", valid_593346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593348: Call_GetRemoteAccessSession_593336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_593348.validator(path, query, header, formData, body)
  let scheme = call_593348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593348.url(scheme.get, call_593348.host, call_593348.base,
                         call_593348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593348, url, valid)

proc call*(call_593349: Call_GetRemoteAccessSession_593336; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_593350 = newJObject()
  if body != nil:
    body_593350 = body
  result = call_593349.call(nil, nil, nil, nil, body_593350)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_593336(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_593337, base: "/",
    url: url_GetRemoteAccessSession_593338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_593351 = ref object of OpenApiRestCall_592365
proc url_GetRun_593353(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRun_593352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593354 = header.getOrDefault("X-Amz-Target")
  valid_593354 = validateParameter(valid_593354, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_593354 != nil:
    section.add "X-Amz-Target", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Signature")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Signature", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Content-Sha256", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Date")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Date", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Credential")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Credential", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Security-Token")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Security-Token", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Algorithm")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Algorithm", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-SignedHeaders", valid_593361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593363: Call_GetRun_593351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_593363.validator(path, query, header, formData, body)
  let scheme = call_593363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593363.url(scheme.get, call_593363.host, call_593363.base,
                         call_593363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593363, url, valid)

proc call*(call_593364: Call_GetRun_593351; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_593365 = newJObject()
  if body != nil:
    body_593365 = body
  result = call_593364.call(nil, nil, nil, nil, body_593365)

var getRun* = Call_GetRun_593351(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_593352, base: "/",
                              url: url_GetRun_593353,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_593366 = ref object of OpenApiRestCall_592365
proc url_GetSuite_593368(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSuite_593367(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593369 = header.getOrDefault("X-Amz-Target")
  valid_593369 = validateParameter(valid_593369, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_593369 != nil:
    section.add "X-Amz-Target", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Signature")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Signature", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Content-Sha256", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Date")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Date", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Credential")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Credential", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Security-Token")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Security-Token", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Algorithm")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Algorithm", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-SignedHeaders", valid_593376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593378: Call_GetSuite_593366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_593378.validator(path, query, header, formData, body)
  let scheme = call_593378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593378.url(scheme.get, call_593378.host, call_593378.base,
                         call_593378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593378, url, valid)

proc call*(call_593379: Call_GetSuite_593366; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_593380 = newJObject()
  if body != nil:
    body_593380 = body
  result = call_593379.call(nil, nil, nil, nil, body_593380)

var getSuite* = Call_GetSuite_593366(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_593367, base: "/",
                                  url: url_GetSuite_593368,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_593381 = ref object of OpenApiRestCall_592365
proc url_GetTest_593383(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTest_593382(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593384 = header.getOrDefault("X-Amz-Target")
  valid_593384 = validateParameter(valid_593384, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_593384 != nil:
    section.add "X-Amz-Target", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Signature")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Signature", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Content-Sha256", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Date")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Date", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Credential")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Credential", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Security-Token")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Security-Token", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Algorithm")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Algorithm", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-SignedHeaders", valid_593391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593393: Call_GetTest_593381; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_593393.validator(path, query, header, formData, body)
  let scheme = call_593393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593393.url(scheme.get, call_593393.host, call_593393.base,
                         call_593393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593393, url, valid)

proc call*(call_593394: Call_GetTest_593381; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_593395 = newJObject()
  if body != nil:
    body_593395 = body
  result = call_593394.call(nil, nil, nil, nil, body_593395)

var getTest* = Call_GetTest_593381(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_593382, base: "/",
                                url: url_GetTest_593383,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_593396 = ref object of OpenApiRestCall_592365
proc url_GetUpload_593398(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpload_593397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593399 = header.getOrDefault("X-Amz-Target")
  valid_593399 = validateParameter(valid_593399, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_593399 != nil:
    section.add "X-Amz-Target", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Signature")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Signature", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Content-Sha256", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Date")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Date", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Credential")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Credential", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Security-Token")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Security-Token", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Algorithm")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Algorithm", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-SignedHeaders", valid_593406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593408: Call_GetUpload_593396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_593408.validator(path, query, header, formData, body)
  let scheme = call_593408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593408.url(scheme.get, call_593408.host, call_593408.base,
                         call_593408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593408, url, valid)

proc call*(call_593409: Call_GetUpload_593396; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_593410 = newJObject()
  if body != nil:
    body_593410 = body
  result = call_593409.call(nil, nil, nil, nil, body_593410)

var getUpload* = Call_GetUpload_593396(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_593397,
                                    base: "/", url: url_GetUpload_593398,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_593411 = ref object of OpenApiRestCall_592365
proc url_GetVPCEConfiguration_593413(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVPCEConfiguration_593412(path: JsonNode; query: JsonNode;
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
  var valid_593414 = header.getOrDefault("X-Amz-Target")
  valid_593414 = validateParameter(valid_593414, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_593414 != nil:
    section.add "X-Amz-Target", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Signature")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Signature", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Content-Sha256", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Date")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Date", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Credential")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Credential", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Security-Token")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Security-Token", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Algorithm")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Algorithm", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-SignedHeaders", valid_593421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593423: Call_GetVPCEConfiguration_593411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_593423.validator(path, query, header, formData, body)
  let scheme = call_593423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593423.url(scheme.get, call_593423.host, call_593423.base,
                         call_593423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593423, url, valid)

proc call*(call_593424: Call_GetVPCEConfiguration_593411; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_593425 = newJObject()
  if body != nil:
    body_593425 = body
  result = call_593424.call(nil, nil, nil, nil, body_593425)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_593411(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_593412, base: "/",
    url: url_GetVPCEConfiguration_593413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_593426 = ref object of OpenApiRestCall_592365
proc url_InstallToRemoteAccessSession_593428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InstallToRemoteAccessSession_593427(path: JsonNode; query: JsonNode;
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
  var valid_593429 = header.getOrDefault("X-Amz-Target")
  valid_593429 = validateParameter(valid_593429, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_593429 != nil:
    section.add "X-Amz-Target", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Signature")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Signature", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Content-Sha256", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Date")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Date", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Credential")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Credential", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Security-Token")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Security-Token", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Algorithm")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Algorithm", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-SignedHeaders", valid_593436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593438: Call_InstallToRemoteAccessSession_593426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_593438.validator(path, query, header, formData, body)
  let scheme = call_593438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593438.url(scheme.get, call_593438.host, call_593438.base,
                         call_593438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593438, url, valid)

proc call*(call_593439: Call_InstallToRemoteAccessSession_593426; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_593440 = newJObject()
  if body != nil:
    body_593440 = body
  result = call_593439.call(nil, nil, nil, nil, body_593440)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_593426(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_593427, base: "/",
    url: url_InstallToRemoteAccessSession_593428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_593441 = ref object of OpenApiRestCall_592365
proc url_ListArtifacts_593443(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListArtifacts_593442(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593444 = query.getOrDefault("nextToken")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "nextToken", valid_593444
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
  var valid_593445 = header.getOrDefault("X-Amz-Target")
  valid_593445 = validateParameter(valid_593445, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_593445 != nil:
    section.add "X-Amz-Target", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Signature")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Signature", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Content-Sha256", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Date")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Date", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Credential")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Credential", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Security-Token")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Security-Token", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Algorithm")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Algorithm", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-SignedHeaders", valid_593452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593454: Call_ListArtifacts_593441; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_593454.validator(path, query, header, formData, body)
  let scheme = call_593454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593454.url(scheme.get, call_593454.host, call_593454.base,
                         call_593454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593454, url, valid)

proc call*(call_593455: Call_ListArtifacts_593441; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593456 = newJObject()
  var body_593457 = newJObject()
  add(query_593456, "nextToken", newJString(nextToken))
  if body != nil:
    body_593457 = body
  result = call_593455.call(nil, query_593456, nil, nil, body_593457)

var listArtifacts* = Call_ListArtifacts_593441(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_593442, base: "/", url: url_ListArtifacts_593443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_593458 = ref object of OpenApiRestCall_592365
proc url_ListDeviceInstances_593460(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceInstances_593459(path: JsonNode; query: JsonNode;
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
  var valid_593461 = header.getOrDefault("X-Amz-Target")
  valid_593461 = validateParameter(valid_593461, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_593461 != nil:
    section.add "X-Amz-Target", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Signature")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Signature", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Content-Sha256", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Date")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Date", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Credential")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Credential", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Security-Token")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Security-Token", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Algorithm")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Algorithm", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-SignedHeaders", valid_593468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593470: Call_ListDeviceInstances_593458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_593470.validator(path, query, header, formData, body)
  let scheme = call_593470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593470.url(scheme.get, call_593470.host, call_593470.base,
                         call_593470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593470, url, valid)

proc call*(call_593471: Call_ListDeviceInstances_593458; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_593472 = newJObject()
  if body != nil:
    body_593472 = body
  result = call_593471.call(nil, nil, nil, nil, body_593472)

var listDeviceInstances* = Call_ListDeviceInstances_593458(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_593459, base: "/",
    url: url_ListDeviceInstances_593460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_593473 = ref object of OpenApiRestCall_592365
proc url_ListDevicePools_593475(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevicePools_593474(path: JsonNode; query: JsonNode;
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
  var valid_593476 = query.getOrDefault("nextToken")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "nextToken", valid_593476
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
  var valid_593477 = header.getOrDefault("X-Amz-Target")
  valid_593477 = validateParameter(valid_593477, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_593477 != nil:
    section.add "X-Amz-Target", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Signature")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Signature", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Content-Sha256", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Date")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Date", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Credential")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Credential", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Security-Token")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Security-Token", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Algorithm")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Algorithm", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-SignedHeaders", valid_593484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593486: Call_ListDevicePools_593473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_593486.validator(path, query, header, formData, body)
  let scheme = call_593486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593486.url(scheme.get, call_593486.host, call_593486.base,
                         call_593486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593486, url, valid)

proc call*(call_593487: Call_ListDevicePools_593473; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593488 = newJObject()
  var body_593489 = newJObject()
  add(query_593488, "nextToken", newJString(nextToken))
  if body != nil:
    body_593489 = body
  result = call_593487.call(nil, query_593488, nil, nil, body_593489)

var listDevicePools* = Call_ListDevicePools_593473(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_593474, base: "/", url: url_ListDevicePools_593475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_593490 = ref object of OpenApiRestCall_592365
proc url_ListDevices_593492(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevices_593491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593493 = query.getOrDefault("nextToken")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "nextToken", valid_593493
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
  var valid_593494 = header.getOrDefault("X-Amz-Target")
  valid_593494 = validateParameter(valid_593494, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_593494 != nil:
    section.add "X-Amz-Target", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Signature")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Signature", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Content-Sha256", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Date")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Date", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Credential")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Credential", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Security-Token")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Security-Token", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Algorithm")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Algorithm", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-SignedHeaders", valid_593501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593503: Call_ListDevices_593490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_593503.validator(path, query, header, formData, body)
  let scheme = call_593503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593503.url(scheme.get, call_593503.host, call_593503.base,
                         call_593503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593503, url, valid)

proc call*(call_593504: Call_ListDevices_593490; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593505 = newJObject()
  var body_593506 = newJObject()
  add(query_593505, "nextToken", newJString(nextToken))
  if body != nil:
    body_593506 = body
  result = call_593504.call(nil, query_593505, nil, nil, body_593506)

var listDevices* = Call_ListDevices_593490(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_593491,
                                        base: "/", url: url_ListDevices_593492,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_593507 = ref object of OpenApiRestCall_592365
proc url_ListInstanceProfiles_593509(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInstanceProfiles_593508(path: JsonNode; query: JsonNode;
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
  var valid_593510 = header.getOrDefault("X-Amz-Target")
  valid_593510 = validateParameter(valid_593510, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_593510 != nil:
    section.add "X-Amz-Target", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Signature")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Signature", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-Content-Sha256", valid_593512
  var valid_593513 = header.getOrDefault("X-Amz-Date")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Date", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Credential")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Credential", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Security-Token")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Security-Token", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Algorithm")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Algorithm", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-SignedHeaders", valid_593517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593519: Call_ListInstanceProfiles_593507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_593519.validator(path, query, header, formData, body)
  let scheme = call_593519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593519.url(scheme.get, call_593519.host, call_593519.base,
                         call_593519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593519, url, valid)

proc call*(call_593520: Call_ListInstanceProfiles_593507; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_593521 = newJObject()
  if body != nil:
    body_593521 = body
  result = call_593520.call(nil, nil, nil, nil, body_593521)

var listInstanceProfiles* = Call_ListInstanceProfiles_593507(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_593508, base: "/",
    url: url_ListInstanceProfiles_593509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_593522 = ref object of OpenApiRestCall_592365
proc url_ListJobs_593524(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_593523(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593525 = query.getOrDefault("nextToken")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "nextToken", valid_593525
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
  var valid_593526 = header.getOrDefault("X-Amz-Target")
  valid_593526 = validateParameter(valid_593526, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_593526 != nil:
    section.add "X-Amz-Target", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-Signature")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-Signature", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-Content-Sha256", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Date")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Date", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Credential")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Credential", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Security-Token")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Security-Token", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Algorithm")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Algorithm", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-SignedHeaders", valid_593533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593535: Call_ListJobs_593522; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_593535.validator(path, query, header, formData, body)
  let scheme = call_593535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593535.url(scheme.get, call_593535.host, call_593535.base,
                         call_593535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593535, url, valid)

proc call*(call_593536: Call_ListJobs_593522; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593537 = newJObject()
  var body_593538 = newJObject()
  add(query_593537, "nextToken", newJString(nextToken))
  if body != nil:
    body_593538 = body
  result = call_593536.call(nil, query_593537, nil, nil, body_593538)

var listJobs* = Call_ListJobs_593522(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_593523, base: "/",
                                  url: url_ListJobs_593524,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_593539 = ref object of OpenApiRestCall_592365
proc url_ListNetworkProfiles_593541(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworkProfiles_593540(path: JsonNode; query: JsonNode;
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
  var valid_593542 = header.getOrDefault("X-Amz-Target")
  valid_593542 = validateParameter(valid_593542, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_593542 != nil:
    section.add "X-Amz-Target", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Signature")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Signature", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Content-Sha256", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Date")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Date", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Credential")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Credential", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Security-Token")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Security-Token", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Algorithm")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Algorithm", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-SignedHeaders", valid_593549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593551: Call_ListNetworkProfiles_593539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_593551.validator(path, query, header, formData, body)
  let scheme = call_593551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593551.url(scheme.get, call_593551.host, call_593551.base,
                         call_593551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593551, url, valid)

proc call*(call_593552: Call_ListNetworkProfiles_593539; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_593553 = newJObject()
  if body != nil:
    body_593553 = body
  result = call_593552.call(nil, nil, nil, nil, body_593553)

var listNetworkProfiles* = Call_ListNetworkProfiles_593539(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_593540, base: "/",
    url: url_ListNetworkProfiles_593541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_593554 = ref object of OpenApiRestCall_592365
proc url_ListOfferingPromotions_593556(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferingPromotions_593555(path: JsonNode; query: JsonNode;
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
  var valid_593557 = header.getOrDefault("X-Amz-Target")
  valid_593557 = validateParameter(valid_593557, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_593557 != nil:
    section.add "X-Amz-Target", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Signature")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Signature", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Content-Sha256", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Date")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Date", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Credential")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Credential", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Security-Token")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Security-Token", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Algorithm")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Algorithm", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-SignedHeaders", valid_593564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593566: Call_ListOfferingPromotions_593554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593566.validator(path, query, header, formData, body)
  let scheme = call_593566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593566.url(scheme.get, call_593566.host, call_593566.base,
                         call_593566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593566, url, valid)

proc call*(call_593567: Call_ListOfferingPromotions_593554; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_593568 = newJObject()
  if body != nil:
    body_593568 = body
  result = call_593567.call(nil, nil, nil, nil, body_593568)

var listOfferingPromotions* = Call_ListOfferingPromotions_593554(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_593555, base: "/",
    url: url_ListOfferingPromotions_593556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_593569 = ref object of OpenApiRestCall_592365
proc url_ListOfferingTransactions_593571(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferingTransactions_593570(path: JsonNode; query: JsonNode;
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
  var valid_593572 = query.getOrDefault("nextToken")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "nextToken", valid_593572
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
  var valid_593573 = header.getOrDefault("X-Amz-Target")
  valid_593573 = validateParameter(valid_593573, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_593573 != nil:
    section.add "X-Amz-Target", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Signature")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Signature", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Content-Sha256", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Date")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Date", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Credential")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Credential", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Security-Token")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Security-Token", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Algorithm")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Algorithm", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-SignedHeaders", valid_593580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593582: Call_ListOfferingTransactions_593569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593582.validator(path, query, header, formData, body)
  let scheme = call_593582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593582.url(scheme.get, call_593582.host, call_593582.base,
                         call_593582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593582, url, valid)

proc call*(call_593583: Call_ListOfferingTransactions_593569; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593584 = newJObject()
  var body_593585 = newJObject()
  add(query_593584, "nextToken", newJString(nextToken))
  if body != nil:
    body_593585 = body
  result = call_593583.call(nil, query_593584, nil, nil, body_593585)

var listOfferingTransactions* = Call_ListOfferingTransactions_593569(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_593570, base: "/",
    url: url_ListOfferingTransactions_593571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_593586 = ref object of OpenApiRestCall_592365
proc url_ListOfferings_593588(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferings_593587(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593589 = query.getOrDefault("nextToken")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "nextToken", valid_593589
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
  var valid_593590 = header.getOrDefault("X-Amz-Target")
  valid_593590 = validateParameter(valid_593590, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_593590 != nil:
    section.add "X-Amz-Target", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Signature")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Signature", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Content-Sha256", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Date")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Date", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Credential")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Credential", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Security-Token")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Security-Token", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Algorithm")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Algorithm", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-SignedHeaders", valid_593597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593599: Call_ListOfferings_593586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593599.validator(path, query, header, formData, body)
  let scheme = call_593599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593599.url(scheme.get, call_593599.host, call_593599.base,
                         call_593599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593599, url, valid)

proc call*(call_593600: Call_ListOfferings_593586; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593601 = newJObject()
  var body_593602 = newJObject()
  add(query_593601, "nextToken", newJString(nextToken))
  if body != nil:
    body_593602 = body
  result = call_593600.call(nil, query_593601, nil, nil, body_593602)

var listOfferings* = Call_ListOfferings_593586(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_593587, base: "/", url: url_ListOfferings_593588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_593603 = ref object of OpenApiRestCall_592365
proc url_ListProjects_593605(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_593604(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593606 = query.getOrDefault("nextToken")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "nextToken", valid_593606
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
  var valid_593607 = header.getOrDefault("X-Amz-Target")
  valid_593607 = validateParameter(valid_593607, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_593607 != nil:
    section.add "X-Amz-Target", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Signature")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Signature", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Content-Sha256", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Date")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Date", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Credential")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Credential", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-Security-Token")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-Security-Token", valid_593612
  var valid_593613 = header.getOrDefault("X-Amz-Algorithm")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "X-Amz-Algorithm", valid_593613
  var valid_593614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "X-Amz-SignedHeaders", valid_593614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593616: Call_ListProjects_593603; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_593616.validator(path, query, header, formData, body)
  let scheme = call_593616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593616.url(scheme.get, call_593616.host, call_593616.base,
                         call_593616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593616, url, valid)

proc call*(call_593617: Call_ListProjects_593603; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593618 = newJObject()
  var body_593619 = newJObject()
  add(query_593618, "nextToken", newJString(nextToken))
  if body != nil:
    body_593619 = body
  result = call_593617.call(nil, query_593618, nil, nil, body_593619)

var listProjects* = Call_ListProjects_593603(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_593604, base: "/", url: url_ListProjects_593605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_593620 = ref object of OpenApiRestCall_592365
proc url_ListRemoteAccessSessions_593622(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRemoteAccessSessions_593621(path: JsonNode; query: JsonNode;
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
  var valid_593623 = header.getOrDefault("X-Amz-Target")
  valid_593623 = validateParameter(valid_593623, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_593623 != nil:
    section.add "X-Amz-Target", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Signature")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Signature", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Content-Sha256", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Date")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Date", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Credential")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Credential", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Security-Token")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Security-Token", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Algorithm")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Algorithm", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-SignedHeaders", valid_593630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593632: Call_ListRemoteAccessSessions_593620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_593632.validator(path, query, header, formData, body)
  let scheme = call_593632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593632.url(scheme.get, call_593632.host, call_593632.base,
                         call_593632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593632, url, valid)

proc call*(call_593633: Call_ListRemoteAccessSessions_593620; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_593634 = newJObject()
  if body != nil:
    body_593634 = body
  result = call_593633.call(nil, nil, nil, nil, body_593634)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_593620(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_593621, base: "/",
    url: url_ListRemoteAccessSessions_593622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_593635 = ref object of OpenApiRestCall_592365
proc url_ListRuns_593637(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRuns_593636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593638 = query.getOrDefault("nextToken")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "nextToken", valid_593638
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
  var valid_593639 = header.getOrDefault("X-Amz-Target")
  valid_593639 = validateParameter(valid_593639, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_593639 != nil:
    section.add "X-Amz-Target", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Signature")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Signature", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Content-Sha256", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Date")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Date", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Credential")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Credential", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Security-Token")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Security-Token", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-Algorithm")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-Algorithm", valid_593645
  var valid_593646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593646 = validateParameter(valid_593646, JString, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "X-Amz-SignedHeaders", valid_593646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593648: Call_ListRuns_593635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_593648.validator(path, query, header, formData, body)
  let scheme = call_593648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593648.url(scheme.get, call_593648.host, call_593648.base,
                         call_593648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593648, url, valid)

proc call*(call_593649: Call_ListRuns_593635; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593650 = newJObject()
  var body_593651 = newJObject()
  add(query_593650, "nextToken", newJString(nextToken))
  if body != nil:
    body_593651 = body
  result = call_593649.call(nil, query_593650, nil, nil, body_593651)

var listRuns* = Call_ListRuns_593635(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_593636, base: "/",
                                  url: url_ListRuns_593637,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_593652 = ref object of OpenApiRestCall_592365
proc url_ListSamples_593654(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSamples_593653(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593655 = query.getOrDefault("nextToken")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "nextToken", valid_593655
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
  var valid_593656 = header.getOrDefault("X-Amz-Target")
  valid_593656 = validateParameter(valid_593656, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_593656 != nil:
    section.add "X-Amz-Target", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Signature")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Signature", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Content-Sha256", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Date")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Date", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Credential")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Credential", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593665: Call_ListSamples_593652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_593665.validator(path, query, header, formData, body)
  let scheme = call_593665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593665.url(scheme.get, call_593665.host, call_593665.base,
                         call_593665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593665, url, valid)

proc call*(call_593666: Call_ListSamples_593652; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593667 = newJObject()
  var body_593668 = newJObject()
  add(query_593667, "nextToken", newJString(nextToken))
  if body != nil:
    body_593668 = body
  result = call_593666.call(nil, query_593667, nil, nil, body_593668)

var listSamples* = Call_ListSamples_593652(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_593653,
                                        base: "/", url: url_ListSamples_593654,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_593669 = ref object of OpenApiRestCall_592365
proc url_ListSuites_593671(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSuites_593670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593672 = query.getOrDefault("nextToken")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "nextToken", valid_593672
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
  var valid_593673 = header.getOrDefault("X-Amz-Target")
  valid_593673 = validateParameter(valid_593673, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_593673 != nil:
    section.add "X-Amz-Target", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Signature")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Signature", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Content-Sha256", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Date")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Date", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Credential")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Credential", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Security-Token")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Security-Token", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Algorithm")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Algorithm", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-SignedHeaders", valid_593680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593682: Call_ListSuites_593669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_593682.validator(path, query, header, formData, body)
  let scheme = call_593682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593682.url(scheme.get, call_593682.host, call_593682.base,
                         call_593682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593682, url, valid)

proc call*(call_593683: Call_ListSuites_593669; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593684 = newJObject()
  var body_593685 = newJObject()
  add(query_593684, "nextToken", newJString(nextToken))
  if body != nil:
    body_593685 = body
  result = call_593683.call(nil, query_593684, nil, nil, body_593685)

var listSuites* = Call_ListSuites_593669(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_593670,
                                      base: "/", url: url_ListSuites_593671,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593686 = ref object of OpenApiRestCall_592365
proc url_ListTagsForResource_593688(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593687(path: JsonNode; query: JsonNode;
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
  var valid_593689 = header.getOrDefault("X-Amz-Target")
  valid_593689 = validateParameter(valid_593689, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_593689 != nil:
    section.add "X-Amz-Target", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Signature")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Signature", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Content-Sha256", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Date")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Date", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Credential")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Credential", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Security-Token")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Security-Token", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Algorithm")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Algorithm", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-SignedHeaders", valid_593696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593698: Call_ListTagsForResource_593686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_593698.validator(path, query, header, formData, body)
  let scheme = call_593698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593698.url(scheme.get, call_593698.host, call_593698.base,
                         call_593698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593698, url, valid)

proc call*(call_593699: Call_ListTagsForResource_593686; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_593700 = newJObject()
  if body != nil:
    body_593700 = body
  result = call_593699.call(nil, nil, nil, nil, body_593700)

var listTagsForResource* = Call_ListTagsForResource_593686(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_593687, base: "/",
    url: url_ListTagsForResource_593688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_593701 = ref object of OpenApiRestCall_592365
proc url_ListTests_593703(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTests_593702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593704 = query.getOrDefault("nextToken")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "nextToken", valid_593704
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
  var valid_593705 = header.getOrDefault("X-Amz-Target")
  valid_593705 = validateParameter(valid_593705, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_593705 != nil:
    section.add "X-Amz-Target", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-Signature")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Signature", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Content-Sha256", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Date")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Date", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Credential")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Credential", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Security-Token")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Security-Token", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Algorithm")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Algorithm", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-SignedHeaders", valid_593712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593714: Call_ListTests_593701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_593714.validator(path, query, header, formData, body)
  let scheme = call_593714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593714.url(scheme.get, call_593714.host, call_593714.base,
                         call_593714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593714, url, valid)

proc call*(call_593715: Call_ListTests_593701; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593716 = newJObject()
  var body_593717 = newJObject()
  add(query_593716, "nextToken", newJString(nextToken))
  if body != nil:
    body_593717 = body
  result = call_593715.call(nil, query_593716, nil, nil, body_593717)

var listTests* = Call_ListTests_593701(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_593702,
                                    base: "/", url: url_ListTests_593703,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_593718 = ref object of OpenApiRestCall_592365
proc url_ListUniqueProblems_593720(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUniqueProblems_593719(path: JsonNode; query: JsonNode;
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
  var valid_593721 = query.getOrDefault("nextToken")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "nextToken", valid_593721
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
  var valid_593722 = header.getOrDefault("X-Amz-Target")
  valid_593722 = validateParameter(valid_593722, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_593722 != nil:
    section.add "X-Amz-Target", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Signature")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Signature", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Content-Sha256", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Date")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Date", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Credential")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Credential", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Security-Token")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Security-Token", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Algorithm")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Algorithm", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-SignedHeaders", valid_593729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593731: Call_ListUniqueProblems_593718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique problems.
  ## 
  let valid = call_593731.validator(path, query, header, formData, body)
  let scheme = call_593731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593731.url(scheme.get, call_593731.host, call_593731.base,
                         call_593731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593731, url, valid)

proc call*(call_593732: Call_ListUniqueProblems_593718; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## Gets information about unique problems.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593733 = newJObject()
  var body_593734 = newJObject()
  add(query_593733, "nextToken", newJString(nextToken))
  if body != nil:
    body_593734 = body
  result = call_593732.call(nil, query_593733, nil, nil, body_593734)

var listUniqueProblems* = Call_ListUniqueProblems_593718(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_593719, base: "/",
    url: url_ListUniqueProblems_593720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_593735 = ref object of OpenApiRestCall_592365
proc url_ListUploads_593737(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUploads_593736(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593738 = query.getOrDefault("nextToken")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "nextToken", valid_593738
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
  var valid_593739 = header.getOrDefault("X-Amz-Target")
  valid_593739 = validateParameter(valid_593739, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_593739 != nil:
    section.add "X-Amz-Target", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Signature")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Signature", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Content-Sha256", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Date")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Date", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-Credential")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Credential", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-Security-Token")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Security-Token", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-Algorithm")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Algorithm", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-SignedHeaders", valid_593746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593748: Call_ListUploads_593735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_593748.validator(path, query, header, formData, body)
  let scheme = call_593748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593748.url(scheme.get, call_593748.host, call_593748.base,
                         call_593748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593748, url, valid)

proc call*(call_593749: Call_ListUploads_593735; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593750 = newJObject()
  var body_593751 = newJObject()
  add(query_593750, "nextToken", newJString(nextToken))
  if body != nil:
    body_593751 = body
  result = call_593749.call(nil, query_593750, nil, nil, body_593751)

var listUploads* = Call_ListUploads_593735(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_593736,
                                        base: "/", url: url_ListUploads_593737,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_593752 = ref object of OpenApiRestCall_592365
proc url_ListVPCEConfigurations_593754(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVPCEConfigurations_593753(path: JsonNode; query: JsonNode;
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
  var valid_593755 = header.getOrDefault("X-Amz-Target")
  valid_593755 = validateParameter(valid_593755, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_593755 != nil:
    section.add "X-Amz-Target", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-Signature")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Signature", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Content-Sha256", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Date")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Date", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Credential")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Credential", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Security-Token")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Security-Token", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Algorithm")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Algorithm", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-SignedHeaders", valid_593762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593764: Call_ListVPCEConfigurations_593752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_593764.validator(path, query, header, formData, body)
  let scheme = call_593764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593764.url(scheme.get, call_593764.host, call_593764.base,
                         call_593764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593764, url, valid)

proc call*(call_593765: Call_ListVPCEConfigurations_593752; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_593766 = newJObject()
  if body != nil:
    body_593766 = body
  result = call_593765.call(nil, nil, nil, nil, body_593766)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_593752(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_593753, base: "/",
    url: url_ListVPCEConfigurations_593754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_593767 = ref object of OpenApiRestCall_592365
proc url_PurchaseOffering_593769(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PurchaseOffering_593768(path: JsonNode; query: JsonNode;
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
  var valid_593770 = header.getOrDefault("X-Amz-Target")
  valid_593770 = validateParameter(valid_593770, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_593770 != nil:
    section.add "X-Amz-Target", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Signature")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Signature", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Content-Sha256", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Date")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Date", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Credential")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Credential", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Security-Token")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Security-Token", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Algorithm")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Algorithm", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-SignedHeaders", valid_593777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593779: Call_PurchaseOffering_593767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593779.validator(path, query, header, formData, body)
  let scheme = call_593779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593779.url(scheme.get, call_593779.host, call_593779.base,
                         call_593779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593779, url, valid)

proc call*(call_593780: Call_PurchaseOffering_593767; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_593781 = newJObject()
  if body != nil:
    body_593781 = body
  result = call_593780.call(nil, nil, nil, nil, body_593781)

var purchaseOffering* = Call_PurchaseOffering_593767(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_593768, base: "/",
    url: url_PurchaseOffering_593769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_593782 = ref object of OpenApiRestCall_592365
proc url_RenewOffering_593784(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RenewOffering_593783(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593785 = header.getOrDefault("X-Amz-Target")
  valid_593785 = validateParameter(valid_593785, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_593785 != nil:
    section.add "X-Amz-Target", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Signature")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Signature", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Content-Sha256", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Date")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Date", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Credential")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Credential", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-Security-Token")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Security-Token", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-Algorithm")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-Algorithm", valid_593791
  var valid_593792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "X-Amz-SignedHeaders", valid_593792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593794: Call_RenewOffering_593782; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_593794.validator(path, query, header, formData, body)
  let scheme = call_593794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593794.url(scheme.get, call_593794.host, call_593794.base,
                         call_593794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593794, url, valid)

proc call*(call_593795: Call_RenewOffering_593782; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_593796 = newJObject()
  if body != nil:
    body_593796 = body
  result = call_593795.call(nil, nil, nil, nil, body_593796)

var renewOffering* = Call_RenewOffering_593782(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_593783, base: "/", url: url_RenewOffering_593784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_593797 = ref object of OpenApiRestCall_592365
proc url_ScheduleRun_593799(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ScheduleRun_593798(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593800 = header.getOrDefault("X-Amz-Target")
  valid_593800 = validateParameter(valid_593800, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_593800 != nil:
    section.add "X-Amz-Target", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-Signature")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-Signature", valid_593801
  var valid_593802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-Content-Sha256", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-Date")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-Date", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-Credential")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Credential", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Security-Token")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Security-Token", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Algorithm")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Algorithm", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-SignedHeaders", valid_593807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593809: Call_ScheduleRun_593797; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_593809.validator(path, query, header, formData, body)
  let scheme = call_593809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593809.url(scheme.get, call_593809.host, call_593809.base,
                         call_593809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593809, url, valid)

proc call*(call_593810: Call_ScheduleRun_593797; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_593811 = newJObject()
  if body != nil:
    body_593811 = body
  result = call_593810.call(nil, nil, nil, nil, body_593811)

var scheduleRun* = Call_ScheduleRun_593797(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_593798,
                                        base: "/", url: url_ScheduleRun_593799,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_593812 = ref object of OpenApiRestCall_592365
proc url_StopJob_593814(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopJob_593813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593815 = header.getOrDefault("X-Amz-Target")
  valid_593815 = validateParameter(valid_593815, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_593815 != nil:
    section.add "X-Amz-Target", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-Signature")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-Signature", valid_593816
  var valid_593817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-Content-Sha256", valid_593817
  var valid_593818 = header.getOrDefault("X-Amz-Date")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-Date", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Credential")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Credential", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Security-Token")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Security-Token", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Algorithm")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Algorithm", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-SignedHeaders", valid_593822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593824: Call_StopJob_593812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_593824.validator(path, query, header, formData, body)
  let scheme = call_593824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593824.url(scheme.get, call_593824.host, call_593824.base,
                         call_593824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593824, url, valid)

proc call*(call_593825: Call_StopJob_593812; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_593826 = newJObject()
  if body != nil:
    body_593826 = body
  result = call_593825.call(nil, nil, nil, nil, body_593826)

var stopJob* = Call_StopJob_593812(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_593813, base: "/",
                                url: url_StopJob_593814,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_593827 = ref object of OpenApiRestCall_592365
proc url_StopRemoteAccessSession_593829(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopRemoteAccessSession_593828(path: JsonNode; query: JsonNode;
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
  var valid_593830 = header.getOrDefault("X-Amz-Target")
  valid_593830 = validateParameter(valid_593830, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_593830 != nil:
    section.add "X-Amz-Target", valid_593830
  var valid_593831 = header.getOrDefault("X-Amz-Signature")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-Signature", valid_593831
  var valid_593832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "X-Amz-Content-Sha256", valid_593832
  var valid_593833 = header.getOrDefault("X-Amz-Date")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-Date", valid_593833
  var valid_593834 = header.getOrDefault("X-Amz-Credential")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Credential", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Security-Token")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Security-Token", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Algorithm")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Algorithm", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-SignedHeaders", valid_593837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593839: Call_StopRemoteAccessSession_593827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_593839.validator(path, query, header, formData, body)
  let scheme = call_593839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593839.url(scheme.get, call_593839.host, call_593839.base,
                         call_593839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593839, url, valid)

proc call*(call_593840: Call_StopRemoteAccessSession_593827; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_593841 = newJObject()
  if body != nil:
    body_593841 = body
  result = call_593840.call(nil, nil, nil, nil, body_593841)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_593827(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_593828, base: "/",
    url: url_StopRemoteAccessSession_593829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_593842 = ref object of OpenApiRestCall_592365
proc url_StopRun_593844(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopRun_593843(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593845 = header.getOrDefault("X-Amz-Target")
  valid_593845 = validateParameter(valid_593845, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_593845 != nil:
    section.add "X-Amz-Target", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Signature")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Signature", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Content-Sha256", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Date")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Date", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Credential")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Credential", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Security-Token")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Security-Token", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Algorithm")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Algorithm", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-SignedHeaders", valid_593852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593854: Call_StopRun_593842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_593854.validator(path, query, header, formData, body)
  let scheme = call_593854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593854.url(scheme.get, call_593854.host, call_593854.base,
                         call_593854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593854, url, valid)

proc call*(call_593855: Call_StopRun_593842; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_593856 = newJObject()
  if body != nil:
    body_593856 = body
  result = call_593855.call(nil, nil, nil, nil, body_593856)

var stopRun* = Call_StopRun_593842(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_593843, base: "/",
                                url: url_StopRun_593844,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593857 = ref object of OpenApiRestCall_592365
proc url_TagResource_593859(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593858(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593860 = header.getOrDefault("X-Amz-Target")
  valid_593860 = validateParameter(valid_593860, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_593860 != nil:
    section.add "X-Amz-Target", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Signature")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Signature", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Content-Sha256", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Date")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Date", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Credential")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Credential", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-Security-Token")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-Security-Token", valid_593865
  var valid_593866 = header.getOrDefault("X-Amz-Algorithm")
  valid_593866 = validateParameter(valid_593866, JString, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "X-Amz-Algorithm", valid_593866
  var valid_593867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-SignedHeaders", valid_593867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593869: Call_TagResource_593857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_593869.validator(path, query, header, formData, body)
  let scheme = call_593869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593869.url(scheme.get, call_593869.host, call_593869.base,
                         call_593869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593869, url, valid)

proc call*(call_593870: Call_TagResource_593857; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_593871 = newJObject()
  if body != nil:
    body_593871 = body
  result = call_593870.call(nil, nil, nil, nil, body_593871)

var tagResource* = Call_TagResource_593857(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_593858,
                                        base: "/", url: url_TagResource_593859,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593872 = ref object of OpenApiRestCall_592365
proc url_UntagResource_593874(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593873(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593875 = header.getOrDefault("X-Amz-Target")
  valid_593875 = validateParameter(valid_593875, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_593875 != nil:
    section.add "X-Amz-Target", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Signature")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Signature", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Content-Sha256", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Date")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Date", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Credential")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Credential", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-Security-Token")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-Security-Token", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-Algorithm")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Algorithm", valid_593881
  var valid_593882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-SignedHeaders", valid_593882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593884: Call_UntagResource_593872; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_593884.validator(path, query, header, formData, body)
  let scheme = call_593884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593884.url(scheme.get, call_593884.host, call_593884.base,
                         call_593884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593884, url, valid)

proc call*(call_593885: Call_UntagResource_593872; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_593886 = newJObject()
  if body != nil:
    body_593886 = body
  result = call_593885.call(nil, nil, nil, nil, body_593886)

var untagResource* = Call_UntagResource_593872(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_593873, base: "/", url: url_UntagResource_593874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_593887 = ref object of OpenApiRestCall_592365
proc url_UpdateDeviceInstance_593889(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDeviceInstance_593888(path: JsonNode; query: JsonNode;
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
  var valid_593890 = header.getOrDefault("X-Amz-Target")
  valid_593890 = validateParameter(valid_593890, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_593890 != nil:
    section.add "X-Amz-Target", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Signature")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Signature", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Content-Sha256", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Date")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Date", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Credential")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Credential", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Security-Token")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Security-Token", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Algorithm")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Algorithm", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-SignedHeaders", valid_593897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593899: Call_UpdateDeviceInstance_593887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance.
  ## 
  let valid = call_593899.validator(path, query, header, formData, body)
  let scheme = call_593899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593899.url(scheme.get, call_593899.host, call_593899.base,
                         call_593899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593899, url, valid)

proc call*(call_593900: Call_UpdateDeviceInstance_593887; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about an existing private device instance.
  ##   body: JObject (required)
  var body_593901 = newJObject()
  if body != nil:
    body_593901 = body
  result = call_593900.call(nil, nil, nil, nil, body_593901)

var updateDeviceInstance* = Call_UpdateDeviceInstance_593887(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_593888, base: "/",
    url: url_UpdateDeviceInstance_593889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_593902 = ref object of OpenApiRestCall_592365
proc url_UpdateDevicePool_593904(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevicePool_593903(path: JsonNode; query: JsonNode;
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
  var valid_593905 = header.getOrDefault("X-Amz-Target")
  valid_593905 = validateParameter(valid_593905, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_593905 != nil:
    section.add "X-Amz-Target", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Content-Sha256", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Date")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Date", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Credential")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Credential", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Security-Token")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Security-Token", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Algorithm")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Algorithm", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-SignedHeaders", valid_593912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593914: Call_UpdateDevicePool_593902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_593914.validator(path, query, header, formData, body)
  let scheme = call_593914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593914.url(scheme.get, call_593914.host, call_593914.base,
                         call_593914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593914, url, valid)

proc call*(call_593915: Call_UpdateDevicePool_593902; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_593916 = newJObject()
  if body != nil:
    body_593916 = body
  result = call_593915.call(nil, nil, nil, nil, body_593916)

var updateDevicePool* = Call_UpdateDevicePool_593902(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_593903, base: "/",
    url: url_UpdateDevicePool_593904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_593917 = ref object of OpenApiRestCall_592365
proc url_UpdateInstanceProfile_593919(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateInstanceProfile_593918(path: JsonNode; query: JsonNode;
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
  var valid_593920 = header.getOrDefault("X-Amz-Target")
  valid_593920 = validateParameter(valid_593920, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_593920 != nil:
    section.add "X-Amz-Target", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Signature")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Signature", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Content-Sha256", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Date")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Date", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Credential")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Credential", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Security-Token")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Security-Token", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Algorithm")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Algorithm", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-SignedHeaders", valid_593927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593929: Call_UpdateInstanceProfile_593917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_593929.validator(path, query, header, formData, body)
  let scheme = call_593929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593929.url(scheme.get, call_593929.host, call_593929.base,
                         call_593929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593929, url, valid)

proc call*(call_593930: Call_UpdateInstanceProfile_593917; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_593931 = newJObject()
  if body != nil:
    body_593931 = body
  result = call_593930.call(nil, nil, nil, nil, body_593931)

var updateInstanceProfile* = Call_UpdateInstanceProfile_593917(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_593918, base: "/",
    url: url_UpdateInstanceProfile_593919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_593932 = ref object of OpenApiRestCall_592365
proc url_UpdateNetworkProfile_593934(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNetworkProfile_593933(path: JsonNode; query: JsonNode;
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
  var valid_593935 = header.getOrDefault("X-Amz-Target")
  valid_593935 = validateParameter(valid_593935, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_593935 != nil:
    section.add "X-Amz-Target", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Signature")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Signature", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Content-Sha256", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Date")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Date", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Credential")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Credential", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-Security-Token")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Security-Token", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-Algorithm")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Algorithm", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-SignedHeaders", valid_593942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593944: Call_UpdateNetworkProfile_593932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile with specific settings.
  ## 
  let valid = call_593944.validator(path, query, header, formData, body)
  let scheme = call_593944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593944.url(scheme.get, call_593944.host, call_593944.base,
                         call_593944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593944, url, valid)

proc call*(call_593945: Call_UpdateNetworkProfile_593932; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile with specific settings.
  ##   body: JObject (required)
  var body_593946 = newJObject()
  if body != nil:
    body_593946 = body
  result = call_593945.call(nil, nil, nil, nil, body_593946)

var updateNetworkProfile* = Call_UpdateNetworkProfile_593932(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_593933, base: "/",
    url: url_UpdateNetworkProfile_593934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_593947 = ref object of OpenApiRestCall_592365
proc url_UpdateProject_593949(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_593948(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593950 = header.getOrDefault("X-Amz-Target")
  valid_593950 = validateParameter(valid_593950, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_593950 != nil:
    section.add "X-Amz-Target", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Signature")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Signature", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Content-Sha256", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Date")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Date", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Credential")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Credential", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-Security-Token")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-Security-Token", valid_593955
  var valid_593956 = header.getOrDefault("X-Amz-Algorithm")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "X-Amz-Algorithm", valid_593956
  var valid_593957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-SignedHeaders", valid_593957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593959: Call_UpdateProject_593947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_593959.validator(path, query, header, formData, body)
  let scheme = call_593959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593959.url(scheme.get, call_593959.host, call_593959.base,
                         call_593959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593959, url, valid)

proc call*(call_593960: Call_UpdateProject_593947; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_593961 = newJObject()
  if body != nil:
    body_593961 = body
  result = call_593960.call(nil, nil, nil, nil, body_593961)

var updateProject* = Call_UpdateProject_593947(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_593948, base: "/", url: url_UpdateProject_593949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_593962 = ref object of OpenApiRestCall_592365
proc url_UpdateUpload_593964(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUpload_593963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593965 = header.getOrDefault("X-Amz-Target")
  valid_593965 = validateParameter(valid_593965, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_593965 != nil:
    section.add "X-Amz-Target", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Signature")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Signature", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Content-Sha256", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Date")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Date", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-Credential")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-Credential", valid_593969
  var valid_593970 = header.getOrDefault("X-Amz-Security-Token")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "X-Amz-Security-Token", valid_593970
  var valid_593971 = header.getOrDefault("X-Amz-Algorithm")
  valid_593971 = validateParameter(valid_593971, JString, required = false,
                                 default = nil)
  if valid_593971 != nil:
    section.add "X-Amz-Algorithm", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-SignedHeaders", valid_593972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593974: Call_UpdateUpload_593962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an uploaded test specification (test spec).
  ## 
  let valid = call_593974.validator(path, query, header, formData, body)
  let scheme = call_593974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593974.url(scheme.get, call_593974.host, call_593974.base,
                         call_593974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593974, url, valid)

proc call*(call_593975: Call_UpdateUpload_593962; body: JsonNode): Recallable =
  ## updateUpload
  ## Update an uploaded test specification (test spec).
  ##   body: JObject (required)
  var body_593976 = newJObject()
  if body != nil:
    body_593976 = body
  result = call_593975.call(nil, nil, nil, nil, body_593976)

var updateUpload* = Call_UpdateUpload_593962(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_593963, base: "/", url: url_UpdateUpload_593964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_593977 = ref object of OpenApiRestCall_592365
proc url_UpdateVPCEConfiguration_593979(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateVPCEConfiguration_593978(path: JsonNode; query: JsonNode;
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
  var valid_593980 = header.getOrDefault("X-Amz-Target")
  valid_593980 = validateParameter(valid_593980, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_593980 != nil:
    section.add "X-Amz-Target", valid_593980
  var valid_593981 = header.getOrDefault("X-Amz-Signature")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "X-Amz-Signature", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-Content-Sha256", valid_593982
  var valid_593983 = header.getOrDefault("X-Amz-Date")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "X-Amz-Date", valid_593983
  var valid_593984 = header.getOrDefault("X-Amz-Credential")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-Credential", valid_593984
  var valid_593985 = header.getOrDefault("X-Amz-Security-Token")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Security-Token", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Algorithm")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Algorithm", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-SignedHeaders", valid_593987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593989: Call_UpdateVPCEConfiguration_593977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_593989.validator(path, query, header, formData, body)
  let scheme = call_593989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593989.url(scheme.get, call_593989.host, call_593989.base,
                         call_593989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593989, url, valid)

proc call*(call_593990: Call_UpdateVPCEConfiguration_593977; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_593991 = newJObject()
  if body != nil:
    body_593991 = body
  result = call_593990.call(nil, nil, nil, nil, body_593991)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_593977(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_593978, base: "/",
    url: url_UpdateVPCEConfiguration_593979, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
