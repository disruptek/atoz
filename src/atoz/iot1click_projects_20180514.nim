
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "projects.iot1click.ap-northeast-1.amazonaws.com", "ap-southeast-1": "projects.iot1click.ap-southeast-1.amazonaws.com", "us-west-2": "projects.iot1click.us-west-2.amazonaws.com", "eu-west-2": "projects.iot1click.eu-west-2.amazonaws.com", "ap-northeast-3": "projects.iot1click.ap-northeast-3.amazonaws.com", "eu-central-1": "projects.iot1click.eu-central-1.amazonaws.com", "us-east-2": "projects.iot1click.us-east-2.amazonaws.com", "us-east-1": "projects.iot1click.us-east-1.amazonaws.com", "cn-northwest-1": "projects.iot1click.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "projects.iot1click.ap-south-1.amazonaws.com", "eu-north-1": "projects.iot1click.eu-north-1.amazonaws.com", "ap-northeast-2": "projects.iot1click.ap-northeast-2.amazonaws.com", "us-west-1": "projects.iot1click.us-west-1.amazonaws.com", "us-gov-east-1": "projects.iot1click.us-gov-east-1.amazonaws.com", "eu-west-3": "projects.iot1click.eu-west-3.amazonaws.com", "cn-north-1": "projects.iot1click.cn-north-1.amazonaws.com.cn", "sa-east-1": "projects.iot1click.sa-east-1.amazonaws.com", "eu-west-1": "projects.iot1click.eu-west-1.amazonaws.com", "us-gov-west-1": "projects.iot1click.us-gov-west-1.amazonaws.com", "ap-southeast-2": "projects.iot1click.ap-southeast-2.amazonaws.com", "ca-central-1": "projects.iot1click.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDeviceWithPlacement_593774 = ref object of OpenApiRestCall_593437
proc url_AssociateDeviceWithPlacement_593776(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_AssociateDeviceWithPlacement_593775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a physical device with a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceTemplateName: JString (required)
  ##                     : The device template name to associate with the device ID.
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement in which to associate the device.
  ##   placementName: JString (required)
  ##                : The name of the placement in which to associate the device.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `deviceTemplateName` field"
  var valid_593902 = path.getOrDefault("deviceTemplateName")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "deviceTemplateName", valid_593902
  var valid_593903 = path.getOrDefault("projectName")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "projectName", valid_593903
  var valid_593904 = path.getOrDefault("placementName")
  valid_593904 = validateParameter(valid_593904, JString, required = true,
                                 default = nil)
  if valid_593904 != nil:
    section.add "placementName", valid_593904
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
  var valid_593905 = header.getOrDefault("X-Amz-Date")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Date", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Security-Token")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Security-Token", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Content-Sha256", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Algorithm")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Algorithm", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Signature")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Signature", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Credential")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Credential", valid_593911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593935: Call_AssociateDeviceWithPlacement_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a physical device with a placement.
  ## 
  let valid = call_593935.validator(path, query, header, formData, body)
  let scheme = call_593935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593935.url(scheme.get, call_593935.host, call_593935.base,
                         call_593935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593935, url, valid)

