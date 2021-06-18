
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT 1-Click Projects Service
## version: 2018-05-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The AWS IoT 1-Click Projects API Reference
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "projects.iot1click.ap-northeast-1.amazonaws.com", "ap-southeast-1": "projects.iot1click.ap-southeast-1.amazonaws.com", "us-west-2": "projects.iot1click.us-west-2.amazonaws.com", "eu-west-2": "projects.iot1click.eu-west-2.amazonaws.com", "ap-northeast-3": "projects.iot1click.ap-northeast-3.amazonaws.com", "eu-central-1": "projects.iot1click.eu-central-1.amazonaws.com", "us-east-2": "projects.iot1click.us-east-2.amazonaws.com", "us-east-1": "projects.iot1click.us-east-1.amazonaws.com", "cn-northwest-1": "projects.iot1click.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "projects.iot1click.ap-south-1.amazonaws.com", "eu-north-1": "projects.iot1click.eu-north-1.amazonaws.com", "ap-northeast-2": "projects.iot1click.ap-northeast-2.amazonaws.com", "us-west-1": "projects.iot1click.us-west-1.amazonaws.com", "us-gov-east-1": "projects.iot1click.us-gov-east-1.amazonaws.com", "eu-west-3": "projects.iot1click.eu-west-3.amazonaws.com", "cn-north-1": "projects.iot1click.cn-north-1.amazonaws.com.cn", "sa-east-1": "projects.iot1click.sa-east-1.amazonaws.com", "eu-west-1": "projects.iot1click.eu-west-1.amazonaws.com", "us-gov-west-1": "projects.iot1click.us-gov-west-1.amazonaws.com", "ap-southeast-2": "projects.iot1click.ap-southeast-2.amazonaws.com", "ca-central-1": "projects.iot1click.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "projects.iot1click.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "projects.iot1click.ap-southeast-1.amazonaws.com",
      "us-west-2": "projects.iot1click.us-west-2.amazonaws.com",
      "eu-west-2": "projects.iot1click.eu-west-2.amazonaws.com",
      "ap-northeast-3": "projects.iot1click.ap-northeast-3.amazonaws.com",
      "eu-central-1": "projects.iot1click.eu-central-1.amazonaws.com",
      "us-east-2": "projects.iot1click.us-east-2.amazonaws.com",
      "us-east-1": "projects.iot1click.us-east-1.amazonaws.com",
      "cn-northwest-1": "projects.iot1click.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "projects.iot1click.ap-south-1.amazonaws.com",
      "eu-north-1": "projects.iot1click.eu-north-1.amazonaws.com",
      "ap-northeast-2": "projects.iot1click.ap-northeast-2.amazonaws.com",
      "us-west-1": "projects.iot1click.us-west-1.amazonaws.com",
      "us-gov-east-1": "projects.iot1click.us-gov-east-1.amazonaws.com",
      "eu-west-3": "projects.iot1click.eu-west-3.amazonaws.com",
      "cn-north-1": "projects.iot1click.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "projects.iot1click.sa-east-1.amazonaws.com",
      "eu-west-1": "projects.iot1click.eu-west-1.amazonaws.com",
      "us-gov-west-1": "projects.iot1click.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "projects.iot1click.ap-southeast-2.amazonaws.com",
      "ca-central-1": "projects.iot1click.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iot1click-projects"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateDeviceWithPlacement_402656288 = ref object of OpenApiRestCall_402656038
