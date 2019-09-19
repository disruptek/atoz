
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772598 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772598](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772598): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateDevicePool_772934 = ref object of OpenApiRestCall_772598
proc url_CreateDevicePool_772936(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDevicePool_772935(path: JsonNode; query: JsonNode;
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
  var valid_773048 = header.getOrDefault("X-Amz-Date")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Date", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Security-Token")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Security-Token", valid_773049
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773063 = header.getOrDefault("X-Amz-Target")
  valid_773063 = validateParameter(valid_773063, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateDevicePool"))
  if valid_773063 != nil:
    section.add "X-Amz-Target", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Content-Sha256", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Algorithm")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Algorithm", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Signature")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Signature", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-SignedHeaders", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Credential")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Credential", valid_773068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_CreateDevicePool_772934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device pool.
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_CreateDevicePool_772934; body: JsonNode): Recallable =
  ## createDevicePool
  ## Creates a device pool.
  ##   body: JObject (required)
  var body_773164 = newJObject()
  if body != nil:
    body_773164 = body
  result = call_773163.call(nil, nil, nil, nil, body_773164)

var createDevicePool* = Call_CreateDevicePool_772934(name: "createDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateDevicePool",
    validator: validate_CreateDevicePool_772935, base: "/",
    url: url_CreateDevicePool_772936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceProfile_773203 = ref object of OpenApiRestCall_772598
proc url_CreateInstanceProfile_773205(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInstanceProfile_773204(path: JsonNode; query: JsonNode;
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
  var valid_773206 = header.getOrDefault("X-Amz-Date")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Date", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Security-Token")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Security-Token", valid_773207
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773208 = header.getOrDefault("X-Amz-Target")
  valid_773208 = validateParameter(valid_773208, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateInstanceProfile"))
  if valid_773208 != nil:
    section.add "X-Amz-Target", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Content-Sha256", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Algorithm")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Algorithm", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Signature")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Signature", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-SignedHeaders", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Credential")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Credential", valid_773213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773215: Call_CreateInstanceProfile_773203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ## 
  let valid = call_773215.validator(path, query, header, formData, body)
  let scheme = call_773215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773215.url(scheme.get, call_773215.host, call_773215.base,
                         call_773215.route, valid.getOrDefault("path"))
  result = hook(call_773215, url, valid)

proc call*(call_773216: Call_CreateInstanceProfile_773203; body: JsonNode): Recallable =
  ## createInstanceProfile
  ## Creates a profile that can be applied to one or more private fleet device instances.
  ##   body: JObject (required)
  var body_773217 = newJObject()
  if body != nil:
    body_773217 = body
  result = call_773216.call(nil, nil, nil, nil, body_773217)

var createInstanceProfile* = Call_CreateInstanceProfile_773203(
    name: "createInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateInstanceProfile",
    validator: validate_CreateInstanceProfile_773204, base: "/",
    url: url_CreateInstanceProfile_773205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_773218 = ref object of OpenApiRestCall_772598
proc url_CreateNetworkProfile_773220(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNetworkProfile_773219(path: JsonNode; query: JsonNode;
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
  var valid_773221 = header.getOrDefault("X-Amz-Date")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Date", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Security-Token")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Security-Token", valid_773222
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773223 = header.getOrDefault("X-Amz-Target")
  valid_773223 = validateParameter(valid_773223, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateNetworkProfile"))
  if valid_773223 != nil:
    section.add "X-Amz-Target", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Content-Sha256", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Algorithm")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Algorithm", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Signature")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Signature", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-SignedHeaders", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Credential")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Credential", valid_773228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773230: Call_CreateNetworkProfile_773218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile.
  ## 
  let valid = call_773230.validator(path, query, header, formData, body)
  let scheme = call_773230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773230.url(scheme.get, call_773230.host, call_773230.base,
                         call_773230.route, valid.getOrDefault("path"))
  result = hook(call_773230, url, valid)

proc call*(call_773231: Call_CreateNetworkProfile_773218; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile.
  ##   body: JObject (required)
  var body_773232 = newJObject()
  if body != nil:
    body_773232 = body
  result = call_773231.call(nil, nil, nil, nil, body_773232)

var createNetworkProfile* = Call_CreateNetworkProfile_773218(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_773219, base: "/",
    url: url_CreateNetworkProfile_773220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_773233 = ref object of OpenApiRestCall_772598
proc url_CreateProject_773235(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProject_773234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773236 = header.getOrDefault("X-Amz-Date")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Date", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Security-Token")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Security-Token", valid_773237
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773238 = header.getOrDefault("X-Amz-Target")
  valid_773238 = validateParameter(valid_773238, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateProject"))
  if valid_773238 != nil:
    section.add "X-Amz-Target", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Content-Sha256", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Algorithm")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Algorithm", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Signature")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Signature", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-SignedHeaders", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Credential")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Credential", valid_773243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773245: Call_CreateProject_773233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new project.
  ## 
  let valid = call_773245.validator(path, query, header, formData, body)
  let scheme = call_773245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773245.url(scheme.get, call_773245.host, call_773245.base,
                         call_773245.route, valid.getOrDefault("path"))
  result = hook(call_773245, url, valid)

proc call*(call_773246: Call_CreateProject_773233; body: JsonNode): Recallable =
  ## createProject
  ## Creates a new project.
  ##   body: JObject (required)
  var body_773247 = newJObject()
  if body != nil:
    body_773247 = body
  result = call_773246.call(nil, nil, nil, nil, body_773247)

var createProject* = Call_CreateProject_773233(name: "createProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateProject",
    validator: validate_CreateProject_773234, base: "/", url: url_CreateProject_773235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRemoteAccessSession_773248 = ref object of OpenApiRestCall_772598
proc url_CreateRemoteAccessSession_773250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRemoteAccessSession_773249(path: JsonNode; query: JsonNode;
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
  var valid_773251 = header.getOrDefault("X-Amz-Date")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Date", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Security-Token")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Security-Token", valid_773252
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773253 = header.getOrDefault("X-Amz-Target")
  valid_773253 = validateParameter(valid_773253, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateRemoteAccessSession"))
  if valid_773253 != nil:
    section.add "X-Amz-Target", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Content-Sha256", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Algorithm")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Algorithm", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Signature")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Signature", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-SignedHeaders", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Credential")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Credential", valid_773258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773260: Call_CreateRemoteAccessSession_773248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies and starts a remote access session.
  ## 
  let valid = call_773260.validator(path, query, header, formData, body)
  let scheme = call_773260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773260.url(scheme.get, call_773260.host, call_773260.base,
                         call_773260.route, valid.getOrDefault("path"))
  result = hook(call_773260, url, valid)

proc call*(call_773261: Call_CreateRemoteAccessSession_773248; body: JsonNode): Recallable =
  ## createRemoteAccessSession
  ## Specifies and starts a remote access session.
  ##   body: JObject (required)
  var body_773262 = newJObject()
  if body != nil:
    body_773262 = body
  result = call_773261.call(nil, nil, nil, nil, body_773262)

var createRemoteAccessSession* = Call_CreateRemoteAccessSession_773248(
    name: "createRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateRemoteAccessSession",
    validator: validate_CreateRemoteAccessSession_773249, base: "/",
    url: url_CreateRemoteAccessSession_773250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUpload_773263 = ref object of OpenApiRestCall_772598
proc url_CreateUpload_773265(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUpload_773264(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773266 = header.getOrDefault("X-Amz-Date")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Date", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Security-Token")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Security-Token", valid_773267
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773268 = header.getOrDefault("X-Amz-Target")
  valid_773268 = validateParameter(valid_773268, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateUpload"))
  if valid_773268 != nil:
    section.add "X-Amz-Target", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773275: Call_CreateUpload_773263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an app or test scripts.
  ## 
  let valid = call_773275.validator(path, query, header, formData, body)
  let scheme = call_773275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773275.url(scheme.get, call_773275.host, call_773275.base,
                         call_773275.route, valid.getOrDefault("path"))
  result = hook(call_773275, url, valid)

proc call*(call_773276: Call_CreateUpload_773263; body: JsonNode): Recallable =
  ## createUpload
  ## Uploads an app or test scripts.
  ##   body: JObject (required)
  var body_773277 = newJObject()
  if body != nil:
    body_773277 = body
  result = call_773276.call(nil, nil, nil, nil, body_773277)

var createUpload* = Call_CreateUpload_773263(name: "createUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateUpload",
    validator: validate_CreateUpload_773264, base: "/", url: url_CreateUpload_773265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCEConfiguration_773278 = ref object of OpenApiRestCall_772598
proc url_CreateVPCEConfiguration_773280(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVPCEConfiguration_773279(path: JsonNode; query: JsonNode;
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
  var valid_773281 = header.getOrDefault("X-Amz-Date")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Date", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Security-Token")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Security-Token", valid_773282
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773283 = header.getOrDefault("X-Amz-Target")
  valid_773283 = validateParameter(valid_773283, JString, required = true, default = newJString(
      "DeviceFarm_20150623.CreateVPCEConfiguration"))
  if valid_773283 != nil:
    section.add "X-Amz-Target", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Content-Sha256", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Algorithm")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Algorithm", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Signature")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Signature", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-SignedHeaders", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Credential")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Credential", valid_773288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773290: Call_CreateVPCEConfiguration_773278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_773290.validator(path, query, header, formData, body)
  let scheme = call_773290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773290.url(scheme.get, call_773290.host, call_773290.base,
                         call_773290.route, valid.getOrDefault("path"))
  result = hook(call_773290, url, valid)

proc call*(call_773291: Call_CreateVPCEConfiguration_773278; body: JsonNode): Recallable =
  ## createVPCEConfiguration
  ## Creates a configuration record in Device Farm for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_773292 = newJObject()
  if body != nil:
    body_773292 = body
  result = call_773291.call(nil, nil, nil, nil, body_773292)

var createVPCEConfiguration* = Call_CreateVPCEConfiguration_773278(
    name: "createVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.CreateVPCEConfiguration",
    validator: validate_CreateVPCEConfiguration_773279, base: "/",
    url: url_CreateVPCEConfiguration_773280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevicePool_773293 = ref object of OpenApiRestCall_772598
proc url_DeleteDevicePool_773295(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDevicePool_773294(path: JsonNode; query: JsonNode;
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
  var valid_773296 = header.getOrDefault("X-Amz-Date")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Date", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Security-Token")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Security-Token", valid_773297
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773298 = header.getOrDefault("X-Amz-Target")
  valid_773298 = validateParameter(valid_773298, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteDevicePool"))
  if valid_773298 != nil:
    section.add "X-Amz-Target", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Content-Sha256", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Algorithm")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Algorithm", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Signature")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Signature", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-SignedHeaders", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Credential")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Credential", valid_773303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773305: Call_DeleteDevicePool_773293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ## 
  let valid = call_773305.validator(path, query, header, formData, body)
  let scheme = call_773305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773305.url(scheme.get, call_773305.host, call_773305.base,
                         call_773305.route, valid.getOrDefault("path"))
  result = hook(call_773305, url, valid)

proc call*(call_773306: Call_DeleteDevicePool_773293; body: JsonNode): Recallable =
  ## deleteDevicePool
  ## Deletes a device pool given the pool ARN. Does not allow deletion of curated pools owned by the system.
  ##   body: JObject (required)
  var body_773307 = newJObject()
  if body != nil:
    body_773307 = body
  result = call_773306.call(nil, nil, nil, nil, body_773307)

var deleteDevicePool* = Call_DeleteDevicePool_773293(name: "deleteDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteDevicePool",
    validator: validate_DeleteDevicePool_773294, base: "/",
    url: url_DeleteDevicePool_773295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceProfile_773308 = ref object of OpenApiRestCall_772598
proc url_DeleteInstanceProfile_773310(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInstanceProfile_773309(path: JsonNode; query: JsonNode;
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
  var valid_773311 = header.getOrDefault("X-Amz-Date")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Date", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Security-Token")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Security-Token", valid_773312
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773313 = header.getOrDefault("X-Amz-Target")
  valid_773313 = validateParameter(valid_773313, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteInstanceProfile"))
  if valid_773313 != nil:
    section.add "X-Amz-Target", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Content-Sha256", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Algorithm")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Algorithm", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Signature")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Signature", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-SignedHeaders", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Credential")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Credential", valid_773318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773320: Call_DeleteInstanceProfile_773308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a profile that can be applied to one or more private device instances.
  ## 
  let valid = call_773320.validator(path, query, header, formData, body)
  let scheme = call_773320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773320.url(scheme.get, call_773320.host, call_773320.base,
                         call_773320.route, valid.getOrDefault("path"))
  result = hook(call_773320, url, valid)

proc call*(call_773321: Call_DeleteInstanceProfile_773308; body: JsonNode): Recallable =
  ## deleteInstanceProfile
  ## Deletes a profile that can be applied to one or more private device instances.
  ##   body: JObject (required)
  var body_773322 = newJObject()
  if body != nil:
    body_773322 = body
  result = call_773321.call(nil, nil, nil, nil, body_773322)

var deleteInstanceProfile* = Call_DeleteInstanceProfile_773308(
    name: "deleteInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteInstanceProfile",
    validator: validate_DeleteInstanceProfile_773309, base: "/",
    url: url_DeleteInstanceProfile_773310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_773323 = ref object of OpenApiRestCall_772598
proc url_DeleteNetworkProfile_773325(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNetworkProfile_773324(path: JsonNode; query: JsonNode;
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
  var valid_773326 = header.getOrDefault("X-Amz-Date")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Date", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Security-Token")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Security-Token", valid_773327
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773328 = header.getOrDefault("X-Amz-Target")
  valid_773328 = validateParameter(valid_773328, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteNetworkProfile"))
  if valid_773328 != nil:
    section.add "X-Amz-Target", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Content-Sha256", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Algorithm")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Algorithm", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Signature")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Signature", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-SignedHeaders", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Credential")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Credential", valid_773333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773335: Call_DeleteNetworkProfile_773323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile.
  ## 
  let valid = call_773335.validator(path, query, header, formData, body)
  let scheme = call_773335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773335.url(scheme.get, call_773335.host, call_773335.base,
                         call_773335.route, valid.getOrDefault("path"))
  result = hook(call_773335, url, valid)

proc call*(call_773336: Call_DeleteNetworkProfile_773323; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile.
  ##   body: JObject (required)
  var body_773337 = newJObject()
  if body != nil:
    body_773337 = body
  result = call_773336.call(nil, nil, nil, nil, body_773337)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_773323(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_773324, base: "/",
    url: url_DeleteNetworkProfile_773325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_773338 = ref object of OpenApiRestCall_772598
proc url_DeleteProject_773340(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteProject_773339(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773341 = header.getOrDefault("X-Amz-Date")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Date", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Security-Token")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Security-Token", valid_773342
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773343 = header.getOrDefault("X-Amz-Target")
  valid_773343 = validateParameter(valid_773343, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteProject"))
  if valid_773343 != nil:
    section.add "X-Amz-Target", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Content-Sha256", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Algorithm")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Algorithm", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Signature")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Signature", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-SignedHeaders", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Credential")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Credential", valid_773348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773350: Call_DeleteProject_773338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_773350.validator(path, query, header, formData, body)
  let scheme = call_773350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773350.url(scheme.get, call_773350.host, call_773350.base,
                         call_773350.route, valid.getOrDefault("path"))
  result = hook(call_773350, url, valid)

proc call*(call_773351: Call_DeleteProject_773338; body: JsonNode): Recallable =
  ## deleteProject
  ## <p>Deletes an AWS Device Farm project, given the project ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_773352 = newJObject()
  if body != nil:
    body_773352 = body
  result = call_773351.call(nil, nil, nil, nil, body_773352)

var deleteProject* = Call_DeleteProject_773338(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteProject",
    validator: validate_DeleteProject_773339, base: "/", url: url_DeleteProject_773340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemoteAccessSession_773353 = ref object of OpenApiRestCall_772598
proc url_DeleteRemoteAccessSession_773355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRemoteAccessSession_773354(path: JsonNode; query: JsonNode;
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
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773358 = header.getOrDefault("X-Amz-Target")
  valid_773358 = validateParameter(valid_773358, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRemoteAccessSession"))
  if valid_773358 != nil:
    section.add "X-Amz-Target", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Content-Sha256", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Algorithm")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Algorithm", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Signature")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Signature", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-SignedHeaders", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Credential")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Credential", valid_773363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773365: Call_DeleteRemoteAccessSession_773353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a completed remote access session and its results.
  ## 
  let valid = call_773365.validator(path, query, header, formData, body)
  let scheme = call_773365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773365.url(scheme.get, call_773365.host, call_773365.base,
                         call_773365.route, valid.getOrDefault("path"))
  result = hook(call_773365, url, valid)

proc call*(call_773366: Call_DeleteRemoteAccessSession_773353; body: JsonNode): Recallable =
  ## deleteRemoteAccessSession
  ## Deletes a completed remote access session and its results.
  ##   body: JObject (required)
  var body_773367 = newJObject()
  if body != nil:
    body_773367 = body
  result = call_773366.call(nil, nil, nil, nil, body_773367)

var deleteRemoteAccessSession* = Call_DeleteRemoteAccessSession_773353(
    name: "deleteRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRemoteAccessSession",
    validator: validate_DeleteRemoteAccessSession_773354, base: "/",
    url: url_DeleteRemoteAccessSession_773355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRun_773368 = ref object of OpenApiRestCall_772598
proc url_DeleteRun_773370(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRun_773369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773371 = header.getOrDefault("X-Amz-Date")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Date", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Security-Token")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Security-Token", valid_773372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773373 = header.getOrDefault("X-Amz-Target")
  valid_773373 = validateParameter(valid_773373, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteRun"))
  if valid_773373 != nil:
    section.add "X-Amz-Target", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Content-Sha256", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Algorithm")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Algorithm", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Signature")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Signature", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-SignedHeaders", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Credential")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Credential", valid_773378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773380: Call_DeleteRun_773368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ## 
  let valid = call_773380.validator(path, query, header, formData, body)
  let scheme = call_773380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773380.url(scheme.get, call_773380.host, call_773380.base,
                         call_773380.route, valid.getOrDefault("path"))
  result = hook(call_773380, url, valid)

proc call*(call_773381: Call_DeleteRun_773368; body: JsonNode): Recallable =
  ## deleteRun
  ## <p>Deletes the run, given the run ARN.</p> <p> <b>Note</b> Deleting this resource does not stop an in-progress run.</p>
  ##   body: JObject (required)
  var body_773382 = newJObject()
  if body != nil:
    body_773382 = body
  result = call_773381.call(nil, nil, nil, nil, body_773382)

var deleteRun* = Call_DeleteRun_773368(name: "deleteRun", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteRun",
                                    validator: validate_DeleteRun_773369,
                                    base: "/", url: url_DeleteRun_773370,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUpload_773383 = ref object of OpenApiRestCall_772598
proc url_DeleteUpload_773385(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUpload_773384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773386 = header.getOrDefault("X-Amz-Date")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Date", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Security-Token")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Security-Token", valid_773387
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773388 = header.getOrDefault("X-Amz-Target")
  valid_773388 = validateParameter(valid_773388, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteUpload"))
  if valid_773388 != nil:
    section.add "X-Amz-Target", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Content-Sha256", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Algorithm")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Algorithm", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Signature")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Signature", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-SignedHeaders", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Credential")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Credential", valid_773393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_DeleteUpload_773383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an upload given the upload ARN.
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_DeleteUpload_773383; body: JsonNode): Recallable =
  ## deleteUpload
  ## Deletes an upload given the upload ARN.
  ##   body: JObject (required)
  var body_773397 = newJObject()
  if body != nil:
    body_773397 = body
  result = call_773396.call(nil, nil, nil, nil, body_773397)

var deleteUpload* = Call_DeleteUpload_773383(name: "deleteUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteUpload",
    validator: validate_DeleteUpload_773384, base: "/", url: url_DeleteUpload_773385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCEConfiguration_773398 = ref object of OpenApiRestCall_772598
proc url_DeleteVPCEConfiguration_773400(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteVPCEConfiguration_773399(path: JsonNode; query: JsonNode;
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
  var valid_773401 = header.getOrDefault("X-Amz-Date")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Date", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Security-Token")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Security-Token", valid_773402
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773403 = header.getOrDefault("X-Amz-Target")
  valid_773403 = validateParameter(valid_773403, JString, required = true, default = newJString(
      "DeviceFarm_20150623.DeleteVPCEConfiguration"))
  if valid_773403 != nil:
    section.add "X-Amz-Target", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Content-Sha256", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Algorithm")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Algorithm", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Signature")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Signature", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-SignedHeaders", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Credential")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Credential", valid_773408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773410: Call_DeleteVPCEConfiguration_773398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_773410.validator(path, query, header, formData, body)
  let scheme = call_773410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773410.url(scheme.get, call_773410.host, call_773410.base,
                         call_773410.route, valid.getOrDefault("path"))
  result = hook(call_773410, url, valid)

proc call*(call_773411: Call_DeleteVPCEConfiguration_773398; body: JsonNode): Recallable =
  ## deleteVPCEConfiguration
  ## Deletes a configuration for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_773412 = newJObject()
  if body != nil:
    body_773412 = body
  result = call_773411.call(nil, nil, nil, nil, body_773412)

var deleteVPCEConfiguration* = Call_DeleteVPCEConfiguration_773398(
    name: "deleteVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.DeleteVPCEConfiguration",
    validator: validate_DeleteVPCEConfiguration_773399, base: "/",
    url: url_DeleteVPCEConfiguration_773400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_773413 = ref object of OpenApiRestCall_772598
proc url_GetAccountSettings_773415(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccountSettings_773414(path: JsonNode; query: JsonNode;
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
  var valid_773416 = header.getOrDefault("X-Amz-Date")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Date", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Security-Token")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Security-Token", valid_773417
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773418 = header.getOrDefault("X-Amz-Target")
  valid_773418 = validateParameter(valid_773418, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetAccountSettings"))
  if valid_773418 != nil:
    section.add "X-Amz-Target", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Content-Sha256", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Algorithm")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Algorithm", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Signature")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Signature", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-SignedHeaders", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Credential")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Credential", valid_773423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773425: Call_GetAccountSettings_773413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ## 
  let valid = call_773425.validator(path, query, header, formData, body)
  let scheme = call_773425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773425.url(scheme.get, call_773425.host, call_773425.base,
                         call_773425.route, valid.getOrDefault("path"))
  result = hook(call_773425, url, valid)

proc call*(call_773426: Call_GetAccountSettings_773413; body: JsonNode): Recallable =
  ## getAccountSettings
  ## Returns the number of unmetered iOS and/or unmetered Android devices that have been purchased by the account.
  ##   body: JObject (required)
  var body_773427 = newJObject()
  if body != nil:
    body_773427 = body
  result = call_773426.call(nil, nil, nil, nil, body_773427)

var getAccountSettings* = Call_GetAccountSettings_773413(
    name: "getAccountSettings", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetAccountSettings",
    validator: validate_GetAccountSettings_773414, base: "/",
    url: url_GetAccountSettings_773415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_773428 = ref object of OpenApiRestCall_772598
proc url_GetDevice_773430(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevice_773429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773431 = header.getOrDefault("X-Amz-Date")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Date", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Security-Token")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Security-Token", valid_773432
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773433 = header.getOrDefault("X-Amz-Target")
  valid_773433 = validateParameter(valid_773433, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevice"))
  if valid_773433 != nil:
    section.add "X-Amz-Target", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Content-Sha256", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Algorithm")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Algorithm", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Signature")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Signature", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-SignedHeaders", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Credential")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Credential", valid_773438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773440: Call_GetDevice_773428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a unique device type.
  ## 
  let valid = call_773440.validator(path, query, header, formData, body)
  let scheme = call_773440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773440.url(scheme.get, call_773440.host, call_773440.base,
                         call_773440.route, valid.getOrDefault("path"))
  result = hook(call_773440, url, valid)

proc call*(call_773441: Call_GetDevice_773428; body: JsonNode): Recallable =
  ## getDevice
  ## Gets information about a unique device type.
  ##   body: JObject (required)
  var body_773442 = newJObject()
  if body != nil:
    body_773442 = body
  result = call_773441.call(nil, nil, nil, nil, body_773442)

var getDevice* = Call_GetDevice_773428(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevice",
                                    validator: validate_GetDevice_773429,
                                    base: "/", url: url_GetDevice_773430,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceInstance_773443 = ref object of OpenApiRestCall_772598
proc url_GetDeviceInstance_773445(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeviceInstance_773444(path: JsonNode; query: JsonNode;
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
  var valid_773446 = header.getOrDefault("X-Amz-Date")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Date", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Security-Token")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Security-Token", valid_773447
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773448 = header.getOrDefault("X-Amz-Target")
  valid_773448 = validateParameter(valid_773448, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDeviceInstance"))
  if valid_773448 != nil:
    section.add "X-Amz-Target", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Content-Sha256", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Algorithm")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Algorithm", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Signature")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Signature", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-SignedHeaders", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Credential")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Credential", valid_773453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773455: Call_GetDeviceInstance_773443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a device instance belonging to a private device fleet.
  ## 
  let valid = call_773455.validator(path, query, header, formData, body)
  let scheme = call_773455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773455.url(scheme.get, call_773455.host, call_773455.base,
                         call_773455.route, valid.getOrDefault("path"))
  result = hook(call_773455, url, valid)

proc call*(call_773456: Call_GetDeviceInstance_773443; body: JsonNode): Recallable =
  ## getDeviceInstance
  ## Returns information about a device instance belonging to a private device fleet.
  ##   body: JObject (required)
  var body_773457 = newJObject()
  if body != nil:
    body_773457 = body
  result = call_773456.call(nil, nil, nil, nil, body_773457)

var getDeviceInstance* = Call_GetDeviceInstance_773443(name: "getDeviceInstance",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDeviceInstance",
    validator: validate_GetDeviceInstance_773444, base: "/",
    url: url_GetDeviceInstance_773445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePool_773458 = ref object of OpenApiRestCall_772598
proc url_GetDevicePool_773460(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevicePool_773459(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773461 = header.getOrDefault("X-Amz-Date")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Date", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Security-Token")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Security-Token", valid_773462
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773463 = header.getOrDefault("X-Amz-Target")
  valid_773463 = validateParameter(valid_773463, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePool"))
  if valid_773463 != nil:
    section.add "X-Amz-Target", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Content-Sha256", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Algorithm")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Algorithm", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Signature")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Signature", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-SignedHeaders", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Credential")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Credential", valid_773468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773470: Call_GetDevicePool_773458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a device pool.
  ## 
  let valid = call_773470.validator(path, query, header, formData, body)
  let scheme = call_773470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773470.url(scheme.get, call_773470.host, call_773470.base,
                         call_773470.route, valid.getOrDefault("path"))
  result = hook(call_773470, url, valid)

proc call*(call_773471: Call_GetDevicePool_773458; body: JsonNode): Recallable =
  ## getDevicePool
  ## Gets information about a device pool.
  ##   body: JObject (required)
  var body_773472 = newJObject()
  if body != nil:
    body_773472 = body
  result = call_773471.call(nil, nil, nil, nil, body_773472)

var getDevicePool* = Call_GetDevicePool_773458(name: "getDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePool",
    validator: validate_GetDevicePool_773459, base: "/", url: url_GetDevicePool_773460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicePoolCompatibility_773473 = ref object of OpenApiRestCall_772598
proc url_GetDevicePoolCompatibility_773475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevicePoolCompatibility_773474(path: JsonNode; query: JsonNode;
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
  var valid_773476 = header.getOrDefault("X-Amz-Date")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Date", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Security-Token")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Security-Token", valid_773477
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773478 = header.getOrDefault("X-Amz-Target")
  valid_773478 = validateParameter(valid_773478, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetDevicePoolCompatibility"))
  if valid_773478 != nil:
    section.add "X-Amz-Target", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Content-Sha256", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Algorithm")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Algorithm", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Signature")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Signature", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-SignedHeaders", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Credential")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Credential", valid_773483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773485: Call_GetDevicePoolCompatibility_773473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about compatibility with a device pool.
  ## 
  let valid = call_773485.validator(path, query, header, formData, body)
  let scheme = call_773485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773485.url(scheme.get, call_773485.host, call_773485.base,
                         call_773485.route, valid.getOrDefault("path"))
  result = hook(call_773485, url, valid)

proc call*(call_773486: Call_GetDevicePoolCompatibility_773473; body: JsonNode): Recallable =
  ## getDevicePoolCompatibility
  ## Gets information about compatibility with a device pool.
  ##   body: JObject (required)
  var body_773487 = newJObject()
  if body != nil:
    body_773487 = body
  result = call_773486.call(nil, nil, nil, nil, body_773487)

var getDevicePoolCompatibility* = Call_GetDevicePoolCompatibility_773473(
    name: "getDevicePoolCompatibility", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetDevicePoolCompatibility",
    validator: validate_GetDevicePoolCompatibility_773474, base: "/",
    url: url_GetDevicePoolCompatibility_773475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceProfile_773488 = ref object of OpenApiRestCall_772598
proc url_GetInstanceProfile_773490(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInstanceProfile_773489(path: JsonNode; query: JsonNode;
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
  var valid_773491 = header.getOrDefault("X-Amz-Date")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Date", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Security-Token")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Security-Token", valid_773492
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773493 = header.getOrDefault("X-Amz-Target")
  valid_773493 = validateParameter(valid_773493, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetInstanceProfile"))
  if valid_773493 != nil:
    section.add "X-Amz-Target", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Content-Sha256", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Algorithm")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Algorithm", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Signature")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Signature", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-SignedHeaders", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Credential")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Credential", valid_773498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773500: Call_GetInstanceProfile_773488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified instance profile.
  ## 
  let valid = call_773500.validator(path, query, header, formData, body)
  let scheme = call_773500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773500.url(scheme.get, call_773500.host, call_773500.base,
                         call_773500.route, valid.getOrDefault("path"))
  result = hook(call_773500, url, valid)

proc call*(call_773501: Call_GetInstanceProfile_773488; body: JsonNode): Recallable =
  ## getInstanceProfile
  ## Returns information about the specified instance profile.
  ##   body: JObject (required)
  var body_773502 = newJObject()
  if body != nil:
    body_773502 = body
  result = call_773501.call(nil, nil, nil, nil, body_773502)

var getInstanceProfile* = Call_GetInstanceProfile_773488(
    name: "getInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetInstanceProfile",
    validator: validate_GetInstanceProfile_773489, base: "/",
    url: url_GetInstanceProfile_773490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_773503 = ref object of OpenApiRestCall_772598
proc url_GetJob_773505(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJob_773504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773508 = header.getOrDefault("X-Amz-Target")
  valid_773508 = validateParameter(valid_773508, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetJob"))
  if valid_773508 != nil:
    section.add "X-Amz-Target", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Content-Sha256", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Algorithm")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Algorithm", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-Signature")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Signature", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-SignedHeaders", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Credential")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Credential", valid_773513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773515: Call_GetJob_773503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a job.
  ## 
  let valid = call_773515.validator(path, query, header, formData, body)
  let scheme = call_773515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773515.url(scheme.get, call_773515.host, call_773515.base,
                         call_773515.route, valid.getOrDefault("path"))
  result = hook(call_773515, url, valid)

proc call*(call_773516: Call_GetJob_773503; body: JsonNode): Recallable =
  ## getJob
  ## Gets information about a job.
  ##   body: JObject (required)
  var body_773517 = newJObject()
  if body != nil:
    body_773517 = body
  result = call_773516.call(nil, nil, nil, nil, body_773517)

var getJob* = Call_GetJob_773503(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetJob",
                              validator: validate_GetJob_773504, base: "/",
                              url: url_GetJob_773505,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_773518 = ref object of OpenApiRestCall_772598
proc url_GetNetworkProfile_773520(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetNetworkProfile_773519(path: JsonNode; query: JsonNode;
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
  var valid_773521 = header.getOrDefault("X-Amz-Date")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Date", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Security-Token")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Security-Token", valid_773522
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773523 = header.getOrDefault("X-Amz-Target")
  valid_773523 = validateParameter(valid_773523, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetNetworkProfile"))
  if valid_773523 != nil:
    section.add "X-Amz-Target", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Content-Sha256", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Algorithm")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Algorithm", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Signature")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Signature", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-SignedHeaders", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Credential")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Credential", valid_773528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773530: Call_GetNetworkProfile_773518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a network profile.
  ## 
  let valid = call_773530.validator(path, query, header, formData, body)
  let scheme = call_773530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773530.url(scheme.get, call_773530.host, call_773530.base,
                         call_773530.route, valid.getOrDefault("path"))
  result = hook(call_773530, url, valid)

proc call*(call_773531: Call_GetNetworkProfile_773518; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Returns information about a network profile.
  ##   body: JObject (required)
  var body_773532 = newJObject()
  if body != nil:
    body_773532 = body
  result = call_773531.call(nil, nil, nil, nil, body_773532)

var getNetworkProfile* = Call_GetNetworkProfile_773518(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetNetworkProfile",
    validator: validate_GetNetworkProfile_773519, base: "/",
    url: url_GetNetworkProfile_773520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOfferingStatus_773533 = ref object of OpenApiRestCall_772598
proc url_GetOfferingStatus_773535(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOfferingStatus_773534(path: JsonNode; query: JsonNode;
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
  var valid_773536 = query.getOrDefault("nextToken")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "nextToken", valid_773536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773537 = header.getOrDefault("X-Amz-Date")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Date", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Security-Token")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Security-Token", valid_773538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773539 = header.getOrDefault("X-Amz-Target")
  valid_773539 = validateParameter(valid_773539, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetOfferingStatus"))
  if valid_773539 != nil:
    section.add "X-Amz-Target", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Content-Sha256", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Algorithm")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Algorithm", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Signature")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Signature", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-SignedHeaders", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Credential")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Credential", valid_773544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773546: Call_GetOfferingStatus_773533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_773546.validator(path, query, header, formData, body)
  let scheme = call_773546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773546.url(scheme.get, call_773546.host, call_773546.base,
                         call_773546.route, valid.getOrDefault("path"))
  result = hook(call_773546, url, valid)

proc call*(call_773547: Call_GetOfferingStatus_773533; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## getOfferingStatus
  ## Gets the current status and future status of all offerings purchased by an AWS account. The response indicates how many offerings are currently available and the offerings that will be available in the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773548 = newJObject()
  var body_773549 = newJObject()
  add(query_773548, "nextToken", newJString(nextToken))
  if body != nil:
    body_773549 = body
  result = call_773547.call(nil, query_773548, nil, nil, body_773549)

var getOfferingStatus* = Call_GetOfferingStatus_773533(name: "getOfferingStatus",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetOfferingStatus",
    validator: validate_GetOfferingStatus_773534, base: "/",
    url: url_GetOfferingStatus_773535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProject_773551 = ref object of OpenApiRestCall_772598
proc url_GetProject_773553(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetProject_773552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773554 = header.getOrDefault("X-Amz-Date")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Date", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Security-Token")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Security-Token", valid_773555
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773556 = header.getOrDefault("X-Amz-Target")
  valid_773556 = validateParameter(valid_773556, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetProject"))
  if valid_773556 != nil:
    section.add "X-Amz-Target", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Content-Sha256", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Algorithm")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Algorithm", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Signature")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Signature", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-SignedHeaders", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Credential")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Credential", valid_773561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773563: Call_GetProject_773551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a project.
  ## 
  let valid = call_773563.validator(path, query, header, formData, body)
  let scheme = call_773563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773563.url(scheme.get, call_773563.host, call_773563.base,
                         call_773563.route, valid.getOrDefault("path"))
  result = hook(call_773563, url, valid)

proc call*(call_773564: Call_GetProject_773551; body: JsonNode): Recallable =
  ## getProject
  ## Gets information about a project.
  ##   body: JObject (required)
  var body_773565 = newJObject()
  if body != nil:
    body_773565 = body
  result = call_773564.call(nil, nil, nil, nil, body_773565)

var getProject* = Call_GetProject_773551(name: "getProject",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetProject",
                                      validator: validate_GetProject_773552,
                                      base: "/", url: url_GetProject_773553,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoteAccessSession_773566 = ref object of OpenApiRestCall_772598
proc url_GetRemoteAccessSession_773568(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoteAccessSession_773567(path: JsonNode; query: JsonNode;
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
  var valid_773569 = header.getOrDefault("X-Amz-Date")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Date", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Security-Token")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Security-Token", valid_773570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773571 = header.getOrDefault("X-Amz-Target")
  valid_773571 = validateParameter(valid_773571, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRemoteAccessSession"))
  if valid_773571 != nil:
    section.add "X-Amz-Target", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Content-Sha256", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Algorithm")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Algorithm", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Signature")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Signature", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-SignedHeaders", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Credential")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Credential", valid_773576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773578: Call_GetRemoteAccessSession_773566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a link to a currently running remote access session.
  ## 
  let valid = call_773578.validator(path, query, header, formData, body)
  let scheme = call_773578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773578.url(scheme.get, call_773578.host, call_773578.base,
                         call_773578.route, valid.getOrDefault("path"))
  result = hook(call_773578, url, valid)

proc call*(call_773579: Call_GetRemoteAccessSession_773566; body: JsonNode): Recallable =
  ## getRemoteAccessSession
  ## Returns a link to a currently running remote access session.
  ##   body: JObject (required)
  var body_773580 = newJObject()
  if body != nil:
    body_773580 = body
  result = call_773579.call(nil, nil, nil, nil, body_773580)

var getRemoteAccessSession* = Call_GetRemoteAccessSession_773566(
    name: "getRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetRemoteAccessSession",
    validator: validate_GetRemoteAccessSession_773567, base: "/",
    url: url_GetRemoteAccessSession_773568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRun_773581 = ref object of OpenApiRestCall_772598
proc url_GetRun_773583(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRun_773582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773584 = header.getOrDefault("X-Amz-Date")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Date", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Security-Token")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Security-Token", valid_773585
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773586 = header.getOrDefault("X-Amz-Target")
  valid_773586 = validateParameter(valid_773586, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetRun"))
  if valid_773586 != nil:
    section.add "X-Amz-Target", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Content-Sha256", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Algorithm")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Algorithm", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Signature")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Signature", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-SignedHeaders", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Credential")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Credential", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_GetRun_773581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a run.
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_GetRun_773581; body: JsonNode): Recallable =
  ## getRun
  ## Gets information about a run.
  ##   body: JObject (required)
  var body_773595 = newJObject()
  if body != nil:
    body_773595 = body
  result = call_773594.call(nil, nil, nil, nil, body_773595)

var getRun* = Call_GetRun_773581(name: "getRun", meth: HttpMethod.HttpPost,
                              host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetRun",
                              validator: validate_GetRun_773582, base: "/",
                              url: url_GetRun_773583,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuite_773596 = ref object of OpenApiRestCall_772598
proc url_GetSuite_773598(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSuite_773597(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773599 = header.getOrDefault("X-Amz-Date")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Date", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Security-Token")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Security-Token", valid_773600
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773601 = header.getOrDefault("X-Amz-Target")
  valid_773601 = validateParameter(valid_773601, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetSuite"))
  if valid_773601 != nil:
    section.add "X-Amz-Target", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Content-Sha256", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Algorithm")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Algorithm", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Signature")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Signature", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-SignedHeaders", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Credential")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Credential", valid_773606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773608: Call_GetSuite_773596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a suite.
  ## 
  let valid = call_773608.validator(path, query, header, formData, body)
  let scheme = call_773608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773608.url(scheme.get, call_773608.host, call_773608.base,
                         call_773608.route, valid.getOrDefault("path"))
  result = hook(call_773608, url, valid)

proc call*(call_773609: Call_GetSuite_773596; body: JsonNode): Recallable =
  ## getSuite
  ## Gets information about a suite.
  ##   body: JObject (required)
  var body_773610 = newJObject()
  if body != nil:
    body_773610 = body
  result = call_773609.call(nil, nil, nil, nil, body_773610)

var getSuite* = Call_GetSuite_773596(name: "getSuite", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetSuite",
                                  validator: validate_GetSuite_773597, base: "/",
                                  url: url_GetSuite_773598,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTest_773611 = ref object of OpenApiRestCall_772598
proc url_GetTest_773613(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTest_773612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773614 = header.getOrDefault("X-Amz-Date")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Date", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Security-Token")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Security-Token", valid_773615
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773616 = header.getOrDefault("X-Amz-Target")
  valid_773616 = validateParameter(valid_773616, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetTest"))
  if valid_773616 != nil:
    section.add "X-Amz-Target", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Content-Sha256", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Algorithm")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Algorithm", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Signature")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Signature", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-SignedHeaders", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Credential")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Credential", valid_773621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_GetTest_773611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a test.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_GetTest_773611; body: JsonNode): Recallable =
  ## getTest
  ## Gets information about a test.
  ##   body: JObject (required)
  var body_773625 = newJObject()
  if body != nil:
    body_773625 = body
  result = call_773624.call(nil, nil, nil, nil, body_773625)

var getTest* = Call_GetTest_773611(name: "getTest", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetTest",
                                validator: validate_GetTest_773612, base: "/",
                                url: url_GetTest_773613,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpload_773626 = ref object of OpenApiRestCall_772598
proc url_GetUpload_773628(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpload_773627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773631 = header.getOrDefault("X-Amz-Target")
  valid_773631 = validateParameter(valid_773631, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetUpload"))
  if valid_773631 != nil:
    section.add "X-Amz-Target", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Content-Sha256", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Algorithm")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Algorithm", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Signature")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Signature", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-SignedHeaders", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Credential")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Credential", valid_773636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773638: Call_GetUpload_773626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an upload.
  ## 
  let valid = call_773638.validator(path, query, header, formData, body)
  let scheme = call_773638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773638.url(scheme.get, call_773638.host, call_773638.base,
                         call_773638.route, valid.getOrDefault("path"))
  result = hook(call_773638, url, valid)

proc call*(call_773639: Call_GetUpload_773626; body: JsonNode): Recallable =
  ## getUpload
  ## Gets information about an upload.
  ##   body: JObject (required)
  var body_773640 = newJObject()
  if body != nil:
    body_773640 = body
  result = call_773639.call(nil, nil, nil, nil, body_773640)

var getUpload* = Call_GetUpload_773626(name: "getUpload", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.GetUpload",
                                    validator: validate_GetUpload_773627,
                                    base: "/", url: url_GetUpload_773628,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVPCEConfiguration_773641 = ref object of OpenApiRestCall_772598
proc url_GetVPCEConfiguration_773643(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetVPCEConfiguration_773642(path: JsonNode; query: JsonNode;
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
  var valid_773644 = header.getOrDefault("X-Amz-Date")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Date", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Security-Token")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Security-Token", valid_773645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773646 = header.getOrDefault("X-Amz-Target")
  valid_773646 = validateParameter(valid_773646, JString, required = true, default = newJString(
      "DeviceFarm_20150623.GetVPCEConfiguration"))
  if valid_773646 != nil:
    section.add "X-Amz-Target", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Content-Sha256", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Algorithm")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Algorithm", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Signature")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Signature", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-SignedHeaders", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Credential")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Credential", valid_773651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773653: Call_GetVPCEConfiguration_773641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ## 
  let valid = call_773653.validator(path, query, header, formData, body)
  let scheme = call_773653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773653.url(scheme.get, call_773653.host, call_773653.base,
                         call_773653.route, valid.getOrDefault("path"))
  result = hook(call_773653, url, valid)

proc call*(call_773654: Call_GetVPCEConfiguration_773641; body: JsonNode): Recallable =
  ## getVPCEConfiguration
  ## Returns information about the configuration settings for your Amazon Virtual Private Cloud (VPC) endpoint.
  ##   body: JObject (required)
  var body_773655 = newJObject()
  if body != nil:
    body_773655 = body
  result = call_773654.call(nil, nil, nil, nil, body_773655)

var getVPCEConfiguration* = Call_GetVPCEConfiguration_773641(
    name: "getVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.GetVPCEConfiguration",
    validator: validate_GetVPCEConfiguration_773642, base: "/",
    url: url_GetVPCEConfiguration_773643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InstallToRemoteAccessSession_773656 = ref object of OpenApiRestCall_772598
proc url_InstallToRemoteAccessSession_773658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InstallToRemoteAccessSession_773657(path: JsonNode; query: JsonNode;
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
  var valid_773659 = header.getOrDefault("X-Amz-Date")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Date", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Security-Token")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Security-Token", valid_773660
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773661 = header.getOrDefault("X-Amz-Target")
  valid_773661 = validateParameter(valid_773661, JString, required = true, default = newJString(
      "DeviceFarm_20150623.InstallToRemoteAccessSession"))
  if valid_773661 != nil:
    section.add "X-Amz-Target", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Content-Sha256", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Algorithm")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Algorithm", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Signature")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Signature", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-SignedHeaders", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Credential")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Credential", valid_773666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773668: Call_InstallToRemoteAccessSession_773656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ## 
  let valid = call_773668.validator(path, query, header, formData, body)
  let scheme = call_773668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773668.url(scheme.get, call_773668.host, call_773668.base,
                         call_773668.route, valid.getOrDefault("path"))
  result = hook(call_773668, url, valid)

proc call*(call_773669: Call_InstallToRemoteAccessSession_773656; body: JsonNode): Recallable =
  ## installToRemoteAccessSession
  ## Installs an application to the device in a remote access session. For Android applications, the file must be in .apk format. For iOS applications, the file must be in .ipa format.
  ##   body: JObject (required)
  var body_773670 = newJObject()
  if body != nil:
    body_773670 = body
  result = call_773669.call(nil, nil, nil, nil, body_773670)

var installToRemoteAccessSession* = Call_InstallToRemoteAccessSession_773656(
    name: "installToRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.InstallToRemoteAccessSession",
    validator: validate_InstallToRemoteAccessSession_773657, base: "/",
    url: url_InstallToRemoteAccessSession_773658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_773671 = ref object of OpenApiRestCall_772598
proc url_ListArtifacts_773673(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListArtifacts_773672(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773674 = query.getOrDefault("nextToken")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "nextToken", valid_773674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773675 = header.getOrDefault("X-Amz-Date")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Date", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Security-Token")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Security-Token", valid_773676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773677 = header.getOrDefault("X-Amz-Target")
  valid_773677 = validateParameter(valid_773677, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListArtifacts"))
  if valid_773677 != nil:
    section.add "X-Amz-Target", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Content-Sha256", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Algorithm")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Algorithm", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Signature")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Signature", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-SignedHeaders", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Credential")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Credential", valid_773682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_ListArtifacts_773671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about artifacts.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_ListArtifacts_773671; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listArtifacts
  ## Gets information about artifacts.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773686 = newJObject()
  var body_773687 = newJObject()
  add(query_773686, "nextToken", newJString(nextToken))
  if body != nil:
    body_773687 = body
  result = call_773685.call(nil, query_773686, nil, nil, body_773687)

var listArtifacts* = Call_ListArtifacts_773671(name: "listArtifacts",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListArtifacts",
    validator: validate_ListArtifacts_773672, base: "/", url: url_ListArtifacts_773673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceInstances_773688 = ref object of OpenApiRestCall_772598
proc url_ListDeviceInstances_773690(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeviceInstances_773689(path: JsonNode; query: JsonNode;
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
  var valid_773691 = header.getOrDefault("X-Amz-Date")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Date", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Security-Token")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Security-Token", valid_773692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773693 = header.getOrDefault("X-Amz-Target")
  valid_773693 = validateParameter(valid_773693, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDeviceInstances"))
  if valid_773693 != nil:
    section.add "X-Amz-Target", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Content-Sha256", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Algorithm")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Algorithm", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Signature")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Signature", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-SignedHeaders", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Credential")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Credential", valid_773698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773700: Call_ListDeviceInstances_773688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ## 
  let valid = call_773700.validator(path, query, header, formData, body)
  let scheme = call_773700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773700.url(scheme.get, call_773700.host, call_773700.base,
                         call_773700.route, valid.getOrDefault("path"))
  result = hook(call_773700, url, valid)

proc call*(call_773701: Call_ListDeviceInstances_773688; body: JsonNode): Recallable =
  ## listDeviceInstances
  ## Returns information about the private device instances associated with one or more AWS accounts.
  ##   body: JObject (required)
  var body_773702 = newJObject()
  if body != nil:
    body_773702 = body
  result = call_773701.call(nil, nil, nil, nil, body_773702)

var listDeviceInstances* = Call_ListDeviceInstances_773688(
    name: "listDeviceInstances", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDeviceInstances",
    validator: validate_ListDeviceInstances_773689, base: "/",
    url: url_ListDeviceInstances_773690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevicePools_773703 = ref object of OpenApiRestCall_772598
proc url_ListDevicePools_773705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevicePools_773704(path: JsonNode; query: JsonNode;
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
  var valid_773706 = query.getOrDefault("nextToken")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "nextToken", valid_773706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773707 = header.getOrDefault("X-Amz-Date")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Date", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Security-Token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Security-Token", valid_773708
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773709 = header.getOrDefault("X-Amz-Target")
  valid_773709 = validateParameter(valid_773709, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevicePools"))
  if valid_773709 != nil:
    section.add "X-Amz-Target", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Content-Sha256", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Algorithm")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Algorithm", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Signature")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Signature", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-SignedHeaders", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Credential")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Credential", valid_773714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773716: Call_ListDevicePools_773703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about device pools.
  ## 
  let valid = call_773716.validator(path, query, header, formData, body)
  let scheme = call_773716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773716.url(scheme.get, call_773716.host, call_773716.base,
                         call_773716.route, valid.getOrDefault("path"))
  result = hook(call_773716, url, valid)

proc call*(call_773717: Call_ListDevicePools_773703; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevicePools
  ## Gets information about device pools.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773718 = newJObject()
  var body_773719 = newJObject()
  add(query_773718, "nextToken", newJString(nextToken))
  if body != nil:
    body_773719 = body
  result = call_773717.call(nil, query_773718, nil, nil, body_773719)

var listDevicePools* = Call_ListDevicePools_773703(name: "listDevicePools",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevicePools",
    validator: validate_ListDevicePools_773704, base: "/", url: url_ListDevicePools_773705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_773720 = ref object of OpenApiRestCall_772598
proc url_ListDevices_773722(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevices_773721(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773723 = query.getOrDefault("nextToken")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "nextToken", valid_773723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773724 = header.getOrDefault("X-Amz-Date")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Date", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Security-Token")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Security-Token", valid_773725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773726 = header.getOrDefault("X-Amz-Target")
  valid_773726 = validateParameter(valid_773726, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListDevices"))
  if valid_773726 != nil:
    section.add "X-Amz-Target", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Content-Sha256", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Algorithm")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Algorithm", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Signature")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Signature", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-SignedHeaders", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Credential")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Credential", valid_773731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773733: Call_ListDevices_773720; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique device types.
  ## 
  let valid = call_773733.validator(path, query, header, formData, body)
  let scheme = call_773733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773733.url(scheme.get, call_773733.host, call_773733.base,
                         call_773733.route, valid.getOrDefault("path"))
  result = hook(call_773733, url, valid)

proc call*(call_773734: Call_ListDevices_773720; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDevices
  ## Gets information about unique device types.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773735 = newJObject()
  var body_773736 = newJObject()
  add(query_773735, "nextToken", newJString(nextToken))
  if body != nil:
    body_773736 = body
  result = call_773734.call(nil, query_773735, nil, nil, body_773736)

var listDevices* = Call_ListDevices_773720(name: "listDevices",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListDevices",
                                        validator: validate_ListDevices_773721,
                                        base: "/", url: url_ListDevices_773722,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceProfiles_773737 = ref object of OpenApiRestCall_772598
proc url_ListInstanceProfiles_773739(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInstanceProfiles_773738(path: JsonNode; query: JsonNode;
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
  var valid_773740 = header.getOrDefault("X-Amz-Date")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Date", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Security-Token")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Security-Token", valid_773741
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773742 = header.getOrDefault("X-Amz-Target")
  valid_773742 = validateParameter(valid_773742, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListInstanceProfiles"))
  if valid_773742 != nil:
    section.add "X-Amz-Target", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Content-Sha256", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Algorithm")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Algorithm", valid_773744
  var valid_773745 = header.getOrDefault("X-Amz-Signature")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Signature", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-SignedHeaders", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Credential")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Credential", valid_773747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773749: Call_ListInstanceProfiles_773737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all the instance profiles in an AWS account.
  ## 
  let valid = call_773749.validator(path, query, header, formData, body)
  let scheme = call_773749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773749.url(scheme.get, call_773749.host, call_773749.base,
                         call_773749.route, valid.getOrDefault("path"))
  result = hook(call_773749, url, valid)

proc call*(call_773750: Call_ListInstanceProfiles_773737; body: JsonNode): Recallable =
  ## listInstanceProfiles
  ## Returns information about all the instance profiles in an AWS account.
  ##   body: JObject (required)
  var body_773751 = newJObject()
  if body != nil:
    body_773751 = body
  result = call_773750.call(nil, nil, nil, nil, body_773751)

var listInstanceProfiles* = Call_ListInstanceProfiles_773737(
    name: "listInstanceProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListInstanceProfiles",
    validator: validate_ListInstanceProfiles_773738, base: "/",
    url: url_ListInstanceProfiles_773739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_773752 = ref object of OpenApiRestCall_772598
proc url_ListJobs_773754(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_773753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773755 = query.getOrDefault("nextToken")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "nextToken", valid_773755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773756 = header.getOrDefault("X-Amz-Date")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Date", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Security-Token")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Security-Token", valid_773757
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773758 = header.getOrDefault("X-Amz-Target")
  valid_773758 = validateParameter(valid_773758, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListJobs"))
  if valid_773758 != nil:
    section.add "X-Amz-Target", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Content-Sha256", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Algorithm")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Algorithm", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Signature")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Signature", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-SignedHeaders", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Credential")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Credential", valid_773763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773765: Call_ListJobs_773752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about jobs for a given test run.
  ## 
  let valid = call_773765.validator(path, query, header, formData, body)
  let scheme = call_773765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773765.url(scheme.get, call_773765.host, call_773765.base,
                         call_773765.route, valid.getOrDefault("path"))
  result = hook(call_773765, url, valid)

proc call*(call_773766: Call_ListJobs_773752; body: JsonNode; nextToken: string = ""): Recallable =
  ## listJobs
  ## Gets information about jobs for a given test run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773767 = newJObject()
  var body_773768 = newJObject()
  add(query_773767, "nextToken", newJString(nextToken))
  if body != nil:
    body_773768 = body
  result = call_773766.call(nil, query_773767, nil, nil, body_773768)

var listJobs* = Call_ListJobs_773752(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListJobs",
                                  validator: validate_ListJobs_773753, base: "/",
                                  url: url_ListJobs_773754,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNetworkProfiles_773769 = ref object of OpenApiRestCall_772598
proc url_ListNetworkProfiles_773771(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNetworkProfiles_773770(path: JsonNode; query: JsonNode;
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
  var valid_773772 = header.getOrDefault("X-Amz-Date")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Date", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-Security-Token")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-Security-Token", valid_773773
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773774 = header.getOrDefault("X-Amz-Target")
  valid_773774 = validateParameter(valid_773774, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListNetworkProfiles"))
  if valid_773774 != nil:
    section.add "X-Amz-Target", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Content-Sha256", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Algorithm")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Algorithm", valid_773776
  var valid_773777 = header.getOrDefault("X-Amz-Signature")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Signature", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-SignedHeaders", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Credential")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Credential", valid_773779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773781: Call_ListNetworkProfiles_773769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of available network profiles.
  ## 
  let valid = call_773781.validator(path, query, header, formData, body)
  let scheme = call_773781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773781.url(scheme.get, call_773781.host, call_773781.base,
                         call_773781.route, valid.getOrDefault("path"))
  result = hook(call_773781, url, valid)

proc call*(call_773782: Call_ListNetworkProfiles_773769; body: JsonNode): Recallable =
  ## listNetworkProfiles
  ## Returns the list of available network profiles.
  ##   body: JObject (required)
  var body_773783 = newJObject()
  if body != nil:
    body_773783 = body
  result = call_773782.call(nil, nil, nil, nil, body_773783)

var listNetworkProfiles* = Call_ListNetworkProfiles_773769(
    name: "listNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListNetworkProfiles",
    validator: validate_ListNetworkProfiles_773770, base: "/",
    url: url_ListNetworkProfiles_773771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingPromotions_773784 = ref object of OpenApiRestCall_772598
proc url_ListOfferingPromotions_773786(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOfferingPromotions_773785(path: JsonNode; query: JsonNode;
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
  var valid_773787 = header.getOrDefault("X-Amz-Date")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Date", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Security-Token")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Security-Token", valid_773788
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773789 = header.getOrDefault("X-Amz-Target")
  valid_773789 = validateParameter(valid_773789, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingPromotions"))
  if valid_773789 != nil:
    section.add "X-Amz-Target", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Content-Sha256", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Algorithm")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Algorithm", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Signature")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Signature", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-SignedHeaders", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Credential")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Credential", valid_773794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773796: Call_ListOfferingPromotions_773784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_773796.validator(path, query, header, formData, body)
  let scheme = call_773796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773796.url(scheme.get, call_773796.host, call_773796.base,
                         call_773796.route, valid.getOrDefault("path"))
  result = hook(call_773796, url, valid)

proc call*(call_773797: Call_ListOfferingPromotions_773784; body: JsonNode): Recallable =
  ## listOfferingPromotions
  ## Returns a list of offering promotions. Each offering promotion record contains the ID and description of the promotion. The API returns a <code>NotEligible</code> error if the caller is not permitted to invoke the operation. Contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_773798 = newJObject()
  if body != nil:
    body_773798 = body
  result = call_773797.call(nil, nil, nil, nil, body_773798)

var listOfferingPromotions* = Call_ListOfferingPromotions_773784(
    name: "listOfferingPromotions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingPromotions",
    validator: validate_ListOfferingPromotions_773785, base: "/",
    url: url_ListOfferingPromotions_773786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferingTransactions_773799 = ref object of OpenApiRestCall_772598
proc url_ListOfferingTransactions_773801(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOfferingTransactions_773800(path: JsonNode; query: JsonNode;
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
  var valid_773802 = query.getOrDefault("nextToken")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "nextToken", valid_773802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773803 = header.getOrDefault("X-Amz-Date")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Date", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Security-Token")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Security-Token", valid_773804
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773805 = header.getOrDefault("X-Amz-Target")
  valid_773805 = validateParameter(valid_773805, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferingTransactions"))
  if valid_773805 != nil:
    section.add "X-Amz-Target", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Content-Sha256", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-Algorithm")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-Algorithm", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Signature")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Signature", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-SignedHeaders", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Credential")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Credential", valid_773810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773812: Call_ListOfferingTransactions_773799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_773812.validator(path, query, header, formData, body)
  let scheme = call_773812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773812.url(scheme.get, call_773812.host, call_773812.base,
                         call_773812.route, valid.getOrDefault("path"))
  result = hook(call_773812, url, valid)

proc call*(call_773813: Call_ListOfferingTransactions_773799; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferingTransactions
  ## Returns a list of all historical purchases, renewals, and system renewal transactions for an AWS account. The list is paginated and ordered by a descending timestamp (most recent transactions are first). The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773814 = newJObject()
  var body_773815 = newJObject()
  add(query_773814, "nextToken", newJString(nextToken))
  if body != nil:
    body_773815 = body
  result = call_773813.call(nil, query_773814, nil, nil, body_773815)

var listOfferingTransactions* = Call_ListOfferingTransactions_773799(
    name: "listOfferingTransactions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferingTransactions",
    validator: validate_ListOfferingTransactions_773800, base: "/",
    url: url_ListOfferingTransactions_773801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_773816 = ref object of OpenApiRestCall_772598
proc url_ListOfferings_773818(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOfferings_773817(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773819 = query.getOrDefault("nextToken")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "nextToken", valid_773819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773820 = header.getOrDefault("X-Amz-Date")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Date", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Security-Token")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Security-Token", valid_773821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773822 = header.getOrDefault("X-Amz-Target")
  valid_773822 = validateParameter(valid_773822, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListOfferings"))
  if valid_773822 != nil:
    section.add "X-Amz-Target", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Content-Sha256", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Algorithm")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Algorithm", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Signature")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Signature", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-SignedHeaders", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Credential")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Credential", valid_773827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773829: Call_ListOfferings_773816; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_773829.validator(path, query, header, formData, body)
  let scheme = call_773829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773829.url(scheme.get, call_773829.host, call_773829.base,
                         call_773829.route, valid.getOrDefault("path"))
  result = hook(call_773829, url, valid)

proc call*(call_773830: Call_ListOfferings_773816; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listOfferings
  ## Returns a list of products or offerings that the user can manage through the API. Each offering record indicates the recurring price per unit and the frequency for that offering. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773831 = newJObject()
  var body_773832 = newJObject()
  add(query_773831, "nextToken", newJString(nextToken))
  if body != nil:
    body_773832 = body
  result = call_773830.call(nil, query_773831, nil, nil, body_773832)

var listOfferings* = Call_ListOfferings_773816(name: "listOfferings",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListOfferings",
    validator: validate_ListOfferings_773817, base: "/", url: url_ListOfferings_773818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_773833 = ref object of OpenApiRestCall_772598
proc url_ListProjects_773835(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProjects_773834(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773836 = query.getOrDefault("nextToken")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "nextToken", valid_773836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773837 = header.getOrDefault("X-Amz-Date")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Date", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Security-Token")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Security-Token", valid_773838
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773839 = header.getOrDefault("X-Amz-Target")
  valid_773839 = validateParameter(valid_773839, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListProjects"))
  if valid_773839 != nil:
    section.add "X-Amz-Target", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Content-Sha256", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-Algorithm")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-Algorithm", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Signature")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Signature", valid_773842
  var valid_773843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-SignedHeaders", valid_773843
  var valid_773844 = header.getOrDefault("X-Amz-Credential")
  valid_773844 = validateParameter(valid_773844, JString, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "X-Amz-Credential", valid_773844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773846: Call_ListProjects_773833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about projects.
  ## 
  let valid = call_773846.validator(path, query, header, formData, body)
  let scheme = call_773846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773846.url(scheme.get, call_773846.host, call_773846.base,
                         call_773846.route, valid.getOrDefault("path"))
  result = hook(call_773846, url, valid)

proc call*(call_773847: Call_ListProjects_773833; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Gets information about projects.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773848 = newJObject()
  var body_773849 = newJObject()
  add(query_773848, "nextToken", newJString(nextToken))
  if body != nil:
    body_773849 = body
  result = call_773847.call(nil, query_773848, nil, nil, body_773849)

var listProjects* = Call_ListProjects_773833(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListProjects",
    validator: validate_ListProjects_773834, base: "/", url: url_ListProjects_773835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRemoteAccessSessions_773850 = ref object of OpenApiRestCall_772598
proc url_ListRemoteAccessSessions_773852(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRemoteAccessSessions_773851(path: JsonNode; query: JsonNode;
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
  var valid_773853 = header.getOrDefault("X-Amz-Date")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Date", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Security-Token")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Security-Token", valid_773854
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773855 = header.getOrDefault("X-Amz-Target")
  valid_773855 = validateParameter(valid_773855, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRemoteAccessSessions"))
  if valid_773855 != nil:
    section.add "X-Amz-Target", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Content-Sha256", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Algorithm")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Algorithm", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Signature")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Signature", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-SignedHeaders", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Credential")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Credential", valid_773860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773862: Call_ListRemoteAccessSessions_773850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all currently running remote access sessions.
  ## 
  let valid = call_773862.validator(path, query, header, formData, body)
  let scheme = call_773862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773862.url(scheme.get, call_773862.host, call_773862.base,
                         call_773862.route, valid.getOrDefault("path"))
  result = hook(call_773862, url, valid)

proc call*(call_773863: Call_ListRemoteAccessSessions_773850; body: JsonNode): Recallable =
  ## listRemoteAccessSessions
  ## Returns a list of all currently running remote access sessions.
  ##   body: JObject (required)
  var body_773864 = newJObject()
  if body != nil:
    body_773864 = body
  result = call_773863.call(nil, nil, nil, nil, body_773864)

var listRemoteAccessSessions* = Call_ListRemoteAccessSessions_773850(
    name: "listRemoteAccessSessions", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListRemoteAccessSessions",
    validator: validate_ListRemoteAccessSessions_773851, base: "/",
    url: url_ListRemoteAccessSessions_773852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuns_773865 = ref object of OpenApiRestCall_772598
proc url_ListRuns_773867(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRuns_773866(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773868 = query.getOrDefault("nextToken")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "nextToken", valid_773868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773869 = header.getOrDefault("X-Amz-Date")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Date", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Security-Token")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Security-Token", valid_773870
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773871 = header.getOrDefault("X-Amz-Target")
  valid_773871 = validateParameter(valid_773871, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListRuns"))
  if valid_773871 != nil:
    section.add "X-Amz-Target", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Content-Sha256", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Algorithm")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Algorithm", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-Signature")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-Signature", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-SignedHeaders", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Credential")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Credential", valid_773876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773878: Call_ListRuns_773865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ## 
  let valid = call_773878.validator(path, query, header, formData, body)
  let scheme = call_773878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773878.url(scheme.get, call_773878.host, call_773878.base,
                         call_773878.route, valid.getOrDefault("path"))
  result = hook(call_773878, url, valid)

proc call*(call_773879: Call_ListRuns_773865; body: JsonNode; nextToken: string = ""): Recallable =
  ## listRuns
  ## Gets information about runs, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773880 = newJObject()
  var body_773881 = newJObject()
  add(query_773880, "nextToken", newJString(nextToken))
  if body != nil:
    body_773881 = body
  result = call_773879.call(nil, query_773880, nil, nil, body_773881)

var listRuns* = Call_ListRuns_773865(name: "listRuns", meth: HttpMethod.HttpPost,
                                  host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListRuns",
                                  validator: validate_ListRuns_773866, base: "/",
                                  url: url_ListRuns_773867,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSamples_773882 = ref object of OpenApiRestCall_772598
proc url_ListSamples_773884(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSamples_773883(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773885 = query.getOrDefault("nextToken")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "nextToken", valid_773885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773886 = header.getOrDefault("X-Amz-Date")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Date", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Security-Token")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Security-Token", valid_773887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773888 = header.getOrDefault("X-Amz-Target")
  valid_773888 = validateParameter(valid_773888, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSamples"))
  if valid_773888 != nil:
    section.add "X-Amz-Target", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Content-Sha256", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773895: Call_ListSamples_773882; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ## 
  let valid = call_773895.validator(path, query, header, formData, body)
  let scheme = call_773895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773895.url(scheme.get, call_773895.host, call_773895.base,
                         call_773895.route, valid.getOrDefault("path"))
  result = hook(call_773895, url, valid)

proc call*(call_773896: Call_ListSamples_773882; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSamples
  ## Gets information about samples, given an AWS Device Farm job ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773897 = newJObject()
  var body_773898 = newJObject()
  add(query_773897, "nextToken", newJString(nextToken))
  if body != nil:
    body_773898 = body
  result = call_773896.call(nil, query_773897, nil, nil, body_773898)

var listSamples* = Call_ListSamples_773882(name: "listSamples",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSamples",
                                        validator: validate_ListSamples_773883,
                                        base: "/", url: url_ListSamples_773884,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuites_773899 = ref object of OpenApiRestCall_772598
proc url_ListSuites_773901(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSuites_773900(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773902 = query.getOrDefault("nextToken")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "nextToken", valid_773902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773903 = header.getOrDefault("X-Amz-Date")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Date", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Security-Token")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Security-Token", valid_773904
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773905 = header.getOrDefault("X-Amz-Target")
  valid_773905 = validateParameter(valid_773905, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListSuites"))
  if valid_773905 != nil:
    section.add "X-Amz-Target", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Content-Sha256", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Algorithm")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Algorithm", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Signature")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Signature", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-SignedHeaders", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-Credential")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Credential", valid_773910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773912: Call_ListSuites_773899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about test suites for a given job.
  ## 
  let valid = call_773912.validator(path, query, header, formData, body)
  let scheme = call_773912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773912.url(scheme.get, call_773912.host, call_773912.base,
                         call_773912.route, valid.getOrDefault("path"))
  result = hook(call_773912, url, valid)

proc call*(call_773913: Call_ListSuites_773899; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listSuites
  ## Gets information about test suites for a given job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773914 = newJObject()
  var body_773915 = newJObject()
  add(query_773914, "nextToken", newJString(nextToken))
  if body != nil:
    body_773915 = body
  result = call_773913.call(nil, query_773914, nil, nil, body_773915)

var listSuites* = Call_ListSuites_773899(name: "listSuites",
                                      meth: HttpMethod.HttpPost,
                                      host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListSuites",
                                      validator: validate_ListSuites_773900,
                                      base: "/", url: url_ListSuites_773901,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773916 = ref object of OpenApiRestCall_772598
proc url_ListTagsForResource_773918(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773917(path: JsonNode; query: JsonNode;
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
  var valid_773919 = header.getOrDefault("X-Amz-Date")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Date", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Security-Token")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Security-Token", valid_773920
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773921 = header.getOrDefault("X-Amz-Target")
  valid_773921 = validateParameter(valid_773921, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTagsForResource"))
  if valid_773921 != nil:
    section.add "X-Amz-Target", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Content-Sha256", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Algorithm")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Algorithm", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Signature")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Signature", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-SignedHeaders", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Credential")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Credential", valid_773926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773928: Call_ListTagsForResource_773916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an AWS Device Farm resource.
  ## 
  let valid = call_773928.validator(path, query, header, formData, body)
  let scheme = call_773928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773928.url(scheme.get, call_773928.host, call_773928.base,
                         call_773928.route, valid.getOrDefault("path"))
  result = hook(call_773928, url, valid)

proc call*(call_773929: Call_ListTagsForResource_773916; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an AWS Device Farm resource.
  ##   body: JObject (required)
  var body_773930 = newJObject()
  if body != nil:
    body_773930 = body
  result = call_773929.call(nil, nil, nil, nil, body_773930)

var listTagsForResource* = Call_ListTagsForResource_773916(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListTagsForResource",
    validator: validate_ListTagsForResource_773917, base: "/",
    url: url_ListTagsForResource_773918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTests_773931 = ref object of OpenApiRestCall_772598
proc url_ListTests_773933(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTests_773932(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773934 = query.getOrDefault("nextToken")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "nextToken", valid_773934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773935 = header.getOrDefault("X-Amz-Date")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Date", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Security-Token")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Security-Token", valid_773936
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773937 = header.getOrDefault("X-Amz-Target")
  valid_773937 = validateParameter(valid_773937, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListTests"))
  if valid_773937 != nil:
    section.add "X-Amz-Target", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Content-Sha256", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Algorithm")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Algorithm", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Signature")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Signature", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-SignedHeaders", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Credential")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Credential", valid_773942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773944: Call_ListTests_773931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about tests in a given test suite.
  ## 
  let valid = call_773944.validator(path, query, header, formData, body)
  let scheme = call_773944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773944.url(scheme.get, call_773944.host, call_773944.base,
                         call_773944.route, valid.getOrDefault("path"))
  result = hook(call_773944, url, valid)

proc call*(call_773945: Call_ListTests_773931; body: JsonNode; nextToken: string = ""): Recallable =
  ## listTests
  ## Gets information about tests in a given test suite.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773946 = newJObject()
  var body_773947 = newJObject()
  add(query_773946, "nextToken", newJString(nextToken))
  if body != nil:
    body_773947 = body
  result = call_773945.call(nil, query_773946, nil, nil, body_773947)

var listTests* = Call_ListTests_773931(name: "listTests", meth: HttpMethod.HttpPost,
                                    host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListTests",
                                    validator: validate_ListTests_773932,
                                    base: "/", url: url_ListTests_773933,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUniqueProblems_773948 = ref object of OpenApiRestCall_772598
proc url_ListUniqueProblems_773950(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUniqueProblems_773949(path: JsonNode; query: JsonNode;
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
  var valid_773951 = query.getOrDefault("nextToken")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "nextToken", valid_773951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773952 = header.getOrDefault("X-Amz-Date")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Date", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-Security-Token")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Security-Token", valid_773953
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773954 = header.getOrDefault("X-Amz-Target")
  valid_773954 = validateParameter(valid_773954, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUniqueProblems"))
  if valid_773954 != nil:
    section.add "X-Amz-Target", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Content-Sha256", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Algorithm")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Algorithm", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Signature")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Signature", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-SignedHeaders", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Credential")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Credential", valid_773959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773961: Call_ListUniqueProblems_773948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about unique problems.
  ## 
  let valid = call_773961.validator(path, query, header, formData, body)
  let scheme = call_773961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773961.url(scheme.get, call_773961.host, call_773961.base,
                         call_773961.route, valid.getOrDefault("path"))
  result = hook(call_773961, url, valid)

proc call*(call_773962: Call_ListUniqueProblems_773948; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUniqueProblems
  ## Gets information about unique problems.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773963 = newJObject()
  var body_773964 = newJObject()
  add(query_773963, "nextToken", newJString(nextToken))
  if body != nil:
    body_773964 = body
  result = call_773962.call(nil, query_773963, nil, nil, body_773964)

var listUniqueProblems* = Call_ListUniqueProblems_773948(
    name: "listUniqueProblems", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListUniqueProblems",
    validator: validate_ListUniqueProblems_773949, base: "/",
    url: url_ListUniqueProblems_773950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUploads_773965 = ref object of OpenApiRestCall_772598
proc url_ListUploads_773967(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUploads_773966(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773968 = query.getOrDefault("nextToken")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "nextToken", valid_773968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773969 = header.getOrDefault("X-Amz-Date")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Date", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-Security-Token")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-Security-Token", valid_773970
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773971 = header.getOrDefault("X-Amz-Target")
  valid_773971 = validateParameter(valid_773971, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListUploads"))
  if valid_773971 != nil:
    section.add "X-Amz-Target", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-Content-Sha256", valid_773972
  var valid_773973 = header.getOrDefault("X-Amz-Algorithm")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "X-Amz-Algorithm", valid_773973
  var valid_773974 = header.getOrDefault("X-Amz-Signature")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-Signature", valid_773974
  var valid_773975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-SignedHeaders", valid_773975
  var valid_773976 = header.getOrDefault("X-Amz-Credential")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "X-Amz-Credential", valid_773976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773978: Call_ListUploads_773965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ## 
  let valid = call_773978.validator(path, query, header, formData, body)
  let scheme = call_773978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773978.url(scheme.get, call_773978.host, call_773978.base,
                         call_773978.route, valid.getOrDefault("path"))
  result = hook(call_773978, url, valid)

proc call*(call_773979: Call_ListUploads_773965; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listUploads
  ## Gets information about uploads, given an AWS Device Farm project ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773980 = newJObject()
  var body_773981 = newJObject()
  add(query_773980, "nextToken", newJString(nextToken))
  if body != nil:
    body_773981 = body
  result = call_773979.call(nil, query_773980, nil, nil, body_773981)

var listUploads* = Call_ListUploads_773965(name: "listUploads",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ListUploads",
                                        validator: validate_ListUploads_773966,
                                        base: "/", url: url_ListUploads_773967,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCEConfigurations_773982 = ref object of OpenApiRestCall_772598
proc url_ListVPCEConfigurations_773984(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListVPCEConfigurations_773983(path: JsonNode; query: JsonNode;
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
  var valid_773985 = header.getOrDefault("X-Amz-Date")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Date", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Security-Token")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Security-Token", valid_773986
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773987 = header.getOrDefault("X-Amz-Target")
  valid_773987 = validateParameter(valid_773987, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ListVPCEConfigurations"))
  if valid_773987 != nil:
    section.add "X-Amz-Target", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Content-Sha256", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Algorithm")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Algorithm", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Signature")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Signature", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-SignedHeaders", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Credential")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Credential", valid_773992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773994: Call_ListVPCEConfigurations_773982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ## 
  let valid = call_773994.validator(path, query, header, formData, body)
  let scheme = call_773994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773994.url(scheme.get, call_773994.host, call_773994.base,
                         call_773994.route, valid.getOrDefault("path"))
  result = hook(call_773994, url, valid)

proc call*(call_773995: Call_ListVPCEConfigurations_773982; body: JsonNode): Recallable =
  ## listVPCEConfigurations
  ## Returns information about all Amazon Virtual Private Cloud (VPC) endpoint configurations in the AWS account.
  ##   body: JObject (required)
  var body_773996 = newJObject()
  if body != nil:
    body_773996 = body
  result = call_773995.call(nil, nil, nil, nil, body_773996)

var listVPCEConfigurations* = Call_ListVPCEConfigurations_773982(
    name: "listVPCEConfigurations", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.ListVPCEConfigurations",
    validator: validate_ListVPCEConfigurations_773983, base: "/",
    url: url_ListVPCEConfigurations_773984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_773997 = ref object of OpenApiRestCall_772598
proc url_PurchaseOffering_773999(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PurchaseOffering_773998(path: JsonNode; query: JsonNode;
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
  var valid_774000 = header.getOrDefault("X-Amz-Date")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Date", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Security-Token")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Security-Token", valid_774001
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774002 = header.getOrDefault("X-Amz-Target")
  valid_774002 = validateParameter(valid_774002, JString, required = true, default = newJString(
      "DeviceFarm_20150623.PurchaseOffering"))
  if valid_774002 != nil:
    section.add "X-Amz-Target", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Content-Sha256", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Algorithm")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Algorithm", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Signature")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Signature", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-SignedHeaders", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Credential")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Credential", valid_774007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774009: Call_PurchaseOffering_773997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_774009.validator(path, query, header, formData, body)
  let scheme = call_774009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774009.url(scheme.get, call_774009.host, call_774009.base,
                         call_774009.route, valid.getOrDefault("path"))
  result = hook(call_774009, url, valid)

proc call*(call_774010: Call_PurchaseOffering_773997; body: JsonNode): Recallable =
  ## purchaseOffering
  ## Immediately purchases offerings for an AWS account. Offerings renew with the latest total purchased quantity for an offering, unless the renewal was overridden. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_774011 = newJObject()
  if body != nil:
    body_774011 = body
  result = call_774010.call(nil, nil, nil, nil, body_774011)

var purchaseOffering* = Call_PurchaseOffering_773997(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.PurchaseOffering",
    validator: validate_PurchaseOffering_773998, base: "/",
    url: url_PurchaseOffering_773999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewOffering_774012 = ref object of OpenApiRestCall_772598
proc url_RenewOffering_774014(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RenewOffering_774013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774015 = header.getOrDefault("X-Amz-Date")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Date", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-Security-Token")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Security-Token", valid_774016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774017 = header.getOrDefault("X-Amz-Target")
  valid_774017 = validateParameter(valid_774017, JString, required = true, default = newJString(
      "DeviceFarm_20150623.RenewOffering"))
  if valid_774017 != nil:
    section.add "X-Amz-Target", valid_774017
  var valid_774018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "X-Amz-Content-Sha256", valid_774018
  var valid_774019 = header.getOrDefault("X-Amz-Algorithm")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "X-Amz-Algorithm", valid_774019
  var valid_774020 = header.getOrDefault("X-Amz-Signature")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-Signature", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-SignedHeaders", valid_774021
  var valid_774022 = header.getOrDefault("X-Amz-Credential")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Credential", valid_774022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774024: Call_RenewOffering_774012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ## 
  let valid = call_774024.validator(path, query, header, formData, body)
  let scheme = call_774024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774024.url(scheme.get, call_774024.host, call_774024.base,
                         call_774024.route, valid.getOrDefault("path"))
  result = hook(call_774024, url, valid)

proc call*(call_774025: Call_RenewOffering_774012; body: JsonNode): Recallable =
  ## renewOffering
  ## Explicitly sets the quantity of devices to renew for an offering, starting from the <code>effectiveDate</code> of the next period. The API returns a <code>NotEligible</code> error if the user is not permitted to invoke the operation. Please contact <a href="mailto:aws-devicefarm-support@amazon.com">aws-devicefarm-support@amazon.com</a> if you believe that you should be able to invoke this operation.
  ##   body: JObject (required)
  var body_774026 = newJObject()
  if body != nil:
    body_774026 = body
  result = call_774025.call(nil, nil, nil, nil, body_774026)

var renewOffering* = Call_RenewOffering_774012(name: "renewOffering",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.RenewOffering",
    validator: validate_RenewOffering_774013, base: "/", url: url_RenewOffering_774014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleRun_774027 = ref object of OpenApiRestCall_772598
proc url_ScheduleRun_774029(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ScheduleRun_774028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774030 = header.getOrDefault("X-Amz-Date")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Date", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Security-Token")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Security-Token", valid_774031
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774032 = header.getOrDefault("X-Amz-Target")
  valid_774032 = validateParameter(valid_774032, JString, required = true, default = newJString(
      "DeviceFarm_20150623.ScheduleRun"))
  if valid_774032 != nil:
    section.add "X-Amz-Target", valid_774032
  var valid_774033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "X-Amz-Content-Sha256", valid_774033
  var valid_774034 = header.getOrDefault("X-Amz-Algorithm")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Algorithm", valid_774034
  var valid_774035 = header.getOrDefault("X-Amz-Signature")
  valid_774035 = validateParameter(valid_774035, JString, required = false,
                                 default = nil)
  if valid_774035 != nil:
    section.add "X-Amz-Signature", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-SignedHeaders", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Credential")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Credential", valid_774037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774039: Call_ScheduleRun_774027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Schedules a run.
  ## 
  let valid = call_774039.validator(path, query, header, formData, body)
  let scheme = call_774039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774039.url(scheme.get, call_774039.host, call_774039.base,
                         call_774039.route, valid.getOrDefault("path"))
  result = hook(call_774039, url, valid)

proc call*(call_774040: Call_ScheduleRun_774027; body: JsonNode): Recallable =
  ## scheduleRun
  ## Schedules a run.
  ##   body: JObject (required)
  var body_774041 = newJObject()
  if body != nil:
    body_774041 = body
  result = call_774040.call(nil, nil, nil, nil, body_774041)

var scheduleRun* = Call_ScheduleRun_774027(name: "scheduleRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.ScheduleRun",
                                        validator: validate_ScheduleRun_774028,
                                        base: "/", url: url_ScheduleRun_774029,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_774042 = ref object of OpenApiRestCall_772598
proc url_StopJob_774044(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopJob_774043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774045 = header.getOrDefault("X-Amz-Date")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Date", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Security-Token")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Security-Token", valid_774046
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774047 = header.getOrDefault("X-Amz-Target")
  valid_774047 = validateParameter(valid_774047, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopJob"))
  if valid_774047 != nil:
    section.add "X-Amz-Target", valid_774047
  var valid_774048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "X-Amz-Content-Sha256", valid_774048
  var valid_774049 = header.getOrDefault("X-Amz-Algorithm")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Algorithm", valid_774049
  var valid_774050 = header.getOrDefault("X-Amz-Signature")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-Signature", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-SignedHeaders", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Credential")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Credential", valid_774052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774054: Call_StopJob_774042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_774054.validator(path, query, header, formData, body)
  let scheme = call_774054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774054.url(scheme.get, call_774054.host, call_774054.base,
                         call_774054.route, valid.getOrDefault("path"))
  result = hook(call_774054, url, valid)

proc call*(call_774055: Call_StopJob_774042; body: JsonNode): Recallable =
  ## stopJob
  ## Initiates a stop request for the current job. AWS Device Farm will immediately stop the job on the device where tests have not started executing, and you will not be billed for this device. On the device where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on the device. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_774056 = newJObject()
  if body != nil:
    body_774056 = body
  result = call_774055.call(nil, nil, nil, nil, body_774056)

var stopJob* = Call_StopJob_774042(name: "stopJob", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopJob",
                                validator: validate_StopJob_774043, base: "/",
                                url: url_StopJob_774044,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRemoteAccessSession_774057 = ref object of OpenApiRestCall_772598
proc url_StopRemoteAccessSession_774059(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopRemoteAccessSession_774058(path: JsonNode; query: JsonNode;
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
  var valid_774060 = header.getOrDefault("X-Amz-Date")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "X-Amz-Date", valid_774060
  var valid_774061 = header.getOrDefault("X-Amz-Security-Token")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Security-Token", valid_774061
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774062 = header.getOrDefault("X-Amz-Target")
  valid_774062 = validateParameter(valid_774062, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRemoteAccessSession"))
  if valid_774062 != nil:
    section.add "X-Amz-Target", valid_774062
  var valid_774063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "X-Amz-Content-Sha256", valid_774063
  var valid_774064 = header.getOrDefault("X-Amz-Algorithm")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Algorithm", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Signature")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Signature", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-SignedHeaders", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Credential")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Credential", valid_774067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774069: Call_StopRemoteAccessSession_774057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends a specified remote access session.
  ## 
  let valid = call_774069.validator(path, query, header, formData, body)
  let scheme = call_774069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774069.url(scheme.get, call_774069.host, call_774069.base,
                         call_774069.route, valid.getOrDefault("path"))
  result = hook(call_774069, url, valid)

proc call*(call_774070: Call_StopRemoteAccessSession_774057; body: JsonNode): Recallable =
  ## stopRemoteAccessSession
  ## Ends a specified remote access session.
  ##   body: JObject (required)
  var body_774071 = newJObject()
  if body != nil:
    body_774071 = body
  result = call_774070.call(nil, nil, nil, nil, body_774071)

var stopRemoteAccessSession* = Call_StopRemoteAccessSession_774057(
    name: "stopRemoteAccessSession", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.StopRemoteAccessSession",
    validator: validate_StopRemoteAccessSession_774058, base: "/",
    url: url_StopRemoteAccessSession_774059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRun_774072 = ref object of OpenApiRestCall_772598
proc url_StopRun_774074(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopRun_774073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774075 = header.getOrDefault("X-Amz-Date")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Date", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Security-Token")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Security-Token", valid_774076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774077 = header.getOrDefault("X-Amz-Target")
  valid_774077 = validateParameter(valid_774077, JString, required = true, default = newJString(
      "DeviceFarm_20150623.StopRun"))
  if valid_774077 != nil:
    section.add "X-Amz-Target", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Content-Sha256", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Algorithm")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Algorithm", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Signature")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Signature", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-SignedHeaders", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Credential")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Credential", valid_774082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774084: Call_StopRun_774072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ## 
  let valid = call_774084.validator(path, query, header, formData, body)
  let scheme = call_774084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774084.url(scheme.get, call_774084.host, call_774084.base,
                         call_774084.route, valid.getOrDefault("path"))
  result = hook(call_774084, url, valid)

proc call*(call_774085: Call_StopRun_774072; body: JsonNode): Recallable =
  ## stopRun
  ## Initiates a stop request for the current test run. AWS Device Farm will immediately stop the run on devices where tests have not started executing, and you will not be billed for these devices. On devices where tests have started executing, Setup Suite and Teardown Suite tests will run to completion before stopping execution on those devices. You will be billed for Setup, Teardown, and any tests that were in progress or already completed.
  ##   body: JObject (required)
  var body_774086 = newJObject()
  if body != nil:
    body_774086 = body
  result = call_774085.call(nil, nil, nil, nil, body_774086)

var stopRun* = Call_StopRun_774072(name: "stopRun", meth: HttpMethod.HttpPost,
                                host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.StopRun",
                                validator: validate_StopRun_774073, base: "/",
                                url: url_StopRun_774074,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774087 = ref object of OpenApiRestCall_772598
proc url_TagResource_774089(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_774088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774090 = header.getOrDefault("X-Amz-Date")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Date", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-Security-Token")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Security-Token", valid_774091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774092 = header.getOrDefault("X-Amz-Target")
  valid_774092 = validateParameter(valid_774092, JString, required = true, default = newJString(
      "DeviceFarm_20150623.TagResource"))
  if valid_774092 != nil:
    section.add "X-Amz-Target", valid_774092
  var valid_774093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-Content-Sha256", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-Algorithm")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-Algorithm", valid_774094
  var valid_774095 = header.getOrDefault("X-Amz-Signature")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "X-Amz-Signature", valid_774095
  var valid_774096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "X-Amz-SignedHeaders", valid_774096
  var valid_774097 = header.getOrDefault("X-Amz-Credential")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Credential", valid_774097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774099: Call_TagResource_774087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_774099.validator(path, query, header, formData, body)
  let scheme = call_774099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774099.url(scheme.get, call_774099.host, call_774099.base,
                         call_774099.route, valid.getOrDefault("path"))
  result = hook(call_774099, url, valid)

proc call*(call_774100: Call_TagResource_774087; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_774101 = newJObject()
  if body != nil:
    body_774101 = body
  result = call_774100.call(nil, nil, nil, nil, body_774101)

var tagResource* = Call_TagResource_774087(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "devicefarm.amazonaws.com", route: "/#X-Amz-Target=DeviceFarm_20150623.TagResource",
                                        validator: validate_TagResource_774088,
                                        base: "/", url: url_TagResource_774089,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774102 = ref object of OpenApiRestCall_772598
proc url_UntagResource_774104(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_774103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774105 = header.getOrDefault("X-Amz-Date")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Date", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-Security-Token")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-Security-Token", valid_774106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774107 = header.getOrDefault("X-Amz-Target")
  valid_774107 = validateParameter(valid_774107, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UntagResource"))
  if valid_774107 != nil:
    section.add "X-Amz-Target", valid_774107
  var valid_774108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "X-Amz-Content-Sha256", valid_774108
  var valid_774109 = header.getOrDefault("X-Amz-Algorithm")
  valid_774109 = validateParameter(valid_774109, JString, required = false,
                                 default = nil)
  if valid_774109 != nil:
    section.add "X-Amz-Algorithm", valid_774109
  var valid_774110 = header.getOrDefault("X-Amz-Signature")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "X-Amz-Signature", valid_774110
  var valid_774111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "X-Amz-SignedHeaders", valid_774111
  var valid_774112 = header.getOrDefault("X-Amz-Credential")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Credential", valid_774112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774114: Call_UntagResource_774102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from a resource.
  ## 
  let valid = call_774114.validator(path, query, header, formData, body)
  let scheme = call_774114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774114.url(scheme.get, call_774114.host, call_774114.base,
                         call_774114.route, valid.getOrDefault("path"))
  result = hook(call_774114, url, valid)

proc call*(call_774115: Call_UntagResource_774102; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes the specified tags from a resource.
  ##   body: JObject (required)
  var body_774116 = newJObject()
  if body != nil:
    body_774116 = body
  result = call_774115.call(nil, nil, nil, nil, body_774116)

var untagResource* = Call_UntagResource_774102(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UntagResource",
    validator: validate_UntagResource_774103, base: "/", url: url_UntagResource_774104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceInstance_774117 = ref object of OpenApiRestCall_772598
proc url_UpdateDeviceInstance_774119(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDeviceInstance_774118(path: JsonNode; query: JsonNode;
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
  var valid_774120 = header.getOrDefault("X-Amz-Date")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Date", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Security-Token")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Security-Token", valid_774121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774122 = header.getOrDefault("X-Amz-Target")
  valid_774122 = validateParameter(valid_774122, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDeviceInstance"))
  if valid_774122 != nil:
    section.add "X-Amz-Target", valid_774122
  var valid_774123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774123 = validateParameter(valid_774123, JString, required = false,
                                 default = nil)
  if valid_774123 != nil:
    section.add "X-Amz-Content-Sha256", valid_774123
  var valid_774124 = header.getOrDefault("X-Amz-Algorithm")
  valid_774124 = validateParameter(valid_774124, JString, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "X-Amz-Algorithm", valid_774124
  var valid_774125 = header.getOrDefault("X-Amz-Signature")
  valid_774125 = validateParameter(valid_774125, JString, required = false,
                                 default = nil)
  if valid_774125 != nil:
    section.add "X-Amz-Signature", valid_774125
  var valid_774126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774126 = validateParameter(valid_774126, JString, required = false,
                                 default = nil)
  if valid_774126 != nil:
    section.add "X-Amz-SignedHeaders", valid_774126
  var valid_774127 = header.getOrDefault("X-Amz-Credential")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-Credential", valid_774127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774129: Call_UpdateDeviceInstance_774117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance.
  ## 
  let valid = call_774129.validator(path, query, header, formData, body)
  let scheme = call_774129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774129.url(scheme.get, call_774129.host, call_774129.base,
                         call_774129.route, valid.getOrDefault("path"))
  result = hook(call_774129, url, valid)

proc call*(call_774130: Call_UpdateDeviceInstance_774117; body: JsonNode): Recallable =
  ## updateDeviceInstance
  ## Updates information about an existing private device instance.
  ##   body: JObject (required)
  var body_774131 = newJObject()
  if body != nil:
    body_774131 = body
  result = call_774130.call(nil, nil, nil, nil, body_774131)

var updateDeviceInstance* = Call_UpdateDeviceInstance_774117(
    name: "updateDeviceInstance", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDeviceInstance",
    validator: validate_UpdateDeviceInstance_774118, base: "/",
    url: url_UpdateDeviceInstance_774119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevicePool_774132 = ref object of OpenApiRestCall_772598
proc url_UpdateDevicePool_774134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDevicePool_774133(path: JsonNode; query: JsonNode;
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
  var valid_774135 = header.getOrDefault("X-Amz-Date")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Date", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Security-Token")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Security-Token", valid_774136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774137 = header.getOrDefault("X-Amz-Target")
  valid_774137 = validateParameter(valid_774137, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateDevicePool"))
  if valid_774137 != nil:
    section.add "X-Amz-Target", valid_774137
  var valid_774138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "X-Amz-Content-Sha256", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-Algorithm")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-Algorithm", valid_774139
  var valid_774140 = header.getOrDefault("X-Amz-Signature")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Signature", valid_774140
  var valid_774141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774141 = validateParameter(valid_774141, JString, required = false,
                                 default = nil)
  if valid_774141 != nil:
    section.add "X-Amz-SignedHeaders", valid_774141
  var valid_774142 = header.getOrDefault("X-Amz-Credential")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "X-Amz-Credential", valid_774142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774144: Call_UpdateDevicePool_774132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ## 
  let valid = call_774144.validator(path, query, header, formData, body)
  let scheme = call_774144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774144.url(scheme.get, call_774144.host, call_774144.base,
                         call_774144.route, valid.getOrDefault("path"))
  result = hook(call_774144, url, valid)

proc call*(call_774145: Call_UpdateDevicePool_774132; body: JsonNode): Recallable =
  ## updateDevicePool
  ## Modifies the name, description, and rules in a device pool given the attributes and the pool ARN. Rule updates are all-or-nothing, meaning they can only be updated as a whole (or not at all).
  ##   body: JObject (required)
  var body_774146 = newJObject()
  if body != nil:
    body_774146 = body
  result = call_774145.call(nil, nil, nil, nil, body_774146)

var updateDevicePool* = Call_UpdateDevicePool_774132(name: "updateDevicePool",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateDevicePool",
    validator: validate_UpdateDevicePool_774133, base: "/",
    url: url_UpdateDevicePool_774134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceProfile_774147 = ref object of OpenApiRestCall_772598
proc url_UpdateInstanceProfile_774149(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateInstanceProfile_774148(path: JsonNode; query: JsonNode;
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
  var valid_774150 = header.getOrDefault("X-Amz-Date")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Date", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Security-Token")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Security-Token", valid_774151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774152 = header.getOrDefault("X-Amz-Target")
  valid_774152 = validateParameter(valid_774152, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateInstanceProfile"))
  if valid_774152 != nil:
    section.add "X-Amz-Target", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Content-Sha256", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-Algorithm")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-Algorithm", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Signature")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Signature", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-SignedHeaders", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-Credential")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Credential", valid_774157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774159: Call_UpdateInstanceProfile_774147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing private device instance profile.
  ## 
  let valid = call_774159.validator(path, query, header, formData, body)
  let scheme = call_774159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774159.url(scheme.get, call_774159.host, call_774159.base,
                         call_774159.route, valid.getOrDefault("path"))
  result = hook(call_774159, url, valid)

proc call*(call_774160: Call_UpdateInstanceProfile_774147; body: JsonNode): Recallable =
  ## updateInstanceProfile
  ## Updates information about an existing private device instance profile.
  ##   body: JObject (required)
  var body_774161 = newJObject()
  if body != nil:
    body_774161 = body
  result = call_774160.call(nil, nil, nil, nil, body_774161)

var updateInstanceProfile* = Call_UpdateInstanceProfile_774147(
    name: "updateInstanceProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateInstanceProfile",
    validator: validate_UpdateInstanceProfile_774148, base: "/",
    url: url_UpdateInstanceProfile_774149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_774162 = ref object of OpenApiRestCall_772598
proc url_UpdateNetworkProfile_774164(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateNetworkProfile_774163(path: JsonNode; query: JsonNode;
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
  var valid_774165 = header.getOrDefault("X-Amz-Date")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Date", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Security-Token")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Security-Token", valid_774166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774167 = header.getOrDefault("X-Amz-Target")
  valid_774167 = validateParameter(valid_774167, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateNetworkProfile"))
  if valid_774167 != nil:
    section.add "X-Amz-Target", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Content-Sha256", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Algorithm")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Algorithm", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Signature")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Signature", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-SignedHeaders", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Credential")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Credential", valid_774172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774174: Call_UpdateNetworkProfile_774162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the network profile with specific settings.
  ## 
  let valid = call_774174.validator(path, query, header, formData, body)
  let scheme = call_774174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774174.url(scheme.get, call_774174.host, call_774174.base,
                         call_774174.route, valid.getOrDefault("path"))
  result = hook(call_774174, url, valid)

proc call*(call_774175: Call_UpdateNetworkProfile_774162; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates the network profile with specific settings.
  ##   body: JObject (required)
  var body_774176 = newJObject()
  if body != nil:
    body_774176 = body
  result = call_774175.call(nil, nil, nil, nil, body_774176)

var updateNetworkProfile* = Call_UpdateNetworkProfile_774162(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_774163, base: "/",
    url: url_UpdateNetworkProfile_774164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_774177 = ref object of OpenApiRestCall_772598
proc url_UpdateProject_774179(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProject_774178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774180 = header.getOrDefault("X-Amz-Date")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Date", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-Security-Token")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Security-Token", valid_774181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774182 = header.getOrDefault("X-Amz-Target")
  valid_774182 = validateParameter(valid_774182, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateProject"))
  if valid_774182 != nil:
    section.add "X-Amz-Target", valid_774182
  var valid_774183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-Content-Sha256", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Algorithm")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Algorithm", valid_774184
  var valid_774185 = header.getOrDefault("X-Amz-Signature")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "X-Amz-Signature", valid_774185
  var valid_774186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-SignedHeaders", valid_774186
  var valid_774187 = header.getOrDefault("X-Amz-Credential")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Credential", valid_774187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774189: Call_UpdateProject_774177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified project name, given the project ARN and a new name.
  ## 
  let valid = call_774189.validator(path, query, header, formData, body)
  let scheme = call_774189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774189.url(scheme.get, call_774189.host, call_774189.base,
                         call_774189.route, valid.getOrDefault("path"))
  result = hook(call_774189, url, valid)

proc call*(call_774190: Call_UpdateProject_774177; body: JsonNode): Recallable =
  ## updateProject
  ## Modifies the specified project name, given the project ARN and a new name.
  ##   body: JObject (required)
  var body_774191 = newJObject()
  if body != nil:
    body_774191 = body
  result = call_774190.call(nil, nil, nil, nil, body_774191)

var updateProject* = Call_UpdateProject_774177(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateProject",
    validator: validate_UpdateProject_774178, base: "/", url: url_UpdateProject_774179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUpload_774192 = ref object of OpenApiRestCall_772598
proc url_UpdateUpload_774194(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUpload_774193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774195 = header.getOrDefault("X-Amz-Date")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Date", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-Security-Token")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Security-Token", valid_774196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774197 = header.getOrDefault("X-Amz-Target")
  valid_774197 = validateParameter(valid_774197, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateUpload"))
  if valid_774197 != nil:
    section.add "X-Amz-Target", valid_774197
  var valid_774198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774198 = validateParameter(valid_774198, JString, required = false,
                                 default = nil)
  if valid_774198 != nil:
    section.add "X-Amz-Content-Sha256", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-Algorithm")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Algorithm", valid_774199
  var valid_774200 = header.getOrDefault("X-Amz-Signature")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "X-Amz-Signature", valid_774200
  var valid_774201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-SignedHeaders", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-Credential")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Credential", valid_774202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774204: Call_UpdateUpload_774192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an uploaded test specification (test spec).
  ## 
  let valid = call_774204.validator(path, query, header, formData, body)
  let scheme = call_774204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774204.url(scheme.get, call_774204.host, call_774204.base,
                         call_774204.route, valid.getOrDefault("path"))
  result = hook(call_774204, url, valid)

proc call*(call_774205: Call_UpdateUpload_774192; body: JsonNode): Recallable =
  ## updateUpload
  ## Update an uploaded test specification (test spec).
  ##   body: JObject (required)
  var body_774206 = newJObject()
  if body != nil:
    body_774206 = body
  result = call_774205.call(nil, nil, nil, nil, body_774206)

var updateUpload* = Call_UpdateUpload_774192(name: "updateUpload",
    meth: HttpMethod.HttpPost, host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateUpload",
    validator: validate_UpdateUpload_774193, base: "/", url: url_UpdateUpload_774194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVPCEConfiguration_774207 = ref object of OpenApiRestCall_772598
proc url_UpdateVPCEConfiguration_774209(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateVPCEConfiguration_774208(path: JsonNode; query: JsonNode;
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
  var valid_774210 = header.getOrDefault("X-Amz-Date")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Date", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-Security-Token")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Security-Token", valid_774211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774212 = header.getOrDefault("X-Amz-Target")
  valid_774212 = validateParameter(valid_774212, JString, required = true, default = newJString(
      "DeviceFarm_20150623.UpdateVPCEConfiguration"))
  if valid_774212 != nil:
    section.add "X-Amz-Target", valid_774212
  var valid_774213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "X-Amz-Content-Sha256", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-Algorithm")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-Algorithm", valid_774214
  var valid_774215 = header.getOrDefault("X-Amz-Signature")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Signature", valid_774215
  var valid_774216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "X-Amz-SignedHeaders", valid_774216
  var valid_774217 = header.getOrDefault("X-Amz-Credential")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-Credential", valid_774217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774219: Call_UpdateVPCEConfiguration_774207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ## 
  let valid = call_774219.validator(path, query, header, formData, body)
  let scheme = call_774219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774219.url(scheme.get, call_774219.host, call_774219.base,
                         call_774219.route, valid.getOrDefault("path"))
  result = hook(call_774219, url, valid)

proc call*(call_774220: Call_UpdateVPCEConfiguration_774207; body: JsonNode): Recallable =
  ## updateVPCEConfiguration
  ## Updates information about an existing Amazon Virtual Private Cloud (VPC) endpoint configuration.
  ##   body: JObject (required)
  var body_774221 = newJObject()
  if body != nil:
    body_774221 = body
  result = call_774220.call(nil, nil, nil, nil, body_774221)

var updateVPCEConfiguration* = Call_UpdateVPCEConfiguration_774207(
    name: "updateVPCEConfiguration", meth: HttpMethod.HttpPost,
    host: "devicefarm.amazonaws.com",
    route: "/#X-Amz-Target=DeviceFarm_20150623.UpdateVPCEConfiguration",
    validator: validate_UpdateVPCEConfiguration_774208, base: "/",
    url: url_UpdateVPCEConfiguration_774209, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
