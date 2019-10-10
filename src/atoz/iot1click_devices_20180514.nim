
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ClaimDevicesByClaimCode_602803 = ref object of OpenApiRestCall_602466
proc url_ClaimDevicesByClaimCode_602805(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ClaimDevicesByClaimCode_602804(path: JsonNode; query: JsonNode;
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
  var valid_602931 = path.getOrDefault("claimCode")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "claimCode", valid_602931
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
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Security-Token")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Security-Token", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Content-Sha256", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_ClaimDevicesByClaimCode_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_ClaimDevicesByClaimCode_602803; claimCode: string): Recallable =
  ## claimDevicesByClaimCode
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
  ##  received a claim code with the device(s).
  ##   claimCode: string (required)
  ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  var path_603033 = newJObject()
  add(path_603033, "claimCode", newJString(claimCode))
  result = call_603032.call(path_603033, nil, nil, nil, nil)

var claimDevicesByClaimCode* = Call_ClaimDevicesByClaimCode_602803(
    name: "claimDevicesByClaimCode", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/claims/{claimCode}",
    validator: validate_ClaimDevicesByClaimCode_602804, base: "/",
    url: url_ClaimDevicesByClaimCode_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_603073 = ref object of OpenApiRestCall_602466
proc url_DescribeDevice_603075(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeDevice_603074(path: JsonNode; query: JsonNode;
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
  var valid_603076 = path.getOrDefault("deviceId")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "deviceId", valid_603076
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
  var valid_603077 = header.getOrDefault("X-Amz-Date")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Date", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Security-Token")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Security-Token", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-SignedHeaders", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_DescribeDevice_603073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_DescribeDevice_603073; deviceId: string): Recallable =
  ## describeDevice
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
  ##  details of the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_603086 = newJObject()
  add(path_603086, "deviceId", newJString(deviceId))
  result = call_603085.call(path_603086, nil, nil, nil, nil)

var describeDevice* = Call_DescribeDevice_603073(name: "describeDevice",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}", validator: validate_DescribeDevice_603074,
    base: "/", url: url_DescribeDevice_603075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FinalizeDeviceClaim_603087 = ref object of OpenApiRestCall_602466
proc url_FinalizeDeviceClaim_603089(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_FinalizeDeviceClaim_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = path.getOrDefault("deviceId")
  valid_603090 = validateParameter(valid_603090, JString, required = true,
                                 default = nil)
  if valid_603090 != nil:
    section.add "deviceId", valid_603090
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
  var valid_603091 = header.getOrDefault("X-Amz-Date")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Date", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Security-Token")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Security-Token", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_FinalizeDeviceClaim_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_FinalizeDeviceClaim_603087; deviceId: string;
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
  var path_603101 = newJObject()
  var body_603102 = newJObject()
  add(path_603101, "deviceId", newJString(deviceId))
  if body != nil:
    body_603102 = body
  result = call_603100.call(path_603101, nil, nil, nil, body_603102)

var finalizeDeviceClaim* = Call_FinalizeDeviceClaim_603087(
    name: "finalizeDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/finalize-claim",
    validator: validate_FinalizeDeviceClaim_603088, base: "/",
    url: url_FinalizeDeviceClaim_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeDeviceMethod_603117 = ref object of OpenApiRestCall_602466
proc url_InvokeDeviceMethod_603119(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_InvokeDeviceMethod_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = path.getOrDefault("deviceId")
  valid_603120 = validateParameter(valid_603120, JString, required = true,
                                 default = nil)
  if valid_603120 != nil:
    section.add "deviceId", valid_603120
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
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Security-Token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Security-Token", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_InvokeDeviceMethod_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_InvokeDeviceMethod_603117; deviceId: string;
          body: JsonNode): Recallable =
  ## invokeDeviceMethod
  ## Given a device ID, issues a request to invoke a named device method (with possible
  ##  parameters). See the "Example POST" code snippet below.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   body: JObject (required)
  var path_603131 = newJObject()
  var body_603132 = newJObject()
  add(path_603131, "deviceId", newJString(deviceId))
  if body != nil:
    body_603132 = body
  result = call_603130.call(path_603131, nil, nil, nil, body_603132)

var invokeDeviceMethod* = Call_InvokeDeviceMethod_603117(
    name: "invokeDeviceMethod", meth: HttpMethod.HttpPost,
    host: "devices.iot1click.amazonaws.com", route: "/devices/{deviceId}/methods",
    validator: validate_InvokeDeviceMethod_603118, base: "/",
    url: url_InvokeDeviceMethod_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceMethods_603103 = ref object of OpenApiRestCall_602466
proc url_GetDeviceMethods_603105(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeviceMethods_603104(path: JsonNode; query: JsonNode;
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
  var valid_603106 = path.getOrDefault("deviceId")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = nil)
  if valid_603106 != nil:
    section.add "deviceId", valid_603106
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
  var valid_603107 = header.getOrDefault("X-Amz-Date")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Date", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Security-Token")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Security-Token", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Content-Sha256", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Algorithm")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Algorithm", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Signature")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Signature", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-SignedHeaders", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_GetDeviceMethods_603103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Given a device ID, returns the invokable methods associated with the device.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_GetDeviceMethods_603103; deviceId: string): Recallable =
  ## getDeviceMethods
  ## Given a device ID, returns the invokable methods associated with the device.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_603116 = newJObject()
  add(path_603116, "deviceId", newJString(deviceId))
  result = call_603115.call(path_603116, nil, nil, nil, nil)

var getDeviceMethods* = Call_GetDeviceMethods_603103(name: "getDeviceMethods",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods", validator: validate_GetDeviceMethods_603104,
    base: "/", url: url_GetDeviceMethods_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDeviceClaim_603133 = ref object of OpenApiRestCall_602466
proc url_InitiateDeviceClaim_603135(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_InitiateDeviceClaim_603134(path: JsonNode; query: JsonNode;
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
  var valid_603136 = path.getOrDefault("deviceId")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "deviceId", valid_603136
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
  var valid_603137 = header.getOrDefault("X-Amz-Date")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Date", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_InitiateDeviceClaim_603133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_InitiateDeviceClaim_603133; deviceId: string): Recallable =
  ## initiateDeviceClaim
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
  ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
  ##  and finalizing the claim. For a device of type button, a device event can
  ##  be published by simply clicking the device.</p>
  ##  </note>
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_603146 = newJObject()
  add(path_603146, "deviceId", newJString(deviceId))
  result = call_603145.call(path_603146, nil, nil, nil, nil)

var initiateDeviceClaim* = Call_InitiateDeviceClaim_603133(
    name: "initiateDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/initiate-claim",
    validator: validate_InitiateDeviceClaim_603134, base: "/",
    url: url_InitiateDeviceClaim_603135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_603147 = ref object of OpenApiRestCall_602466
proc url_ListDeviceEvents_603149(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListDeviceEvents_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = path.getOrDefault("deviceId")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = nil)
  if valid_603150 != nil:
    section.add "deviceId", valid_603150
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
  var valid_603151 = query.getOrDefault("toTimeStamp")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = nil)
  if valid_603151 != nil:
    section.add "toTimeStamp", valid_603151
  var valid_603152 = query.getOrDefault("maxResults")
  valid_603152 = validateParameter(valid_603152, JInt, required = false, default = nil)
  if valid_603152 != nil:
    section.add "maxResults", valid_603152
  var valid_603153 = query.getOrDefault("nextToken")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "nextToken", valid_603153
  var valid_603154 = query.getOrDefault("fromTimeStamp")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = nil)
  if valid_603154 != nil:
    section.add "fromTimeStamp", valid_603154
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
  var valid_603155 = header.getOrDefault("X-Amz-Date")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Date", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Content-Sha256", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Algorithm")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Algorithm", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Signature")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Signature", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-SignedHeaders", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Credential")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Credential", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_ListDeviceEvents_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
  ##  array of events for the device.
  ## 
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603162, url, valid)

proc call*(call_603163: Call_ListDeviceEvents_603147; deviceId: string;
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
  var path_603164 = newJObject()
  var query_603165 = newJObject()
  add(path_603164, "deviceId", newJString(deviceId))
  add(query_603165, "toTimeStamp", newJString(toTimeStamp))
  add(query_603165, "maxResults", newJInt(maxResults))
  add(query_603165, "nextToken", newJString(nextToken))
  add(query_603165, "fromTimeStamp", newJString(fromTimeStamp))
  result = call_603163.call(path_603164, query_603165, nil, nil, nil)

var listDeviceEvents* = Call_ListDeviceEvents_603147(name: "listDeviceEvents",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/events#fromTimeStamp&toTimeStamp",
    validator: validate_ListDeviceEvents_603148, base: "/",
    url: url_ListDeviceEvents_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_603166 = ref object of OpenApiRestCall_602466
proc url_ListDevices_603168(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevices_603167(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603169 = query.getOrDefault("maxResults")
  valid_603169 = validateParameter(valid_603169, JInt, required = false, default = nil)
  if valid_603169 != nil:
    section.add "maxResults", valid_603169
  var valid_603170 = query.getOrDefault("nextToken")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "nextToken", valid_603170
  var valid_603171 = query.getOrDefault("deviceType")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "deviceType", valid_603171
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
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Security-Token")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Security-Token", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Content-Sha256", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Signature", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-SignedHeaders", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Credential")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Credential", valid_603178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603179: Call_ListDevices_603166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ## 
  let valid = call_603179.validator(path, query, header, formData, body)
  let scheme = call_603179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603179.url(scheme.get, call_603179.host, call_603179.base,
                         call_603179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603179, url, valid)

proc call*(call_603180: Call_ListDevices_603166; maxResults: int = 0;
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
  var query_603181 = newJObject()
  add(query_603181, "maxResults", newJInt(maxResults))
  add(query_603181, "nextToken", newJString(nextToken))
  add(query_603181, "deviceType", newJString(deviceType))
  result = call_603180.call(nil, query_603181, nil, nil, nil)

var listDevices* = Call_ListDevices_603166(name: "listDevices",
                                        meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
                                        route: "/devices",
                                        validator: validate_ListDevices_603167,
                                        base: "/", url: url_ListDevices_603168,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603196 = ref object of OpenApiRestCall_602466
proc url_TagResource_603198(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_603197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603199 = path.getOrDefault("resource-arn")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = nil)
  if valid_603199 != nil:
    section.add "resource-arn", valid_603199
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
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Security-Token")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Security-Token", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_TagResource_603196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_TagResource_603196; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
  ##  resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  ##   body: JObject (required)
  var path_603210 = newJObject()
  var body_603211 = newJObject()
  add(path_603210, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_603211 = body
  result = call_603209.call(path_603210, nil, nil, nil, body_603211)

var tagResource* = Call_TagResource_603196(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "devices.iot1click.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_603197,
                                        base: "/", url: url_TagResource_603198,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603182 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603184(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_603183(path: JsonNode; query: JsonNode;
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
  var valid_603185 = path.getOrDefault("resource-arn")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "resource-arn", valid_603185
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
  var valid_603186 = header.getOrDefault("X-Amz-Date")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Date", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Algorithm")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Algorithm", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Signature", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_ListTagsForResource_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags associated with the specified resource ARN.
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_ListTagsForResource_603182; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with the specified resource ARN.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_603195 = newJObject()
  add(path_603195, "resource-arn", newJString(resourceArn))
  result = call_603194.call(path_603195, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603182(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_603183, base: "/",
    url: url_ListTagsForResource_603184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnclaimDevice_603212 = ref object of OpenApiRestCall_602466
proc url_UnclaimDevice_603214(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UnclaimDevice_603213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603215 = path.getOrDefault("deviceId")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "deviceId", valid_603215
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
  var valid_603216 = header.getOrDefault("X-Amz-Date")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Date", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Security-Token")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Security-Token", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Content-Sha256", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Algorithm")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Algorithm", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Signature")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Signature", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-SignedHeaders", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Credential")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Credential", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_UnclaimDevice_603212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from your AWS account using its device ID.
  ## 
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603223, url, valid)

proc call*(call_603224: Call_UnclaimDevice_603212; deviceId: string): Recallable =
  ## unclaimDevice
  ## Disassociates a device from your AWS account using its device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  var path_603225 = newJObject()
  add(path_603225, "deviceId", newJString(deviceId))
  result = call_603224.call(path_603225, nil, nil, nil, nil)

var unclaimDevice* = Call_UnclaimDevice_603212(name: "unclaimDevice",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/unclaim", validator: validate_UnclaimDevice_603213,
    base: "/", url: url_UnclaimDevice_603214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603226 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603228(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_603227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603229 = path.getOrDefault("resource-arn")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = nil)
  if valid_603229 != nil:
    section.add "resource-arn", valid_603229
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603230 = query.getOrDefault("tagKeys")
  valid_603230 = validateParameter(valid_603230, JArray, required = true, default = nil)
  if valid_603230 != nil:
    section.add "tagKeys", valid_603230
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
  var valid_603231 = header.getOrDefault("X-Amz-Date")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Date", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Security-Token")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Security-Token", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Content-Sha256", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Algorithm")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Algorithm", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Credential")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Credential", valid_603237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_UntagResource_603226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603238, url, valid)

proc call*(call_603239: Call_UntagResource_603226; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
  ##  resource ARN.
  ##   tagKeys: JArray (required)
  ##          : A collections of tag keys. For example, {"key1","key2"}
  ##   resourceArn: string (required)
  ##              : The ARN of the resource.
  var path_603240 = newJObject()
  var query_603241 = newJObject()
  if tagKeys != nil:
    query_603241.add "tagKeys", tagKeys
  add(path_603240, "resource-arn", newJString(resourceArn))
  result = call_603239.call(path_603240, query_603241, nil, nil, nil)

var untagResource* = Call_UntagResource_603226(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_603227,
    base: "/", url: url_UntagResource_603228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceState_603242 = ref object of OpenApiRestCall_602466
proc url_UpdateDeviceState_603244(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDeviceState_603243(path: JsonNode; query: JsonNode;
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
  var valid_603245 = path.getOrDefault("deviceId")
  valid_603245 = validateParameter(valid_603245, JString, required = true,
                                 default = nil)
  if valid_603245 != nil:
    section.add "deviceId", valid_603245
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
  var valid_603246 = header.getOrDefault("X-Amz-Date")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Date", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Security-Token")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Security-Token", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Content-Sha256", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Algorithm")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Algorithm", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Signature")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Signature", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-SignedHeaders", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Credential")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Credential", valid_603252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603254: Call_UpdateDeviceState_603242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ## 
  let valid = call_603254.validator(path, query, header, formData, body)
  let scheme = call_603254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603254.url(scheme.get, call_603254.host, call_603254.base,
                         call_603254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603254, url, valid)

proc call*(call_603255: Call_UpdateDeviceState_603242; deviceId: string;
          body: JsonNode): Recallable =
  ## updateDeviceState
  ## Using a Boolean value (true or false), this operation
  ##  enables or disables the device given a device ID.
  ##   deviceId: string (required)
  ##           : The unique identifier of the device.
  ##   body: JObject (required)
  var path_603256 = newJObject()
  var body_603257 = newJObject()
  add(path_603256, "deviceId", newJString(deviceId))
  if body != nil:
    body_603257 = body
  result = call_603255.call(path_603256, nil, nil, nil, body_603257)

var updateDeviceState* = Call_UpdateDeviceState_603242(name: "updateDeviceState",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/state", validator: validate_UpdateDeviceState_603243,
    base: "/", url: url_UpdateDeviceState_603244,
    schemes: {Scheme.Https, Scheme.Http})
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
