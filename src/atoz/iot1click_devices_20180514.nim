
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "devices.iot1click.ap-northeast-1.amazonaws.com", "ap-southeast-1": "devices.iot1click.ap-southeast-1.amazonaws.com", "us-west-2": "devices.iot1click.us-west-2.amazonaws.com", "eu-west-2": "devices.iot1click.eu-west-2.amazonaws.com", "ap-northeast-3": "devices.iot1click.ap-northeast-3.amazonaws.com", "eu-central-1": "devices.iot1click.eu-central-1.amazonaws.com", "us-east-2": "devices.iot1click.us-east-2.amazonaws.com", "us-east-1": "devices.iot1click.us-east-1.amazonaws.com", "cn-northwest-1": "devices.iot1click.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "devices.iot1click.ap-south-1.amazonaws.com", "eu-north-1": "devices.iot1click.eu-north-1.amazonaws.com", "ap-northeast-2": "devices.iot1click.ap-northeast-2.amazonaws.com", "us-west-1": "devices.iot1click.us-west-1.amazonaws.com", "us-gov-east-1": "devices.iot1click.us-gov-east-1.amazonaws.com", "eu-west-3": "devices.iot1click.eu-west-3.amazonaws.com", "cn-north-1": "devices.iot1click.cn-north-1.amazonaws.com.cn", "sa-east-1": "devices.iot1click.sa-east-1.amazonaws.com", "eu-west-1": "devices.iot1click.eu-west-1.amazonaws.com", "us-gov-west-1": "devices.iot1click.us-gov-west-1.amazonaws.com", "ap-southeast-2": "devices.iot1click.ap-southeast-2.amazonaws.com", "ca-central-1": "devices.iot1click.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_ClaimDevicesByClaimCode_402656288 = ref object of OpenApiRestCall_402656038
proc url_ClaimDevicesByClaimCode_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ClaimDevicesByClaimCode_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
                ##  received a claim code with the device(s).
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   claimCode: JString (required)
                                 ##            : The claim code, starting with "C-", as provided by the device manufacturer.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `claimCode` field"
  var valid_402656380 = path.getOrDefault("claimCode")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "claimCode", valid_402656380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_ClaimDevicesByClaimCode_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
                                                                                         ##  received a claim code with the device(s).
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_ClaimDevicesByClaimCode_402656288;
           claimCode: string): Recallable =
  ## claimDevicesByClaimCode
  ## Adds device(s) to your account (i.e., claim one or more devices) if and only if you
                            ##  received a claim code with the device(s).
  ##   
                                                                         ## claimCode: string (required)
                                                                         ##            
                                                                         ## : 
                                                                         ## The 
                                                                         ## claim 
                                                                         ## code, 
                                                                         ## starting 
                                                                         ## with 
                                                                         ## "C-", 
                                                                         ## as 
                                                                         ## provided 
                                                                         ## by 
                                                                         ## the 
                                                                         ## device 
                                                                         ## manufacturer.
  var path_402656451 = newJObject()
  add(path_402656451, "claimCode", newJString(claimCode))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var claimDevicesByClaimCode* = Call_ClaimDevicesByClaimCode_402656288(
    name: "claimDevicesByClaimCode", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/claims/{claimCode}",
    validator: validate_ClaimDevicesByClaimCode_402656289, base: "/",
    makeUrl: url_ClaimDevicesByClaimCode_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDevice_402656481 = ref object of OpenApiRestCall_402656038
proc url_DescribeDevice_402656483(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDevice_402656482(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
                ##  details of the device.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656484 = path.getOrDefault("deviceId")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "deviceId", valid_402656484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656492: Call_DescribeDevice_402656481; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
                                                                                         ##  details of the device.
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_DescribeDevice_402656481; deviceId: string): Recallable =
  ## describeDevice
  ## Given a device ID, returns a DescribeDeviceResponse object describing the
                   ##  details of the device.
  ##   deviceId: string (required)
                                             ##           : The unique identifier of the device.
  var path_402656494 = newJObject()
  add(path_402656494, "deviceId", newJString(deviceId))
  result = call_402656493.call(path_402656494, nil, nil, nil, nil)

var describeDevice* = Call_DescribeDevice_402656481(name: "describeDevice",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}", validator: validate_DescribeDevice_402656482,
    base: "/", makeUrl: url_DescribeDevice_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FinalizeDeviceClaim_402656495 = ref object of OpenApiRestCall_402656038
proc url_FinalizeDeviceClaim_402656497(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FinalizeDeviceClaim_402656496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656498 = path.getOrDefault("deviceId")
  valid_402656498 = validateParameter(valid_402656498, JString, required = true,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "deviceId", valid_402656498
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656499 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Security-Token", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Signature")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Signature", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Algorithm", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Date")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Date", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Credential")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Credential", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656507: Call_FinalizeDeviceClaim_402656495;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
                                                                                         ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
                                                                                         ##  and finalizing the claim. For a device of type button, a device event can
                                                                                         ##  be published by simply clicking the device.</p>
                                                                                         ##  </note>
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_FinalizeDeviceClaim_402656495; deviceId: string;
           body: JsonNode): Recallable =
  ## finalizeDeviceClaim
  ## <p>Given a device ID, finalizes the claim request for the associated device.</p><note>
                        ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
                        ##  and finalizing the claim. For a device of type button, a device event can
                        ##  be published by simply clicking the device.</p>
                        ##  </note>
  ##   deviceId: string (required)
                                   ##           : The unique identifier of the device.
  ##   
                                                                                      ## body: JObject (required)
  var path_402656509 = newJObject()
  var body_402656510 = newJObject()
  add(path_402656509, "deviceId", newJString(deviceId))
  if body != nil:
    body_402656510 = body
  result = call_402656508.call(path_402656509, nil, nil, nil, body_402656510)

var finalizeDeviceClaim* = Call_FinalizeDeviceClaim_402656495(
    name: "finalizeDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/finalize-claim",
    validator: validate_FinalizeDeviceClaim_402656496, base: "/",
    makeUrl: url_FinalizeDeviceClaim_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeDeviceMethod_402656525 = ref object of OpenApiRestCall_402656038
proc url_InvokeDeviceMethod_402656527(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeDeviceMethod_402656526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Given a device ID, issues a request to invoke a named device method (with possible
                ##  parameters). See the "Example POST" code snippet below.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656528 = path.getOrDefault("deviceId")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true,
                                      default = nil)
  if valid_402656528 != nil:
    section.add "deviceId", valid_402656528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656537: Call_InvokeDeviceMethod_402656525;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Given a device ID, issues a request to invoke a named device method (with possible
                                                                                         ##  parameters). See the "Example POST" code snippet below.
                                                                                         ## 
  let valid = call_402656537.validator(path, query, header, formData, body, _)
  let scheme = call_402656537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656537.makeUrl(scheme.get, call_402656537.host, call_402656537.base,
                                   call_402656537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656537, uri, valid, _)

proc call*(call_402656538: Call_InvokeDeviceMethod_402656525; deviceId: string;
           body: JsonNode): Recallable =
  ## invokeDeviceMethod
  ## Given a device ID, issues a request to invoke a named device method (with possible
                       ##  parameters). See the "Example POST" code snippet below.
  ##   
                                                                                  ## deviceId: string (required)
                                                                                  ##           
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## unique 
                                                                                  ## identifier 
                                                                                  ## of 
                                                                                  ## the 
                                                                                  ## device.
  ##   
                                                                                            ## body: JObject (required)
  var path_402656539 = newJObject()
  var body_402656540 = newJObject()
  add(path_402656539, "deviceId", newJString(deviceId))
  if body != nil:
    body_402656540 = body
  result = call_402656538.call(path_402656539, nil, nil, nil, body_402656540)

var invokeDeviceMethod* = Call_InvokeDeviceMethod_402656525(
    name: "invokeDeviceMethod", meth: HttpMethod.HttpPost,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods",
    validator: validate_InvokeDeviceMethod_402656526, base: "/",
    makeUrl: url_InvokeDeviceMethod_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceMethods_402656511 = ref object of OpenApiRestCall_402656038
proc url_GetDeviceMethods_402656513(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceMethods_402656512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Given a device ID, returns the invokable methods associated with the device.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656514 = path.getOrDefault("deviceId")
  valid_402656514 = validateParameter(valid_402656514, JString, required = true,
                                      default = nil)
  if valid_402656514 != nil:
    section.add "deviceId", valid_402656514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656522: Call_GetDeviceMethods_402656511;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Given a device ID, returns the invokable methods associated with the device.
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_GetDeviceMethods_402656511; deviceId: string): Recallable =
  ## getDeviceMethods
  ## Given a device ID, returns the invokable methods associated with the device.
  ##   
                                                                                 ## deviceId: string (required)
                                                                                 ##           
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## unique 
                                                                                 ## identifier 
                                                                                 ## of 
                                                                                 ## the 
                                                                                 ## device.
  var path_402656524 = newJObject()
  add(path_402656524, "deviceId", newJString(deviceId))
  result = call_402656523.call(path_402656524, nil, nil, nil, nil)

var getDeviceMethods* = Call_GetDeviceMethods_402656511(
    name: "getDeviceMethods", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/methods", validator: validate_GetDeviceMethods_402656512,
    base: "/", makeUrl: url_GetDeviceMethods_402656513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDeviceClaim_402656541 = ref object of OpenApiRestCall_402656038
proc url_InitiateDeviceClaim_402656543(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InitiateDeviceClaim_402656542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656544 = path.getOrDefault("deviceId")
  valid_402656544 = validateParameter(valid_402656544, JString, required = true,
                                      default = nil)
  if valid_402656544 != nil:
    section.add "deviceId", valid_402656544
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656545 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Security-Token", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Signature")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Signature", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Algorithm", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Date")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Date", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Credential")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Credential", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656552: Call_InitiateDeviceClaim_402656541;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
                                                                                         ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
                                                                                         ##  and finalizing the claim. For a device of type button, a device event can
                                                                                         ##  be published by simply clicking the device.</p>
                                                                                         ##  </note>
                                                                                         ## 
  let valid = call_402656552.validator(path, query, header, formData, body, _)
  let scheme = call_402656552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656552.makeUrl(scheme.get, call_402656552.host, call_402656552.base,
                                   call_402656552.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656552, uri, valid, _)

proc call*(call_402656553: Call_InitiateDeviceClaim_402656541; deviceId: string): Recallable =
  ## initiateDeviceClaim
  ## <p>Given a device ID, initiates a claim request for the associated device.</p><note>
                        ##  <p>Claiming a device consists of initiating a claim, then publishing a device event,
                        ##  and finalizing the claim. For a device of type button, a device event can
                        ##  be published by simply clicking the device.</p>
                        ##  </note>
  ##   deviceId: string (required)
                                   ##           : The unique identifier of the device.
  var path_402656554 = newJObject()
  add(path_402656554, "deviceId", newJString(deviceId))
  result = call_402656553.call(path_402656554, nil, nil, nil, nil)

var initiateDeviceClaim* = Call_InitiateDeviceClaim_402656541(
    name: "initiateDeviceClaim", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/initiate-claim",
    validator: validate_InitiateDeviceClaim_402656542, base: "/",
    makeUrl: url_InitiateDeviceClaim_402656543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_402656555 = ref object of OpenApiRestCall_402656038
proc url_ListDeviceEvents_402656557(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/devices/"),
                 (kind: VariableSegment, value: "deviceId"), (
        kind: ConstantSegment, value: "/events#fromTimeStamp&toTimeStamp")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeviceEvents_402656556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
                ##  array of events for the device.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656558 = path.getOrDefault("deviceId")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true,
                                      default = nil)
  if valid_402656558 != nil:
    section.add "deviceId", valid_402656558
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return per request. If not set, a default value of
                                  ##  
                                  ## 100 is used.
  ##   toTimeStamp: JString (required)
                                                 ##              : The end date for the device event query, in ISO8061 format. For example,
                                                 ##  
                                                 ## 2018-03-28T15:45:12.880Z
                                                 ##  
  ##   nextToken: JString
                                                     ##            : The token to retrieve the next set of results.
  ##   
                                                                                                                   ## fromTimeStamp: JString (required)
                                                                                                                   ##                
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## start 
                                                                                                                   ## date 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## device 
                                                                                                                   ## event 
                                                                                                                   ## query, 
                                                                                                                   ## in 
                                                                                                                   ## ISO8061 
                                                                                                                   ## format. 
                                                                                                                   ## For 
                                                                                                                   ## example,
                                                                                                                   ##  
                                                                                                                   ## 2018-03-28T15:45:12.880Z
                                                                                                                   ##  
  section = newJObject()
  var valid_402656559 = query.getOrDefault("maxResults")
  valid_402656559 = validateParameter(valid_402656559, JInt, required = false,
                                      default = nil)
  if valid_402656559 != nil:
    section.add "maxResults", valid_402656559
  assert query != nil,
         "query argument is necessary due to required `toTimeStamp` field"
  var valid_402656560 = query.getOrDefault("toTimeStamp")
  valid_402656560 = validateParameter(valid_402656560, JString, required = true,
                                      default = nil)
  if valid_402656560 != nil:
    section.add "toTimeStamp", valid_402656560
  var valid_402656561 = query.getOrDefault("nextToken")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "nextToken", valid_402656561
  var valid_402656562 = query.getOrDefault("fromTimeStamp")
  valid_402656562 = validateParameter(valid_402656562, JString, required = true,
                                      default = nil)
  if valid_402656562 != nil:
    section.add "fromTimeStamp", valid_402656562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656563 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Security-Token", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Signature")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Signature", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Algorithm", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Date")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Date", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Credential")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Credential", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656570: Call_ListDeviceEvents_402656555;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Using a device ID, returns a DeviceEventsResponse object containing an
                                                                                         ##  array of events for the device.
                                                                                         ## 
  let valid = call_402656570.validator(path, query, header, formData, body, _)
  let scheme = call_402656570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656570.makeUrl(scheme.get, call_402656570.host, call_402656570.base,
                                   call_402656570.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656570, uri, valid, _)

proc call*(call_402656571: Call_ListDeviceEvents_402656555; deviceId: string;
           toTimeStamp: string; fromTimeStamp: string; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listDeviceEvents
  ## Using a device ID, returns a DeviceEventsResponse object containing an
                     ##  array of events for the device.
  ##   deviceId: string (required)
                                                        ##           : The unique identifier of the device.
  ##   
                                                                                                           ## maxResults: int
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## maximum 
                                                                                                           ## number 
                                                                                                           ## of 
                                                                                                           ## results 
                                                                                                           ## to 
                                                                                                           ## return 
                                                                                                           ## per 
                                                                                                           ## request. 
                                                                                                           ## If 
                                                                                                           ## not 
                                                                                                           ## set, 
                                                                                                           ## a 
                                                                                                           ## default 
                                                                                                           ## value 
                                                                                                           ## of
                                                                                                           ##  
                                                                                                           ## 100 
                                                                                                           ## is 
                                                                                                           ## used.
  ##   
                                                                                                                   ## toTimeStamp: string (required)
                                                                                                                   ##              
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## end 
                                                                                                                   ## date 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## device 
                                                                                                                   ## event 
                                                                                                                   ## query, 
                                                                                                                   ## in 
                                                                                                                   ## ISO8061 
                                                                                                                   ## format. 
                                                                                                                   ## For 
                                                                                                                   ## example,
                                                                                                                   ##  
                                                                                                                   ## 2018-03-28T15:45:12.880Z
                                                                                                                   ##  
  ##   
                                                                                                                       ## nextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## token 
                                                                                                                       ## to 
                                                                                                                       ## retrieve 
                                                                                                                       ## the 
                                                                                                                       ## next 
                                                                                                                       ## set 
                                                                                                                       ## of 
                                                                                                                       ## results.
  ##   
                                                                                                                                  ## fromTimeStamp: string (required)
                                                                                                                                  ##                
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## start 
                                                                                                                                  ## date 
                                                                                                                                  ## for 
                                                                                                                                  ## the 
                                                                                                                                  ## device 
                                                                                                                                  ## event 
                                                                                                                                  ## query, 
                                                                                                                                  ## in 
                                                                                                                                  ## ISO8061 
                                                                                                                                  ## format. 
                                                                                                                                  ## For 
                                                                                                                                  ## example,
                                                                                                                                  ##  
                                                                                                                                  ## 2018-03-28T15:45:12.880Z
                                                                                                                                  ##  
  var path_402656572 = newJObject()
  var query_402656573 = newJObject()
  add(path_402656572, "deviceId", newJString(deviceId))
  add(query_402656573, "maxResults", newJInt(maxResults))
  add(query_402656573, "toTimeStamp", newJString(toTimeStamp))
  add(query_402656573, "nextToken", newJString(nextToken))
  add(query_402656573, "fromTimeStamp", newJString(fromTimeStamp))
  result = call_402656571.call(path_402656572, query_402656573, nil, nil, nil)

var listDeviceEvents* = Call_ListDeviceEvents_402656555(
    name: "listDeviceEvents", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/events#fromTimeStamp&toTimeStamp",
    validator: validate_ListDeviceEvents_402656556, base: "/",
    makeUrl: url_ListDeviceEvents_402656557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevices_402656574 = ref object of OpenApiRestCall_402656038
proc url_ListDevices_402656576(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevices_402656575(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the 1-Click compatible devices associated with your AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceType: JString
                                  ##             : The type of the device, such as "button".
  ##   
                                                                                            ## maxResults: JInt
                                                                                            ##             
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## maximum 
                                                                                            ## number 
                                                                                            ## of 
                                                                                            ## results 
                                                                                            ## to 
                                                                                            ## return 
                                                                                            ## per 
                                                                                            ## request. 
                                                                                            ## If 
                                                                                            ## not 
                                                                                            ## set, 
                                                                                            ## a 
                                                                                            ## default 
                                                                                            ## value 
                                                                                            ## of
                                                                                            ##  
                                                                                            ## 100 
                                                                                            ## is 
                                                                                            ## used.
  ##   
                                                                                                    ## nextToken: JString
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## token 
                                                                                                    ## to 
                                                                                                    ## retrieve 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results.
  section = newJObject()
  var valid_402656577 = query.getOrDefault("deviceType")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "deviceType", valid_402656577
  var valid_402656578 = query.getOrDefault("maxResults")
  valid_402656578 = validateParameter(valid_402656578, JInt, required = false,
                                      default = nil)
  if valid_402656578 != nil:
    section.add "maxResults", valid_402656578
  var valid_402656579 = query.getOrDefault("nextToken")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "nextToken", valid_402656579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656587: Call_ListDevices_402656574; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the 1-Click compatible devices associated with your AWS account.
                                                                                         ## 
  let valid = call_402656587.validator(path, query, header, formData, body, _)
  let scheme = call_402656587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656587.makeUrl(scheme.get, call_402656587.host, call_402656587.base,
                                   call_402656587.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656587, uri, valid, _)

proc call*(call_402656588: Call_ListDevices_402656574; deviceType: string = "";
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDevices
  ## Lists the 1-Click compatible devices associated with your AWS account.
  ##   
                                                                           ## deviceType: string
                                                                           ##             
                                                                           ## : 
                                                                           ## The 
                                                                           ## type 
                                                                           ## of 
                                                                           ## the 
                                                                           ## device, 
                                                                           ## such 
                                                                           ## as 
                                                                           ## "button".
  ##   
                                                                                       ## maxResults: int
                                                                                       ##             
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## maximum 
                                                                                       ## number 
                                                                                       ## of 
                                                                                       ## results 
                                                                                       ## to 
                                                                                       ## return 
                                                                                       ## per 
                                                                                       ## request. 
                                                                                       ## If 
                                                                                       ## not 
                                                                                       ## set, 
                                                                                       ## a 
                                                                                       ## default 
                                                                                       ## value 
                                                                                       ## of
                                                                                       ##  
                                                                                       ## 100 
                                                                                       ## is 
                                                                                       ## used.
  ##   
                                                                                               ## nextToken: string
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## token 
                                                                                               ## to 
                                                                                               ## retrieve 
                                                                                               ## the 
                                                                                               ## next 
                                                                                               ## set 
                                                                                               ## of 
                                                                                               ## results.
  var query_402656589 = newJObject()
  add(query_402656589, "deviceType", newJString(deviceType))
  add(query_402656589, "maxResults", newJInt(maxResults))
  add(query_402656589, "nextToken", newJString(nextToken))
  result = call_402656588.call(nil, query_402656589, nil, nil, nil)

var listDevices* = Call_ListDevices_402656574(name: "listDevices",
    meth: HttpMethod.HttpGet, host: "devices.iot1click.amazonaws.com",
    route: "/devices", validator: validate_ListDevices_402656575, base: "/",
    makeUrl: url_ListDevices_402656576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656604 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656606(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656605(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656607 = path.getOrDefault("resource-arn")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "resource-arn", valid_402656607
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Security-Token", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Signature")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Signature", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Algorithm", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Date")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Date", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Credential")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Credential", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656616: Call_TagResource_402656604; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
                                                                                         ##  resource.
                                                                                         ## 
  let valid = call_402656616.validator(path, query, header, formData, body, _)
  let scheme = call_402656616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656616.makeUrl(scheme.get, call_402656616.host, call_402656616.base,
                                   call_402656616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656616, uri, valid, _)

proc call*(call_402656617: Call_TagResource_402656604; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds or updates the tags associated with the resource ARN. See <a href="https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-appendix.html#1click-limits">AWS IoT 1-Click Service Limits</a> for the maximum number of tags allowed per
                ##  resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The ARN of the resource.
  var path_402656618 = newJObject()
  var body_402656619 = newJObject()
  if body != nil:
    body_402656619 = body
  add(path_402656618, "resource-arn", newJString(resourceArn))
  result = call_402656617.call(path_402656618, nil, nil, nil, body_402656619)

var tagResource* = Call_TagResource_402656604(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_402656605,
    base: "/", makeUrl: url_TagResource_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656590 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656592(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656593 = path.getOrDefault("resource-arn")
  valid_402656593 = validateParameter(valid_402656593, JString, required = true,
                                      default = nil)
  if valid_402656593 != nil:
    section.add "resource-arn", valid_402656593
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656594 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Security-Token", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Signature")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Signature", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Algorithm", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Date")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Date", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Credential")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Credential", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656601: Call_ListTagsForResource_402656590;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags associated with the specified resource ARN.
                                                                                         ## 
  let valid = call_402656601.validator(path, query, header, formData, body, _)
  let scheme = call_402656601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656601.makeUrl(scheme.get, call_402656601.host, call_402656601.base,
                                   call_402656601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656601, uri, valid, _)

proc call*(call_402656602: Call_ListTagsForResource_402656590;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags associated with the specified resource ARN.
  ##   resourceArn: string (required)
                                                               ##              : The ARN of the resource.
  var path_402656603 = newJObject()
  add(path_402656603, "resource-arn", newJString(resourceArn))
  result = call_402656602.call(path_402656603, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656590(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "devices.iot1click.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402656591, base: "/",
    makeUrl: url_ListTagsForResource_402656592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnclaimDevice_402656620 = ref object of OpenApiRestCall_402656038
proc url_UnclaimDevice_402656622(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnclaimDevice_402656621(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disassociates a device from your AWS account using its device ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656623 = path.getOrDefault("deviceId")
  valid_402656623 = validateParameter(valid_402656623, JString, required = true,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "deviceId", valid_402656623
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656624 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Security-Token", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Signature")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Signature", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Algorithm", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Date")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Date", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Credential")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Credential", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656631: Call_UnclaimDevice_402656620; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a device from your AWS account using its device ID.
                                                                                         ## 
  let valid = call_402656631.validator(path, query, header, formData, body, _)
  let scheme = call_402656631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656631.makeUrl(scheme.get, call_402656631.host, call_402656631.base,
                                   call_402656631.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656631, uri, valid, _)

proc call*(call_402656632: Call_UnclaimDevice_402656620; deviceId: string): Recallable =
  ## unclaimDevice
  ## Disassociates a device from your AWS account using its device ID.
  ##   deviceId: string (required)
                                                                      ##           : The unique identifier of the device.
  var path_402656633 = newJObject()
  add(path_402656633, "deviceId", newJString(deviceId))
  result = call_402656632.call(path_402656633, nil, nil, nil, nil)

var unclaimDevice* = Call_UnclaimDevice_402656620(name: "unclaimDevice",
    meth: HttpMethod.HttpPut, host: "devices.iot1click.amazonaws.com",
    route: "/devices/{deviceId}/unclaim", validator: validate_UnclaimDevice_402656621,
    base: "/", makeUrl: url_UnclaimDevice_402656622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656634 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656636(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656635(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656637 = path.getOrDefault("resource-arn")
  valid_402656637 = validateParameter(valid_402656637, JString, required = true,
                                      default = nil)
  if valid_402656637 != nil:
    section.add "resource-arn", valid_402656637
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A collections of tag keys. For example, {"key1","key2"}
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656638 = query.getOrDefault("tagKeys")
  valid_402656638 = validateParameter(valid_402656638, JArray, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "tagKeys", valid_402656638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656639 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Security-Token", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Signature")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Signature", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Algorithm", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Date")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Date", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Credential")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Credential", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656646: Call_UntagResource_402656634; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
                                                                                         ##  resource ARN.
                                                                                         ## 
  let valid = call_402656646.validator(path, query, header, formData, body, _)
  let scheme = call_402656646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656646.makeUrl(scheme.get, call_402656646.host, call_402656646.base,
                                   call_402656646.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656646, uri, valid, _)

proc call*(call_402656647: Call_UntagResource_402656634; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Using tag keys, deletes the tags (key/value pairs) associated with the specified
                  ##  resource ARN.
  ##   tagKeys: JArray (required)
                                   ##          : A collections of tag keys. For example, {"key1","key2"}
  ##   
                                                                                                        ## resourceArn: string (required)
                                                                                                        ##              
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## ARN 
                                                                                                        ## of 
                                                                                                        ## the 
                                                                                                        ## resource.
  var path_402656648 = newJObject()
  var query_402656649 = newJObject()
  if tagKeys != nil:
    query_402656649.add "tagKeys", tagKeys
  add(path_402656648, "resource-arn", newJString(resourceArn))
  result = call_402656647.call(path_402656648, query_402656649, nil, nil, nil)

var untagResource* = Call_UntagResource_402656634(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "devices.iot1click.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402656635,
    base: "/", makeUrl: url_UntagResource_402656636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceState_402656650 = ref object of OpenApiRestCall_402656038
proc url_UpdateDeviceState_402656652(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeviceState_402656651(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Using a Boolean value (true or false), this operation
                ##  enables or disables the device given a device ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The unique identifier of the device.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656653 = path.getOrDefault("deviceId")
  valid_402656653 = validateParameter(valid_402656653, JString, required = true,
                                      default = nil)
  if valid_402656653 != nil:
    section.add "deviceId", valid_402656653
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656654 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Security-Token", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Signature")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Signature", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Algorithm", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Date")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Date", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Credential")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Credential", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656662: Call_UpdateDeviceState_402656650;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Using a Boolean value (true or false), this operation
                                                                                         ##  enables or disables the device given a device ID.
                                                                                         ## 
  let valid = call_402656662.validator(path, query, header, formData, body, _)
  let scheme = call_402656662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656662.makeUrl(scheme.get, call_402656662.host, call_402656662.base,
                                   call_402656662.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656662, uri, valid, _)

proc call*(call_402656663: Call_UpdateDeviceState_402656650; deviceId: string;
           body: JsonNode): Recallable =
  ## updateDeviceState
  ## Using a Boolean value (true or false), this operation
                      ##  enables or disables the device given a device ID.
  ##   
                                                                           ## deviceId: string (required)
                                                                           ##           
                                                                           ## : 
                                                                           ## The 
                                                                           ## unique 
                                                                           ## identifier 
                                                                           ## of 
                                                                           ## the 
                                                                           ## device.
  ##   
                                                                                     ## body: JObject (required)
  var path_402656664 = newJObject()
  var body_402656665 = newJObject()
  add(path_402656664, "deviceId", newJString(deviceId))
  if body != nil:
    body_402656665 = body
  result = call_402656663.call(path_402656664, nil, nil, nil, body_402656665)

var updateDeviceState* = Call_UpdateDeviceState_402656650(
    name: "updateDeviceState", meth: HttpMethod.HttpPut,
    host: "devices.iot1click.amazonaws.com", route: "/devices/{deviceId}/state",
    validator: validate_UpdateDeviceState_402656651, base: "/",
    makeUrl: url_UpdateDeviceState_402656652,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}