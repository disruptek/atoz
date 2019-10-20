
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateDeviceWithPlacement_592703 = ref object of OpenApiRestCall_592364
proc url_AssociateDeviceWithPlacement_592705(protocol: Scheme; host: string;
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

proc validate_AssociateDeviceWithPlacement_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("placementName")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "placementName", valid_592831
  var valid_592832 = path.getOrDefault("deviceTemplateName")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "deviceTemplateName", valid_592832
  var valid_592833 = path.getOrDefault("projectName")
  valid_592833 = validateParameter(valid_592833, JString, required = true,
                                 default = nil)
  if valid_592833 != nil:
    section.add "projectName", valid_592833
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
  var valid_592834 = header.getOrDefault("X-Amz-Signature")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Signature", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Content-Sha256", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Date")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Date", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Credential")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Credential", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Security-Token")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Security-Token", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Algorithm")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Algorithm", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-SignedHeaders", valid_592840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592864: Call_AssociateDeviceWithPlacement_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a physical device with a placement.
  ## 
  let valid = call_592864.validator(path, query, header, formData, body)
  let scheme = call_592864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592864.url(scheme.get, call_592864.host, call_592864.base,
                         call_592864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592864, url, valid)

proc call*(call_592935: Call_AssociateDeviceWithPlacement_592703;
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
  var path_592936 = newJObject()
  var body_592938 = newJObject()
  add(path_592936, "placementName", newJString(placementName))
  add(path_592936, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_592936, "projectName", newJString(projectName))
  if body != nil:
    body_592938 = body
  result = call_592935.call(path_592936, nil, nil, nil, body_592938)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_592703(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_592704, base: "/",
    url: url_AssociateDeviceWithPlacement_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_592977 = ref object of OpenApiRestCall_592364
proc url_DisassociateDeviceFromPlacement_592979(protocol: Scheme; host: string;
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

proc validate_DisassociateDeviceFromPlacement_592978(path: JsonNode;
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
  var valid_592980 = path.getOrDefault("placementName")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = nil)
  if valid_592980 != nil:
    section.add "placementName", valid_592980
  var valid_592981 = path.getOrDefault("deviceTemplateName")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "deviceTemplateName", valid_592981
  var valid_592982 = path.getOrDefault("projectName")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = nil)
  if valid_592982 != nil:
    section.add "projectName", valid_592982
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
  var valid_592983 = header.getOrDefault("X-Amz-Signature")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Signature", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Content-Sha256", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Date")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Date", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Credential")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Credential", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Security-Token")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Security-Token", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Algorithm")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Algorithm", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-SignedHeaders", valid_592989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_DisassociateDeviceFromPlacement_592977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a physical device from a placement.
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_DisassociateDeviceFromPlacement_592977;
          placementName: string; deviceTemplateName: string; projectName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   placementName: string (required)
  ##                : The name of the placement that the device should be removed from.
  ##   deviceTemplateName: string (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: string (required)
  ##              : The name of the project that contains the placement.
  var path_592992 = newJObject()
  add(path_592992, "placementName", newJString(placementName))
  add(path_592992, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_592992, "projectName", newJString(projectName))
  result = call_592991.call(path_592992, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_592977(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_592978, base: "/",
    url: url_DisassociateDeviceFromPlacement_592979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_593010 = ref object of OpenApiRestCall_592364
proc url_CreatePlacement_593012(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePlacement_593011(path: JsonNode; query: JsonNode;
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
  var valid_593013 = path.getOrDefault("projectName")
  valid_593013 = validateParameter(valid_593013, JString, required = true,
                                 default = nil)
  if valid_593013 != nil:
    section.add "projectName", valid_593013
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
  var valid_593014 = header.getOrDefault("X-Amz-Signature")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Signature", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Content-Sha256", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Date")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Date", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Credential")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Credential", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Security-Token")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Security-Token", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Algorithm")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Algorithm", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-SignedHeaders", valid_593020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593022: Call_CreatePlacement_593010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty placement.
  ## 
  let valid = call_593022.validator(path, query, header, formData, body)
  let scheme = call_593022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593022.url(scheme.get, call_593022.host, call_593022.base,
                         call_593022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593022, url, valid)

proc call*(call_593023: Call_CreatePlacement_593010; projectName: string;
          body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
  ##              : The name of the project in which to create the placement.
  ##   body: JObject (required)
  var path_593024 = newJObject()
  var body_593025 = newJObject()
  add(path_593024, "projectName", newJString(projectName))
  if body != nil:
    body_593025 = body
  result = call_593023.call(path_593024, nil, nil, nil, body_593025)

var createPlacement* = Call_CreatePlacement_593010(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_593011, base: "/", url: url_CreatePlacement_593012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_592993 = ref object of OpenApiRestCall_592364
proc url_ListPlacements_592995(protocol: Scheme; host: string; base: string;
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

proc validate_ListPlacements_592994(path: JsonNode; query: JsonNode;
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
  var valid_592996 = path.getOrDefault("projectName")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = nil)
  if valid_592996 != nil:
    section.add "projectName", valid_592996
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  section = newJObject()
  var valid_592997 = query.getOrDefault("nextToken")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "nextToken", valid_592997
  var valid_592998 = query.getOrDefault("maxResults")
  valid_592998 = validateParameter(valid_592998, JInt, required = false, default = nil)
  if valid_592998 != nil:
    section.add "maxResults", valid_592998
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
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Security-Token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Security-Token", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Algorithm")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Algorithm", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-SignedHeaders", valid_593005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_ListPlacements_592993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the placement(s) of a project.
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_ListPlacements_592993; projectName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   projectName: string (required)
  ##              : The project containing the placements to be listed.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  var path_593008 = newJObject()
  var query_593009 = newJObject()
  add(query_593009, "nextToken", newJString(nextToken))
  add(path_593008, "projectName", newJString(projectName))
  add(query_593009, "maxResults", newJInt(maxResults))
  result = call_593007.call(path_593008, query_593009, nil, nil, nil)

var listPlacements* = Call_ListPlacements_592993(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_592994, base: "/", url: url_ListPlacements_592995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_593041 = ref object of OpenApiRestCall_592364
proc url_CreateProject_593043(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_593042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593052: Call_CreateProject_593041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ## 
  let valid = call_593052.validator(path, query, header, formData, body)
  let scheme = call_593052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593052.url(scheme.get, call_593052.host, call_593052.base,
                         call_593052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593052, url, valid)

proc call*(call_593053: Call_CreateProject_593041; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   body: JObject (required)
  var body_593054 = newJObject()
  if body != nil:
    body_593054 = body
  result = call_593053.call(nil, nil, nil, nil, body_593054)

var createProject* = Call_CreateProject_593041(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_593042, base: "/",
    url: url_CreateProject_593043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_593026 = ref object of OpenApiRestCall_592364
proc url_ListProjects_593028(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_593027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593029 = query.getOrDefault("nextToken")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "nextToken", valid_593029
  var valid_593030 = query.getOrDefault("maxResults")
  valid_593030 = validateParameter(valid_593030, JInt, required = false, default = nil)
  if valid_593030 != nil:
    section.add "maxResults", valid_593030
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
  var valid_593031 = header.getOrDefault("X-Amz-Signature")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Signature", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Content-Sha256", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Date")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Date", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Credential")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Credential", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Security-Token")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Security-Token", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Algorithm")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Algorithm", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-SignedHeaders", valid_593037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593038: Call_ListProjects_593026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  let valid = call_593038.validator(path, query, header, formData, body)
  let scheme = call_593038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593038.url(scheme.get, call_593038.host, call_593038.base,
                         call_593038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593038, url, valid)

proc call*(call_593039: Call_ListProjects_593026; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  var query_593040 = newJObject()
  add(query_593040, "nextToken", newJString(nextToken))
  add(query_593040, "maxResults", newJInt(maxResults))
  result = call_593039.call(nil, query_593040, nil, nil, nil)

var listProjects* = Call_ListProjects_593026(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_593027, base: "/",
    url: url_ListProjects_593028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_593070 = ref object of OpenApiRestCall_592364
proc url_UpdatePlacement_593072(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePlacement_593071(path: JsonNode; query: JsonNode;
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
  var valid_593073 = path.getOrDefault("placementName")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = nil)
  if valid_593073 != nil:
    section.add "placementName", valid_593073
  var valid_593074 = path.getOrDefault("projectName")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = nil)
  if valid_593074 != nil:
    section.add "projectName", valid_593074
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
  var valid_593075 = header.getOrDefault("X-Amz-Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Signature", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Content-Sha256", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Date")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Date", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Credential")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Credential", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Security-Token")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Security-Token", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Algorithm")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Algorithm", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-SignedHeaders", valid_593081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593083: Call_UpdatePlacement_593070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  let valid = call_593083.validator(path, query, header, formData, body)
  let scheme = call_593083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593083.url(scheme.get, call_593083.host, call_593083.base,
                         call_593083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593083, url, valid)

proc call*(call_593084: Call_UpdatePlacement_593070; placementName: string;
          projectName: string; body: JsonNode): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   placementName: string (required)
  ##                : The name of the placement to update.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement to be updated.
  ##   body: JObject (required)
  var path_593085 = newJObject()
  var body_593086 = newJObject()
  add(path_593085, "placementName", newJString(placementName))
  add(path_593085, "projectName", newJString(projectName))
  if body != nil:
    body_593086 = body
  result = call_593084.call(path_593085, nil, nil, nil, body_593086)

var updatePlacement* = Call_UpdatePlacement_593070(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_593071, base: "/", url: url_UpdatePlacement_593072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_593055 = ref object of OpenApiRestCall_592364
proc url_DescribePlacement_593057(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePlacement_593056(path: JsonNode; query: JsonNode;
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
  var valid_593058 = path.getOrDefault("placementName")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "placementName", valid_593058
  var valid_593059 = path.getOrDefault("projectName")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "projectName", valid_593059
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
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_DescribePlacement_593055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a placement in a project.
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_DescribePlacement_593055; placementName: string;
          projectName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   placementName: string (required)
  ##                : The name of the placement within a project.
  ##   projectName: string (required)
  ##              : The project containing the placement to be described.
  var path_593069 = newJObject()
  add(path_593069, "placementName", newJString(placementName))
  add(path_593069, "projectName", newJString(projectName))
  result = call_593068.call(path_593069, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_593055(name: "describePlacement",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_593056, base: "/",
    url: url_DescribePlacement_593057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_593087 = ref object of OpenApiRestCall_592364
proc url_DeletePlacement_593089(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePlacement_593088(path: JsonNode; query: JsonNode;
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
  var valid_593090 = path.getOrDefault("placementName")
  valid_593090 = validateParameter(valid_593090, JString, required = true,
                                 default = nil)
  if valid_593090 != nil:
    section.add "placementName", valid_593090
  var valid_593091 = path.getOrDefault("projectName")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = nil)
  if valid_593091 != nil:
    section.add "projectName", valid_593091
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
  var valid_593092 = header.getOrDefault("X-Amz-Signature")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Signature", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Content-Sha256", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Date")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Date", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Credential")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Credential", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Security-Token")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Security-Token", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Algorithm")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Algorithm", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-SignedHeaders", valid_593098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593099: Call_DeletePlacement_593087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_593099.validator(path, query, header, formData, body)
  let scheme = call_593099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593099.url(scheme.get, call_593099.host, call_593099.base,
                         call_593099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593099, url, valid)

proc call*(call_593100: Call_DeletePlacement_593087; placementName: string;
          projectName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   placementName: string (required)
  ##                : The name of the empty placement to delete.
  ##   projectName: string (required)
  ##              : The project containing the empty placement to delete.
  var path_593101 = newJObject()
  add(path_593101, "placementName", newJString(placementName))
  add(path_593101, "projectName", newJString(projectName))
  result = call_593100.call(path_593101, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_593087(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_593088, base: "/", url: url_DeletePlacement_593089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_593116 = ref object of OpenApiRestCall_592364
proc url_UpdateProject_593118(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_593117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593119 = path.getOrDefault("projectName")
  valid_593119 = validateParameter(valid_593119, JString, required = true,
                                 default = nil)
  if valid_593119 != nil:
    section.add "projectName", valid_593119
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
  var valid_593120 = header.getOrDefault("X-Amz-Signature")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Signature", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Content-Sha256", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Date")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Date", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Credential")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Credential", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Security-Token")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Security-Token", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Algorithm")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Algorithm", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-SignedHeaders", valid_593126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593128: Call_UpdateProject_593116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ## 
  let valid = call_593128.validator(path, query, header, formData, body)
  let scheme = call_593128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593128.url(scheme.get, call_593128.host, call_593128.base,
                         call_593128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593128, url, valid)

proc call*(call_593129: Call_UpdateProject_593116; projectName: string;
          body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   projectName: string (required)
  ##              : The name of the project to be updated.
  ##   body: JObject (required)
  var path_593130 = newJObject()
  var body_593131 = newJObject()
  add(path_593130, "projectName", newJString(projectName))
  if body != nil:
    body_593131 = body
  result = call_593129.call(path_593130, nil, nil, nil, body_593131)

var updateProject* = Call_UpdateProject_593116(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_593117,
    base: "/", url: url_UpdateProject_593118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_593102 = ref object of OpenApiRestCall_592364
proc url_DescribeProject_593104(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProject_593103(path: JsonNode; query: JsonNode;
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
  var valid_593105 = path.getOrDefault("projectName")
  valid_593105 = validateParameter(valid_593105, JString, required = true,
                                 default = nil)
  if valid_593105 != nil:
    section.add "projectName", valid_593105
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
  var valid_593106 = header.getOrDefault("X-Amz-Signature")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Signature", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Content-Sha256", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Date")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Date", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Credential")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Credential", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Security-Token")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Security-Token", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Algorithm")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Algorithm", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-SignedHeaders", valid_593112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593113: Call_DescribeProject_593102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object describing a project.
  ## 
  let valid = call_593113.validator(path, query, header, formData, body)
  let scheme = call_593113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593113.url(scheme.get, call_593113.host, call_593113.base,
                         call_593113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593113, url, valid)

proc call*(call_593114: Call_DescribeProject_593102; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
  ##              : The name of the project to be described.
  var path_593115 = newJObject()
  add(path_593115, "projectName", newJString(projectName))
  result = call_593114.call(path_593115, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_593102(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_593103,
    base: "/", url: url_DescribeProject_593104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_593132 = ref object of OpenApiRestCall_592364
proc url_DeleteProject_593134(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_593133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593135 = path.getOrDefault("projectName")
  valid_593135 = validateParameter(valid_593135, JString, required = true,
                                 default = nil)
  if valid_593135 != nil:
    section.add "projectName", valid_593135
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
  var valid_593136 = header.getOrDefault("X-Amz-Signature")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Signature", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Content-Sha256", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Date")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Date", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Credential")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Credential", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Security-Token")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Security-Token", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Algorithm")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Algorithm", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-SignedHeaders", valid_593142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593143: Call_DeleteProject_593132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_593143.validator(path, query, header, formData, body)
  let scheme = call_593143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593143.url(scheme.get, call_593143.host, call_593143.base,
                         call_593143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593143, url, valid)

proc call*(call_593144: Call_DeleteProject_593132; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The name of the empty project to delete.
  var path_593145 = newJObject()
  add(path_593145, "projectName", newJString(projectName))
  result = call_593144.call(path_593145, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_593132(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_593133,
    base: "/", url: url_DeleteProject_593134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_593146 = ref object of OpenApiRestCall_592364
proc url_GetDevicesInPlacement_593148(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevicesInPlacement_593147(path: JsonNode; query: JsonNode;
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
  var valid_593149 = path.getOrDefault("placementName")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "placementName", valid_593149
  var valid_593150 = path.getOrDefault("projectName")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "projectName", valid_593150
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
  var valid_593151 = header.getOrDefault("X-Amz-Signature")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Signature", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Content-Sha256", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Date")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Date", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Credential")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Credential", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Security-Token")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Security-Token", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Algorithm")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Algorithm", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-SignedHeaders", valid_593157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593158: Call_GetDevicesInPlacement_593146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object enumerating the devices in a placement.
  ## 
  let valid = call_593158.validator(path, query, header, formData, body)
  let scheme = call_593158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593158.url(scheme.get, call_593158.host, call_593158.base,
                         call_593158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593158, url, valid)

proc call*(call_593159: Call_GetDevicesInPlacement_593146; placementName: string;
          projectName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   placementName: string (required)
  ##                : The name of the placement to get the devices from.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement.
  var path_593160 = newJObject()
  add(path_593160, "placementName", newJString(placementName))
  add(path_593160, "projectName", newJString(projectName))
  result = call_593159.call(path_593160, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_593146(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_593147, base: "/",
    url: url_GetDevicesInPlacement_593148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593175 = ref object of OpenApiRestCall_592364
proc url_TagResource_593177(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_593176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593178 = path.getOrDefault("resourceArn")
  valid_593178 = validateParameter(valid_593178, JString, required = true,
                                 default = nil)
  if valid_593178 != nil:
    section.add "resourceArn", valid_593178
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
  var valid_593179 = header.getOrDefault("X-Amz-Signature")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Signature", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Content-Sha256", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Date")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Date", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Credential")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Credential", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Security-Token")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Security-Token", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Algorithm")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Algorithm", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-SignedHeaders", valid_593185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593187: Call_TagResource_593175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ## 
  let valid = call_593187.validator(path, query, header, formData, body)
  let scheme = call_593187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593187.url(scheme.get, call_593187.host, call_593187.base,
                         call_593187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593187, url, valid)

proc call*(call_593188: Call_TagResource_593175; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   resourceArn: string (required)
  ##              : The ARN of the resouce for which tag(s) should be added or modified.
  ##   body: JObject (required)
  var path_593189 = newJObject()
  var body_593190 = newJObject()
  add(path_593189, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593190 = body
  result = call_593188.call(path_593189, nil, nil, nil, body_593190)

var tagResource* = Call_TagResource_593175(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_593176,
                                        base: "/", url: url_TagResource_593177,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593161 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593163(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_593162(path: JsonNode; query: JsonNode;
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
  var valid_593164 = path.getOrDefault("resourceArn")
  valid_593164 = validateParameter(valid_593164, JString, required = true,
                                 default = nil)
  if valid_593164 != nil:
    section.add "resourceArn", valid_593164
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
  var valid_593165 = header.getOrDefault("X-Amz-Signature")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Signature", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Content-Sha256", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Date")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Date", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Credential")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Credential", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Security-Token")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Security-Token", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Algorithm")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Algorithm", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-SignedHeaders", valid_593171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_ListTagsForResource_593161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ## 
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_ListTagsForResource_593161; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var path_593174 = newJObject()
  add(path_593174, "resourceArn", newJString(resourceArn))
  result = call_593173.call(path_593174, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593161(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_593162, base: "/",
    url: url_ListTagsForResource_593163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593191 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593193(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593194 = path.getOrDefault("resourceArn")
  valid_593194 = validateParameter(valid_593194, JString, required = true,
                                 default = nil)
  if valid_593194 != nil:
    section.add "resourceArn", valid_593194
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593195 = query.getOrDefault("tagKeys")
  valid_593195 = validateParameter(valid_593195, JArray, required = true, default = nil)
  if valid_593195 != nil:
    section.add "tagKeys", valid_593195
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
  var valid_593196 = header.getOrDefault("X-Amz-Signature")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Signature", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Content-Sha256", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Date")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Date", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Credential")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Credential", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Security-Token")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Security-Token", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Algorithm")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Algorithm", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-SignedHeaders", valid_593202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593203: Call_UntagResource_593191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ## 
  let valid = call_593203.validator(path, query, header, formData, body)
  let scheme = call_593203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593203.url(scheme.get, call_593203.host, call_593203.base,
                         call_593203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593203, url, valid)

proc call*(call_593204: Call_UntagResource_593191; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tag you want to remove.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  var path_593205 = newJObject()
  var query_593206 = newJObject()
  add(path_593205, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_593206.add "tagKeys", tagKeys
  result = call_593204.call(path_593205, query_593206, nil, nil, nil)

var untagResource* = Call_UntagResource_593191(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_593192,
    base: "/", url: url_UntagResource_593193, schemes: {Scheme.Https, Scheme.Http})
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
