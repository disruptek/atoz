
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDeviceWithPlacement_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateDeviceWithPlacement_605929(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateDeviceWithPlacement_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a physical device with a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the placement in which to associate the device.
  ##   deviceTemplateName: JString (required)
  ##                     : The device template name to associate with the device ID.
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement in which to associate the device.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606055 = path.getOrDefault("placementName")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "placementName", valid_606055
  var valid_606056 = path.getOrDefault("deviceTemplateName")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = nil)
  if valid_606056 != nil:
    section.add "deviceTemplateName", valid_606056
  var valid_606057 = path.getOrDefault("projectName")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = nil)
  if valid_606057 != nil:
    section.add "projectName", valid_606057
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
  var valid_606058 = header.getOrDefault("X-Amz-Signature")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Signature", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Content-Sha256", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Date")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Date", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Credential")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Credential", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Security-Token")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Security-Token", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Algorithm")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Algorithm", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-SignedHeaders", valid_606064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606088: Call_AssociateDeviceWithPlacement_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a physical device with a placement.
  ## 
  let valid = call_606088.validator(path, query, header, formData, body)
  let scheme = call_606088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606088.url(scheme.get, call_606088.host, call_606088.base,
                         call_606088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606088, url, valid)

proc call*(call_606159: Call_AssociateDeviceWithPlacement_605927;
          placementName: string; deviceTemplateName: string; projectName: string;
          body: JsonNode): Recallable =
  ## associateDeviceWithPlacement
  ## Associates a physical device with a placement.
  ##   placementName: string (required)
  ##                : The name of the placement in which to associate the device.
  ##   deviceTemplateName: string (required)
  ##                     : The device template name to associate with the device ID.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement in which to associate the device.
  ##   body: JObject (required)
  var path_606160 = newJObject()
  var body_606162 = newJObject()
  add(path_606160, "placementName", newJString(placementName))
  add(path_606160, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_606160, "projectName", newJString(projectName))
  if body != nil:
    body_606162 = body
  result = call_606159.call(path_606160, nil, nil, nil, body_606162)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_605927(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_605928, base: "/",
    url: url_AssociateDeviceWithPlacement_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_606201 = ref object of OpenApiRestCall_605589
proc url_DisassociateDeviceFromPlacement_606203(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateDeviceFromPlacement_606202(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a physical device from a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the placement that the device should be removed from.
  ##   deviceTemplateName: JString (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: JString (required)
  ##              : The name of the project that contains the placement.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606204 = path.getOrDefault("placementName")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = nil)
  if valid_606204 != nil:
    section.add "placementName", valid_606204
  var valid_606205 = path.getOrDefault("deviceTemplateName")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "deviceTemplateName", valid_606205
  var valid_606206 = path.getOrDefault("projectName")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = nil)
  if valid_606206 != nil:
    section.add "projectName", valid_606206
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
  var valid_606207 = header.getOrDefault("X-Amz-Signature")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Signature", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Content-Sha256", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Date")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Date", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Credential")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Credential", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Security-Token")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Security-Token", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Algorithm")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Algorithm", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-SignedHeaders", valid_606213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_DisassociateDeviceFromPlacement_606201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a physical device from a placement.
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_DisassociateDeviceFromPlacement_606201;
          placementName: string; deviceTemplateName: string; projectName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   placementName: string (required)
  ##                : The name of the placement that the device should be removed from.
  ##   deviceTemplateName: string (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: string (required)
  ##              : The name of the project that contains the placement.
  var path_606216 = newJObject()
  add(path_606216, "placementName", newJString(placementName))
  add(path_606216, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_606216, "projectName", newJString(projectName))
  result = call_606215.call(path_606216, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_606201(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_606202, base: "/",
    url: url_DisassociateDeviceFromPlacement_606203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_606234 = ref object of OpenApiRestCall_605589
proc url_CreatePlacement_606236(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePlacement_606235(path: JsonNode; query: JsonNode;
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
  var valid_606237 = path.getOrDefault("projectName")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = nil)
  if valid_606237 != nil:
    section.add "projectName", valid_606237
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
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_CreatePlacement_606234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty placement.
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_CreatePlacement_606234; projectName: string;
          body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
  ##              : The name of the project in which to create the placement.
  ##   body: JObject (required)
  var path_606248 = newJObject()
  var body_606249 = newJObject()
  add(path_606248, "projectName", newJString(projectName))
  if body != nil:
    body_606249 = body
  result = call_606247.call(path_606248, nil, nil, nil, body_606249)

var createPlacement* = Call_CreatePlacement_606234(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_606235, base: "/", url: url_CreatePlacement_606236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_606217 = ref object of OpenApiRestCall_605589
proc url_ListPlacements_606219(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPlacements_606218(path: JsonNode; query: JsonNode;
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
  var valid_606220 = path.getOrDefault("projectName")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = nil)
  if valid_606220 != nil:
    section.add "projectName", valid_606220
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  section = newJObject()
  var valid_606221 = query.getOrDefault("nextToken")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "nextToken", valid_606221
  var valid_606222 = query.getOrDefault("maxResults")
  valid_606222 = validateParameter(valid_606222, JInt, required = false, default = nil)
  if valid_606222 != nil:
    section.add "maxResults", valid_606222
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
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606230: Call_ListPlacements_606217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the placement(s) of a project.
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_ListPlacements_606217; projectName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   projectName: string (required)
  ##              : The project containing the placements to be listed.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  var path_606232 = newJObject()
  var query_606233 = newJObject()
  add(query_606233, "nextToken", newJString(nextToken))
  add(path_606232, "projectName", newJString(projectName))
  add(query_606233, "maxResults", newJInt(maxResults))
  result = call_606231.call(path_606232, query_606233, nil, nil, nil)

var listPlacements* = Call_ListPlacements_606217(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_606218, base: "/", url: url_ListPlacements_606219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_606265 = ref object of OpenApiRestCall_605589
proc url_CreateProject_606267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_606266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606276: Call_CreateProject_606265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ## 
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateProject_606265; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   body: JObject (required)
  var body_606278 = newJObject()
  if body != nil:
    body_606278 = body
  result = call_606277.call(nil, nil, nil, nil, body_606278)

var createProject* = Call_CreateProject_606265(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_606266, base: "/",
    url: url_CreateProject_606267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_606250 = ref object of OpenApiRestCall_605589
proc url_ListProjects_606252(protocol: Scheme; host: string; base: string;
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

proc validate_ListProjects_606251(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  section = newJObject()
  var valid_606253 = query.getOrDefault("nextToken")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "nextToken", valid_606253
  var valid_606254 = query.getOrDefault("maxResults")
  valid_606254 = validateParameter(valid_606254, JInt, required = false, default = nil)
  if valid_606254 != nil:
    section.add "maxResults", valid_606254
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
  var valid_606255 = header.getOrDefault("X-Amz-Signature")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Signature", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Content-Sha256", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Date")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Date", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Credential")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Credential", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Security-Token")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Security-Token", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Algorithm")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Algorithm", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-SignedHeaders", valid_606261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606262: Call_ListProjects_606250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  let valid = call_606262.validator(path, query, header, formData, body)
  let scheme = call_606262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606262.url(scheme.get, call_606262.host, call_606262.base,
                         call_606262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606262, url, valid)

proc call*(call_606263: Call_ListProjects_606250; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  var query_606264 = newJObject()
  add(query_606264, "nextToken", newJString(nextToken))
  add(query_606264, "maxResults", newJInt(maxResults))
  result = call_606263.call(nil, query_606264, nil, nil, nil)

var listProjects* = Call_ListProjects_606250(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_606251, base: "/",
    url: url_ListProjects_606252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_606294 = ref object of OpenApiRestCall_605589
proc url_UpdatePlacement_606296(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePlacement_606295(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the placement to update.
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement to be updated.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606297 = path.getOrDefault("placementName")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = nil)
  if valid_606297 != nil:
    section.add "placementName", valid_606297
  var valid_606298 = path.getOrDefault("projectName")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = nil)
  if valid_606298 != nil:
    section.add "projectName", valid_606298
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
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606307: Call_UpdatePlacement_606294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  let valid = call_606307.validator(path, query, header, formData, body)
  let scheme = call_606307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606307.url(scheme.get, call_606307.host, call_606307.base,
                         call_606307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606307, url, valid)

proc call*(call_606308: Call_UpdatePlacement_606294; placementName: string;
          projectName: string; body: JsonNode): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   placementName: string (required)
  ##                : The name of the placement to update.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement to be updated.
  ##   body: JObject (required)
  var path_606309 = newJObject()
  var body_606310 = newJObject()
  add(path_606309, "placementName", newJString(placementName))
  add(path_606309, "projectName", newJString(projectName))
  if body != nil:
    body_606310 = body
  result = call_606308.call(path_606309, nil, nil, nil, body_606310)

var updatePlacement* = Call_UpdatePlacement_606294(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_606295, base: "/", url: url_UpdatePlacement_606296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_606279 = ref object of OpenApiRestCall_605589
proc url_DescribePlacement_606281(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePlacement_606280(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a placement in a project.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the placement within a project.
  ##   projectName: JString (required)
  ##              : The project containing the placement to be described.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606282 = path.getOrDefault("placementName")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "placementName", valid_606282
  var valid_606283 = path.getOrDefault("projectName")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "projectName", valid_606283
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
  var valid_606284 = header.getOrDefault("X-Amz-Signature")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Signature", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Content-Sha256", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Date")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Date", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Credential")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Credential", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Security-Token")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Security-Token", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Algorithm")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Algorithm", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-SignedHeaders", valid_606290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_DescribePlacement_606279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a placement in a project.
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_DescribePlacement_606279; placementName: string;
          projectName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   placementName: string (required)
  ##                : The name of the placement within a project.
  ##   projectName: string (required)
  ##              : The project containing the placement to be described.
  var path_606293 = newJObject()
  add(path_606293, "placementName", newJString(placementName))
  add(path_606293, "projectName", newJString(projectName))
  result = call_606292.call(path_606293, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_606279(name: "describePlacement",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_606280, base: "/",
    url: url_DescribePlacement_606281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_606311 = ref object of OpenApiRestCall_605589
proc url_DeletePlacement_606313(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePlacement_606312(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the empty placement to delete.
  ##   projectName: JString (required)
  ##              : The project containing the empty placement to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606314 = path.getOrDefault("placementName")
  valid_606314 = validateParameter(valid_606314, JString, required = true,
                                 default = nil)
  if valid_606314 != nil:
    section.add "placementName", valid_606314
  var valid_606315 = path.getOrDefault("projectName")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = nil)
  if valid_606315 != nil:
    section.add "projectName", valid_606315
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
  var valid_606316 = header.getOrDefault("X-Amz-Signature")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Signature", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Content-Sha256", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Date")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Date", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Credential")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Credential", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Security-Token")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Security-Token", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Algorithm")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Algorithm", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-SignedHeaders", valid_606322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606323: Call_DeletePlacement_606311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_606323.validator(path, query, header, formData, body)
  let scheme = call_606323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606323.url(scheme.get, call_606323.host, call_606323.base,
                         call_606323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606323, url, valid)

proc call*(call_606324: Call_DeletePlacement_606311; placementName: string;
          projectName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   placementName: string (required)
  ##                : The name of the empty placement to delete.
  ##   projectName: string (required)
  ##              : The project containing the empty placement to delete.
  var path_606325 = newJObject()
  add(path_606325, "placementName", newJString(placementName))
  add(path_606325, "projectName", newJString(projectName))
  result = call_606324.call(path_606325, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_606311(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_606312, base: "/", url: url_DeletePlacement_606313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_606340 = ref object of OpenApiRestCall_605589
proc url_UpdateProject_606342(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateProject_606341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606343 = path.getOrDefault("projectName")
  valid_606343 = validateParameter(valid_606343, JString, required = true,
                                 default = nil)
  if valid_606343 != nil:
    section.add "projectName", valid_606343
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
  var valid_606344 = header.getOrDefault("X-Amz-Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Signature", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Content-Sha256", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Date")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Date", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Credential")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Credential", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Security-Token")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Security-Token", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Algorithm")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Algorithm", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-SignedHeaders", valid_606350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606352: Call_UpdateProject_606340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ## 
  let valid = call_606352.validator(path, query, header, formData, body)
  let scheme = call_606352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606352.url(scheme.get, call_606352.host, call_606352.base,
                         call_606352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606352, url, valid)

proc call*(call_606353: Call_UpdateProject_606340; projectName: string;
          body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   projectName: string (required)
  ##              : The name of the project to be updated.
  ##   body: JObject (required)
  var path_606354 = newJObject()
  var body_606355 = newJObject()
  add(path_606354, "projectName", newJString(projectName))
  if body != nil:
    body_606355 = body
  result = call_606353.call(path_606354, nil, nil, nil, body_606355)

var updateProject* = Call_UpdateProject_606340(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_606341,
    base: "/", url: url_UpdateProject_606342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_606326 = ref object of OpenApiRestCall_605589
proc url_DescribeProject_606328(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProject_606327(path: JsonNode; query: JsonNode;
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
  var valid_606329 = path.getOrDefault("projectName")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = nil)
  if valid_606329 != nil:
    section.add "projectName", valid_606329
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
  var valid_606330 = header.getOrDefault("X-Amz-Signature")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Signature", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Content-Sha256", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Date")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Date", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Credential")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Credential", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Security-Token")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Security-Token", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Algorithm")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Algorithm", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-SignedHeaders", valid_606336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606337: Call_DescribeProject_606326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object describing a project.
  ## 
  let valid = call_606337.validator(path, query, header, formData, body)
  let scheme = call_606337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606337.url(scheme.get, call_606337.host, call_606337.base,
                         call_606337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606337, url, valid)

proc call*(call_606338: Call_DescribeProject_606326; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
  ##              : The name of the project to be described.
  var path_606339 = newJObject()
  add(path_606339, "projectName", newJString(projectName))
  result = call_606338.call(path_606339, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_606326(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_606327,
    base: "/", url: url_DescribeProject_606328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_606356 = ref object of OpenApiRestCall_605589
proc url_DeleteProject_606358(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProject_606357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606359 = path.getOrDefault("projectName")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "projectName", valid_606359
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
  var valid_606360 = header.getOrDefault("X-Amz-Signature")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Signature", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Content-Sha256", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Date")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Date", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Credential")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Credential", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Security-Token")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Security-Token", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Algorithm")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Algorithm", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-SignedHeaders", valid_606366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606367: Call_DeleteProject_606356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_606367.validator(path, query, header, formData, body)
  let scheme = call_606367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606367.url(scheme.get, call_606367.host, call_606367.base,
                         call_606367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606367, url, valid)

proc call*(call_606368: Call_DeleteProject_606356; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The name of the empty project to delete.
  var path_606369 = newJObject()
  add(path_606369, "projectName", newJString(projectName))
  result = call_606368.call(path_606369, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_606356(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_606357,
    base: "/", url: url_DeleteProject_606358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_606370 = ref object of OpenApiRestCall_605589
proc url_GetDevicesInPlacement_606372(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDevicesInPlacement_606371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an object enumerating the devices in a placement.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   placementName: JString (required)
  ##                : The name of the placement to get the devices from.
  ##   projectName: JString (required)
  ##              : The name of the project containing the placement.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `placementName` field"
  var valid_606373 = path.getOrDefault("placementName")
  valid_606373 = validateParameter(valid_606373, JString, required = true,
                                 default = nil)
  if valid_606373 != nil:
    section.add "placementName", valid_606373
  var valid_606374 = path.getOrDefault("projectName")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "projectName", valid_606374
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
  var valid_606375 = header.getOrDefault("X-Amz-Signature")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Signature", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Content-Sha256", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Date")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Date", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Credential")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Credential", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Security-Token")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Security-Token", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Algorithm")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Algorithm", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-SignedHeaders", valid_606381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606382: Call_GetDevicesInPlacement_606370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object enumerating the devices in a placement.
  ## 
  let valid = call_606382.validator(path, query, header, formData, body)
  let scheme = call_606382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606382.url(scheme.get, call_606382.host, call_606382.base,
                         call_606382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606382, url, valid)

proc call*(call_606383: Call_GetDevicesInPlacement_606370; placementName: string;
          projectName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   placementName: string (required)
  ##                : The name of the placement to get the devices from.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement.
  var path_606384 = newJObject()
  add(path_606384, "placementName", newJString(placementName))
  add(path_606384, "projectName", newJString(projectName))
  result = call_606383.call(path_606384, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_606370(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_606371, base: "/",
    url: url_GetDevicesInPlacement_606372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606399 = ref object of OpenApiRestCall_605589
proc url_TagResource_606401(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606402 = path.getOrDefault("resourceArn")
  valid_606402 = validateParameter(valid_606402, JString, required = true,
                                 default = nil)
  if valid_606402 != nil:
    section.add "resourceArn", valid_606402
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
  var valid_606403 = header.getOrDefault("X-Amz-Signature")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Signature", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Content-Sha256", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Date")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Date", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Credential")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Credential", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Security-Token")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Security-Token", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Algorithm")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Algorithm", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-SignedHeaders", valid_606409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606411: Call_TagResource_606399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ## 
  let valid = call_606411.validator(path, query, header, formData, body)
  let scheme = call_606411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606411.url(scheme.get, call_606411.host, call_606411.base,
                         call_606411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606411, url, valid)

proc call*(call_606412: Call_TagResource_606399; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   resourceArn: string (required)
  ##              : The ARN of the resouce for which tag(s) should be added or modified.
  ##   body: JObject (required)
  var path_606413 = newJObject()
  var body_606414 = newJObject()
  add(path_606413, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606414 = body
  result = call_606412.call(path_606413, nil, nil, nil, body_606414)

var tagResource* = Call_TagResource_606399(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606400,
                                        base: "/", url: url_TagResource_606401,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606385 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606387(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606386(path: JsonNode; query: JsonNode;
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
  var valid_606388 = path.getOrDefault("resourceArn")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "resourceArn", valid_606388
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
  var valid_606389 = header.getOrDefault("X-Amz-Signature")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Signature", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Content-Sha256", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Date")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Date", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Credential")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Credential", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Security-Token")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Security-Token", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Algorithm")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Algorithm", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-SignedHeaders", valid_606395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_ListTagsForResource_606385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_ListTagsForResource_606385; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var path_606398 = newJObject()
  add(path_606398, "resourceArn", newJString(resourceArn))
  result = call_606397.call(path_606398, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606385(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606386, base: "/",
    url: url_ListTagsForResource_606387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606415 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606417(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606418 = path.getOrDefault("resourceArn")
  valid_606418 = validateParameter(valid_606418, JString, required = true,
                                 default = nil)
  if valid_606418 != nil:
    section.add "resourceArn", valid_606418
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606419 = query.getOrDefault("tagKeys")
  valid_606419 = validateParameter(valid_606419, JArray, required = true, default = nil)
  if valid_606419 != nil:
    section.add "tagKeys", valid_606419
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
  var valid_606420 = header.getOrDefault("X-Amz-Signature")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Signature", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Content-Sha256", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Date")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Date", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Credential")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Credential", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Security-Token")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Security-Token", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Algorithm")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Algorithm", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-SignedHeaders", valid_606426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606427: Call_UntagResource_606415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ## 
  let valid = call_606427.validator(path, query, header, formData, body)
  let scheme = call_606427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606427.url(scheme.get, call_606427.host, call_606427.base,
                         call_606427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606427, url, valid)

proc call*(call_606428: Call_UntagResource_606415; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tag you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var path_606429 = newJObject()
  var query_606430 = newJObject()
  add(path_606429, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606430.add "tagKeys", tagKeys
  result = call_606428.call(path_606429, query_606430, nil, nil, nil)

var untagResource* = Call_UntagResource_606415(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606416,
    base: "/", url: url_UntagResource_606417, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
