
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_ClaimDevicesByClaimCode_601727 = ref object of OpenApiRestCall_601389
proc url_ClaimDevicesByClaimCode_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ClaimDevicesByClaimCode_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("claimCode")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "claimCode", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_ClaimDevicesByClaimCode_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_ClaimDevicesByClaimCode_601727; claimCode: string): Recallable =
  ## claimDevicesByClaimCode
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ##   claimCode: string (required)
  ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  var path_601957 = newJObject()
  add(path_601957, "claimCode", newJString(claimCode))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var claimDevicesByClaimCode* = Call_ClaimDevicesByClaimCode_601727(
    name: "claimDevicesByClaimCode", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/claims/{claimCode}",
    validator: validate_ClaimDevicesByClaimCode_601728, base: "/",
    url: url_ClaimDevicesByClaimCode_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_601997 = ref object of OpenApiRestCall_601389
proc url_DescribeDevice_601999(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDevice_601998(path: JsonNode; query: JsonNode;
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
  var valid_602000 = path.getOrDefault("deviceId")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "deviceId", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_DescribeDevice_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_DescribeDevice_601997; deviceId: string): Recallable =
  ## describeDevice
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602010 = newJObject()
  add(path_602010, "deviceId", newJString(deviceId))
  result = call_602009.call(path_602010, nil, nil, nil, nil)

var describeDevice* = Call_DescribeDevice_601997(name: "describeDevice",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}", validator: validate_DescribeDevice_601998,
    base: "/", url: url_DescribeDevice_601999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FinalizeDeviceClaim_602011 = ref object of OpenApiRestCall_601389
proc url_FinalizeDeviceClaim_602013(protocol: Scheme; host: string; base: string;
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

proc validate_FinalizeDeviceClaim_602012(path: JsonNode; query: JsonNode;
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
  var valid_602014 = path.getOrDefault("deviceId")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "deviceId", valid_602014
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
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_FinalizeDeviceClaim_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_FinalizeDeviceClaim_602011; body: JsonNode;
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
  var path_602025 = newJObject()
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  add(path_602025, "deviceId", newJString(deviceId))
  result = call_602024.call(path_602025, nil, nil, nil, body_602026)

var finalizeDeviceClaim* = Call_FinalizeDeviceClaim_602011(
    name: "finalizeDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/finalize-claim",
    validator: validate_FinalizeDeviceClaim_602012, base: "/",
    url: url_FinalizeDeviceClaim_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeDeviceMethod_602041 = ref object of OpenApiRestCall_601389
proc url_InvokeDeviceMethod_602043(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeDeviceMethod_602042(path: JsonNode; query: JsonNode;
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
  var valid_602044 = path.getOrDefault("deviceId")
  valid_602044 = validateParameter(valid_602044, JString, required = true,
                                 default = nil)
  if valid_602044 != nil:
    section.add "deviceId", valid_602044
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
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_InvokeDeviceMethod_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_InvokeDeviceMethod_602041; body: JsonNode;
          deviceId: string): Recallable =
  ## invokeDeviceMethod
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602055 = newJObject()
  var body_602056 = newJObject()
  if body != nil:
    body_602056 = body
  add(path_602055, "deviceId", newJString(deviceId))
  result = call_602054.call(path_602055, nil, nil, nil, body_602056)

var invokeDeviceMethod* = Call_InvokeDeviceMethod_602041(
    name: "invokeDeviceMethod", meth: HttpMethod.HttpPost,
    host: "devices.iot1click.amazonaws.com", route: "/devices/{deviceId}/methods",
    validator: validate_InvokeDeviceMethod_602042, base: "/",
    url: url_InvokeDeviceMethod_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceMethods_602027 = ref object of OpenApiRestCall_601389
proc url_GetDeviceMethods_602029(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceMethods_602028(path: JsonNode; query: JsonNode;
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
  var valid_602030 = path.getOrDefault("deviceId")
  valid_602030 = validateParameter(valid_602030, JString, required = true,
                                 default = nil)
  if valid_602030 != nil:
    section.add "deviceId", valid_602030
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
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_GetDeviceMethods_602027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns the invokable methods associated with the device.
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_GetDeviceMethods_602027; deviceId: string): Recallable =
  ## getDeviceMethods
  ## Given a device ID, returns the invokable methods associated with the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602040 = newJObject()
  add(path_602040, "deviceId", newJString(deviceId))
  result = call_602039.call(path_602040, nil, nil, nil, nil)

var getDeviceMethods* = Call_GetDeviceMethods_602027(name: "getDeviceMethods",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods", validator: validate_GetDeviceMethods_602028,
    base: "/", url: url_GetDeviceMethods_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDeviceClaim_602057 = ref object of OpenApiRestCall_601389
proc url_InitiateDeviceClaim_602059(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateDeviceClaim_602058(path: JsonNode; query: JsonNode;
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
  var valid_602060 = path.getOrDefault("deviceId")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = nil)
  if valid_602060 != nil:
    section.add "deviceId", valid_602060
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
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_InitiateDeviceClaim_602057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_InitiateDeviceClaim_602057; deviceId: string): Recallable =
  ## initiateDeviceClaim
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602070 = newJObject()
  add(path_602070, "deviceId", newJString(deviceId))
  result = call_602069.call(path_602070, nil, nil, nil, nil)

var initiateDeviceClaim* = Call_InitiateDeviceClaim_602057(
    name: "initiateDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/initiate-claim",
    validator: validate_InitiateDeviceClaim_602058, base: "/",
    url: url_InitiateDeviceClaim_602059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_602071 = ref object of OpenApiRestCall_601389
proc url_ListDeviceEvents_602073(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceEvents_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = path.getOrDefault("deviceId")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = nil)
  if valid_602074 != nil:
    section.add "deviceId", valid_602074
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
  var valid_602075 = query.getOrDefault("nextToken")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "nextToken", valid_602075
  assert query != nil,
        "query argument is necessary due to required `fromTimeStamp` field"
  var valid_602076 = query.getOrDefault("fromTimeStamp")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = nil)
  if valid_602076 != nil:
    section.add "fromTimeStamp", valid_602076
  var valid_602077 = query.getOrDefault("toTimeStamp")
  valid_602077 = validateParameter(valid_602077, JString, required = true,
                                 default = nil)
  if valid_602077 != nil:
    section.add "toTimeStamp", valid_602077
  var valid_602078 = query.getOrDefault("maxResults")
  valid_602078 = validateParameter(valid_602078, JInt, required = false, default = nil)
  if valid_602078 != nil:
    section.add "maxResults", valid_602078
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
  var valid_602079 = header.getOrDefault("X-Amz-Signature")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Signature", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Content-Sha256", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Date")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Date", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Credential")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Credential", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Security-Token")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Security-Token", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Algorithm")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Algorithm", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-SignedHeaders", valid_602085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602086: Call_ListDeviceEvents_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ## 
  let valid = call_602086.validator(path, query, header, formData, body)
  let scheme = call_602086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602086.url(scheme.get, call_602086.host, call_602086.base,
                         call_602086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602086, url, valid)

proc call*(call_602087: Call_ListDeviceEvents_602071; fromTimeStamp: string;
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
  var path_602088 = newJObject()
  var query_602089 = newJObject()
  add(query_602089, "nextToken", newJString(nextToken))
  add(query_602089, "fromTimeStamp", newJString(fromTimeStamp))
  add(query_602089, "toTimeStamp", newJString(toTimeStamp))
  add(path_602088, "deviceId", newJString(deviceId))
  add(query_602089, "maxResults", newJInt(maxResults))
  result = call_602087.call(path_602088, query_602089, nil, nil, nil)

var listDeviceEvents* = Call_ListDeviceEvents_602071(name: "listDeviceEvents",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/events#fromTimeStamp&toTimeStamp",
    validator: validate_ListDeviceEvents_602072, base: "/",
    url: url_ListDeviceEvents_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_602090 = ref object of OpenApiRestCall_601389
proc url_ListDevices_602092(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevices_602091(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602093 = query.getOrDefault("nextToken")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "nextToken", valid_602093
  var valid_602094 = query.getOrDefault("deviceType")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "deviceType", valid_602094
  var valid_602095 = query.getOrDefault("maxResults")
  valid_602095 = validateParameter(valid_602095, JInt, required = false, default = nil)
  if valid_602095 != nil:
    section.add "maxResults", valid_602095
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
  var valid_602096 = header.getOrDefault("X-Amz-Signature")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Signature", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Content-Sha256", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Date")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Date", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Credential")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Credential", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Security-Token")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Security-Token", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Algorithm")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Algorithm", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-SignedHeaders", valid_602102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602103: Call_ListDevices_602090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  let valid = call_602103.validator(path, query, header, formData, body)
  let scheme = call_602103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602103.url(scheme.get, call_602103.host, call_602103.base,
                         call_602103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602103, url, valid)

proc call*(call_602104: Call_ListDevices_602090; nextToken: string = "";
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
  var query_602105 = newJObject()
  add(query_602105, "nextToken", newJString(nextToken))
  add(query_602105, "deviceType", newJString(deviceType))
  add(query_602105, "maxResults", newJInt(maxResults))
  result = call_602104.call(nil, query_602105, nil, nil, nil)

var listDevices* = Call_ListDevices_602090(name: "listDevices",
                                        meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
                                        route: "/devices",
                                        validator: validate_ListDevices_602091,
                                        base: "/", url: url_ListDevices_602092,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602120 = ref object of OpenApiRestCall_601389
proc url_TagResource_602122(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602121(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602123 = path.getOrDefault("resource-arn")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = nil)
  if valid_602123 != nil:
    section.add "resource-arn", valid_602123
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
  var valid_602124 = header.getOrDefault("X-Amz-Signature")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Signature", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Content-Sha256", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Date")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Date", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Credential")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Credential", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Security-Token")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Security-Token", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Algorithm")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Algorithm", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-SignedHeaders", valid_602130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602132: Call_TagResource_602120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ## 
  let valid = call_602132.validator(path, query, header, formData, body)
  let scheme = call_602132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602132.url(scheme.get, call_602132.host, call_602132.base,
                         call_602132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602132, url, valid)

proc call*(call_602133: Call_TagResource_602120; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var path_602134 = newJObject()
  var body_602135 = newJObject()
  add(path_602134, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602135 = body
  result = call_602133.call(path_602134, nil, nil, nil, body_602135)

var tagResource* = Call_TagResource_602120(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "devices.iot1click.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_602121,
                                        base: "/", url: url_TagResource_602122,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602106 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602108(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602107(path: JsonNode; query: JsonNode;
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
  var valid_602109 = path.getOrDefault("resource-arn")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = nil)
  if valid_602109 != nil:
    section.add "resource-arn", valid_602109
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
  var valid_602110 = header.getOrDefault("X-Amz-Signature")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Signature", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Content-Sha256", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Date")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Date", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Credential")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Credential", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Security-Token")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Security-Token", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Algorithm")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Algorithm", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-SignedHeaders", valid_602116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602117: Call_ListTagsForResource_602106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with the specified resource ARN.
  ## 
  let valid = call_602117.validator(path, query, header, formData, body)
  let scheme = call_602117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602117.url(scheme.get, call_602117.host, call_602117.base,
                         call_602117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602117, url, valid)

proc call*(call_602118: Call_ListTagsForResource_602106; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with the specified resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_602119 = newJObject()
  add(path_602119, "resource-arn", newJString(resourceArn))
  result = call_602118.call(path_602119, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602106(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_602107, base: "/",
    url: url_ListTagsForResource_602108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnclaimDevice_602136 = ref object of OpenApiRestCall_601389
proc url_UnclaimDevice_602138(protocol: Scheme; host: string; base: string;
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

proc validate_UnclaimDevice_602137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602139 = path.getOrDefault("deviceId")
  valid_602139 = validateParameter(valid_602139, JString, required = true,
                                 default = nil)
  if valid_602139 != nil:
    section.add "deviceId", valid_602139
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
  var valid_602140 = header.getOrDefault("X-Amz-Signature")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Signature", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Content-Sha256", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Date")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Date", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Credential")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Credential", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Security-Token")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Security-Token", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Algorithm")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Algorithm", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-SignedHeaders", valid_602146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_UnclaimDevice_602136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from your AWS account using its device ID.
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602147, url, valid)

proc call*(call_602148: Call_UnclaimDevice_602136; deviceId: string): Recallable =
  ## unclaimDevice
  ## Disassociates a device from your AWS account using its device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602149 = newJObject()
  add(path_602149, "deviceId", newJString(deviceId))
  result = call_602148.call(path_602149, nil, nil, nil, nil)

var unclaimDevice* = Call_UnclaimDevice_602136(name: "unclaimDevice",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/unclaim", validator: validate_UnclaimDevice_602137,
    base: "/", url: url_UnclaimDevice_602138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602150 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602152(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602153 = path.getOrDefault("resource-arn")
  valid_602153 = validateParameter(valid_602153, JString, required = true,
                                 default = nil)
  if valid_602153 != nil:
    section.add "resource-arn", valid_602153
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602154 = query.getOrDefault("tagKeys")
  valid_602154 = validateParameter(valid_602154, JArray, required = true, default = nil)
  if valid_602154 != nil:
    section.add "tagKeys", valid_602154
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
  var valid_602155 = header.getOrDefault("X-Amz-Signature")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Signature", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Content-Sha256", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Credential")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Credential", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Security-Token")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Security-Token", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_UntagResource_602150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_UntagResource_602150; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  var path_602164 = newJObject()
  var query_602165 = newJObject()
  add(path_602164, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602165.add "tagKeys", tagKeys
  result = call_602163.call(path_602164, query_602165, nil, nil, nil)

var untagResource* = Call_UntagResource_602150(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602151,
    base: "/", url: url_UntagResource_602152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceState_602166 = ref object of OpenApiRestCall_601389
proc url_UpdateDeviceState_602168(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceState_602167(path: JsonNode; query: JsonNode;
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
  var valid_602169 = path.getOrDefault("deviceId")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "deviceId", valid_602169
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
  var valid_602170 = header.getOrDefault("X-Amz-Signature")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Signature", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Content-Sha256", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Date")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Date", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Credential")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Credential", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Security-Token")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Security-Token", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Algorithm")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Algorithm", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-SignedHeaders", valid_602176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602178: Call_UpdateDeviceState_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ## 
  let valid = call_602178.validator(path, query, header, formData, body)
  let scheme = call_602178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602178.url(scheme.get, call_602178.host, call_602178.base,
                         call_602178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602178, url, valid)

proc call*(call_602179: Call_UpdateDeviceState_602166; body: JsonNode;
          deviceId: string): Recallable =
  ## updateDeviceState
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_602180 = newJObject()
  var body_602181 = newJObject()
  if body != nil:
    body_602181 = body
  add(path_602180, "deviceId", newJString(deviceId))
  result = call_602179.call(path_602180, nil, nil, nil, body_602181)

var updateDeviceState* = Call_UpdateDeviceState_602166(name: "updateDeviceState",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/state", validator: validate_UpdateDeviceState_602167,
    base: "/", url: url_UpdateDeviceState_602168,
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
