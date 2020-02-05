
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT 1-Click Devices Service
## version: 2018-05-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Describes all of the AWS IoT 1-Click device-related API operations for the service.
##  Also provides sample requests, responses, and errors for the supported web services
##  protocols.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iot1click/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "devices.iot1click.ap-northeast-1.amazonaws.com", "ap-southeast-1": "devices.iot1click.ap-southeast-1.amazonaws.com", "us-west-2": "devices.iot1click.us-west-2.amazonaws.com", "eu-west-2": "devices.iot1click.eu-west-2.amazonaws.com", "ap-northeast-3": "devices.iot1click.ap-northeast-3.amazonaws.com", "eu-central-1": "devices.iot1click.eu-central-1.amazonaws.com", "us-east-2": "devices.iot1click.us-east-2.amazonaws.com", "us-east-1": "devices.iot1click.us-east-1.amazonaws.com", "cn-northwest-1": "devices.iot1click.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "devices.iot1click.ap-south-1.amazonaws.com", "eu-north-1": "devices.iot1click.eu-north-1.amazonaws.com", "ap-northeast-2": "devices.iot1click.ap-northeast-2.amazonaws.com", "us-west-1": "devices.iot1click.us-west-1.amazonaws.com", "us-gov-east-1": "devices.iot1click.us-gov-east-1.amazonaws.com", "eu-west-3": "devices.iot1click.eu-west-3.amazonaws.com", "cn-north-1": "devices.iot1click.cn-north-1.amazonaws.com.cn", "sa-east-1": "devices.iot1click.sa-east-1.amazonaws.com", "eu-west-1": "devices.iot1click.eu-west-1.amazonaws.com", "us-gov-west-1": "devices.iot1click.us-gov-west-1.amazonaws.com", "ap-southeast-2": "devices.iot1click.ap-southeast-2.amazonaws.com", "ca-central-1": "devices.iot1click.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "devices.iot1click.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "devices.iot1click.ap-southeast-1.amazonaws.com",
      "us-west-2": "devices.iot1click.us-west-2.amazonaws.com",
      "eu-west-2": "devices.iot1click.eu-west-2.amazonaws.com",
      "ap-northeast-3": "devices.iot1click.ap-northeast-3.amazonaws.com",
      "eu-central-1": "devices.iot1click.eu-central-1.amazonaws.com",
      "us-east-2": "devices.iot1click.us-east-2.amazonaws.com",
      "us-east-1": "devices.iot1click.us-east-1.amazonaws.com",
      "cn-northwest-1": "devices.iot1click.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "devices.iot1click.ap-south-1.amazonaws.com",
      "eu-north-1": "devices.iot1click.eu-north-1.amazonaws.com",
      "ap-northeast-2": "devices.iot1click.ap-northeast-2.amazonaws.com",
      "us-west-1": "devices.iot1click.us-west-1.amazonaws.com",
      "us-gov-east-1": "devices.iot1click.us-gov-east-1.amazonaws.com",
      "eu-west-3": "devices.iot1click.eu-west-3.amazonaws.com",
      "cn-north-1": "devices.iot1click.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "devices.iot1click.sa-east-1.amazonaws.com",
      "eu-west-1": "devices.iot1click.eu-west-1.amazonaws.com",
      "us-gov-west-1": "devices.iot1click.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "devices.iot1click.ap-southeast-2.amazonaws.com",
      "ca-central-1": "devices.iot1click.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iot1click-devices"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ClaimDevicesByClaimCode_612996 = ref object of OpenApiRestCall_612658
proc url_ClaimDevicesByClaimCode_612998(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "claimCode" in path, "`claimCode` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/claims/"),
               (kind: VariableSegment, value: "claimCode")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ClaimDevicesByClaimCode_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   claimCode: JString (required)
  ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `claimCode` field"
  var valid_613124 = path.getOrDefault("claimCode")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "claimCode", valid_613124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_ClaimDevicesByClaimCode_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_ClaimDevicesByClaimCode_612996; claimCode: string): Recallable =
  ## claimDevicesByClaimCode
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ##   claimCode: string (required)
  ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  var path_613226 = newJObject()
  add(path_613226, "claimCode", newJString(claimCode))
  result = call_613225.call(path_613226, nil, nil, nil, nil)