proc call*(call_594006: Call_AssociateDeviceWithPlacement_593774;
          deviceTemplateName: string; projectName: string; body: JsonNode;
          placementName: string): Recallable =
  ## associateDeviceWithPlacement
  ## Associates a physical device with a placement.
  ##   deviceTemplateName: string (required)
  ##                     : The device template name to associate with the device ID.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement in which to associate the device.
  ##   body: JObject (required)
  ##   placementName: string (required)
  ##                : The name of the placement in which to associate the device.
  var path_594007 = newJObject()
  var body_594009 = newJObject()
  add(path_594007, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_594007, "projectName", newJString(projectName))
  if body != nil:
    body_594009 = body
  add(path_594007, "placementName", newJString(placementName))
  result = call_594006.call(path_594007, nil, nil, nil, body_594009)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_593774(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_593775, base: "/",
    url: url_AssociateDeviceWithPlacement_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_594048 = ref object of OpenApiRestCall_593437
proc url_DisassociateDeviceFromPlacement_594050(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DisassociateDeviceFromPlacement_594049(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a physical device from a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceTemplateName: JString (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: JString (required)
  ##              : The name of the project that contains the placement.
  ##   placementName: JString (required)
  ##                : The name of the placement that the device should be removed from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `deviceTemplateName` field"
  var valid_594051 = path.getOrDefault("deviceTemplateName")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = nil)
  if valid_594051 != nil:
    section.add "deviceTemplateName", valid_594051
  var valid_594052 = path.getOrDefault("projectName")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "projectName", valid_594052
  var valid_594053 = path.getOrDefault("placementName")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = nil)
  if valid_594053 != nil:
    section.add "placementName", valid_594053
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
  var valid_594054 = header.getOrDefault("X-Amz-Date")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Date", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Security-Token")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Security-Token", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Content-Sha256", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Algorithm")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Algorithm", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Signature")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Signature", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-SignedHeaders", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Credential")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Credential", valid_594060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594061: Call_DisassociateDeviceFromPlacement_594048;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a physical device from a placement.
  ## 
  let valid = call_594061.validator(path, query, header, formData, body)
  let scheme = call_594061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594061.url(scheme.get, call_594061.host, call_594061.base,
                         call_594061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594061, url, valid)

