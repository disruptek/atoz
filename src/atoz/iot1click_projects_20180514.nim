
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
  Call_AssociateDeviceWithPlacement_602803 = ref object of OpenApiRestCall_602466
proc url_AssociateDeviceWithPlacement_602805(protocol: Scheme; host: string;
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

proc validate_AssociateDeviceWithPlacement_602804(path: JsonNode; query: JsonNode;
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
  var valid_602931 = path.getOrDefault("deviceTemplateName")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "deviceTemplateName", valid_602931
  var valid_602932 = path.getOrDefault("projectName")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "projectName", valid_602932
  var valid_602933 = path.getOrDefault("placementName")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = nil)
  if valid_602933 != nil:
    section.add "placementName", valid_602933
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
  var valid_602934 = header.getOrDefault("X-Amz-Date")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Date", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Security-Token")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Security-Token", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Content-Sha256", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Algorithm")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Algorithm", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Signature")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Signature", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-SignedHeaders", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602964: Call_AssociateDeviceWithPlacement_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a physical device with a placement.
  ## 
  let valid = call_602964.validator(path, query, header, formData, body)
  let scheme = call_602964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602964.url(scheme.get, call_602964.host, call_602964.base,
                         call_602964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602964, url, valid)

proc call*(call_603035: Call_AssociateDeviceWithPlacement_602803;
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
  var path_603036 = newJObject()
  var body_603038 = newJObject()
  add(path_603036, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_603036, "projectName", newJString(projectName))
  if body != nil:
    body_603038 = body
  add(path_603036, "placementName", newJString(placementName))
  result = call_603035.call(path_603036, nil, nil, nil, body_603038)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_602803(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_602804, base: "/",
    url: url_AssociateDeviceWithPlacement_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_603077 = ref object of OpenApiRestCall_602466
proc url_DisassociateDeviceFromPlacement_603079(protocol: Scheme; host: string;
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

proc validate_DisassociateDeviceFromPlacement_603078(path: JsonNode;
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
  var valid_603080 = path.getOrDefault("deviceTemplateName")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = nil)
  if valid_603080 != nil:
    section.add "deviceTemplateName", valid_603080
  var valid_603081 = path.getOrDefault("projectName")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "projectName", valid_603081
  var valid_603082 = path.getOrDefault("placementName")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = nil)
  if valid_603082 != nil:
    section.add "placementName", valid_603082
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
  var valid_603083 = header.getOrDefault("X-Amz-Date")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Date", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Security-Token")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Security-Token", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Content-Sha256", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Algorithm")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Algorithm", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Signature")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Signature", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-SignedHeaders", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Credential")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Credential", valid_603089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_DisassociateDeviceFromPlacement_603077;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a physical device from a placement.
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603090, url, valid)