proc url_AssociateDeviceWithPlacement_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  assert "deviceTemplateName" in path,
         "`deviceTemplateName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName"),
                 (kind: ConstantSegment, value: "/devices/"),
                 (kind: VariableSegment, value: "deviceTemplateName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateDeviceWithPlacement_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates a physical device with a placement.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project containing the placement in which to associate the device.
  ##   
                                                                                                                                     ## placementName: JString (required)
                                                                                                                                     ##                
                                                                                                                                     ## : 
                                                                                                                                     ## The 
                                                                                                                                     ## name 
                                                                                                                                     ## of 
                                                                                                                                     ## the 
                                                                                                                                     ## placement 
                                                                                                                                     ## in 
                                                                                                                                     ## which 
                                                                                                                                     ## to 
                                                                                                                                     ## associate 
                                                                                                                                     ## the 
                                                                                                                                     ## device.
  ##   
                                                                                                                                               ## deviceTemplateName: JString (required)
                                                                                                                                               ##                     
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## device 
                                                                                                                                               ## template 
                                                                                                                                               ## name 
                                                                                                                                               ## to 
                                                                                                                                               ## associate 
                                                                                                                                               ## with 
                                                                                                                                               ## the 
                                                                                                                                               ## device 
                                                                                                                                               ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656383 = path.getOrDefault("projectName")
  valid_402656383 = validateParameter(valid_402656383, JString, required = true,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "projectName", valid_402656383
  var valid_402656384 = path.getOrDefault("placementName")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true,
                                      default = nil)
  if valid_402656384 != nil:
    section.add "placementName", valid_402656384
  var valid_402656385 = path.getOrDefault("deviceTemplateName")
  valid_402656385 = validateParameter(valid_402656385, JString, required = true,
                                      default = nil)
  if valid_402656385 != nil:
    section.add "deviceTemplateName", valid_402656385
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
  var valid_402656386 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Security-Token", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Signature")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Signature", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Algorithm", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Date")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Date", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Credential")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Credential", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656392
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

