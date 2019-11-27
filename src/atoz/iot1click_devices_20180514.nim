
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_ClaimDevicesByClaimCode_599705 = ref object of OpenApiRestCall_599368
proc url_ClaimDevicesByClaimCode_599707(protocol: Scheme; host: string; base: string;
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

proc validate_ClaimDevicesByClaimCode_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("claimCode")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "claimCode", valid_599833
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
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
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_ClaimDevicesByClaimCode_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_ClaimDevicesByClaimCode_599705; claimCode: string): Recallable =
  ## claimDevicesByClaimCode
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ##   claimCode: string (required)
  ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  var path_599935 = newJObject()
  add(path_599935, "claimCode", newJString(claimCode))
  result = call_599934.call(path_599935, nil, nil, nil, nil)

var claimDevicesByClaimCode* = Call_ClaimDevicesByClaimCode_599705(
    name: "claimDevicesByClaimCode", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/claims/{claimCode}",
    validator: validate_ClaimDevicesByClaimCode_599706, base: "/",
    url: url_ClaimDevicesByClaimCode_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_599975 = ref object of OpenApiRestCall_599368
proc url_DescribeDevice_599977(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDevice_599976(path: JsonNode; query: JsonNode;
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
  var valid_599978 = path.getOrDefault("deviceId")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "deviceId", valid_599978
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
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
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_DescribeDevice_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_DescribeDevice_599975; deviceId: string): Recallable =
  ## describeDevice
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_599988 = newJObject()
  add(path_599988, "deviceId", newJString(deviceId))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var describeDevice* = Call_DescribeDevice_599975(name: "describeDevice",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}", validator: validate_DescribeDevice_599976,
    base: "/", url: url_DescribeDevice_599977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FinalizeDeviceClaim_599989 = ref object of OpenApiRestCall_599368
proc url_FinalizeDeviceClaim_599991(protocol: Scheme; host: string; base: string;
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

proc validate_FinalizeDeviceClaim_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = path.getOrDefault("deviceId")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = nil)
  if valid_599992 != nil:
    section.add "deviceId", valid_599992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_FinalizeDeviceClaim_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_FinalizeDeviceClaim_599989; deviceId: string;
          body: JsonNode): Recallable =
  ## finalizeDeviceClaim
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   body: JObject (required)
  var path_600003 = newJObject()
  var body_600004 = newJObject()
  add(path_600003, "deviceId", newJString(deviceId))
  if body != nil:
    body_600004 = body
  result = call_600002.call(path_600003, nil, nil, nil, body_600004)

var finalizeDeviceClaim* = Call_FinalizeDeviceClaim_599989(
    name: "finalizeDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/finalize-claim",
    validator: validate_FinalizeDeviceClaim_599990, base: "/",
    url: url_FinalizeDeviceClaim_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeDeviceMethod_600019 = ref object of OpenApiRestCall_599368
proc url_InvokeDeviceMethod_600021(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeDeviceMethod_600020(path: JsonNode; query: JsonNode;
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
  var valid_600022 = path.getOrDefault("deviceId")
  valid_600022 = validateParameter(valid_600022, JString, required = true,
                                 default = nil)
  if valid_600022 != nil:
    section.add "deviceId", valid_600022
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_InvokeDeviceMethod_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_InvokeDeviceMethod_600019; deviceId: string;
          body: JsonNode): Recallable =
  ## invokeDeviceMethod
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   body: JObject (required)
  var path_600033 = newJObject()
  var body_600034 = newJObject()
  add(path_600033, "deviceId", newJString(deviceId))
  if body != nil:
    body_600034 = body
  result = call_600032.call(path_600033, nil, nil, nil, body_600034)

var invokeDeviceMethod* = Call_InvokeDeviceMethod_600019(
    name: "invokeDeviceMethod", meth: HttpMethod.HttpPost,
    host: "devices.iot1click.amazonaws.com", route: "/devices/{deviceId}/methods",
    validator: validate_InvokeDeviceMethod_600020, base: "/",
    url: url_InvokeDeviceMethod_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceMethods_600005 = ref object of OpenApiRestCall_599368
proc url_GetDeviceMethods_600007(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceMethods_600006(path: JsonNode; query: JsonNode;
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
  var valid_600008 = path.getOrDefault("deviceId")
  valid_600008 = validateParameter(valid_600008, JString, required = true,
                                 default = nil)
  if valid_600008 != nil:
    section.add "deviceId", valid_600008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600009 = header.getOrDefault("X-Amz-Date")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Date", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Security-Token")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Security-Token", valid_600010
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
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_GetDeviceMethods_600005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns the invokable methods associated with the device.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_GetDeviceMethods_600005; deviceId: string): Recallable =
  ## getDeviceMethods
  ## Given a device ID, returns the invokable methods associated with the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_600018 = newJObject()
  add(path_600018, "deviceId", newJString(deviceId))
  result = call_600017.call(path_600018, nil, nil, nil, nil)

var getDeviceMethods* = Call_GetDeviceMethods_600005(name: "getDeviceMethods",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods", validator: validate_GetDeviceMethods_600006,
    base: "/", url: url_GetDeviceMethods_600007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDeviceClaim_600035 = ref object of OpenApiRestCall_599368
proc url_InitiateDeviceClaim_600037(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateDeviceClaim_600036(path: JsonNode; query: JsonNode;
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
  var valid_600038 = path.getOrDefault("deviceId")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = nil)
  if valid_600038 != nil:
    section.add "deviceId", valid_600038
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
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
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_InitiateDeviceClaim_600035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_InitiateDeviceClaim_600035; deviceId: string): Recallable =
  ## initiateDeviceClaim
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_600048 = newJObject()
  add(path_600048, "deviceId", newJString(deviceId))
  result = call_600047.call(path_600048, nil, nil, nil, nil)

var initiateDeviceClaim* = Call_InitiateDeviceClaim_600035(
    name: "initiateDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/initiate-claim",
    validator: validate_InitiateDeviceClaim_600036, base: "/",
    url: url_InitiateDeviceClaim_600037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_600049 = ref object of OpenApiRestCall_599368
proc url_ListDeviceEvents_600051(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceEvents_600050(path: JsonNode; query: JsonNode;
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
  var valid_600052 = path.getOrDefault("deviceId")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = nil)
  if valid_600052 != nil:
    section.add "deviceId", valid_600052
  result.add "path", section
  ## parameters in `query` object:
  ##   toTimeStamp: JString (required)
  ##              : The end date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   fromTimeStamp: JString (required)
  ##                : The start date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `toTimeStamp` field"
  var valid_600053 = query.getOrDefault("toTimeStamp")
  valid_600053 = validateParameter(valid_600053, JString, required = true,
                                 default = nil)
  if valid_600053 != nil:
    section.add "toTimeStamp", valid_600053
  var valid_600054 = query.getOrDefault("maxResults")
  valid_600054 = validateParameter(valid_600054, JInt, required = false, default = nil)
  if valid_600054 != nil:
    section.add "maxResults", valid_600054
  var valid_600055 = query.getOrDefault("nextToken")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "nextToken", valid_600055
  var valid_600056 = query.getOrDefault("fromTimeStamp")
  valid_600056 = validateParameter(valid_600056, JString, required = true,
                                 default = nil)
  if valid_600056 != nil:
    section.add "fromTimeStamp", valid_600056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600057 = header.getOrDefault("X-Amz-Date")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Date", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Security-Token")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Security-Token", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Content-Sha256", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Algorithm")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Algorithm", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Signature")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Signature", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-SignedHeaders", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Credential")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Credential", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600064: Call_ListDeviceEvents_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ## 
  let valid = call_600064.validator(path, query, header, formData, body)
  let scheme = call_600064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600064.url(scheme.get, call_600064.host, call_600064.base,
                         call_600064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600064, url, valid)

proc call*(call_600065: Call_ListDeviceEvents_600049; deviceId: string;
          toTimeStamp: string; fromTimeStamp: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDeviceEvents
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   toTimeStamp: string (required)
  ##              : The end date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   fromTimeStamp: string (required)
  ##                : The start date for the device event query, in ISO8061 format. For example,
  ##  2018-03-28T15:45:12.880Z
  ##  
  var path_600066 = newJObject()
  var query_600067 = newJObject()
  add(path_600066, "deviceId", newJString(deviceId))
  add(query_600067, "toTimeStamp", newJString(toTimeStamp))
  add(query_600067, "maxResults", newJInt(maxResults))
  add(query_600067, "nextToken", newJString(nextToken))
  add(query_600067, "fromTimeStamp", newJString(fromTimeStamp))
  result = call_600065.call(path_600066, query_600067, nil, nil, nil)

var listDeviceEvents* = Call_ListDeviceEvents_600049(name: "listDeviceEvents",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/events#fromTimeStamp&toTimeStamp",
    validator: validate_ListDeviceEvents_600050, base: "/",
    url: url_ListDeviceEvents_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_600068 = ref object of OpenApiRestCall_599368
proc url_ListDevices_600070(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_600069(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   deviceType: JString
  ##             : The type of the device, such as "button".
  section = newJObject()
  var valid_600071 = query.getOrDefault("maxResults")
  valid_600071 = validateParameter(valid_600071, JInt, required = false, default = nil)
  if valid_600071 != nil:
    section.add "maxResults", valid_600071
  var valid_600072 = query.getOrDefault("nextToken")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "nextToken", valid_600072
  var valid_600073 = query.getOrDefault("deviceType")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "deviceType", valid_600073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600074 = header.getOrDefault("X-Amz-Date")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Date", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Security-Token")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Security-Token", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Content-Sha256", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Algorithm")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Algorithm", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Signature")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Signature", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-SignedHeaders", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Credential")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Credential", valid_600080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600081: Call_ListDevices_600068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  let valid = call_600081.validator(path, query, header, formData, body)
  let scheme = call_600081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600081.url(scheme.get, call_600081.host, call_600081.base,
                         call_600081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600081, url, valid)

proc call*(call_600082: Call_ListDevices_600068; maxResults: int = 0;
          nextToken: string = ""; deviceType: string = ""): Recallable =
  ## listDevices
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of
  ##  100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   deviceType: string
  ##             : The type of the device, such as "button".
  var query_600083 = newJObject()
  add(query_600083, "maxResults", newJInt(maxResults))
  add(query_600083, "nextToken", newJString(nextToken))
  add(query_600083, "deviceType", newJString(deviceType))
  result = call_600082.call(nil, query_600083, nil, nil, nil)

var listDevices* = Call_ListDevices_600068(name: "listDevices",
                                        meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
                                        route: "/devices",
                                        validator: validate_ListDevices_600069,
                                        base: "/", url: url_ListDevices_600070,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600098 = ref object of OpenApiRestCall_599368
proc url_TagResource_600100(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600101 = path.getOrDefault("resource-arn")
  valid_600101 = validateParameter(valid_600101, JString, required = true,
                                 default = nil)
  if valid_600101 != nil:
    section.add "resource-arn", valid_600101
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600102 = header.getOrDefault("X-Amz-Date")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Date", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Security-Token")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Security-Token", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Content-Sha256", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Algorithm")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Algorithm", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Signature")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Signature", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-SignedHeaders", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Credential")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Credential", valid_600108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_TagResource_600098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_TagResource_600098; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var path_600112 = newJObject()
  var body_600113 = newJObject()
  add(path_600112, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_600113 = body
  result = call_600111.call(path_600112, nil, nil, nil, body_600113)

var tagResource* = Call_TagResource_600098(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "devices.iot1click.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_600099,
                                        base: "/", url: url_TagResource_600100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600084 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600086(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600085(path: JsonNode; query: JsonNode;
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
  var valid_600087 = path.getOrDefault("resource-arn")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = nil)
  if valid_600087 != nil:
    section.add "resource-arn", valid_600087
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600088 = header.getOrDefault("X-Amz-Date")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Date", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Security-Token")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Security-Token", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Content-Sha256", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Algorithm")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Algorithm", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Signature", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-SignedHeaders", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Credential")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Credential", valid_600094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_ListTagsForResource_600084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with the specified resource ARN.
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_ListTagsForResource_600084; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with the specified resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_600097 = newJObject()
  add(path_600097, "resource-arn", newJString(resourceArn))
  result = call_600096.call(path_600097, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600084(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_600085, base: "/",
    url: url_ListTagsForResource_600086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnclaimDevice_600114 = ref object of OpenApiRestCall_599368
proc url_UnclaimDevice_600116(protocol: Scheme; host: string; base: string;
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

proc validate_UnclaimDevice_600115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600117 = path.getOrDefault("deviceId")
  valid_600117 = validateParameter(valid_600117, JString, required = true,
                                 default = nil)
  if valid_600117 != nil:
    section.add "deviceId", valid_600117
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600118 = header.getOrDefault("X-Amz-Date")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Date", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Security-Token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Security-Token", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Content-Sha256", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Algorithm")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Algorithm", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Signature")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Signature", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-SignedHeaders", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Credential")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Credential", valid_600124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600125: Call_UnclaimDevice_600114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from your AWS account using its device ID.
  ## 
  let valid = call_600125.validator(path, query, header, formData, body)
  let scheme = call_600125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600125.url(scheme.get, call_600125.host, call_600125.base,
                         call_600125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600125, url, valid)

proc call*(call_600126: Call_UnclaimDevice_600114; deviceId: string): Recallable =
  ## unclaimDevice
  ## Disassociates a device from your AWS account using its device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_600127 = newJObject()
  add(path_600127, "deviceId", newJString(deviceId))
  result = call_600126.call(path_600127, nil, nil, nil, nil)

var unclaimDevice* = Call_UnclaimDevice_600114(name: "unclaimDevice",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/unclaim", validator: validate_UnclaimDevice_600115,
    base: "/", url: url_UnclaimDevice_600116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600128 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600130(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600131 = path.getOrDefault("resource-arn")
  valid_600131 = validateParameter(valid_600131, JString, required = true,
                                 default = nil)
  if valid_600131 != nil:
    section.add "resource-arn", valid_600131
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600132 = query.getOrDefault("tagKeys")
  valid_600132 = validateParameter(valid_600132, JArray, required = true, default = nil)
  if valid_600132 != nil:
    section.add "tagKeys", valid_600132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600133 = header.getOrDefault("X-Amz-Date")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Date", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Security-Token")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Security-Token", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Content-Sha256", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Algorithm")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Algorithm", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Signature")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Signature", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-SignedHeaders", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Credential")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Credential", valid_600139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600140: Call_UntagResource_600128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ## 
  let valid = call_600140.validator(path, query, header, formData, body)
  let scheme = call_600140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600140.url(scheme.get, call_600140.host, call_600140.base,
                         call_600140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600140, url, valid)

proc call*(call_600141: Call_UntagResource_600128; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_600142 = newJObject()
  var query_600143 = newJObject()
  if tagKeys != nil:
    query_600143.add "tagKeys", tagKeys
  add(path_600142, "resource-arn", newJString(resourceArn))
  result = call_600141.call(path_600142, query_600143, nil, nil, nil)

var untagResource* = Call_UntagResource_600128(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_600129,
    base: "/", url: url_UntagResource_600130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceState_600144 = ref object of OpenApiRestCall_599368
proc url_UpdateDeviceState_600146(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceState_600145(path: JsonNode; query: JsonNode;
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
  var valid_600147 = path.getOrDefault("deviceId")
  valid_600147 = validateParameter(valid_600147, JString, required = true,
                                 default = nil)
  if valid_600147 != nil:
    section.add "deviceId", valid_600147
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600148 = header.getOrDefault("X-Amz-Date")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Date", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Security-Token")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Security-Token", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Content-Sha256", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Algorithm")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Algorithm", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Signature")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Signature", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-SignedHeaders", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Credential")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Credential", valid_600154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600156: Call_UpdateDeviceState_600144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ## 
  let valid = call_600156.validator(path, query, header, formData, body)
  let scheme = call_600156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600156.url(scheme.get, call_600156.host, call_600156.base,
                         call_600156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600156, url, valid)

proc call*(call_600157: Call_UpdateDeviceState_600144; deviceId: string;
          body: JsonNode): Recallable =
  ## updateDeviceState
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   body: JObject (required)
  var path_600158 = newJObject()
  var body_600159 = newJObject()
  add(path_600158, "deviceId", newJString(deviceId))
  if body != nil:
    body_600159 = body
  result = call_600157.call(path_600158, nil, nil, nil, body_600159)

var updateDeviceState* = Call_UpdateDeviceState_600144(name: "updateDeviceState",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/state", validator: validate_UpdateDeviceState_600145,
    base: "/", url: url_UpdateDeviceState_600146,
    schemes: {Scheme.Https, Scheme.Http})
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