proc call*(call_603091: Call_DisassociateDeviceFromPlacement_603077;
          deviceTemplateName: string; projectName: string; placementName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   deviceTemplateName: string (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: string (required)
  ##              : The name of the project that contains the placement.
  ##   placementName: string (required)
  ##                : The name of the placement that the device should be removed from.
  var path_603092 = newJObject()
  add(path_603092, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_603092, "projectName", newJString(projectName))
  add(path_603092, "placementName", newJString(placementName))
  result = call_603091.call(path_603092, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_603077(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_603078, base: "/",
    url: url_DisassociateDeviceFromPlacement_603079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_603110 = ref object of OpenApiRestCall_602466
proc url_CreatePlacement_603112(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePlacement_603111(path: JsonNode; query: JsonNode;
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
  var valid_603113 = path.getOrDefault("projectName")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "projectName", valid_603113
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
  var valid_603114 = header.getOrDefault("X-Amz-Date")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Date", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Security-Token")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Security-Token", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Algorithm")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Algorithm", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Signature")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Signature", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-SignedHeaders", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Credential")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Credential", valid_603120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603122: Call_CreatePlacement_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty placement.
  ## 
  let valid = call_603122.validator(path, query, header, formData, body)
  let scheme = call_603122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603122.url(scheme.get, call_603122.host, call_603122.base,
                         call_603122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603122, url, valid)

proc call*(call_603123: Call_CreatePlacement_603110; projectName: string;
          body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
  ##              : The name of the project in which to create the placement.
  ##   body: JObject (required)
  var path_603124 = newJObject()
  var body_603125 = newJObject()
  add(path_603124, "projectName", newJString(projectName))
  if body != nil:
    body_603125 = body
  result = call_603123.call(path_603124, nil, nil, nil, body_603125)

var createPlacement* = Call_CreatePlacement_603110(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_603111, base: "/", url: url_CreatePlacement_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_603093 = ref object of OpenApiRestCall_602466
proc url_ListPlacements_603095(protocol: Scheme; host: string; base: string;
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

proc validate_ListPlacements_603094(path: JsonNode; query: JsonNode;
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
  var valid_603096 = path.getOrDefault("projectName")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "projectName", valid_603096
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  section = newJObject()
  var valid_603097 = query.getOrDefault("maxResults")
  valid_603097 = validateParameter(valid_603097, JInt, required = false, default = nil)
  if valid_603097 != nil:
    section.add "maxResults", valid_603097
  var valid_603098 = query.getOrDefault("nextToken")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "nextToken", valid_603098
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
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Security-Token")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Security-Token", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_ListPlacements_603093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the placement(s) of a project.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603106, url, valid)

proc call*(call_603107: Call_ListPlacements_603093; projectName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   projectName: string (required)
  ##              : The project containing the placements to be listed.
  var path_603108 = newJObject()
  var query_603109 = newJObject()
  add(query_603109, "maxResults", newJInt(maxResults))
  add(query_603109, "nextToken", newJString(nextToken))
  add(path_603108, "projectName", newJString(projectName))
  result = call_603107.call(path_603108, query_603109, nil, nil, nil)

var listPlacements* = Call_ListPlacements_603093(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_603094, base: "/", url: url_ListPlacements_603095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_603141 = ref object of OpenApiRestCall_602466
proc url_CreateProject_603143(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_603142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603144 = header.getOrDefault("X-Amz-Date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Date", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Security-Token")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Security-Token", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Content-Sha256", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Algorithm")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Algorithm", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-SignedHeaders", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Credential")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Credential", valid_603150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603152: Call_CreateProject_603141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ## 
  let valid = call_603152.validator(path, query, header, formData, body)
  let scheme = call_603152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603152.url(scheme.get, call_603152.host, call_603152.base,
                         call_603152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603152, url, valid)

proc call*(call_603153: Call_CreateProject_603141; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   body: JObject (required)
  var body_603154 = newJObject()
  if body != nil:
    body_603154 = body
  result = call_603153.call(nil, nil, nil, nil, body_603154)

var createProject* = Call_CreateProject_603141(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_603142, base: "/",
    url: url_CreateProject_603143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_603126 = ref object of OpenApiRestCall_602466
proc url_ListProjects_603128(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_603127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603129 = query.getOrDefault("maxResults")
  valid_603129 = validateParameter(valid_603129, JInt, required = false, default = nil)
  if valid_603129 != nil:
    section.add "maxResults", valid_603129
  var valid_603130 = query.getOrDefault("nextToken")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "nextToken", valid_603130
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
  var valid_603131 = header.getOrDefault("X-Amz-Date")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Date", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Security-Token")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Security-Token", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Content-Sha256", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Algorithm")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Algorithm", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Signature")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Signature", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-SignedHeaders", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Credential")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Credential", valid_603137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603138: Call_ListProjects_603126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  let valid = call_603138.validator(path, query, header, formData, body)
  let scheme = call_603138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603138.url(scheme.get, call_603138.host, call_603138.base,
                         call_603138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603138, url, valid)

proc call*(call_603139: Call_ListProjects_603126; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  var query_603140 = newJObject()
  add(query_603140, "maxResults", newJInt(maxResults))
  add(query_603140, "nextToken", newJString(nextToken))
  result = call_603139.call(nil, query_603140, nil, nil, nil)

var listProjects* = Call_ListProjects_603126(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_603127, base: "/",
    url: url_ListProjects_603128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_603170 = ref object of OpenApiRestCall_602466
proc url_UpdatePlacement_603172(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePlacement_603171(path: JsonNode; query: JsonNode;
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
  var valid_603173 = path.getOrDefault("projectName")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "projectName", valid_603173
  var valid_603174 = path.getOrDefault("placementName")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "placementName", valid_603174
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
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603183: Call_UpdatePlacement_603170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  let valid = call_603183.validator(path, query, header, formData, body)
  let scheme = call_603183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603183.url(scheme.get, call_603183.host, call_603183.base,
                         call_603183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603183, url, valid)

proc call*(call_603184: Call_UpdatePlacement_603170; projectName: string;
          body: JsonNode; placementName: string): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   projectName: string (required)
  ##              : The name of the project containing the placement to be updated.
  ##   body: JObject (required)
  ##   placementName: string (required)
  ##                : The name of the placement to update.
  var path_603185 = newJObject()
  var body_603186 = newJObject()
  add(path_603185, "projectName", newJString(projectName))
  if body != nil:
    body_603186 = body
  add(path_603185, "placementName", newJString(placementName))
  result = call_603184.call(path_603185, nil, nil, nil, body_603186)

var updatePlacement* = Call_UpdatePlacement_603170(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_603171, base: "/", url: url_UpdatePlacement_603172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_603155 = ref object of OpenApiRestCall_602466
proc url_DescribePlacement_603157(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePlacement_603156(path: JsonNode; query: JsonNode;
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
  var valid_603158 = path.getOrDefault("projectName")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "projectName", valid_603158
  var valid_603159 = path.getOrDefault("placementName")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "placementName", valid_603159
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
  var valid_603160 = header.getOrDefault("X-Amz-Date")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Date", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Security-Token")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Security-Token", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Content-Sha256", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Algorithm")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Algorithm", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Signature")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Signature", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-SignedHeaders", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_DescribePlacement_603155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a placement in a project.
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_DescribePlacement_603155; projectName: string;
          placementName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   projectName: string (required)
  ##              : The project containing the placement to be described.
  ##   placementName: string (required)
  ##                : The name of the placement within a project.
  var path_603169 = newJObject()
  add(path_603169, "projectName", newJString(projectName))
  add(path_603169, "placementName", newJString(placementName))
  result = call_603168.call(path_603169, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_603155(name: "describePlacement",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_603156, base: "/",
    url: url_DescribePlacement_603157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_603187 = ref object of OpenApiRestCall_602466
proc url_DeletePlacement_603189(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePlacement_603188(path: JsonNode; query: JsonNode;
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
  var valid_603190 = path.getOrDefault("projectName")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "projectName", valid_603190
  var valid_603191 = path.getOrDefault("placementName")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "placementName", valid_603191
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603199: Call_DeletePlacement_603187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_603199.validator(path, query, header, formData, body)
  let scheme = call_603199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603199.url(scheme.get, call_603199.host, call_603199.base,
                         call_603199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603199, url, valid)

proc call*(call_603200: Call_DeletePlacement_603187; projectName: string;
          placementName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The project containing the empty placement to delete.
  ##   placementName: string (required)
  ##                : The name of the empty placement to delete.
  var path_603201 = newJObject()
  add(path_603201, "projectName", newJString(projectName))
  add(path_603201, "placementName", newJString(placementName))
  result = call_603200.call(path_603201, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_603187(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_603188, base: "/", url: url_DeletePlacement_603189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_603216 = ref object of OpenApiRestCall_602466
proc url_UpdateProject_603218(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_603217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603219 = path.getOrDefault("projectName")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "projectName", valid_603219
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
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Content-Sha256", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Algorithm")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Algorithm", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Signature")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Signature", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-SignedHeaders", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Credential")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Credential", valid_603226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603228: Call_UpdateProject_603216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ## 
  let valid = call_603228.validator(path, query, header, formData, body)
  let scheme = call_603228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603228.url(scheme.get, call_603228.host, call_603228.base,
                         call_603228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603228, url, valid)

proc call*(call_603229: Call_UpdateProject_603216; projectName: string;
          body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   projectName: string (required)
  ##              : The name of the project to be updated.
  ##   body: JObject (required)
  var path_603230 = newJObject()
  var body_603231 = newJObject()
  add(path_603230, "projectName", newJString(projectName))
  if body != nil:
    body_603231 = body
  result = call_603229.call(path_603230, nil, nil, nil, body_603231)

var updateProject* = Call_UpdateProject_603216(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_603217,
    base: "/", url: url_UpdateProject_603218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_603202 = ref object of OpenApiRestCall_602466
proc url_DescribeProject_603204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProject_603203(path: JsonNode; query: JsonNode;
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
  var valid_603205 = path.getOrDefault("projectName")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "projectName", valid_603205
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
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Security-Token")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Security-Token", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_DescribeProject_603202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object describing a project.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_DescribeProject_603202; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
  ##              : The name of the project to be described.
  var path_603215 = newJObject()
  add(path_603215, "projectName", newJString(projectName))
  result = call_603214.call(path_603215, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_603202(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_603203,
    base: "/", url: url_DescribeProject_603204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_603232 = ref object of OpenApiRestCall_602466
proc url_DeleteProject_603234(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_603233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603235 = path.getOrDefault("projectName")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "projectName", valid_603235
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
  var valid_603236 = header.getOrDefault("X-Amz-Date")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Date", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Security-Token")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Security-Token", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Content-Sha256", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Algorithm")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Algorithm", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-SignedHeaders", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Credential")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Credential", valid_603242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603243: Call_DeleteProject_603232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_603243.validator(path, query, header, formData, body)
  let scheme = call_603243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603243.url(scheme.get, call_603243.host, call_603243.base,
                         call_603243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603243, url, valid)

proc call*(call_603244: Call_DeleteProject_603232; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The name of the empty project to delete.
  var path_603245 = newJObject()
  add(path_603245, "projectName", newJString(projectName))
  result = call_603244.call(path_603245, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_603232(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_603233,
    base: "/", url: url_DeleteProject_603234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_603246 = ref object of OpenApiRestCall_602466
proc url_GetDevicesInPlacement_603248(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevicesInPlacement_603247(path: JsonNode; query: JsonNode;
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
  var valid_603249 = path.getOrDefault("projectName")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "projectName", valid_603249
  var valid_603250 = path.getOrDefault("placementName")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "placementName", valid_603250
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
  var valid_603251 = header.getOrDefault("X-Amz-Date")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Date", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Security-Token")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Security-Token", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Content-Sha256", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Signature")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Signature", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-SignedHeaders", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603258: Call_GetDevicesInPlacement_603246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object enumerating the devices in a placement.
  ## 
  let valid = call_603258.validator(path, query, header, formData, body)
  let scheme = call_603258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603258.url(scheme.get, call_603258.host, call_603258.base,
                         call_603258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603258, url, valid)

proc call*(call_603259: Call_GetDevicesInPlacement_603246; projectName: string;
          placementName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement.
  ##   placementName: string (required)
  ##                : The name of the placement to get the devices from.
  var path_603260 = newJObject()
  add(path_603260, "projectName", newJString(projectName))
  add(path_603260, "placementName", newJString(placementName))
  result = call_603259.call(path_603260, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_603246(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_603247, base: "/",
    url: url_GetDevicesInPlacement_603248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603275 = ref object of OpenApiRestCall_602466
proc url_TagResource_603277(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603278 = path.getOrDefault("resourceArn")
  valid_603278 = validateParameter(valid_603278, JString, required = true,
                                 default = nil)
  if valid_603278 != nil:
    section.add "resourceArn", valid_603278
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
  var valid_603279 = header.getOrDefault("X-Amz-Date")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Date", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Security-Token")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Security-Token", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Content-Sha256", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Algorithm")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Algorithm", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Signature")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Signature", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-SignedHeaders", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Credential")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Credential", valid_603285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603287: Call_TagResource_603275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ## 
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603287, url, valid)

proc call*(call_603288: Call_TagResource_603275; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resouce for which tag(s) should be added or modified.
  var path_603289 = newJObject()
  var body_603290 = newJObject()
  if body != nil:
    body_603290 = body
  add(path_603289, "resourceArn", newJString(resourceArn))
  result = call_603288.call(path_603289, nil, nil, nil, body_603290)

var tagResource* = Call_TagResource_603275(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_603276,
                                        base: "/", url: url_TagResource_603277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603261 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603263(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_603262(path: JsonNode; query: JsonNode;
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
  var valid_603264 = path.getOrDefault("resourceArn")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = nil)
  if valid_603264 != nil:
    section.add "resourceArn", valid_603264
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
  var valid_603265 = header.getOrDefault("X-Amz-Date")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Date", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Security-Token")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Security-Token", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Content-Sha256", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Algorithm")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Algorithm", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Signature")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Signature", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-SignedHeaders", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Credential")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Credential", valid_603271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603272: Call_ListTagsForResource_603261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ## 
  let valid = call_603272.validator(path, query, header, formData, body)
  let scheme = call_603272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603272.url(scheme.get, call_603272.host, call_603272.base,
                         call_603272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603272, url, valid)

proc call*(call_603273: Call_ListTagsForResource_603261; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var path_603274 = newJObject()
  add(path_603274, "resourceArn", newJString(resourceArn))
  result = call_603273.call(path_603274, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603261(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_603262, base: "/",
    url: url_ListTagsForResource_603263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603291 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603293(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603294 = path.getOrDefault("resourceArn")
  valid_603294 = validateParameter(valid_603294, JString, required = true,
                                 default = nil)
  if valid_603294 != nil:
    section.add "resourceArn", valid_603294
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603295 = query.getOrDefault("tagKeys")
  valid_603295 = validateParameter(valid_603295, JArray, required = true, default = nil)
  if valid_603295 != nil:
    section.add "tagKeys", valid_603295
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
  var valid_603296 = header.getOrDefault("X-Amz-Date")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Date", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Security-Token")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Security-Token", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Content-Sha256", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Algorithm")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Algorithm", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Signature")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Signature", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-SignedHeaders", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Credential")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Credential", valid_603302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603303: Call_UntagResource_603291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ## 
  let valid = call_603303.validator(path, query, header, formData, body)
  let scheme = call_603303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603303.url(scheme.get, call_603303.host, call_603303.base,
                         call_603303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603303, url, valid)

proc call*(call_603304: Call_UntagResource_603291; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tag you want to remove.
  var path_603305 = newJObject()
  var query_603306 = newJObject()
  if tagKeys != nil:
    query_603306.add "tagKeys", tagKeys
  add(path_603305, "resourceArn", newJString(resourceArn))
  result = call_603304.call(path_603305, query_603306, nil, nil, nil)

var untagResource* = Call_UntagResource_603291(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_603292,
    base: "/", url: url_UntagResource_603293, schemes: {Scheme.Https, Scheme.Http})
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