proc call*(call_594062: Call_DisassociateDeviceFromPlacement_594048;
          deviceTemplateName: string; projectName: string; placementName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   deviceTemplateName: string (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: string (required)
  ##              : The name of the project that contains the placement.
  ##   placementName: string (required)
  ##                : The name of the placement that the device should be removed from.
  var path_594063 = newJObject()
  add(path_594063, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_594063, "projectName", newJString(projectName))
  add(path_594063, "placementName", newJString(placementName))
  result = call_594062.call(path_594063, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_594048(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_594049, base: "/",
    url: url_DisassociateDeviceFromPlacement_594050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_594081 = ref object of OpenApiRestCall_593437
proc url_CreatePlacement_594083(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreatePlacement_594082(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_594084 = path.getOrDefault("projectName")
  valid_594084 = validateParameter(valid_594084, JString, required = true,
                                 default = nil)
  if valid_594084 != nil:
    section.add "projectName", valid_594084
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
  var valid_594085 = header.getOrDefault("X-Amz-Date")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Date", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Security-Token")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Security-Token", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Content-Sha256", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Algorithm")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Algorithm", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Signature")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Signature", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-SignedHeaders", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Credential")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Credential", valid_594091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594093: Call_CreatePlacement_594081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty placement.
  ## 
  let valid = call_594093.validator(path, query, header, formData, body)
  let scheme = call_594093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594093.url(scheme.get, call_594093.host, call_594093.base,
                         call_594093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594093, url, valid)

proc call*(call_594094: Call_CreatePlacement_594081; projectName: string;
          body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
  ##              : The name of the project in which to create the placement.
  ##   body: JObject (required)
  var path_594095 = newJObject()
  var body_594096 = newJObject()
  add(path_594095, "projectName", newJString(projectName))
  if body != nil:
    body_594096 = body
  result = call_594094.call(path_594095, nil, nil, nil, body_594096)

var createPlacement* = Call_CreatePlacement_594081(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_594082, base: "/", url: url_CreatePlacement_594083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_594064 = ref object of OpenApiRestCall_593437
proc url_ListPlacements_594066(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListPlacements_594065(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_594067 = path.getOrDefault("projectName")
  valid_594067 = validateParameter(valid_594067, JString, required = true,
                                 default = nil)
  if valid_594067 != nil:
    section.add "projectName", valid_594067
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  section = newJObject()
  var valid_594068 = query.getOrDefault("maxResults")
  valid_594068 = validateParameter(valid_594068, JInt, required = false, default = nil)
  if valid_594068 != nil:
    section.add "maxResults", valid_594068
  var valid_594069 = query.getOrDefault("nextToken")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "nextToken", valid_594069
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
  var valid_594070 = header.getOrDefault("X-Amz-Date")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Date", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Security-Token")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Security-Token", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Content-Sha256", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Algorithm")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Algorithm", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Credential")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Credential", valid_594076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_ListPlacements_594064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the placement(s) of a project.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_ListPlacements_594064; projectName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   projectName: string (required)
  ##              : The project containing the placements to be listed.
  var path_594079 = newJObject()
  var query_594080 = newJObject()
  add(query_594080, "maxResults", newJInt(maxResults))
  add(query_594080, "nextToken", newJString(nextToken))
  add(path_594079, "projectName", newJString(projectName))
  result = call_594078.call(path_594079, query_594080, nil, nil, nil)

var listPlacements* = Call_ListPlacements_594064(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_594065, base: "/", url: url_ListPlacements_594066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_594112 = ref object of OpenApiRestCall_593437
proc url_CreateProject_594114(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_594113(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Content-Sha256", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Signature")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Signature", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-SignedHeaders", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Credential")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Credential", valid_594121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594123: Call_CreateProject_594112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ## 
  let valid = call_594123.validator(path, query, header, formData, body)
  let scheme = call_594123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594123.url(scheme.get, call_594123.host, call_594123.base,
                         call_594123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594123, url, valid)

proc call*(call_594124: Call_CreateProject_594112; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   body: JObject (required)
  var body_594125 = newJObject()
  if body != nil:
    body_594125 = body
  result = call_594124.call(nil, nil, nil, nil, body_594125)

var createProject* = Call_CreateProject_594112(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_594113, base: "/",
    url: url_CreateProject_594114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_594097 = ref object of OpenApiRestCall_593437
proc url_ListProjects_594099(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_594098(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  section = newJObject()
  var valid_594100 = query.getOrDefault("maxResults")
  valid_594100 = validateParameter(valid_594100, JInt, required = false, default = nil)
  if valid_594100 != nil:
    section.add "maxResults", valid_594100
  var valid_594101 = query.getOrDefault("nextToken")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "nextToken", valid_594101
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
  var valid_594102 = header.getOrDefault("X-Amz-Date")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Date", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Security-Token")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Security-Token", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Content-Sha256", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Algorithm")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Algorithm", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Signature")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Signature", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-SignedHeaders", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Credential")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Credential", valid_594108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594109: Call_ListProjects_594097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  let valid = call_594109.validator(path, query, header, formData, body)
  let scheme = call_594109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594109.url(scheme.get, call_594109.host, call_594109.base,
                         call_594109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594109, url, valid)

proc call*(call_594110: Call_ListProjects_594097; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  var query_594111 = newJObject()
  add(query_594111, "maxResults", newJInt(maxResults))
  add(query_594111, "nextToken", newJString(nextToken))
  result = call_594110.call(nil, query_594111, nil, nil, nil)

var listProjects* = Call_ListProjects_594097(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_594098, base: "/",
    url: url_ListProjects_594099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_594141 = ref object of OpenApiRestCall_593437
proc url_UpdatePlacement_594143(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_UpdatePlacement_594142(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement to be updated.
  ##   placementName: JString (required)
  ##                : The name of the placement to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `projectName` field"
  var valid_594144 = path.getOrDefault("projectName")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = nil)
  if valid_594144 != nil:
    section.add "projectName", valid_594144
  var valid_594145 = path.getOrDefault("placementName")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = nil)
  if valid_594145 != nil:
    section.add "placementName", valid_594145
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
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Security-Token")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Security-Token", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Content-Sha256", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-SignedHeaders", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Credential")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Credential", valid_594152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594154: Call_UpdatePlacement_594141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  let valid = call_594154.validator(path, query, header, formData, body)
  let scheme = call_594154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594154.url(scheme.get, call_594154.host, call_594154.base,
                         call_594154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594154, url, valid)

proc call*(call_594155: Call_UpdatePlacement_594141; projectName: string;
          body: JsonNode; placementName: string): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   projectName: string (required)
  ##              : The name of the project containing the placement to be updated.
  ##   body: JObject (required)
  ##   placementName: string (required)
  ##                : The name of the placement to update.
  var path_594156 = newJObject()
  var body_594157 = newJObject()
  add(path_594156, "projectName", newJString(projectName))
  if body != nil:
    body_594157 = body
  add(path_594156, "placementName", newJString(placementName))
  result = call_594155.call(path_594156, nil, nil, nil, body_594157)

var updatePlacement* = Call_UpdatePlacement_594141(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_594142, base: "/", url: url_UpdatePlacement_594143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_594126 = ref object of OpenApiRestCall_593437
proc url_DescribePlacement_594128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DescribePlacement_594127(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a placement in a project.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
  ##              : The project containing the placement to be described.
  ##   placementName: JString (required)
  ##                : The name of the placement within a project.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `projectName` field"
  var valid_594129 = path.getOrDefault("projectName")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "projectName", valid_594129
  var valid_594130 = path.getOrDefault("placementName")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = nil)
  if valid_594130 != nil:
    section.add "placementName", valid_594130
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
  var valid_594131 = header.getOrDefault("X-Amz-Date")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Date", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Content-Sha256", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Algorithm")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Algorithm", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-SignedHeaders", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Credential")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Credential", valid_594137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_DescribePlacement_594126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a placement in a project.
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_DescribePlacement_594126; projectName: string;
          placementName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   projectName: string (required)
  ##              : The project containing the placement to be described.
  ##   placementName: string (required)
  ##                : The name of the placement within a project.
  var path_594140 = newJObject()
  add(path_594140, "projectName", newJString(projectName))
  add(path_594140, "placementName", newJString(placementName))
  result = call_594139.call(path_594140, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_594126(name: "describePlacement",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_594127, base: "/",
    url: url_DescribePlacement_594128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_594158 = ref object of OpenApiRestCall_593437
proc url_DeletePlacement_594160(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DeletePlacement_594159(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
  ##              : The project containing the empty placement to delete.
  ##   placementName: JString (required)
  ##                : The name of the empty placement to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `projectName` field"
  var valid_594161 = path.getOrDefault("projectName")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "projectName", valid_594161
  var valid_594162 = path.getOrDefault("placementName")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "placementName", valid_594162
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
  var valid_594163 = header.getOrDefault("X-Amz-Date")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Date", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Security-Token")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Security-Token", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Content-Sha256", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Algorithm")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Algorithm", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Signature")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Signature", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-SignedHeaders", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Credential")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Credential", valid_594169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594170: Call_DeletePlacement_594158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_594170.validator(path, query, header, formData, body)
  let scheme = call_594170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594170.url(scheme.get, call_594170.host, call_594170.base,
                         call_594170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594170, url, valid)

proc call*(call_594171: Call_DeletePlacement_594158; projectName: string;
          placementName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The project containing the empty placement to delete.
  ##   placementName: string (required)
  ##                : The name of the empty placement to delete.
  var path_594172 = newJObject()
  add(path_594172, "projectName", newJString(projectName))
  add(path_594172, "placementName", newJString(placementName))
  result = call_594171.call(path_594172, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_594158(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_594159, base: "/", url: url_DeletePlacement_594160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_594187 = ref object of OpenApiRestCall_593437
proc url_UpdateProject_594189(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateProject_594188(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594190 = path.getOrDefault("projectName")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "projectName", valid_594190
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
  var valid_594191 = header.getOrDefault("X-Amz-Date")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Date", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Security-Token")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Security-Token", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Algorithm")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Algorithm", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Credential")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Credential", valid_594197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594199: Call_UpdateProject_594187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ## 
  let valid = call_594199.validator(path, query, header, formData, body)
  let scheme = call_594199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594199.url(scheme.get, call_594199.host, call_594199.base,
                         call_594199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594199, url, valid)

proc call*(call_594200: Call_UpdateProject_594187; projectName: string;
          body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   projectName: string (required)
  ##              : The name of the project to be updated.
  ##   body: JObject (required)
  var path_594201 = newJObject()
  var body_594202 = newJObject()
  add(path_594201, "projectName", newJString(projectName))
  if body != nil:
    body_594202 = body
  result = call_594200.call(path_594201, nil, nil, nil, body_594202)

var updateProject* = Call_UpdateProject_594187(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_594188,
    base: "/", url: url_UpdateProject_594189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_594173 = ref object of OpenApiRestCall_593437
proc url_DescribeProject_594175(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeProject_594174(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_594176 = path.getOrDefault("projectName")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "projectName", valid_594176
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
  var valid_594177 = header.getOrDefault("X-Amz-Date")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Date", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Security-Token")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Security-Token", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Content-Sha256", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Algorithm")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Algorithm", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Signature")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Signature", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-SignedHeaders", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594184: Call_DescribeProject_594173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object describing a project.
  ## 
  let valid = call_594184.validator(path, query, header, formData, body)
  let scheme = call_594184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594184.url(scheme.get, call_594184.host, call_594184.base,
                         call_594184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594184, url, valid)

proc call*(call_594185: Call_DescribeProject_594173; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
  ##              : The name of the project to be described.
  var path_594186 = newJObject()
  add(path_594186, "projectName", newJString(projectName))
  result = call_594185.call(path_594186, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_594173(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_594174,
    base: "/", url: url_DescribeProject_594175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_594203 = ref object of OpenApiRestCall_593437
proc url_DeleteProject_594205(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteProject_594204(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594206 = path.getOrDefault("projectName")
  valid_594206 = validateParameter(valid_594206, JString, required = true,
                                 default = nil)
  if valid_594206 != nil:
    section.add "projectName", valid_594206
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
  var valid_594207 = header.getOrDefault("X-Amz-Date")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Date", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Security-Token")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Security-Token", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Content-Sha256", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Algorithm")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Algorithm", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Signature")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Signature", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-SignedHeaders", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594214: Call_DeleteProject_594203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_594214.validator(path, query, header, formData, body)
  let scheme = call_594214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594214.url(scheme.get, call_594214.host, call_594214.base,
                         call_594214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594214, url, valid)

proc call*(call_594215: Call_DeleteProject_594203; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The name of the empty project to delete.
  var path_594216 = newJObject()
  add(path_594216, "projectName", newJString(projectName))
  result = call_594215.call(path_594216, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_594203(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_594204,
    base: "/", url: url_DeleteProject_594205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_594217 = ref object of OpenApiRestCall_593437
proc url_GetDevicesInPlacement_594219(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_GetDevicesInPlacement_594218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an object enumerating the devices in a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement.
  ##   placementName: JString (required)
  ##                : The name of the placement to get the devices from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `projectName` field"
  var valid_594220 = path.getOrDefault("projectName")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "projectName", valid_594220
  var valid_594221 = path.getOrDefault("placementName")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "placementName", valid_594221
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
  var valid_594222 = header.getOrDefault("X-Amz-Date")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Date", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Security-Token")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Security-Token", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Algorithm")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Algorithm", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Signature")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Signature", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-SignedHeaders", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594229: Call_GetDevicesInPlacement_594217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object enumerating the devices in a placement.
  ## 
  let valid = call_594229.validator(path, query, header, formData, body)
  let scheme = call_594229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594229.url(scheme.get, call_594229.host, call_594229.base,
                         call_594229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594229, url, valid)

proc call*(call_594230: Call_GetDevicesInPlacement_594217; projectName: string;
          placementName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement.
  ##   placementName: string (required)
  ##                : The name of the placement to get the devices from.
  var path_594231 = newJObject()
  add(path_594231, "projectName", newJString(projectName))
  add(path_594231, "placementName", newJString(placementName))
  result = call_594230.call(path_594231, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_594217(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_594218, base: "/",
    url: url_GetDevicesInPlacement_594219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594246 = ref object of OpenApiRestCall_593437
proc url_TagResource_594248(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_594247(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594249 = path.getOrDefault("resourceArn")
  valid_594249 = validateParameter(valid_594249, JString, required = true,
                                 default = nil)
  if valid_594249 != nil:
    section.add "resourceArn", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Algorithm")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Algorithm", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-SignedHeaders", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Credential")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Credential", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594258: Call_TagResource_594246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ## 
  let valid = call_594258.validator(path, query, header, formData, body)
  let scheme = call_594258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594258.url(scheme.get, call_594258.host, call_594258.base,
                         call_594258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594258, url, valid)

proc call*(call_594259: Call_TagResource_594246; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resouce for which tag(s) should be added or modified.
  var path_594260 = newJObject()
  var body_594261 = newJObject()
  if body != nil:
    body_594261 = body
  add(path_594260, "resourceArn", newJString(resourceArn))
  result = call_594259.call(path_594260, nil, nil, nil, body_594261)

var tagResource* = Call_TagResource_594246(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594247,
                                        base: "/", url: url_TagResource_594248,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594232 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594234(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594233(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_594235 = path.getOrDefault("resourceArn")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = nil)
  if valid_594235 != nil:
    section.add "resourceArn", valid_594235
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
  var valid_594236 = header.getOrDefault("X-Amz-Date")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Date", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Security-Token")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Security-Token", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Content-Sha256", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Algorithm")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Algorithm", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-SignedHeaders", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Credential")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Credential", valid_594242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594243: Call_ListTagsForResource_594232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ## 
  let valid = call_594243.validator(path, query, header, formData, body)
  let scheme = call_594243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594243.url(scheme.get, call_594243.host, call_594243.base,
                         call_594243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594243, url, valid)

proc call*(call_594244: Call_ListTagsForResource_594232; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var path_594245 = newJObject()
  add(path_594245, "resourceArn", newJString(resourceArn))
  result = call_594244.call(path_594245, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594232(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594233, base: "/",
    url: url_ListTagsForResource_594234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594262 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594264(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_594263(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594265 = path.getOrDefault("resourceArn")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "resourceArn", valid_594265
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594266 = query.getOrDefault("tagKeys")
  valid_594266 = validateParameter(valid_594266, JArray, required = true, default = nil)
  if valid_594266 != nil:
    section.add "tagKeys", valid_594266
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
  var valid_594267 = header.getOrDefault("X-Amz-Date")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Date", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Security-Token")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Security-Token", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Content-Sha256", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Algorithm")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Algorithm", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Signature")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Signature", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-SignedHeaders", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Credential")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Credential", valid_594273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594274: Call_UntagResource_594262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ## 
  let valid = call_594274.validator(path, query, header, formData, body)
  let scheme = call_594274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594274.url(scheme.get, call_594274.host, call_594274.base,
                         call_594274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594274, url, valid)

proc call*(call_594275: Call_UntagResource_594262; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tag you want to remove.
  var path_594276 = newJObject()
  var query_594277 = newJObject()
  if tagKeys != nil:
    query_594277.add "tagKeys", tagKeys
  add(path_594276, "resourceArn", newJString(resourceArn))
  result = call_594275.call(path_594276, query_594277, nil, nil, nil)

var untagResource* = Call_UntagResource_594262(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594263,
    base: "/", url: url_UntagResource_594264, schemes: {Scheme.Https, Scheme.Http})
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