proc call*(call_402656407: Call_AssociateDeviceWithPlacement_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a physical device with a placement.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_AssociateDeviceWithPlacement_402656288;
           projectName: string; placementName: string; body: JsonNode;
           deviceTemplateName: string): Recallable =
  ## associateDeviceWithPlacement
  ## Associates a physical device with a placement.
  ##   projectName: string (required)
                                                   ##              : The name of the project containing the placement in which to associate the device.
  ##   
                                                                                                                                                       ## placementName: string (required)
                                                                                                                                                       ##                
                                                                                                                                                       ## : 
                                                                                                                                                       ## The 
                                                                                                                                                       ## name 
                                                                                                                                                       ## of 
                                                                                                                                                       ## the 
                                                                                                                                                       ## placement 
                                                                                                                                                       ## in 
                                                                                                                                                       ## which 
                                                                                                                                                       ## to 
                                                                                                                                                       ## associate 
                                                                                                                                                       ## the 
                                                                                                                                                       ## device.
  ##   
                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                            ## deviceTemplateName: string (required)
                                                                                                                                                                                            ##                     
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## The 
                                                                                                                                                                                            ## device 
                                                                                                                                                                                            ## template 
                                                                                                                                                                                            ## name 
                                                                                                                                                                                            ## to 
                                                                                                                                                                                            ## associate 
                                                                                                                                                                                            ## with 
                                                                                                                                                                                            ## the 
                                                                                                                                                                                            ## device 
                                                                                                                                                                                            ## ID.
  var path_402656457 = newJObject()
  var body_402656459 = newJObject()
  add(path_402656457, "projectName", newJString(projectName))
  add(path_402656457, "placementName", newJString(placementName))
  if body != nil:
    body_402656459 = body
  add(path_402656457, "deviceTemplateName", newJString(deviceTemplateName))
  result = call_402656456.call(path_402656457, nil, nil, nil, body_402656459)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_402656288(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_402656289, base: "/",
    makeUrl: url_AssociateDeviceWithPlacement_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_402656485 = ref object of OpenApiRestCall_402656038
proc url_DisassociateDeviceFromPlacement_402656487(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  assert "deviceTemplateName" in path,
         "`deviceTemplateName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName"),
                 (kind: ConstantSegment, value: "/devices/"),
                 (kind: VariableSegment, value: "deviceTemplateName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateDeviceFromPlacement_402656486(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a physical device from a placement.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project that contains the placement.
  ##   
                                                                                                       ## placementName: JString (required)
                                                                                                       ##                
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## name 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## placement 
                                                                                                       ## that 
                                                                                                       ## the 
                                                                                                       ## device 
                                                                                                       ## should 
                                                                                                       ## be 
                                                                                                       ## removed 
                                                                                                       ## from.
  ##   
                                                                                                               ## deviceTemplateName: JString (required)
                                                                                                               ##                     
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## device 
                                                                                                               ## ID 
                                                                                                               ## that 
                                                                                                               ## should 
                                                                                                               ## be 
                                                                                                               ## removed 
                                                                                                               ## from 
                                                                                                               ## the 
                                                                                                               ## placement.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656488 = path.getOrDefault("projectName")
  valid_402656488 = validateParameter(valid_402656488, JString, required = true,
                                      default = nil)
  if valid_402656488 != nil:
    section.add "projectName", valid_402656488
  var valid_402656489 = path.getOrDefault("placementName")
  valid_402656489 = validateParameter(valid_402656489, JString, required = true,
                                      default = nil)
  if valid_402656489 != nil:
    section.add "placementName", valid_402656489
  var valid_402656490 = path.getOrDefault("deviceTemplateName")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "deviceTemplateName", valid_402656490
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
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_DisassociateDeviceFromPlacement_402656485;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a physical device from a placement.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_DisassociateDeviceFromPlacement_402656485;
           projectName: string; placementName: string;
           deviceTemplateName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   projectName: string (required)
                                                ##              : The name of the project that contains the placement.
  ##   
                                                                                                                      ## placementName: string (required)
                                                                                                                      ##                
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## name 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## placement 
                                                                                                                      ## that 
                                                                                                                      ## the 
                                                                                                                      ## device 
                                                                                                                      ## should 
                                                                                                                      ## be 
                                                                                                                      ## removed 
                                                                                                                      ## from.
  ##   
                                                                                                                              ## deviceTemplateName: string (required)
                                                                                                                              ##                     
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## device 
                                                                                                                              ## ID 
                                                                                                                              ## that 
                                                                                                                              ## should 
                                                                                                                              ## be 
                                                                                                                              ## removed 
                                                                                                                              ## from 
                                                                                                                              ## the 
                                                                                                                              ## placement.
  var path_402656500 = newJObject()
  add(path_402656500, "projectName", newJString(projectName))
  add(path_402656500, "placementName", newJString(placementName))
  add(path_402656500, "deviceTemplateName", newJString(deviceTemplateName))
  result = call_402656499.call(path_402656500, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_402656485(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_402656486, base: "/",
    makeUrl: url_DisassociateDeviceFromPlacement_402656487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_402656518 = ref object of OpenApiRestCall_402656038
proc url_CreatePlacement_402656520(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePlacement_402656519(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an empty placement.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project in which to create the placement.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656521 = path.getOrDefault("projectName")
  valid_402656521 = validateParameter(valid_402656521, JString, required = true,
                                      default = nil)
  if valid_402656521 != nil:
    section.add "projectName", valid_402656521
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
  var valid_402656522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Security-Token", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Signature")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Signature", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Algorithm", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Date")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Date", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Credential")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Credential", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656528
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

proc call*(call_402656530: Call_CreatePlacement_402656518; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an empty placement.
                                                                                         ## 
  let valid = call_402656530.validator(path, query, header, formData, body, _)
  let scheme = call_402656530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656530.makeUrl(scheme.get, call_402656530.host, call_402656530.base,
                                   call_402656530.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656530, uri, valid, _)

proc call*(call_402656531: Call_CreatePlacement_402656518; projectName: string;
           body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
                                ##              : The name of the project in which to create the placement.
  ##   
                                                                                                           ## body: JObject (required)
  var path_402656532 = newJObject()
  var body_402656533 = newJObject()
  add(path_402656532, "projectName", newJString(projectName))
  if body != nil:
    body_402656533 = body
  result = call_402656531.call(path_402656532, nil, nil, nil, body_402656533)

var createPlacement* = Call_CreatePlacement_402656518(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_402656519, base: "/",
    makeUrl: url_CreatePlacement_402656520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_402656501 = ref object of OpenApiRestCall_402656038
proc url_ListPlacements_402656503(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPlacements_402656502(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the placement(s) of a project.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The project containing the placements to be listed.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656504 = path.getOrDefault("projectName")
  valid_402656504 = validateParameter(valid_402656504, JString, required = true,
                                      default = nil)
  if valid_402656504 != nil:
    section.add "projectName", valid_402656504
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
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
  var valid_402656505 = query.getOrDefault("maxResults")
  valid_402656505 = validateParameter(valid_402656505, JInt, required = false,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "maxResults", valid_402656505
  var valid_402656506 = query.getOrDefault("nextToken")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "nextToken", valid_402656506
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
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656514: Call_ListPlacements_402656501; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the placement(s) of a project.
                                                                                         ## 
  let valid = call_402656514.validator(path, query, header, formData, body, _)
  let scheme = call_402656514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656514.makeUrl(scheme.get, call_402656514.host, call_402656514.base,
                                   call_402656514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656514, uri, valid, _)

proc call*(call_402656515: Call_ListPlacements_402656501; projectName: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   projectName: string (required)
                                         ##              : The project containing the placements to be listed.
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
  var path_402656516 = newJObject()
  var query_402656517 = newJObject()
  add(path_402656516, "projectName", newJString(projectName))
  add(query_402656517, "maxResults", newJInt(maxResults))
  add(query_402656517, "nextToken", newJString(nextToken))
  result = call_402656515.call(path_402656516, query_402656517, nil, nil, nil)

var listPlacements* = Call_ListPlacements_402656501(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_402656502, base: "/",
    makeUrl: url_ListPlacements_402656503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_402656549 = ref object of OpenApiRestCall_402656038
proc url_CreateProject_402656551(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_402656550(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656552 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Security-Token", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Signature")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Signature", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Algorithm", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Date")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Date", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Credential")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Credential", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656558
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

proc call*(call_402656560: Call_CreateProject_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
                                                                                         ## 
  let valid = call_402656560.validator(path, query, header, formData, body, _)
  let scheme = call_402656560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656560.makeUrl(scheme.get, call_402656560.host, call_402656560.base,
                                   call_402656560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656560, uri, valid, _)

proc call*(call_402656561: Call_CreateProject_402656549; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   
                                                                                                                                                                 ## body: JObject (required)
  var body_402656562 = newJObject()
  if body != nil:
    body_402656562 = body
  result = call_402656561.call(nil, nil, nil, nil, body_402656562)

var createProject* = Call_CreateProject_402656549(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_402656550, base: "/",
    makeUrl: url_CreateProject_402656551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_402656534 = ref object of OpenApiRestCall_402656038
proc url_ListProjects_402656536(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_402656535(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
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
  var valid_402656537 = query.getOrDefault("maxResults")
  valid_402656537 = validateParameter(valid_402656537, JInt, required = false,
                                      default = nil)
  if valid_402656537 != nil:
    section.add "maxResults", valid_402656537
  var valid_402656538 = query.getOrDefault("nextToken")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "nextToken", valid_402656538
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
  var valid_402656539 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Security-Token", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Signature")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Signature", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Algorithm", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Date")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Date", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Credential")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Credential", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_ListProjects_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_ListProjects_402656534; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
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
  var query_402656548 = newJObject()
  add(query_402656548, "maxResults", newJInt(maxResults))
  add(query_402656548, "nextToken", newJString(nextToken))
  result = call_402656547.call(nil, query_402656548, nil, nil, nil)

var listProjects* = Call_ListProjects_402656534(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_402656535, base: "/",
    makeUrl: url_ListProjects_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_402656578 = ref object of OpenApiRestCall_402656038
proc url_UpdatePlacement_402656580(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePlacement_402656579(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project containing the placement to be updated.
  ##   
                                                                                                                  ## placementName: JString (required)
                                                                                                                  ##                
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## name 
                                                                                                                  ## of 
                                                                                                                  ## the 
                                                                                                                  ## placement 
                                                                                                                  ## to 
                                                                                                                  ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656581 = path.getOrDefault("projectName")
  valid_402656581 = validateParameter(valid_402656581, JString, required = true,
                                      default = nil)
  if valid_402656581 != nil:
    section.add "projectName", valid_402656581
  var valid_402656582 = path.getOrDefault("placementName")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true,
                                      default = nil)
  if valid_402656582 != nil:
    section.add "placementName", valid_402656582
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
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_UpdatePlacement_402656578; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_UpdatePlacement_402656578; projectName: string;
           placementName: string; body: JsonNode): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   
                                                                                                          ## projectName: string (required)
                                                                                                          ##              
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## name 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## project 
                                                                                                          ## containing 
                                                                                                          ## the 
                                                                                                          ## placement 
                                                                                                          ## to 
                                                                                                          ## be 
                                                                                                          ## updated.
  ##   
                                                                                                                     ## placementName: string (required)
                                                                                                                     ##                
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## name 
                                                                                                                     ## of 
                                                                                                                     ## the 
                                                                                                                     ## placement 
                                                                                                                     ## to 
                                                                                                                     ## update.
  ##   
                                                                                                                               ## body: JObject (required)
  var path_402656593 = newJObject()
  var body_402656594 = newJObject()
  add(path_402656593, "projectName", newJString(projectName))
  add(path_402656593, "placementName", newJString(placementName))
  if body != nil:
    body_402656594 = body
  result = call_402656592.call(path_402656593, nil, nil, nil, body_402656594)

var updatePlacement* = Call_UpdatePlacement_402656578(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_402656579, base: "/",
    makeUrl: url_UpdatePlacement_402656580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_402656563 = ref object of OpenApiRestCall_402656038
proc url_DescribePlacement_402656565(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePlacement_402656564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a placement in a project.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The project containing the placement to be described.
  ##   
                                                                                                        ## placementName: JString (required)
                                                                                                        ##                
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## name 
                                                                                                        ## of 
                                                                                                        ## the 
                                                                                                        ## placement 
                                                                                                        ## within 
                                                                                                        ## a 
                                                                                                        ## project.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656566 = path.getOrDefault("projectName")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "projectName", valid_402656566
  var valid_402656567 = path.getOrDefault("placementName")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true,
                                      default = nil)
  if valid_402656567 != nil:
    section.add "placementName", valid_402656567
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
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656575: Call_DescribePlacement_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a placement in a project.
                                                                                         ## 
  let valid = call_402656575.validator(path, query, header, formData, body, _)
  let scheme = call_402656575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656575.makeUrl(scheme.get, call_402656575.host, call_402656575.base,
                                   call_402656575.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656575, uri, valid, _)

proc call*(call_402656576: Call_DescribePlacement_402656563;
           projectName: string; placementName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   projectName: string (required)
                                        ##              : The project containing the placement to be described.
  ##   
                                                                                                               ## placementName: string (required)
                                                                                                               ##                
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## name 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## placement 
                                                                                                               ## within 
                                                                                                               ## a 
                                                                                                               ## project.
  var path_402656577 = newJObject()
  add(path_402656577, "projectName", newJString(projectName))
  add(path_402656577, "placementName", newJString(placementName))
  result = call_402656576.call(path_402656577, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_402656563(
    name: "describePlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_402656564, base: "/",
    makeUrl: url_DescribePlacement_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_402656595 = ref object of OpenApiRestCall_402656038
proc url_DeletePlacement_402656597(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePlacement_402656596(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The project containing the empty placement to delete.
  ##   
                                                                                                        ## placementName: JString (required)
                                                                                                        ##                
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## name 
                                                                                                        ## of 
                                                                                                        ## the 
                                                                                                        ## empty 
                                                                                                        ## placement 
                                                                                                        ## to 
                                                                                                        ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656598 = path.getOrDefault("projectName")
  valid_402656598 = validateParameter(valid_402656598, JString, required = true,
                                      default = nil)
  if valid_402656598 != nil:
    section.add "projectName", valid_402656598
  var valid_402656599 = path.getOrDefault("placementName")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true,
                                      default = nil)
  if valid_402656599 != nil:
    section.add "placementName", valid_402656599
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
  var valid_402656600 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Security-Token", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Signature")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Signature", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Algorithm", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Date")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Date", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Credential")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Credential", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656607: Call_DeletePlacement_402656595; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
                                                                                         ## 
  let valid = call_402656607.validator(path, query, header, formData, body, _)
  let scheme = call_402656607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656607.makeUrl(scheme.get, call_402656607.host, call_402656607.base,
                                   call_402656607.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656607, uri, valid, _)

proc call*(call_402656608: Call_DeletePlacement_402656595; projectName: string;
           placementName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   
                                                                                                                                                                                                      ## projectName: string (required)
                                                                                                                                                                                                      ##              
                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                      ## project 
                                                                                                                                                                                                      ## containing 
                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                      ## empty 
                                                                                                                                                                                                      ## placement 
                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                      ## delete.
  ##   
                                                                                                                                                                                                                ## placementName: string (required)
                                                                                                                                                                                                                ##                
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                ## name 
                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## empty 
                                                                                                                                                                                                                ## placement 
                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                ## delete.
  var path_402656609 = newJObject()
  add(path_402656609, "projectName", newJString(projectName))
  add(path_402656609, "placementName", newJString(placementName))
  result = call_402656608.call(path_402656609, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_402656595(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_402656596, base: "/",
    makeUrl: url_DeletePlacement_402656597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_402656624 = ref object of OpenApiRestCall_402656038
proc url_UpdateProject_402656626(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateProject_402656625(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project to be updated.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656627 = path.getOrDefault("projectName")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true,
                                      default = nil)
  if valid_402656627 != nil:
    section.add "projectName", valid_402656627
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
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_UpdateProject_402656624; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_UpdateProject_402656624; projectName: string;
           body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   
                                                                                                                                                                                                                                                                                                                ## projectName: string (required)
                                                                                                                                                                                                                                                                                                                ##              
                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                ## name 
                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                ## project 
                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                ## be 
                                                                                                                                                                                                                                                                                                                ## updated.
  ##   
                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var path_402656638 = newJObject()
  var body_402656639 = newJObject()
  add(path_402656638, "projectName", newJString(projectName))
  if body != nil:
    body_402656639 = body
  result = call_402656637.call(path_402656638, nil, nil, nil, body_402656639)

var updateProject* = Call_UpdateProject_402656624(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_402656625,
    base: "/", makeUrl: url_UpdateProject_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_402656610 = ref object of OpenApiRestCall_402656038
proc url_DescribeProject_402656612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProject_402656611(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an object describing a project.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project to be described.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656613 = path.getOrDefault("projectName")
  valid_402656613 = validateParameter(valid_402656613, JString, required = true,
                                      default = nil)
  if valid_402656613 != nil:
    section.add "projectName", valid_402656613
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
  var valid_402656614 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Security-Token", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Signature")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Signature", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Algorithm", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Date")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Date", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Credential")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Credential", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_DescribeProject_402656610; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an object describing a project.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DescribeProject_402656610; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
                                            ##              : The name of the project to be described.
  var path_402656623 = newJObject()
  add(path_402656623, "projectName", newJString(projectName))
  result = call_402656622.call(path_402656623, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_402656610(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_402656611,
    base: "/", makeUrl: url_DescribeProject_402656612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_402656640 = ref object of OpenApiRestCall_402656038
proc url_DeleteProject_402656642(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProject_402656641(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the empty project to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656643 = path.getOrDefault("projectName")
  valid_402656643 = validateParameter(valid_402656643, JString, required = true,
                                      default = nil)
  if valid_402656643 != nil:
    section.add "projectName", valid_402656643
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
  var valid_402656644 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Security-Token", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Signature")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Signature", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Algorithm", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Date")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Date", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Credential")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Credential", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DeleteProject_402656640; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeleteProject_402656640; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   
                                                                                                                                                                                                   ## projectName: string (required)
                                                                                                                                                                                                   ##              
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## empty 
                                                                                                                                                                                                   ## project 
                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                   ## delete.
  var path_402656653 = newJObject()
  add(path_402656653, "projectName", newJString(projectName))
  result = call_402656652.call(path_402656653, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_402656640(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_402656641,
    base: "/", makeUrl: url_DeleteProject_402656642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_402656654 = ref object of OpenApiRestCall_402656038
proc url_GetDevicesInPlacement_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectName" in path, "`projectName` is a required path parameter"
  assert "placementName" in path, "`placementName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectName"),
                 (kind: ConstantSegment, value: "/placements/"),
                 (kind: VariableSegment, value: "placementName"),
                 (kind: ConstantSegment, value: "/devices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDevicesInPlacement_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an object enumerating the devices in a placement.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
                                 ##              : The name of the project containing the placement.
  ##   
                                                                                                    ## placementName: JString (required)
                                                                                                    ##                
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## name 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## placement 
                                                                                                    ## to 
                                                                                                    ## get 
                                                                                                    ## the 
                                                                                                    ## devices 
                                                                                                    ## from.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectName` field"
  var valid_402656657 = path.getOrDefault("projectName")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "projectName", valid_402656657
  var valid_402656658 = path.getOrDefault("placementName")
  valid_402656658 = validateParameter(valid_402656658, JString, required = true,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "placementName", valid_402656658
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
  var valid_402656659 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Security-Token", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Signature")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Signature", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Algorithm", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Date")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Date", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Credential")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Credential", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_GetDevicesInPlacement_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an object enumerating the devices in a placement.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_GetDevicesInPlacement_402656654;
           projectName: string; placementName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   projectName: string (required)
                                                              ##              : The name of the project containing the placement.
  ##   
                                                                                                                                 ## placementName: string (required)
                                                                                                                                 ##                
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## name 
                                                                                                                                 ## of 
                                                                                                                                 ## the 
                                                                                                                                 ## placement 
                                                                                                                                 ## to 
                                                                                                                                 ## get 
                                                                                                                                 ## the 
                                                                                                                                 ## devices 
                                                                                                                                 ## from.
  var path_402656668 = newJObject()
  add(path_402656668, "projectName", newJString(projectName))
  add(path_402656668, "placementName", newJString(placementName))
  result = call_402656667.call(path_402656668, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_402656654(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_402656655, base: "/",
    makeUrl: url_GetDevicesInPlacement_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656683 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656685(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656684(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The ARN of the resouce for which tag(s) should be added or modified.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656686 = path.getOrDefault("resourceArn")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "resourceArn", valid_402656686
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
  var valid_402656687 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Security-Token", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Signature")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Signature", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Algorithm", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Date")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Date", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Credential")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Credential", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656693
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

proc call*(call_402656695: Call_TagResource_402656683; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
                                                                                         ## 
  let valid = call_402656695.validator(path, query, header, formData, body, _)
  let scheme = call_402656695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656695.makeUrl(scheme.get, call_402656695.host, call_402656695.base,
                                   call_402656695.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656695, uri, valid, _)

proc call*(call_402656696: Call_TagResource_402656683; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   
                                                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                             ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                             ##              
                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                             ## ARN 
                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                             ## resouce 
                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                             ## which 
                                                                                                                                                                                                                                                                                             ## tag(s) 
                                                                                                                                                                                                                                                                                             ## should 
                                                                                                                                                                                                                                                                                             ## be 
                                                                                                                                                                                                                                                                                             ## added 
                                                                                                                                                                                                                                                                                             ## or 
                                                                                                                                                                                                                                                                                             ## modified.
  var path_402656697 = newJObject()
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  add(path_402656697, "resourceArn", newJString(resourceArn))
  result = call_402656696.call(path_402656697, nil, nil, nil, body_402656698)

var tagResource* = Call_TagResource_402656683(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656684,
    base: "/", makeUrl: url_TagResource_402656685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656669 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656671(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The ARN of the resource whose tags you want to list.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656672 = path.getOrDefault("resourceArn")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "resourceArn", valid_402656672
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
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656680: Call_ListTagsForResource_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
                                                                                         ## 
  let valid = call_402656680.validator(path, query, header, formData, body, _)
  let scheme = call_402656680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656680.makeUrl(scheme.get, call_402656680.host, call_402656680.base,
                                   call_402656680.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656680, uri, valid, _)

proc call*(call_402656681: Call_ListTagsForResource_402656669;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   
                                                                                       ## resourceArn: string (required)
                                                                                       ##              
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## ARN 
                                                                                       ## of 
                                                                                       ## the 
                                                                                       ## resource 
                                                                                       ## whose 
                                                                                       ## tags 
                                                                                       ## you 
                                                                                       ## want 
                                                                                       ## to 
                                                                                       ## list.
  var path_402656682 = newJObject()
  add(path_402656682, "resourceArn", newJString(resourceArn))
  result = call_402656681.call(path_402656682, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656669(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656670, base: "/",
    makeUrl: url_ListTagsForResource_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656699 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656701(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656700(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The ARN of the resource whose tag you want to remove.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656702 = path.getOrDefault("resourceArn")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true,
                                      default = nil)
  if valid_402656702 != nil:
    section.add "resourceArn", valid_402656702
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656703 = query.getOrDefault("tagKeys")
  valid_402656703 = validateParameter(valid_402656703, JArray, required = true,
                                      default = nil)
  if valid_402656703 != nil:
    section.add "tagKeys", valid_402656703
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
  var valid_402656704 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Security-Token", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Signature")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Signature", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Algorithm", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Date")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Date", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Credential")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Credential", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_UntagResource_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_UntagResource_402656699; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   
                                                                         ## tagKeys: JArray (required)
                                                                         ##          
                                                                         ## : 
                                                                         ## The 
                                                                         ## keys 
                                                                         ## of 
                                                                         ## those 
                                                                         ## tags 
                                                                         ## which 
                                                                         ## you 
                                                                         ## want 
                                                                         ## to 
                                                                         ## remove.
  ##   
                                                                                   ## resourceArn: string (required)
                                                                                   ##              
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## ARN 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## resource 
                                                                                   ## whose 
                                                                                   ## tag 
                                                                                   ## you 
                                                                                   ## want 
                                                                                   ## to 
                                                                                   ## remove.
  var path_402656713 = newJObject()
  var query_402656714 = newJObject()
  if tagKeys != nil:
    query_402656714.add "tagKeys", tagKeys
  add(path_402656713, "resourceArn", newJString(resourceArn))
  result = call_402656712.call(path_402656713, query_402656714, nil, nil, nil)

var untagResource* = Call_UntagResource_402656699(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656700,
    base: "/", makeUrl: url_UntagResource_402656701,
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