var claimDevicesByClaimCode* = Call_ClaimDevicesByClaimCode_612996(
    name: "claimDevicesByClaimCode", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/claims/{claimCode}",
    validator: validate_ClaimDevicesByClaimCode_612997, base: "/",
    url: url_ClaimDevicesByClaimCode_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_613266 = ref object of OpenApiRestCall_612658
proc url_DescribeDevice_613268(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDevice_613267(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613269 = path.getOrDefault("deviceId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "deviceId", valid_613269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_DescribeDevice_613266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_DescribeDevice_613266; deviceId: string): Recallable =
  ## describeDevice
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613279 = newJObject()
  add(path_613279, "deviceId", newJString(deviceId))
  result = call_613278.call(path_613279, nil, nil, nil, nil)

var describeDevice* = Call_DescribeDevice_613266(name: "describeDevice",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}", validator: validate_DescribeDevice_613267,
    base: "/", url: url_DescribeDevice_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FinalizeDeviceClaim_613280 = ref object of OpenApiRestCall_612658
proc url_FinalizeDeviceClaim_613282(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/finalize-claim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FinalizeDeviceClaim_613281(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613283 = path.getOrDefault("deviceId")
  valid_613283 = validateParameter(valid_613283, JString, required = true,
                                 default = nil)
  if valid_613283 != nil:
    section.add "deviceId", valid_613283
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_FinalizeDeviceClaim_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_FinalizeDeviceClaim_613280; body: JsonNode;
          deviceId: string): Recallable =
  ## finalizeDeviceClaim
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613294 = newJObject()
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  add(path_613294, "deviceId", newJString(deviceId))
  result = call_613293.call(path_613294, nil, nil, nil, body_613295)

var finalizeDeviceClaim* = Call_FinalizeDeviceClaim_613280(
    name: "finalizeDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/finalize-claim",
    validator: validate_FinalizeDeviceClaim_613281, base: "/",
    url: url_FinalizeDeviceClaim_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeDeviceMethod_613310 = ref object of OpenApiRestCall_612658
proc url_InvokeDeviceMethod_613312(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/methods")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeDeviceMethod_613311(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613313 = path.getOrDefault("deviceId")
  valid_613313 = validateParameter(valid_613313, JString, required = true,
                                 default = nil)
  if valid_613313 != nil:
    section.add "deviceId", valid_613313
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_InvokeDeviceMethod_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_InvokeDeviceMethod_613310; body: JsonNode;
          deviceId: string): Recallable =
  ## invokeDeviceMethod
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613324 = newJObject()
  var body_613325 = newJObject()
  if body != nil:
    body_613325 = body
  add(path_613324, "deviceId", newJString(deviceId))
  result = call_613323.call(path_613324, nil, nil, nil, body_613325)

var invokeDeviceMethod* = Call_InvokeDeviceMethod_613310(
    name: "invokeDeviceMethod", meth: HttpMethod.HttpPost,
    host: "devices.iot1click.amazonaws.com", route: "/devices/{deviceId}/methods",
    validator: validate_InvokeDeviceMethod_613311, base: "/",
    url: url_InvokeDeviceMethod_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceMethods_613296 = ref object of OpenApiRestCall_612658
proc url_GetDeviceMethods_613298(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/methods")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceMethods_613297(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Given a device ID, returns the invokable methods associated with the device.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613299 = path.getOrDefault("deviceId")
  valid_613299 = validateParameter(valid_613299, JString, required = true,
                                 default = nil)
  if valid_613299 != nil:
    section.add "deviceId", valid_613299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_GetDeviceMethods_613296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns the invokable methods associated with the device.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_GetDeviceMethods_613296; deviceId: string): Recallable =
  ## getDeviceMethods
  ## Given a device ID, returns the invokable methods associated with the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613309 = newJObject()
  add(path_613309, "deviceId", newJString(deviceId))
  result = call_613308.call(path_613309, nil, nil, nil, nil)

var getDeviceMethods* = Call_GetDeviceMethods_613296(name: "getDeviceMethods",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods", validator: validate_GetDeviceMethods_613297,
    base: "/", url: url_GetDeviceMethods_613298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDeviceClaim_613326 = ref object of OpenApiRestCall_612658
proc url_InitiateDeviceClaim_613328(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/initiate-claim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InitiateDeviceClaim_613327(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613329 = path.getOrDefault("deviceId")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = nil)
  if valid_613329 != nil:
    section.add "deviceId", valid_613329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_InitiateDeviceClaim_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_InitiateDeviceClaim_613326; deviceId: string): Recallable =
  ## initiateDeviceClaim
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613339 = newJObject()
  add(path_613339, "deviceId", newJString(deviceId))
  result = call_613338.call(path_613339, nil, nil, nil, nil)

var initiateDeviceClaim* = Call_InitiateDeviceClaim_613326(
    name: "initiateDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/initiate-claim",
    validator: validate_InitiateDeviceClaim_613327, base: "/",
    url: url_InitiateDeviceClaim_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_613340 = ref object of OpenApiRestCall_612658
proc url_ListDeviceEvents_613342(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"), (kind: ConstantSegment,
        value: "/events#fromTimeStamp&toTimeStamp")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeviceEvents_613341(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613343 = path.getOrDefault("deviceId")
  valid_613343 = validateParameter(valid_613343, JString, required = true,
                                 default = nil)
  if valid_613343 != nil:
    section.add "deviceId", valid_613343
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   fromTimeStamp: JString (required)
  ##                : The start date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   toTimeStamp: JString (required)
  ##              : The end date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  section = newJObject()
  var valid_613344 = query.getOrDefault("nextToken")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "nextToken", valid_613344
  assert query != nil,
        "query argument is necessary due to required `fromTimeStamp` field"
  var valid_613345 = query.getOrDefault("fromTimeStamp")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = nil)
  if valid_613345 != nil:
    section.add "fromTimeStamp", valid_613345
  var valid_613346 = query.getOrDefault("toTimeStamp")
  valid_613346 = validateParameter(valid_613346, JString, required = true,
                                 default = nil)
  if valid_613346 != nil:
    section.add "toTimeStamp", valid_613346
  var valid_613347 = query.getOrDefault("maxResults")
  valid_613347 = validateParameter(valid_613347, JInt, required = false, default = nil)
  if valid_613347 != nil:
    section.add "maxResults", valid_613347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613348 = header.getOrDefault("X-Amz-Signature")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Signature", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Content-Sha256", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Date")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Date", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Credential")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Credential", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Security-Token")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Security-Token", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Algorithm")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Algorithm", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-SignedHeaders", valid_613354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613355: Call_ListDeviceEvents_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ## 
  let valid = call_613355.validator(path, query, header, formData, body)
  let scheme = call_613355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613355.url(scheme.get, call_613355.host, call_613355.base,
                         call_613355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613355, url, valid)

proc call*(call_613356: Call_ListDeviceEvents_613340; fromTimeStamp: string;
          toTimeStamp: string; deviceId: string; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDeviceEvents
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   fromTimeStamp: string (required)
  ##                : The start date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   toTimeStamp: string (required)
  ##              : The end date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  var path_613357 = newJObject()
  var query_613358 = newJObject()
  add(query_613358, "nextToken", newJString(nextToken))
  add(query_613358, "fromTimeStamp", newJString(fromTimeStamp))
  add(query_613358, "toTimeStamp", newJString(toTimeStamp))
  add(path_613357, "deviceId", newJString(deviceId))
  add(query_613358, "maxResults", newJInt(maxResults))
  result = call_613356.call(path_613357, query_613358, nil, nil, nil)

var listDeviceEvents* = Call_ListDeviceEvents_613340(name: "listDeviceEvents",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/events#fromTimeStamp&toTimeStamp",
    validator: validate_ListDeviceEvents_613341, base: "/",
    url: url_ListDeviceEvents_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_613359 = ref object of OpenApiRestCall_612658
proc url_ListDevices_613361(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_613360(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   deviceType: JString
  ##             : The type of the device, such as "button".
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  section = newJObject()
  var valid_613362 = query.getOrDefault("nextToken")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "nextToken", valid_613362
  var valid_613363 = query.getOrDefault("deviceType")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "deviceType", valid_613363
  var valid_613364 = query.getOrDefault("maxResults")
  valid_613364 = validateParameter(valid_613364, JInt, required = false, default = nil)
  if valid_613364 != nil:
    section.add "maxResults", valid_613364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613365 = header.getOrDefault("X-Amz-Signature")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Signature", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Content-Sha256", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Date")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Date", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Credential")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Credential", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Security-Token")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Security-Token", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Algorithm")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Algorithm", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-SignedHeaders", valid_613371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613372: Call_ListDevices_613359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  let valid = call_613372.validator(path, query, header, formData, body)
  let scheme = call_613372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613372.url(scheme.get, call_613372.host, call_613372.base,
                         call_613372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613372, url, valid)

proc call*(call_613373: Call_ListDevices_613359; nextToken: string = "";
          deviceType: string = ""; maxResults: int = 0): Recallable =
  ## listDevices
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   deviceType: string
  ##             : The type of the device, such as "button".
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  var query_613374 = newJObject()
  add(query_613374, "nextToken", newJString(nextToken))
  add(query_613374, "deviceType", newJString(deviceType))
  add(query_613374, "maxResults", newJInt(maxResults))
  result = call_613373.call(nil, query_613374, nil, nil, nil)

var listDevices* = Call_ListDevices_613359(name: "listDevices",
                                        meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
                                        route: "/devices",
                                        validator: validate_ListDevices_613360,
                                        base: "/", url: url_ListDevices_613361,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613389 = ref object of OpenApiRestCall_612658
proc url_TagResource_613391(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613390(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The ARN of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613392 = path.getOrDefault("resource-arn")
  valid_613392 = validateParameter(valid_613392, JString, required = true,
                                 default = nil)
  if valid_613392 != nil:
    section.add "resource-arn", valid_613392
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613393 = header.getOrDefault("X-Amz-Signature")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Signature", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Content-Sha256", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Date")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Date", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Credential")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Credential", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Security-Token")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Security-Token", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Algorithm")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Algorithm", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-SignedHeaders", valid_613399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613401: Call_TagResource_613389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ## 
  let valid = call_613401.validator(path, query, header, formData, body)
  let scheme = call_613401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613401.url(scheme.get, call_613401.host, call_613401.base,
                         call_613401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613401, url, valid)

proc call*(call_613402: Call_TagResource_613389; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var path_613403 = newJObject()
  var body_613404 = newJObject()
  add(path_613403, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_613404 = body
  result = call_613402.call(path_613403, nil, nil, nil, body_613404)

var tagResource* = Call_TagResource_613389(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "devices.iot1click.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_613390,
                                        base: "/", url: url_TagResource_613391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613375 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613377(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613376(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags associated with the specified resource ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The ARN of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613378 = path.getOrDefault("resource-arn")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "resource-arn", valid_613378
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613379 = header.getOrDefault("X-Amz-Signature")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Signature", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Content-Sha256", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Date")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Date", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Credential")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Credential", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Security-Token")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Security-Token", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Algorithm")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Algorithm", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-SignedHeaders", valid_613385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613386: Call_ListTagsForResource_613375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with the specified resource ARN.
  ## 
  let valid = call_613386.validator(path, query, header, formData, body)
  let scheme = call_613386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613386.url(scheme.get, call_613386.host, call_613386.base,
                         call_613386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613386, url, valid)

proc call*(call_613387: Call_ListTagsForResource_613375; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with the specified resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_613388 = newJObject()
  add(path_613388, "resource-arn", newJString(resourceArn))
  result = call_613387.call(path_613388, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613375(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_613376, base: "/",
    url: url_ListTagsForResource_613377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnclaimDevice_613405 = ref object of OpenApiRestCall_612658
proc url_UnclaimDevice_613407(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/unclaim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnclaimDevice_613406(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a device from your AWS account using its device ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613408 = path.getOrDefault("deviceId")
  valid_613408 = validateParameter(valid_613408, JString, required = true,
                                 default = nil)
  if valid_613408 != nil:
    section.add "deviceId", valid_613408
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613409 = header.getOrDefault("X-Amz-Signature")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Signature", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Content-Sha256", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Date")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Date", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Credential")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Credential", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Security-Token")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Security-Token", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Algorithm")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Algorithm", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-SignedHeaders", valid_613415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613416: Call_UnclaimDevice_613405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from your AWS account using its device ID.
  ## 
  let valid = call_613416.validator(path, query, header, formData, body)
  let scheme = call_613416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613416.url(scheme.get, call_613416.host, call_613416.base,
                         call_613416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613416, url, valid)

proc call*(call_613417: Call_UnclaimDevice_613405; deviceId: string): Recallable =
  ## unclaimDevice
  ## Disassociates a device from your AWS account using its device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613418 = newJObject()
  add(path_613418, "deviceId", newJString(deviceId))
  result = call_613417.call(path_613418, nil, nil, nil, nil)

var unclaimDevice* = Call_UnclaimDevice_613405(name: "unclaimDevice",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/unclaim", validator: validate_UnclaimDevice_613406,
    base: "/", url: url_UnclaimDevice_613407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613419 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613421(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613420(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The ARN of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613422 = path.getOrDefault("resource-arn")
  valid_613422 = validateParameter(valid_613422, JString, required = true,
                                 default = nil)
  if valid_613422 != nil:
    section.add "resource-arn", valid_613422
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613423 = query.getOrDefault("tagKeys")
  valid_613423 = validateParameter(valid_613423, JArray, required = true, default = nil)
  if valid_613423 != nil:
    section.add "tagKeys", valid_613423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613424 = header.getOrDefault("X-Amz-Signature")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Signature", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Content-Sha256", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Date")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Date", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Credential")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Credential", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Security-Token")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Security-Token", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Algorithm")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Algorithm", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-SignedHeaders", valid_613430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613431: Call_UntagResource_613419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ## 
  let valid = call_613431.validator(path, query, header, formData, body)
  let scheme = call_613431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613431.url(scheme.get, call_613431.host, call_613431.base,
                         call_613431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613431, url, valid)

proc call*(call_613432: Call_UntagResource_613419; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  var path_613433 = newJObject()
  var query_613434 = newJObject()
  add(path_613433, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_613434.add "tagKeys", tagKeys
  result = call_613432.call(path_613433, query_613434, nil, nil, nil)

var untagResource* = Call_UntagResource_613419(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_613420,
    base: "/", url: url_UntagResource_613421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceState_613435 = ref object of OpenApiRestCall_612658
proc url_UpdateDeviceState_613437(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId"),
               (kind: ConstantSegment, value: "/state")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeviceState_613436(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_613438 = path.getOrDefault("deviceId")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "deviceId", valid_613438
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613439 = header.getOrDefault("X-Amz-Signature")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Signature", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Content-Sha256", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Date")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Date", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Credential")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Credential", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Security-Token")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Security-Token", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Algorithm")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Algorithm", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-SignedHeaders", valid_613445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613447: Call_UpdateDeviceState_613435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ## 
  let valid = call_613447.validator(path, query, header, formData, body)
  let scheme = call_613447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613447.url(scheme.get, call_613447.host, call_613447.base,
                         call_613447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613447, url, valid)

proc call*(call_613448: Call_UpdateDeviceState_613435; body: JsonNode;
          deviceId: string): Recallable =
  ## updateDeviceState
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_613449 = newJObject()
  var body_613450 = newJObject()
  if body != nil:
    body_613450 = body
  add(path_613449, "deviceId", newJString(deviceId))
  result = call_613448.call(path_613449, nil, nil, nil, body_613450)

var updateDeviceState* = Call_UpdateDeviceState_613435(name: "updateDeviceState",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/state", validator: validate_UpdateDeviceState_613436,
    base: "/", url: url_UpdateDeviceState_613437,
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
