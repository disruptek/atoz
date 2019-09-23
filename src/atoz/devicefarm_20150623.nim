
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600438): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_CreateDevicePool_600775 = ref object of OpenApiRestCall_600438
proc url_CreateDevicePool_600777(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevicePool_600776(path: JsonNode; query: JsonNode;
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
  var valid_600889 = header.getOrDefault("X-Amz-Date")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Date", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Security-Token")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Security-Token", valid_600890
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600904 = header.getOrDefault("X-Amz-Target")
  valid_600904 = validateParameter(valid_600904, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_600904 != nil:
    section.add "X-Amz-Target", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Content-Sha256", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Algorithm")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Algorithm", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Signature")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Signature", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-SignedHeaders", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Credential")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Credential", valid_600909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_CreateDevicePool_600775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600933, url, valid)

proc call*(call_601004: Call_CreateDevicePool_600775; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_601005 = newJObject()
  if body != nil:
    body_601005 = body
  result = call_601004.call(nil, nil, nil, nil, body_601005)

var createDevicePool* = Call_CreateDevicePool_600775(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_600776, base: "/",
    url: url_CreateDevicePool_600777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_601044 = ref object of OpenApiRestCall_600438
proc url_CreateInstanceProfile_601046(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInstanceProfile_601045(path: JsonNode; query: JsonNode;
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
  var valid_601047 = header.getOrDefault("X-Amz-Date")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Date", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Security-Token")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Security-Token", valid_601048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601049 = header.getOrDefault("X-Amz-Target")
  valid_601049 = validateParameter(valid_601049, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_601049 != nil:
    section.add "X-Amz-Target", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Content-Sha256", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Algorithm")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Algorithm", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Signature")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Signature", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-SignedHeaders", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Credential")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Credential", valid_601054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_CreateInstanceProfile_601044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_CreateInstanceProfile_601044; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_601058 = newJObject()
  if body != nil:
    body_601058 = body
  result = call_601057.call(nil, nil, nil, nil, body_601058)

var createInstanceProfile* = Call_CreateInstanceProfile_601044(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_601045, base: "/",
    url: url_CreateInstanceProfile_601046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_601059 = ref object of OpenApiRestCall_600438
proc url_CreateNetworkProfile_601061(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetworkProfile_601060(path: JsonNode; query: JsonNode;
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
  var valid_601062 = header.getOrDefault("X-Amz-Date")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Date", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Security-Token")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Security-Token", valid_601063
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601064 = header.getOrDefault("X-Amz-Target")
  valid_601064 = validateParameter(valid_601064, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_601064 != nil:
    section.add "X-Amz-Target", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_CreateNetworkProfile_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_CreateNetworkProfile_601059; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_601073 = newJObject()
  if body != nil:
    body_601073 = body
  result = call_601072.call(nil, nil, nil, nil, body_601073)

var createNetworkProfile* = Call_CreateNetworkProfile_601059(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_601060, base: "/",
    url: url_CreateNetworkProfile_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_601074 = ref object of OpenApiRestCall_600438
proc url_CreateProject_601076(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_601075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601077 = header.getOrDefault("X-Amz-Date")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Date", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Security-Token")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Security-Token", valid_601078
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601079 = header.getOrDefault("X-Amz-Target")
  valid_601079 = validateParameter(valid_601079, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_601079 != nil:
    section.add "X-Amz-Target", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Content-Sha256", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Algorithm")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Algorithm", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Signature")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Signature", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-SignedHeaders", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Credential")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Credential", valid_601084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_CreateProject_601074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new project.
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_CreateProject_601074; body: JsonNode): Recallable =
  ## createProject
  ## Creates a new project.
  ##   body: JObject (required)
  var body_601088 = newJObject()
  if body != nil:
    body_601088 = body
  result = call_601087.call(nil, nil, nil, nil, body_601088)

var createProject* = Call_CreateProject_601074(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_601075, base: "/", url: url_CreateProject_601076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_601089 = ref object of OpenApiRestCall_600438
proc url_CreateRemoteAccessSession_601091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRemoteAccessSession_601090(path: JsonNode; query: JsonNode;
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
  var valid_601092 = header.getOrDefault("X-Amz-Date")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Date", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Security-Token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Security-Token", valid_601093
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601094 = header.getOrDefault("X-Amz-Target")
  valid_601094 = validateParameter(valid_601094, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_601094 != nil:
    section.add "X-Amz-Target", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601101: Call_CreateRemoteAccessSession_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_601101.validator(path, query, header, formData, body)
  let scheme = call_601101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601101.url(scheme.get, call_601101.host, call_601101.base,
                         call_601101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601101, url, valid)

proc call*(call_601102: Call_CreateRemoteAccessSession_601089; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_601103 = newJObject()
  if body != nil:
    body_601103 = body
  result = call_601102.call(nil, nil, nil, nil, body_601103)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_601089(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_601090, base: "/",
    url: url_CreateRemoteAccessSession_601091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_601104 = ref object of OpenApiRestCall_600438
proc url_CreateUpload_601106(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUpload_601105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601107 = header.getOrDefault("X-Amz-Date")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Date", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Security-Token")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Security-Token", valid_601108
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601109 = header.getOrDefault("X-Amz-Target")
  valid_601109 = validateParameter(valid_601109, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_601109 != nil:
    section.add "X-Amz-Target", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601116: Call_CreateUpload_601104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_601116.validator(path, query, header, formData, body)
  let scheme = call_601116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601116.url(scheme.get, call_601116.host, call_601116.base,
                         call_601116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601116, url, valid)

proc call*(call_601117: Call_CreateUpload_601104; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_601118 = newJObject()
  if body != nil:
    body_601118 = body
  result = call_601117.call(nil, nil, nil, nil, body_601118)

var createUpload* = Call_CreateUpload_601104(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_601105, base: "/", url: url_CreateUpload_601106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_601119 = ref object of OpenApiRestCall_600438
proc url_CreateVPCEConfiguration_601121(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVPCEConfiguration_601120(path: JsonNode; query: JsonNode;
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
  var valid_601122 = header.getOrDefault("X-Amz-Date")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Date", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Security-Token")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Security-Token", valid_601123
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601124 = header.getOrDefault("X-Amz-Target")
  valid_601124 = validateParameter(valid_601124, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_601124 != nil:
    section.add "X-Amz-Target", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601131: Call_CreateVPCEConfiguration_601119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_601131.validator(path, query, header, formData, body)
  let scheme = call_601131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601131.url(scheme.get, call_601131.host, call_601131.base,
                         call_601131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601131, url, valid)

proc call*(call_601132: Call_CreateVPCEConfiguration_601119; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_601133 = newJObject()
  if body != nil:
    body_601133 = body
  result = call_601132.call(nil, nil, nil, nil, body_601133)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_601119(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_601120, base: "/",
    url: url_CreateVPCEConfiguration_601121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_601134 = ref object of OpenApiRestCall_600438
proc url_DeleteDevicePool_601136(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevicePool_601135(path: JsonNode; query: JsonNode;
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
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601139 = header.getOrDefault("X-Amz-Target")
  valid_601139 = validateParameter(valid_601139, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_601139 != nil:
    section.add "X-Amz-Target", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Content-Sha256", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Algorithm")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Algorithm", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Signature")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Signature", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-SignedHeaders", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Credential")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Credential", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_DeleteDevicePool_601134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_DeleteDevicePool_601134; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_601148 = newJObject()
  if body != nil:
    body_601148 = body
  result = call_601147.call(nil, nil, nil, nil, body_601148)

var deleteDevicePool* = Call_DeleteDevicePool_601134(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_601135, base: "/",
    url: url_DeleteDevicePool_601136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_601149 = ref object of OpenApiRestCall_600438
proc url_DeleteInstanceProfile_601151(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInstanceProfile_601150(path: JsonNode; query: JsonNode;
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
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601154 = header.getOrDefault("X-Amz-Target")
  valid_601154 = validateParameter(valid_601154, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_601154 != nil:
    section.add "X-Amz-Target", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Content-Sha256", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Algorithm")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Algorithm", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Signature")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Signature", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-SignedHeaders", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Credential")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Credential", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_DeleteInstanceProfile_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_DeleteInstanceProfile_601149; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_601163 = newJObject()
  if body != nil:
    body_601163 = body
  result = call_601162.call(nil, nil, nil, nil, body_601163)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_601149(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_601150, base: "/",
    url: url_DeleteInstanceProfile_601151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_601164 = ref object of OpenApiRestCall_600438
proc url_DeleteNetworkProfile_601166(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNetworkProfile_601165(path: JsonNode; query: JsonNode;
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
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601169 = header.getOrDefault("X-Amz-Target")
  valid_601169 = validateParameter(valid_601169, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_601169 != nil:
    section.add "X-Amz-Target", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Content-Sha256", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Algorithm")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Algorithm", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Signature")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Signature", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-SignedHeaders", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Credential")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Credential", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_DeleteNetworkProfile_601164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_DeleteNetworkProfile_601164; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_601178 = newJObject()
  if body != nil:
    body_601178 = body
  result = call_601177.call(nil, nil, nil, nil, body_601178)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_601164(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_601165, base: "/",
    url: url_DeleteNetworkProfile_601166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_601179 = ref object of OpenApiRestCall_600438
proc url_DeleteProject_601181(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProject_601180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601184 = header.getOrDefault("X-Amz-Target")
  valid_601184 = validateParameter(valid_601184, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_601184 != nil:
    section.add "X-Amz-Target", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_DeleteProject_601179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_DeleteProject_601179; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_601193 = newJObject()
  if body != nil:
    body_601193 = body
  result = call_601192.call(nil, nil, nil, nil, body_601193)

var deleteProject* = Call_DeleteProject_601179(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_601180, base: "/", url: url_DeleteProject_601181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_601194 = ref object of OpenApiRestCall_600438
proc url_DeleteRemoteAccessSession_601196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRemoteAccessSession_601195(path: JsonNode; query: JsonNode;
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
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601199 = header.getOrDefault("X-Amz-Target")
  valid_601199 = validateParameter(valid_601199, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_601199 != nil:
    section.add "X-Amz-Target", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Content-Sha256", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Algorithm")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Algorithm", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Signature")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Signature", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-SignedHeaders", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Credential")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Credential", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_DeleteRemoteAccessSession_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_DeleteRemoteAccessSession_601194; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_601208 = newJObject()
  if body != nil:
    body_601208 = body
  result = call_601207.call(nil, nil, nil, nil, body_601208)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_601194(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_601195, base: "/",
    url: url_DeleteRemoteAccessSession_601196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_601209 = ref object of OpenApiRestCall_600438
proc url_DeleteRun_601211(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRun_601210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601214 = header.getOrDefault("X-Amz-Target")
  valid_601214 = validateParameter(valid_601214, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_601214 != nil:
    section.add "X-Amz-Target", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_DeleteRun_601209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_DeleteRun_601209; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_601223 = newJObject()
  if body != nil:
    body_601223 = body
  result = call_601222.call(nil, nil, nil, nil, body_601223)

var deleteRun* = Call_DeleteRun_601209(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_601210,
                                    base: "/", url: url_DeleteRun_601211,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_601224 = ref object of OpenApiRestCall_600438
proc url_DeleteUpload_601226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUpload_601225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601227 = header.getOrDefault("X-Amz-Date")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Date", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Security-Token")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Security-Token", valid_601228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601229 = header.getOrDefault("X-Amz-Target")
  valid_601229 = validateParameter(valid_601229, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_601229 != nil:
    section.add "X-Amz-Target", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_DeleteUpload_601224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_DeleteUpload_601224; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_601238 = newJObject()
  if body != nil:
    body_601238 = body
  result = call_601237.call(nil, nil, nil, nil, body_601238)

var deleteUpload* = Call_DeleteUpload_601224(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_601225, base: "/", url: url_DeleteUpload_601226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_601239 = ref object of OpenApiRestCall_600438
proc url_DeleteVPCEConfiguration_601241(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVPCEConfiguration_601240(path: JsonNode; query: JsonNode;
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
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_DeleteVPCEConfiguration_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_DeleteVPCEConfiguration_601239; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_601253 = newJObject()
  if body != nil:
    body_601253 = body
  result = call_601252.call(nil, nil, nil, nil, body_601253)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_601239(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_601240, base: "/",
    url: url_DeleteVPCEConfiguration_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_601254 = ref object of OpenApiRestCall_600438
proc url_GetAccountSettings_601256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccountSettings_601255(path: JsonNode; query: JsonNode;
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
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601259 = header.getOrDefault("X-Amz-Target")
  valid_601259 = validateParameter(valid_601259, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_601259 != nil:
    section.add "X-Amz-Target", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_GetAccountSettings_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_GetAccountSettings_601254; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_601268 = newJObject()
  if body != nil:
    body_601268 = body
  result = call_601267.call(nil, nil, nil, nil, body_601268)

var getAccountSettings* = Call_GetAccountSettings_601254(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_601255, base: "/",
    url: url_GetAccountSettings_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_601269 = ref object of OpenApiRestCall_600438
proc url_GetDevice_601271(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevice_601270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601274 = header.getOrDefault("X-Amz-Target")
  valid_601274 = validateParameter(valid_601274, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_601274 != nil:
    section.add "X-Amz-Target", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_GetDevice_601269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_GetDevice_601269; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_601283 = newJObject()
  if body != nil:
    body_601283 = body
  result = call_601282.call(nil, nil, nil, nil, body_601283)

var getDevice* = Call_GetDevice_601269(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_601270,
                                    base: "/", url: url_GetDevice_601271,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_601284 = ref object of OpenApiRestCall_600438
proc url_GetDeviceInstance_601286(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeviceInstance_601285(path: JsonNode; query: JsonNode;
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601289 = header.getOrDefault("X-Amz-Target")
  valid_601289 = validateParameter(valid_601289, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_601289 != nil:
    section.add "X-Amz-Target", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_GetDeviceInstance_601284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance belonging to a private device fleet.
  ## 
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_GetDeviceInstance_601284; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance belonging to a private device fleet.
  ##   body: JObject (required)
  var body_601298 = newJObject()
  if body != nil:
    body_601298 = body
  result = call_601297.call(nil, nil, nil, nil, body_601298)

var getDeviceInstance* = Call_GetDeviceInstance_601284(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_601285, base: "/",
    url: url_GetDeviceInstance_601286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_601299 = ref object of OpenApiRestCall_600438
proc url_GetDevicePool_601301(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevicePool_601300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601302 = header.getOrDefault("X-Amz-Date")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Date", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Security-Token")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Security-Token", valid_601303
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601304 = header.getOrDefault("X-Amz-Target")
  valid_601304 = validateParameter(valid_601304, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_601304 != nil:
    section.add "X-Amz-Target", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_GetDevicePool_601299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_GetDevicePool_601299; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_601313 = newJObject()
  if body != nil:
    body_601313 = body
  result = call_601312.call(nil, nil, nil, nil, body_601313)

var getDevicePool* = Call_GetDevicePool_601299(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_601300, base: "/", url: url_GetDevicePool_601301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_601314 = ref object of OpenApiRestCall_600438
proc url_GetDevicePoolCompatibility_601316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevicePoolCompatibility_601315(path: JsonNode; query: JsonNode;
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
  var valid_601317 = header.getOrDefault("X-Amz-Date")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Date", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Security-Token")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Security-Token", valid_601318
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601319 = header.getOrDefault("X-Amz-Target")
  valid_601319 = validateParameter(valid_601319, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_601319 != nil:
    section.add "X-Amz-Target", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Content-Sha256", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Algorithm")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Algorithm", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Signature")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Signature", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-SignedHeaders", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Credential")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Credential", valid_601324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601326: Call_GetDevicePoolCompatibility_601314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_601326.validator(path, query, header, formData, body)
  let scheme = call_601326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601326.url(scheme.get, call_601326.host, call_601326.base,
                         call_601326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601326, url, valid)

proc call*(call_601327: Call_GetDevicePoolCompatibility_601314; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_601328 = newJObject()
  if body != nil:
    body_601328 = body
  result = call_601327.call(nil, nil, nil, nil, body_601328)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_601314(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_601315, base: "/",
    url: url_GetDevicePoolCompatibility_601316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_601329 = ref object of OpenApiRestCall_600438
proc url_GetInstanceProfile_601331(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceProfile_601330(path: JsonNode; query: JsonNode;
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
  var valid_601332 = header.getOrDefault("X-Amz-Date")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Date", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Security-Token")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Security-Token", valid_601333
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601334 = header.getOrDefault("X-Amz-Target")
  valid_601334 = validateParameter(valid_601334, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_601334 != nil:
    section.add "X-Amz-Target", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Content-Sha256", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Algorithm")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Algorithm", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Signature")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Signature", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-SignedHeaders", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Credential")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Credential", valid_601339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601341: Call_GetInstanceProfile_601329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_601341.validator(path, query, header, formData, body)
  let scheme = call_601341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601341.url(scheme.get, call_601341.host, call_601341.base,
                         call_601341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601341, url, valid)

proc call*(call_601342: Call_GetInstanceProfile_601329; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_601343 = newJObject()
  if body != nil:
    body_601343 = body
  result = call_601342.call(nil, nil, nil, nil, body_601343)

var getInstanceProfile* = Call_GetInstanceProfile_601329(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_601330, base: "/",
    url: url_GetInstanceProfile_601331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_601344 = ref object of OpenApiRestCall_600438
proc url_GetJob_601346(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_601345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601349 = header.getOrDefault("X-Amz-Target")
  valid_601349 = validateParameter(valid_601349, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_601349 != nil:
    section.add "X-Amz-Target", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Content-Sha256", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Algorithm")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Algorithm", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Signature")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Signature", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-SignedHeaders", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Credential")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Credential", valid_601354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601356: Call_GetJob_601344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_601356.validator(path, query, header, formData, body)
  let scheme = call_601356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601356.url(scheme.get, call_601356.host, call_601356.base,
                         call_601356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601356, url, valid)

proc call*(call_601357: Call_GetJob_601344; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_601358 = newJObject()
  if body != nil:
    body_601358 = body
  result = call_601357.call(nil, nil, nil, nil, body_601358)

var getJob* = Call_GetJob_601344(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_601345, base: "/",
                              url: url_GetJob_601346,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_601359 = ref object of OpenApiRestCall_600438
proc url_GetNetworkProfile_601361(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNetworkProfile_601360(path: JsonNode; query: JsonNode;
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
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601364 = header.getOrDefault("X-Amz-Target")
  valid_601364 = validateParameter(valid_601364, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_601364 != nil:
    section.add "X-Amz-Target", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Content-Sha256", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Algorithm")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Algorithm", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Signature")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Signature", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-SignedHeaders", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Credential")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Credential", valid_601369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_GetNetworkProfile_601359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601371, url, valid)

proc call*(call_601372: Call_GetNetworkProfile_601359; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_601373 = newJObject()
  if body != nil:
    body_601373 = body
  result = call_601372.call(nil, nil, nil, nil, body_601373)

var getNetworkProfile* = Call_GetNetworkProfile_601359(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_601360, base: "/",
    url: url_GetNetworkProfile_601361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_601374 = ref object of OpenApiRestCall_600438
proc url_GetOfferingStatus_601376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOfferingStatus_601375(path: JsonNode; query: JsonNode;
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
  var valid_601377 = query.getOrDefault("nextToken")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "nextToken", valid_601377
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
  var valid_601378 = header.getOrDefault("X-Amz-Date")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Date", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Security-Token")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Security-Token", valid_601379
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601380 = header.getOrDefault("X-Amz-Target")
  valid_601380 = validateParameter(valid_601380, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_601380 != nil:
    section.add "X-Amz-Target", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Content-Sha256", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Algorithm")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Algorithm", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Signature")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Signature", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-SignedHeaders", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Credential")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Credential", valid_601385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601387: Call_GetOfferingStatus_601374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601387.validator(path, query, header, formData, body)
  let scheme = call_601387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601387.url(scheme.get, call_601387.host, call_601387.base,
                         call_601387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601387, url, valid)

proc call*(call_601388: Call_GetOfferingStatus_601374; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601389 = newJObject()
  var body_601390 = newJObject()
  add(query_601389, "nextToken", newJString(nextToken))
  if body != nil:
    body_601390 = body
  result = call_601388.call(nil, query_601389, nil, nil, body_601390)

var getOfferingStatus* = Call_GetOfferingStatus_601374(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_601375, base: "/",
    url: url_GetOfferingStatus_601376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_601392 = ref object of OpenApiRestCall_600438
proc url_GetProject_601394(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetProject_601393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601395 = header.getOrDefault("X-Amz-Date")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Date", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Security-Token")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Security-Token", valid_601396
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601397 = header.getOrDefault("X-Amz-Target")
  valid_601397 = validateParameter(valid_601397, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_601397 != nil:
    section.add "X-Amz-Target", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Content-Sha256", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Algorithm")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Algorithm", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Signature")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Signature", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-SignedHeaders", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Credential")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Credential", valid_601402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601404: Call_GetProject_601392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_601404.validator(path, query, header, formData, body)
  let scheme = call_601404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601404.url(scheme.get, call_601404.host, call_601404.base,
                         call_601404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601404, url, valid)

proc call*(call_601405: Call_GetProject_601392; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_601406 = newJObject()
  if body != nil:
    body_601406 = body
  result = call_601405.call(nil, nil, nil, nil, body_601406)

var getProject* = Call_GetProject_601392(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_601393,
                                      base: "/", url: url_GetProject_601394,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_601407 = ref object of OpenApiRestCall_600438
proc url_GetRemoteAccessSession_601409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoteAccessSession_601408(path: JsonNode; query: JsonNode;
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
  var valid_601410 = header.getOrDefault("X-Amz-Date")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Date", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Security-Token")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Security-Token", valid_601411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601412 = header.getOrDefault("X-Amz-Target")
  valid_601412 = validateParameter(valid_601412, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_601412 != nil:
    section.add "X-Amz-Target", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Content-Sha256", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Algorithm")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Algorithm", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Signature")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Signature", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-SignedHeaders", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Credential")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Credential", valid_601417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601419: Call_GetRemoteAccessSession_601407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_601419.validator(path, query, header, formData, body)
  let scheme = call_601419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601419.url(scheme.get, call_601419.host, call_601419.base,
                         call_601419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601419, url, valid)

proc call*(call_601420: Call_GetRemoteAccessSession_601407; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_601421 = newJObject()
  if body != nil:
    body_601421 = body
  result = call_601420.call(nil, nil, nil, nil, body_601421)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_601407(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_601408, base: "/",
    url: url_GetRemoteAccessSession_601409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_601422 = ref object of OpenApiRestCall_600438
proc url_GetRun_601424(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRun_601423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601425 = header.getOrDefault("X-Amz-Date")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Date", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Security-Token")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Security-Token", valid_601426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601427 = header.getOrDefault("X-Amz-Target")
  valid_601427 = validateParameter(valid_601427, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_601427 != nil:
    section.add "X-Amz-Target", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Content-Sha256", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Algorithm")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Algorithm", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Signature")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Signature", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-SignedHeaders", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Credential")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Credential", valid_601432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601434: Call_GetRun_601422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_601434.validator(path, query, header, formData, body)
  let scheme = call_601434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601434.url(scheme.get, call_601434.host, call_601434.base,
                         call_601434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601434, url, valid)

proc call*(call_601435: Call_GetRun_601422; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_601436 = newJObject()
  if body != nil:
    body_601436 = body
  result = call_601435.call(nil, nil, nil, nil, body_601436)

var getRun* = Call_GetRun_601422(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_601423, base: "/",
                              url: url_GetRun_601424,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_601437 = ref object of OpenApiRestCall_600438
proc url_GetSuite_601439(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSuite_601438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601440 = header.getOrDefault("X-Amz-Date")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Date", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Security-Token")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Security-Token", valid_601441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601442 = header.getOrDefault("X-Amz-Target")
  valid_601442 = validateParameter(valid_601442, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_601442 != nil:
    section.add "X-Amz-Target", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Content-Sha256", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Algorithm")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Algorithm", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Signature")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Signature", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-SignedHeaders", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Credential")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Credential", valid_601447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601449: Call_GetSuite_601437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_601449.validator(path, query, header, formData, body)
  let scheme = call_601449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601449.url(scheme.get, call_601449.host, call_601449.base,
                         call_601449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601449, url, valid)

proc call*(call_601450: Call_GetSuite_601437; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_601451 = newJObject()
  if body != nil:
    body_601451 = body
  result = call_601450.call(nil, nil, nil, nil, body_601451)

var getSuite* = Call_GetSuite_601437(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_601438, base: "/",
                                  url: url_GetSuite_601439,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_601452 = ref object of OpenApiRestCall_600438
proc url_GetTest_601454(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTest_601453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601455 = header.getOrDefault("X-Amz-Date")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Date", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Security-Token")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Security-Token", valid_601456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601457 = header.getOrDefault("X-Amz-Target")
  valid_601457 = validateParameter(valid_601457, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_601457 != nil:
    section.add "X-Amz-Target", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Content-Sha256", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Algorithm")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Algorithm", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Signature")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Signature", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-SignedHeaders", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Credential")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Credential", valid_601462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601464: Call_GetTest_601452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_601464.validator(path, query, header, formData, body)
  let scheme = call_601464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601464.url(scheme.get, call_601464.host, call_601464.base,
                         call_601464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601464, url, valid)

proc call*(call_601465: Call_GetTest_601452; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_601466 = newJObject()
  if body != nil:
    body_601466 = body
  result = call_601465.call(nil, nil, nil, nil, body_601466)

var getTest* = Call_GetTest_601452(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_601453, base: "/",
                                url: url_GetTest_601454,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_601467 = ref object of OpenApiRestCall_600438
proc url_GetUpload_601469(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpload_601468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601470 = header.getOrDefault("X-Amz-Date")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Date", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Security-Token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Security-Token", valid_601471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601472 = header.getOrDefault("X-Amz-Target")
  valid_601472 = validateParameter(valid_601472, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_601472 != nil:
    section.add "X-Amz-Target", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Content-Sha256", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Algorithm")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Algorithm", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Signature")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Signature", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-SignedHeaders", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Credential")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Credential", valid_601477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601479: Call_GetUpload_601467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_601479.validator(path, query, header, formData, body)
  let scheme = call_601479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601479.url(scheme.get, call_601479.host, call_601479.base,
                         call_601479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601479, url, valid)

proc call*(call_601480: Call_GetUpload_601467; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_601481 = newJObject()
  if body != nil:
    body_601481 = body
  result = call_601480.call(nil, nil, nil, nil, body_601481)

var getUpload* = Call_GetUpload_601467(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_601468,
                                    base: "/", url: url_GetUpload_601469,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_601482 = ref object of OpenApiRestCall_600438
proc url_GetVPCEConfiguration_601484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVPCEConfiguration_601483(path: JsonNode; query: JsonNode;
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
  var valid_601485 = header.getOrDefault("X-Amz-Date")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Date", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Security-Token")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Security-Token", valid_601486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601487 = header.getOrDefault("X-Amz-Target")
  valid_601487 = validateParameter(valid_601487, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_601487 != nil:
    section.add "X-Amz-Target", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Content-Sha256", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Algorithm")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Algorithm", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Signature")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Signature", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-SignedHeaders", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Credential")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Credential", valid_601492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_GetVPCEConfiguration_601482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601494, url, valid)

proc call*(call_601495: Call_GetVPCEConfiguration_601482; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_601496 = newJObject()
  if body != nil:
    body_601496 = body
  result = call_601495.call(nil, nil, nil, nil, body_601496)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_601482(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_601483, base: "/",
    url: url_GetVPCEConfiguration_601484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_601497 = ref object of OpenApiRestCall_600438
proc url_InstallToRemoteAccessSession_601499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InstallToRemoteAccessSession_601498(path: JsonNode; query: JsonNode;
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
  var valid_601500 = header.getOrDefault("X-Amz-Date")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Date", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Security-Token")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Security-Token", valid_601501
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601502 = header.getOrDefault("X-Amz-Target")
  valid_601502 = validateParameter(valid_601502, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_601502 != nil:
    section.add "X-Amz-Target", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Content-Sha256", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Algorithm")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Algorithm", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Signature")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Signature", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-SignedHeaders", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Credential")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Credential", valid_601507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601509: Call_InstallToRemoteAccessSession_601497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_601509.validator(path, query, header, formData, body)
  let scheme = call_601509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601509.url(scheme.get, call_601509.host, call_601509.base,
                         call_601509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601509, url, valid)

proc call*(call_601510: Call_InstallToRemoteAccessSession_601497; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_601511 = newJObject()
  if body != nil:
    body_601511 = body
  result = call_601510.call(nil, nil, nil, nil, body_601511)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_601497(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_601498, base: "/",
    url: url_InstallToRemoteAccessSession_601499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_601512 = ref object of OpenApiRestCall_600438
proc url_ListArtifacts_601514(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListArtifacts_601513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601515 = query.getOrDefault("nextToken")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "nextToken", valid_601515
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
  var valid_601516 = header.getOrDefault("X-Amz-Date")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Date", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Security-Token")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Security-Token", valid_601517
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601518 = header.getOrDefault("X-Amz-Target")
  valid_601518 = validateParameter(valid_601518, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_601518 != nil:
    section.add "X-Amz-Target", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Content-Sha256", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Algorithm")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Algorithm", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Signature")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Signature", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-SignedHeaders", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Credential")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Credential", valid_601523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601525: Call_ListArtifacts_601512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_601525.validator(path, query, header, formData, body)
  let scheme = call_601525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601525.url(scheme.get, call_601525.host, call_601525.base,
                         call_601525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601525, url, valid)

proc call*(call_601526: Call_ListArtifacts_601512; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601527 = newJObject()
  var body_601528 = newJObject()
  add(query_601527, "nextToken", newJString(nextToken))
  if body != nil:
    body_601528 = body
  result = call_601526.call(nil, query_601527, nil, nil, body_601528)

var listArtifacts* = Call_ListArtifacts_601512(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_601513, base: "/", url: url_ListArtifacts_601514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_601529 = ref object of OpenApiRestCall_600438
proc url_ListDeviceInstances_601531(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceInstances_601530(path: JsonNode; query: JsonNode;
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
  var valid_601532 = header.getOrDefault("X-Amz-Date")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Date", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Security-Token")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Security-Token", valid_601533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601534 = header.getOrDefault("X-Amz-Target")
  valid_601534 = validateParameter(valid_601534, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_601534 != nil:
    section.add "X-Amz-Target", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Content-Sha256", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Algorithm")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Algorithm", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Signature")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Signature", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-SignedHeaders", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Credential")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Credential", valid_601539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601541: Call_ListDeviceInstances_601529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_601541.validator(path, query, header, formData, body)
  let scheme = call_601541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601541.url(scheme.get, call_601541.host, call_601541.base,
                         call_601541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601541, url, valid)

proc call*(call_601542: Call_ListDeviceInstances_601529; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_601543 = newJObject()
  if body != nil:
    body_601543 = body
  result = call_601542.call(nil, nil, nil, nil, body_601543)

var listDeviceInstances* = Call_ListDeviceInstances_601529(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_601530, base: "/",
    url: url_ListDeviceInstances_601531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_601544 = ref object of OpenApiRestCall_600438
proc url_ListDevicePools_601546(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevicePools_601545(path: JsonNode; query: JsonNode;
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
  var valid_601547 = query.getOrDefault("nextToken")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "nextToken", valid_601547
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
  var valid_601548 = header.getOrDefault("X-Amz-Date")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Date", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Security-Token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Security-Token", valid_601549
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601550 = header.getOrDefault("X-Amz-Target")
  valid_601550 = validateParameter(valid_601550, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_601550 != nil:
    section.add "X-Amz-Target", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Content-Sha256", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Algorithm")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Algorithm", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Signature")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Signature", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-SignedHeaders", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Credential")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Credential", valid_601555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_ListDevicePools_601544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_ListDevicePools_601544; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601559 = newJObject()
  var body_601560 = newJObject()
  add(query_601559, "nextToken", newJString(nextToken))
  if body != nil:
    body_601560 = body
  result = call_601558.call(nil, query_601559, nil, nil, body_601560)

var listDevicePools* = Call_ListDevicePools_601544(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_601545, base: "/", url: url_ListDevicePools_601546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_601561 = ref object of OpenApiRestCall_600438
proc url_ListDevices_601563(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevices_601562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601564 = query.getOrDefault("nextToken")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "nextToken", valid_601564
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
  var valid_601565 = header.getOrDefault("X-Amz-Date")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Date", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Security-Token")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Security-Token", valid_601566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601567 = header.getOrDefault("X-Amz-Target")
  valid_601567 = validateParameter(valid_601567, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_601567 != nil:
    section.add "X-Amz-Target", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Content-Sha256", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Algorithm")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Algorithm", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Signature")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Signature", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-SignedHeaders", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Credential")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Credential", valid_601572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601574: Call_ListDevices_601561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_601574.validator(path, query, header, formData, body)
  let scheme = call_601574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601574.url(scheme.get, call_601574.host, call_601574.base,
                         call_601574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601574, url, valid)

proc call*(call_601575: Call_ListDevices_601561; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601576 = newJObject()
  var body_601577 = newJObject()
  add(query_601576, "nextToken", newJString(nextToken))
  if body != nil:
    body_601577 = body
  result = call_601575.call(nil, query_601576, nil, nil, body_601577)

var listDevices* = Call_ListDevices_601561(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_601562,
                                        base: "/", url: url_ListDevices_601563,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_601578 = ref object of OpenApiRestCall_600438
proc url_ListInstanceProfiles_601580(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInstanceProfiles_601579(path: JsonNode; query: JsonNode;
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
  var valid_601581 = header.getOrDefault("X-Amz-Date")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Date", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Security-Token")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Security-Token", valid_601582
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601583 = header.getOrDefault("X-Amz-Target")
  valid_601583 = validateParameter(valid_601583, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_601583 != nil:
    section.add "X-Amz-Target", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Content-Sha256", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Algorithm")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Algorithm", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Signature")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Signature", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-SignedHeaders", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Credential")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Credential", valid_601588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601590: Call_ListInstanceProfiles_601578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_601590.validator(path, query, header, formData, body)
  let scheme = call_601590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601590.url(scheme.get, call_601590.host, call_601590.base,
                         call_601590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601590, url, valid)

proc call*(call_601591: Call_ListInstanceProfiles_601578; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_601592 = newJObject()
  if body != nil:
    body_601592 = body
  result = call_601591.call(nil, nil, nil, nil, body_601592)

var listInstanceProfiles* = Call_ListInstanceProfiles_601578(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_601579, base: "/",
    url: url_ListInstanceProfiles_601580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_601593 = ref object of OpenApiRestCall_600438
proc url_ListJobs_601595(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_601594(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601596 = query.getOrDefault("nextToken")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "nextToken", valid_601596
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
  var valid_601597 = header.getOrDefault("X-Amz-Date")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Date", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Security-Token")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Security-Token", valid_601598
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601599 = header.getOrDefault("X-Amz-Target")
  valid_601599 = validateParameter(valid_601599, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_601599 != nil:
    section.add "X-Amz-Target", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Content-Sha256", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Algorithm")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Algorithm", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Signature")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Signature", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-SignedHeaders", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Credential")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Credential", valid_601604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601606: Call_ListJobs_601593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_601606.validator(path, query, header, formData, body)
  let scheme = call_601606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601606.url(scheme.get, call_601606.host, call_601606.base,
                         call_601606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601606, url, valid)

proc call*(call_601607: Call_ListJobs_601593; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601608 = newJObject()
  var body_601609 = newJObject()
  add(query_601608, "nextToken", newJString(nextToken))
  if body != nil:
    body_601609 = body
  result = call_601607.call(nil, query_601608, nil, nil, body_601609)

var listJobs* = Call_ListJobs_601593(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_601594, base: "/",
                                  url: url_ListJobs_601595,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_601610 = ref object of OpenApiRestCall_600438
proc url_ListNetworkProfiles_601612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNetworkProfiles_601611(path: JsonNode; query: JsonNode;
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
  var valid_601613 = header.getOrDefault("X-Amz-Date")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Date", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Security-Token")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Security-Token", valid_601614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601615 = header.getOrDefault("X-Amz-Target")
  valid_601615 = validateParameter(valid_601615, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_601615 != nil:
    section.add "X-Amz-Target", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Content-Sha256", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Algorithm")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Algorithm", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Signature")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Signature", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-SignedHeaders", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Credential")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Credential", valid_601620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601622: Call_ListNetworkProfiles_601610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_601622.validator(path, query, header, formData, body)
  let scheme = call_601622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601622.url(scheme.get, call_601622.host, call_601622.base,
                         call_601622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601622, url, valid)

proc call*(call_601623: Call_ListNetworkProfiles_601610; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_601624 = newJObject()
  if body != nil:
    body_601624 = body
  result = call_601623.call(nil, nil, nil, nil, body_601624)

var listNetworkProfiles* = Call_ListNetworkProfiles_601610(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_601611, base: "/",
    url: url_ListNetworkProfiles_601612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_601625 = ref object of OpenApiRestCall_600438
proc url_ListOfferingPromotions_601627(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferingPromotions_601626(path: JsonNode; query: JsonNode;
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
  var valid_601628 = header.getOrDefault("X-Amz-Date")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Date", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Security-Token")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Security-Token", valid_601629
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601630 = header.getOrDefault("X-Amz-Target")
  valid_601630 = validateParameter(valid_601630, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_601630 != nil:
    section.add "X-Amz-Target", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Content-Sha256", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Algorithm")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Algorithm", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Signature")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Signature", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-SignedHeaders", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Credential")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Credential", valid_601635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601637: Call_ListOfferingPromotions_601625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601637.validator(path, query, header, formData, body)
  let scheme = call_601637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601637.url(scheme.get, call_601637.host, call_601637.base,
                         call_601637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601637, url, valid)

proc call*(call_601638: Call_ListOfferingPromotions_601625; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_601639 = newJObject()
  if body != nil:
    body_601639 = body
  result = call_601638.call(nil, nil, nil, nil, body_601639)

var listOfferingPromotions* = Call_ListOfferingPromotions_601625(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_601626, base: "/",
    url: url_ListOfferingPromotions_601627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_601640 = ref object of OpenApiRestCall_600438
proc url_ListOfferingTransactions_601642(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferingTransactions_601641(path: JsonNode; query: JsonNode;
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
  var valid_601643 = query.getOrDefault("nextToken")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "nextToken", valid_601643
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
  var valid_601644 = header.getOrDefault("X-Amz-Date")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Date", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Security-Token")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Security-Token", valid_601645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601646 = header.getOrDefault("X-Amz-Target")
  valid_601646 = validateParameter(valid_601646, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_601646 != nil:
    section.add "X-Amz-Target", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Content-Sha256", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Algorithm")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Algorithm", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Signature")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Signature", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-SignedHeaders", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Credential")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Credential", valid_601651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_ListOfferingTransactions_601640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601653, url, valid)

proc call*(call_601654: Call_ListOfferingTransactions_601640; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601655 = newJObject()
  var body_601656 = newJObject()
  add(query_601655, "nextToken", newJString(nextToken))
  if body != nil:
    body_601656 = body
  result = call_601654.call(nil, query_601655, nil, nil, body_601656)

var listOfferingTransactions* = Call_ListOfferingTransactions_601640(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_601641, base: "/",
    url: url_ListOfferingTransactions_601642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_601657 = ref object of OpenApiRestCall_600438
proc url_ListOfferings_601659(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferings_601658(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601660 = query.getOrDefault("nextToken")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "nextToken", valid_601660
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
  var valid_601661 = header.getOrDefault("X-Amz-Date")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Date", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Security-Token")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Security-Token", valid_601662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601663 = header.getOrDefault("X-Amz-Target")
  valid_601663 = validateParameter(valid_601663, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_601663 != nil:
    section.add "X-Amz-Target", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Content-Sha256", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Algorithm")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Algorithm", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Signature")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Signature", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-SignedHeaders", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Credential")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Credential", valid_601668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601670: Call_ListOfferings_601657; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601670.validator(path, query, header, formData, body)
  let scheme = call_601670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601670.url(scheme.get, call_601670.host, call_601670.base,
                         call_601670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601670, url, valid)

proc call*(call_601671: Call_ListOfferings_601657; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601672 = newJObject()
  var body_601673 = newJObject()
  add(query_601672, "nextToken", newJString(nextToken))
  if body != nil:
    body_601673 = body
  result = call_601671.call(nil, query_601672, nil, nil, body_601673)

var listOfferings* = Call_ListOfferings_601657(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_601658, base: "/", url: url_ListOfferings_601659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_601674 = ref object of OpenApiRestCall_600438
proc url_ListProjects_601676(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_601675(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601677 = query.getOrDefault("nextToken")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "nextToken", valid_601677
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
  var valid_601678 = header.getOrDefault("X-Amz-Date")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Date", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Security-Token")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Security-Token", valid_601679
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601680 = header.getOrDefault("X-Amz-Target")
  valid_601680 = validateParameter(valid_601680, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_601680 != nil:
    section.add "X-Amz-Target", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Content-Sha256", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Algorithm")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Algorithm", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Signature")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Signature", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-SignedHeaders", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Credential")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Credential", valid_601685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601687: Call_ListProjects_601674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_601687.validator(path, query, header, formData, body)
  let scheme = call_601687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601687.url(scheme.get, call_601687.host, call_601687.base,
                         call_601687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601687, url, valid)

proc call*(call_601688: Call_ListProjects_601674; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601689 = newJObject()
  var body_601690 = newJObject()
  add(query_601689, "nextToken", newJString(nextToken))
  if body != nil:
    body_601690 = body
  result = call_601688.call(nil, query_601689, nil, nil, body_601690)

var listProjects* = Call_ListProjects_601674(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_601675, base: "/", url: url_ListProjects_601676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_601691 = ref object of OpenApiRestCall_600438
proc url_ListRemoteAccessSessions_601693(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRemoteAccessSessions_601692(path: JsonNode; query: JsonNode;
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
  var valid_601694 = header.getOrDefault("X-Amz-Date")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Date", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Security-Token")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Security-Token", valid_601695
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601696 = header.getOrDefault("X-Amz-Target")
  valid_601696 = validateParameter(valid_601696, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_601696 != nil:
    section.add "X-Amz-Target", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Content-Sha256", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Algorithm")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Algorithm", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Signature")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Signature", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-SignedHeaders", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Credential")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Credential", valid_601701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601703: Call_ListRemoteAccessSessions_601691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_601703.validator(path, query, header, formData, body)
  let scheme = call_601703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601703.url(scheme.get, call_601703.host, call_601703.base,
                         call_601703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601703, url, valid)

proc call*(call_601704: Call_ListRemoteAccessSessions_601691; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_601705 = newJObject()
  if body != nil:
    body_601705 = body
  result = call_601704.call(nil, nil, nil, nil, body_601705)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_601691(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_601692, base: "/",
    url: url_ListRemoteAccessSessions_601693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_601706 = ref object of OpenApiRestCall_600438
proc url_ListRuns_601708(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRuns_601707(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601709 = query.getOrDefault("nextToken")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "nextToken", valid_601709
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
  var valid_601710 = header.getOrDefault("X-Amz-Date")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Date", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Security-Token")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Security-Token", valid_601711
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601712 = header.getOrDefault("X-Amz-Target")
  valid_601712 = validateParameter(valid_601712, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_601712 != nil:
    section.add "X-Amz-Target", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Content-Sha256", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Algorithm")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Algorithm", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Signature")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Signature", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-SignedHeaders", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Credential")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Credential", valid_601717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601719: Call_ListRuns_601706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_601719.validator(path, query, header, formData, body)
  let scheme = call_601719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601719.url(scheme.get, call_601719.host, call_601719.base,
                         call_601719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601719, url, valid)

proc call*(call_601720: Call_ListRuns_601706; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601721 = newJObject()
  var body_601722 = newJObject()
  add(query_601721, "nextToken", newJString(nextToken))
  if body != nil:
    body_601722 = body
  result = call_601720.call(nil, query_601721, nil, nil, body_601722)

var listRuns* = Call_ListRuns_601706(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_601707, base: "/",
                                  url: url_ListRuns_601708,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_601723 = ref object of OpenApiRestCall_600438
proc url_ListSamples_601725(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSamples_601724(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601726 = query.getOrDefault("nextToken")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "nextToken", valid_601726
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
  var valid_601727 = header.getOrDefault("X-Amz-Date")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Date", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Security-Token")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Security-Token", valid_601728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601729 = header.getOrDefault("X-Amz-Target")
  valid_601729 = validateParameter(valid_601729, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_601729 != nil:
    section.add "X-Amz-Target", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Content-Sha256", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Algorithm")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Algorithm", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Signature")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Signature", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-SignedHeaders", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Credential")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Credential", valid_601734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601736: Call_ListSamples_601723; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_601736.validator(path, query, header, formData, body)
  let scheme = call_601736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601736.url(scheme.get, call_601736.host, call_601736.base,
                         call_601736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601736, url, valid)

proc call*(call_601737: Call_ListSamples_601723; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601738 = newJObject()
  var body_601739 = newJObject()
  add(query_601738, "nextToken", newJString(nextToken))
  if body != nil:
    body_601739 = body
  result = call_601737.call(nil, query_601738, nil, nil, body_601739)

var listSamples* = Call_ListSamples_601723(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_601724,
                                        base: "/", url: url_ListSamples_601725,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_601740 = ref object of OpenApiRestCall_600438
proc url_ListSuites_601742(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSuites_601741(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601743 = query.getOrDefault("nextToken")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "nextToken", valid_601743
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
  var valid_601744 = header.getOrDefault("X-Amz-Date")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Date", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Security-Token")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Security-Token", valid_601745
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601746 = header.getOrDefault("X-Amz-Target")
  valid_601746 = validateParameter(valid_601746, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_601746 != nil:
    section.add "X-Amz-Target", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Content-Sha256", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Algorithm")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Algorithm", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Signature")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Signature", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-SignedHeaders", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Credential")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Credential", valid_601751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601753: Call_ListSuites_601740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_601753.validator(path, query, header, formData, body)
  let scheme = call_601753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601753.url(scheme.get, call_601753.host, call_601753.base,
                         call_601753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601753, url, valid)

proc call*(call_601754: Call_ListSuites_601740; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601755 = newJObject()
  var body_601756 = newJObject()
  add(query_601755, "nextToken", newJString(nextToken))
  if body != nil:
    body_601756 = body
  result = call_601754.call(nil, query_601755, nil, nil, body_601756)

var listSuites* = Call_ListSuites_601740(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_601741,
                                      base: "/", url: url_ListSuites_601742,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601757 = ref object of OpenApiRestCall_600438
proc url_ListTagsForResource_601759(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_601758(path: JsonNode; query: JsonNode;
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
  var valid_601760 = header.getOrDefault("X-Amz-Date")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Date", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Security-Token")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Security-Token", valid_601761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601762 = header.getOrDefault("X-Amz-Target")
  valid_601762 = validateParameter(valid_601762, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_601762 != nil:
    section.add "X-Amz-Target", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Content-Sha256", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Algorithm")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Algorithm", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Signature")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Signature", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-SignedHeaders", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Credential")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Credential", valid_601767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601769: Call_ListTagsForResource_601757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_601769.validator(path, query, header, formData, body)
  let scheme = call_601769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601769.url(scheme.get, call_601769.host, call_601769.base,
                         call_601769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601769, url, valid)

proc call*(call_601770: Call_ListTagsForResource_601757; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_601771 = newJObject()
  if body != nil:
    body_601771 = body
  result = call_601770.call(nil, nil, nil, nil, body_601771)

var listTagsForResource* = Call_ListTagsForResource_601757(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_601758, base: "/",
    url: url_ListTagsForResource_601759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_601772 = ref object of OpenApiRestCall_600438
proc url_ListTests_601774(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTests_601773(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601775 = query.getOrDefault("nextToken")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "nextToken", valid_601775
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
  var valid_601776 = header.getOrDefault("X-Amz-Date")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Date", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Security-Token")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Security-Token", valid_601777
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601778 = header.getOrDefault("X-Amz-Target")
  valid_601778 = validateParameter(valid_601778, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_601778 != nil:
    section.add "X-Amz-Target", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Content-Sha256", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Algorithm")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Algorithm", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Signature")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Signature", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-SignedHeaders", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Credential")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Credential", valid_601783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601785: Call_ListTests_601772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_601785.validator(path, query, header, formData, body)
  let scheme = call_601785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601785.url(scheme.get, call_601785.host, call_601785.base,
                         call_601785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601785, url, valid)

proc call*(call_601786: Call_ListTests_601772; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601787 = newJObject()
  var body_601788 = newJObject()
  add(query_601787, "nextToken", newJString(nextToken))
  if body != nil:
    body_601788 = body
  result = call_601786.call(nil, query_601787, nil, nil, body_601788)

var listTests* = Call_ListTests_601772(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_601773,
                                    base: "/", url: url_ListTests_601774,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_601789 = ref object of OpenApiRestCall_600438
proc url_ListUniqueProblems_601791(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUniqueProblems_601790(path: JsonNode; query: JsonNode;
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
  var valid_601792 = query.getOrDefault("nextToken")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "nextToken", valid_601792
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
  var valid_601793 = header.getOrDefault("X-Amz-Date")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Date", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Security-Token")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Security-Token", valid_601794
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601795 = header.getOrDefault("X-Amz-Target")
  valid_601795 = validateParameter(valid_601795, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_601795 != nil:
    section.add "X-Amz-Target", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Content-Sha256", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Algorithm")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Algorithm", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Signature")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Signature", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-SignedHeaders", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Credential")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Credential", valid_601800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601802: Call_ListUniqueProblems_601789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique problems.
  ## 
  let valid = call_601802.validator(path, query, header, formData, body)
  let scheme = call_601802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601802.url(scheme.get, call_601802.host, call_601802.base,
                         call_601802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601802, url, valid)

proc call*(call_601803: Call_ListUniqueProblems_601789; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## Gets information about unique problems.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601804 = newJObject()
  var body_601805 = newJObject()
  add(query_601804, "nextToken", newJString(nextToken))
  if body != nil:
    body_601805 = body
  result = call_601803.call(nil, query_601804, nil, nil, body_601805)

var listUniqueProblems* = Call_ListUniqueProblems_601789(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_601790, base: "/",
    url: url_ListUniqueProblems_601791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_601806 = ref object of OpenApiRestCall_600438
proc url_ListUploads_601808(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUploads_601807(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601809 = query.getOrDefault("nextToken")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "nextToken", valid_601809
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
  var valid_601810 = header.getOrDefault("X-Amz-Date")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Date", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Security-Token")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Security-Token", valid_601811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601812 = header.getOrDefault("X-Amz-Target")
  valid_601812 = validateParameter(valid_601812, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_601812 != nil:
    section.add "X-Amz-Target", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Content-Sha256", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Algorithm")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Algorithm", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Signature")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Signature", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-SignedHeaders", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Credential")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Credential", valid_601817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601819: Call_ListUploads_601806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_601819.validator(path, query, header, formData, body)
  let scheme = call_601819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601819.url(scheme.get, call_601819.host, call_601819.base,
                         call_601819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601819, url, valid)

proc call*(call_601820: Call_ListUploads_601806; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601821 = newJObject()
  var body_601822 = newJObject()
  add(query_601821, "nextToken", newJString(nextToken))
  if body != nil:
    body_601822 = body
  result = call_601820.call(nil, query_601821, nil, nil, body_601822)

var listUploads* = Call_ListUploads_601806(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_601807,
                                        base: "/", url: url_ListUploads_601808,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_601823 = ref object of OpenApiRestCall_600438
proc url_ListVPCEConfigurations_601825(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVPCEConfigurations_601824(path: JsonNode; query: JsonNode;
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
  var valid_601826 = header.getOrDefault("X-Amz-Date")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Date", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Security-Token")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Security-Token", valid_601827
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601828 = header.getOrDefault("X-Amz-Target")
  valid_601828 = validateParameter(valid_601828, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_601828 != nil:
    section.add "X-Amz-Target", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Content-Sha256", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Algorithm")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Algorithm", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Signature")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Signature", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-SignedHeaders", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Credential")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Credential", valid_601833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601835: Call_ListVPCEConfigurations_601823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_601835.validator(path, query, header, formData, body)
  let scheme = call_601835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601835.url(scheme.get, call_601835.host, call_601835.base,
                         call_601835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601835, url, valid)

proc call*(call_601836: Call_ListVPCEConfigurations_601823; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_601837 = newJObject()
  if body != nil:
    body_601837 = body
  result = call_601836.call(nil, nil, nil, nil, body_601837)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_601823(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_601824, base: "/",
    url: url_ListVPCEConfigurations_601825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_601838 = ref object of OpenApiRestCall_600438
proc url_PurchaseOffering_601840(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PurchaseOffering_601839(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Date")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Date", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Security-Token")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Security-Token", valid_601842
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601843 = header.getOrDefault("X-Amz-Target")
  valid_601843 = validateParameter(valid_601843, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_601843 != nil:
    section.add "X-Amz-Target", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Algorithm")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Algorithm", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601850: Call_PurchaseOffering_601838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601850.validator(path, query, header, formData, body)
  let scheme = call_601850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601850.url(scheme.get, call_601850.host, call_601850.base,
                         call_601850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601850, url, valid)

proc call*(call_601851: Call_PurchaseOffering_601838; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_601852 = newJObject()
  if body != nil:
    body_601852 = body
  result = call_601851.call(nil, nil, nil, nil, body_601852)

var purchaseOffering* = Call_PurchaseOffering_601838(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_601839, base: "/",
    url: url_PurchaseOffering_601840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_601853 = ref object of OpenApiRestCall_600438
proc url_RenewOffering_601855(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RenewOffering_601854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601856 = header.getOrDefault("X-Amz-Date")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Date", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Security-Token")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Security-Token", valid_601857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601858 = header.getOrDefault("X-Amz-Target")
  valid_601858 = validateParameter(valid_601858, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_601858 != nil:
    section.add "X-Amz-Target", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Signature")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Signature", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Credential")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Credential", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601865: Call_RenewOffering_601853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_601865.validator(path, query, header, formData, body)
  let scheme = call_601865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601865.url(scheme.get, call_601865.host, call_601865.base,
                         call_601865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601865, url, valid)

proc call*(call_601866: Call_RenewOffering_601853; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_601867 = newJObject()
  if body != nil:
    body_601867 = body
  result = call_601866.call(nil, nil, nil, nil, body_601867)

var renewOffering* = Call_RenewOffering_601853(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_601854, base: "/", url: url_RenewOffering_601855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_601868 = ref object of OpenApiRestCall_600438
proc url_ScheduleRun_601870(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ScheduleRun_601869(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601871 = header.getOrDefault("X-Amz-Date")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Date", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Security-Token")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Security-Token", valid_601872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601873 = header.getOrDefault("X-Amz-Target")
  valid_601873 = validateParameter(valid_601873, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_601873 != nil:
    section.add "X-Amz-Target", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Content-Sha256", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Algorithm")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Algorithm", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Signature")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Signature", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-SignedHeaders", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Credential")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Credential", valid_601878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601880: Call_ScheduleRun_601868; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_601880.validator(path, query, header, formData, body)
  let scheme = call_601880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601880.url(scheme.get, call_601880.host, call_601880.base,
                         call_601880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601880, url, valid)

proc call*(call_601881: Call_ScheduleRun_601868; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_601882 = newJObject()
  if body != nil:
    body_601882 = body
  result = call_601881.call(nil, nil, nil, nil, body_601882)

var scheduleRun* = Call_ScheduleRun_601868(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_601869,
                                        base: "/", url: url_ScheduleRun_601870,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_601883 = ref object of OpenApiRestCall_600438
proc url_StopJob_601885(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopJob_601884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601886 = header.getOrDefault("X-Amz-Date")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Date", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Security-Token")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Security-Token", valid_601887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601888 = header.getOrDefault("X-Amz-Target")
  valid_601888 = validateParameter(valid_601888, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_601888 != nil:
    section.add "X-Amz-Target", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Content-Sha256", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-Algorithm")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Algorithm", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Signature")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Signature", valid_601891
  var valid_601892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-SignedHeaders", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-Credential")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-Credential", valid_601893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601895: Call_StopJob_601883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_601895.validator(path, query, header, formData, body)
  let scheme = call_601895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601895.url(scheme.get, call_601895.host, call_601895.base,
                         call_601895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601895, url, valid)

proc call*(call_601896: Call_StopJob_601883; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_601897 = newJObject()
  if body != nil:
    body_601897 = body
  result = call_601896.call(nil, nil, nil, nil, body_601897)

var stopJob* = Call_StopJob_601883(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_601884, base: "/",
                                url: url_StopJob_601885,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_601898 = ref object of OpenApiRestCall_600438
proc url_StopRemoteAccessSession_601900(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopRemoteAccessSession_601899(path: JsonNode; query: JsonNode;
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
  var valid_601901 = header.getOrDefault("X-Amz-Date")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Date", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Security-Token")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Security-Token", valid_601902
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601903 = header.getOrDefault("X-Amz-Target")
  valid_601903 = validateParameter(valid_601903, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_601903 != nil:
    section.add "X-Amz-Target", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Content-Sha256", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Algorithm")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Algorithm", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Signature")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Signature", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-SignedHeaders", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Credential")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Credential", valid_601908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601910: Call_StopRemoteAccessSession_601898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_601910.validator(path, query, header, formData, body)
  let scheme = call_601910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601910.url(scheme.get, call_601910.host, call_601910.base,
                         call_601910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601910, url, valid)

proc call*(call_601911: Call_StopRemoteAccessSession_601898; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_601912 = newJObject()
  if body != nil:
    body_601912 = body
  result = call_601911.call(nil, nil, nil, nil, body_601912)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_601898(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_601899, base: "/",
    url: url_StopRemoteAccessSession_601900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_601913 = ref object of OpenApiRestCall_600438
proc url_StopRun_601915(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopRun_601914(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601916 = header.getOrDefault("X-Amz-Date")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Date", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Security-Token")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Security-Token", valid_601917
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601918 = header.getOrDefault("X-Amz-Target")
  valid_601918 = validateParameter(valid_601918, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_601918 != nil:
    section.add "X-Amz-Target", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Content-Sha256", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Algorithm")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Algorithm", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Signature")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Signature", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-SignedHeaders", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Credential")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Credential", valid_601923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601925: Call_StopRun_601913; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_601925.validator(path, query, header, formData, body)
  let scheme = call_601925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601925.url(scheme.get, call_601925.host, call_601925.base,
                         call_601925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601925, url, valid)

proc call*(call_601926: Call_StopRun_601913; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_601927 = newJObject()
  if body != nil:
    body_601927 = body
  result = call_601926.call(nil, nil, nil, nil, body_601927)

var stopRun* = Call_StopRun_601913(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_601914, base: "/",
                                url: url_StopRun_601915,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601928 = ref object of OpenApiRestCall_600438
proc url_TagResource_601930(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_601929(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601931 = header.getOrDefault("X-Amz-Date")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Date", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-Security-Token")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Security-Token", valid_601932
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601933 = header.getOrDefault("X-Amz-Target")
  valid_601933 = validateParameter(valid_601933, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_601933 != nil:
    section.add "X-Amz-Target", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Content-Sha256", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Algorithm")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Algorithm", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Signature")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Signature", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-SignedHeaders", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Credential")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Credential", valid_601938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601940: Call_TagResource_601928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_601940.validator(path, query, header, formData, body)
  let scheme = call_601940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601940.url(scheme.get, call_601940.host, call_601940.base,
                         call_601940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601940, url, valid)

proc call*(call_601941: Call_TagResource_601928; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_601942 = newJObject()
  if body != nil:
    body_601942 = body
  result = call_601941.call(nil, nil, nil, nil, body_601942)

var tagResource* = Call_TagResource_601928(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_601929,
                                        base: "/", url: url_TagResource_601930,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601943 = ref object of OpenApiRestCall_600438
proc url_UntagResource_601945(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_601944(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601946 = header.getOrDefault("X-Amz-Date")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Date", valid_601946
  var valid_601947 = header.getOrDefault("X-Amz-Security-Token")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Security-Token", valid_601947
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601948 = header.getOrDefault("X-Amz-Target")
  valid_601948 = validateParameter(valid_601948, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_601948 != nil:
    section.add "X-Amz-Target", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Content-Sha256", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Algorithm")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Algorithm", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Signature")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Signature", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-SignedHeaders", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Credential")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Credential", valid_601953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601955: Call_UntagResource_601943; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_601955.validator(path, query, header, formData, body)
  let scheme = call_601955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601955.url(scheme.get, call_601955.host, call_601955.base,
                         call_601955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601955, url, valid)

proc call*(call_601956: Call_UntagResource_601943; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var untagResource* = Call_UntagResource_601943(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_601944, base: "/", url: url_UntagResource_601945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_601958 = ref object of OpenApiRestCall_600438
proc url_UpdateDeviceInstance_601960(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDeviceInstance_601959(path: JsonNode; query: JsonNode;
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
  var valid_601961 = header.getOrDefault("X-Amz-Date")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Date", valid_601961
  var valid_601962 = header.getOrDefault("X-Amz-Security-Token")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Security-Token", valid_601962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601963 = header.getOrDefault("X-Amz-Target")
  valid_601963 = validateParameter(valid_601963, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_601963 != nil:
    section.add "X-Amz-Target", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Content-Sha256", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Algorithm")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Algorithm", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Signature")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Signature", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-SignedHeaders", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Credential")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Credential", valid_601968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601970: Call_UpdateDeviceInstance_601958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance.
  ## 
  let valid = call_601970.validator(path, query, header, formData, body)
  let scheme = call_601970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601970.url(scheme.get, call_601970.host, call_601970.base,
                         call_601970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601970, url, valid)

proc call*(call_601971: Call_UpdateDeviceInstance_601958; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about an existing private device instance.
  ##   body: JObject (required)
  var body_601972 = newJObject()
  if body != nil:
    body_601972 = body
  result = call_601971.call(nil, nil, nil, nil, body_601972)

var updateDeviceInstance* = Call_UpdateDeviceInstance_601958(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_601959, base: "/",
    url: url_UpdateDeviceInstance_601960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_601973 = ref object of OpenApiRestCall_600438
proc url_UpdateDevicePool_601975(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevicePool_601974(path: JsonNode; query: JsonNode;
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
  var valid_601976 = header.getOrDefault("X-Amz-Date")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Date", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-Security-Token")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Security-Token", valid_601977
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601978 = header.getOrDefault("X-Amz-Target")
  valid_601978 = validateParameter(valid_601978, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_601978 != nil:
    section.add "X-Amz-Target", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Content-Sha256", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Algorithm")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Algorithm", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Signature")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Signature", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-SignedHeaders", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Credential")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Credential", valid_601983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601985: Call_UpdateDevicePool_601973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_601985.validator(path, query, header, formData, body)
  let scheme = call_601985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601985.url(scheme.get, call_601985.host, call_601985.base,
                         call_601985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601985, url, valid)

proc call*(call_601986: Call_UpdateDevicePool_601973; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_601987 = newJObject()
  if body != nil:
    body_601987 = body
  result = call_601986.call(nil, nil, nil, nil, body_601987)

var updateDevicePool* = Call_UpdateDevicePool_601973(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_601974, base: "/",
    url: url_UpdateDevicePool_601975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_601988 = ref object of OpenApiRestCall_600438
proc url_UpdateInstanceProfile_601990(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateInstanceProfile_601989(path: JsonNode; query: JsonNode;
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
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Security-Token")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Security-Token", valid_601992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601993 = header.getOrDefault("X-Amz-Target")
  valid_601993 = validateParameter(valid_601993, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_601993 != nil:
    section.add "X-Amz-Target", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Content-Sha256", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Algorithm")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Algorithm", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Signature")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Signature", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Credential")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Credential", valid_601998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602000: Call_UpdateInstanceProfile_601988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_602000.validator(path, query, header, formData, body)
  let scheme = call_602000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602000.url(scheme.get, call_602000.host, call_602000.base,
                         call_602000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602000, url, valid)

proc call*(call_602001: Call_UpdateInstanceProfile_601988; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_602002 = newJObject()
  if body != nil:
    body_602002 = body
  result = call_602001.call(nil, nil, nil, nil, body_602002)

var updateInstanceProfile* = Call_UpdateInstanceProfile_601988(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_601989, base: "/",
    url: url_UpdateInstanceProfile_601990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_602003 = ref object of OpenApiRestCall_600438
proc url_UpdateNetworkProfile_602005(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNetworkProfile_602004(path: JsonNode; query: JsonNode;
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
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602008 = header.getOrDefault("X-Amz-Target")
  valid_602008 = validateParameter(valid_602008, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_602008 != nil:
    section.add "X-Amz-Target", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Content-Sha256", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Signature")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Signature", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Credential")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Credential", valid_602013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_UpdateNetworkProfile_602003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile with specific settings.
  ## 
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602015, url, valid)

proc call*(call_602016: Call_UpdateNetworkProfile_602003; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile with specific settings.
  ##   body: JObject (required)
  var body_602017 = newJObject()
  if body != nil:
    body_602017 = body
  result = call_602016.call(nil, nil, nil, nil, body_602017)

var updateNetworkProfile* = Call_UpdateNetworkProfile_602003(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_602004, base: "/",
    url: url_UpdateNetworkProfile_602005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_602018 = ref object of OpenApiRestCall_600438
proc url_UpdateProject_602020(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_602019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602021 = header.getOrDefault("X-Amz-Date")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Date", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Security-Token")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Security-Token", valid_602022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602023 = header.getOrDefault("X-Amz-Target")
  valid_602023 = validateParameter(valid_602023, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_602023 != nil:
    section.add "X-Amz-Target", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Signature")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Signature", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602030: Call_UpdateProject_602018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602030, url, valid)

proc call*(call_602031: Call_UpdateProject_602018; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_602032 = newJObject()
  if body != nil:
    body_602032 = body
  result = call_602031.call(nil, nil, nil, nil, body_602032)

var updateProject* = Call_UpdateProject_602018(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_602019, base: "/", url: url_UpdateProject_602020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_602033 = ref object of OpenApiRestCall_600438
proc url_UpdateUpload_602035(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUpload_602034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602036 = header.getOrDefault("X-Amz-Date")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Date", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Security-Token")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Security-Token", valid_602037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602038 = header.getOrDefault("X-Amz-Target")
  valid_602038 = validateParameter(valid_602038, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_602038 != nil:
    section.add "X-Amz-Target", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Algorithm")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Algorithm", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_UpdateUpload_602033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an uploaded test specification (test spec).
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602045, url, valid)

proc call*(call_602046: Call_UpdateUpload_602033; body: JsonNode): Recallable =
  ## updateUpload
  ## Update an uploaded test specification (test spec).
  ##   body: JObject (required)
  var body_602047 = newJObject()
  if body != nil:
    body_602047 = body
  result = call_602046.call(nil, nil, nil, nil, body_602047)

var updateUpload* = Call_UpdateUpload_602033(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_602034, base: "/", url: url_UpdateUpload_602035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_602048 = ref object of OpenApiRestCall_600438
proc url_UpdateVPCEConfiguration_602050(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateVPCEConfiguration_602049(path: JsonNode; query: JsonNode;
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
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602053 = header.getOrDefault("X-Amz-Target")
  valid_602053 = validateParameter(valid_602053, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_602053 != nil:
    section.add "X-Amz-Target", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Content-Sha256", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Algorithm")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Algorithm", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Signature")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Signature", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-SignedHeaders", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Credential")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Credential", valid_602058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602060: Call_UpdateVPCEConfiguration_602048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_602060.validator(path, query, header, formData, body)
  let scheme = call_602060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602060.url(scheme.get, call_602060.host, call_602060.base,
                         call_602060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602060, url, valid)

proc call*(call_602061: Call_UpdateVPCEConfiguration_602048; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_602062 = newJObject()
  if body != nil:
    body_602062 = body
  result = call_602061.call(nil, nil, nil, nil, body_602062)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_602048(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_602049, base: "/",
    url: url_UpdateVPCEConfiguration_602050, schemes: {Scheme.Https, Scheme.Http})
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
