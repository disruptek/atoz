
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
  Call_AssociateDeviceWithPlacement_599705 = ref object of OpenApiRestCall_599368
proc url_AssociateDeviceWithPlacement_599707(protocol: Scheme; host: string;
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

proc validate_AssociateDeviceWithPlacement_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("deviceTemplateName")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "deviceTemplateName", valid_599833
  var valid_599834 = path.getOrDefault("projectName")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "projectName", valid_599834
  var valid_599835 = path.getOrDefault("placementName")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = nil)
  if valid_599835 != nil:
    section.add "placementName", valid_599835
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
  var valid_599836 = header.getOrDefault("X-Amz-Date")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Date", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Security-Token")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Security-Token", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Algorithm")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Algorithm", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Signature")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Signature", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-SignedHeaders", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Credential")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Credential", valid_599842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599866: Call_AssociateDeviceWithPlacement_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a physical device with a placement.
  ## 
  let valid = call_599866.validator(path, query, header, formData, body)
  let scheme = call_599866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599866.url(scheme.get, call_599866.host, call_599866.base,
                         call_599866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599866, url, valid)

proc call*(call_599937: Call_AssociateDeviceWithPlacement_599705;
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
  var path_599938 = newJObject()
  var body_599940 = newJObject()
  add(path_599938, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_599938, "projectName", newJString(projectName))
  if body != nil:
    body_599940 = body
  add(path_599938, "placementName", newJString(placementName))
  result = call_599937.call(path_599938, nil, nil, nil, body_599940)

var associateDeviceWithPlacement* = Call_AssociateDeviceWithPlacement_599705(
    name: "associateDeviceWithPlacement", meth: HttpMethod.HttpPut,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_AssociateDeviceWithPlacement_599706, base: "/",
    url: url_AssociateDeviceWithPlacement_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromPlacement_599979 = ref object of OpenApiRestCall_599368
proc url_DisassociateDeviceFromPlacement_599981(protocol: Scheme; host: string;
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

proc validate_DisassociateDeviceFromPlacement_599980(path: JsonNode;
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
  var valid_599982 = path.getOrDefault("deviceTemplateName")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = nil)
  if valid_599982 != nil:
    section.add "deviceTemplateName", valid_599982
  var valid_599983 = path.getOrDefault("projectName")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "projectName", valid_599983
  var valid_599984 = path.getOrDefault("placementName")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = nil)
  if valid_599984 != nil:
    section.add "placementName", valid_599984
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
  var valid_599985 = header.getOrDefault("X-Amz-Date")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Date", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Security-Token")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Security-Token", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Content-Sha256", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Algorithm")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Algorithm", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Signature")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Signature", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-SignedHeaders", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Credential")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Credential", valid_599991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_DisassociateDeviceFromPlacement_599979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a physical device from a placement.
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_DisassociateDeviceFromPlacement_599979;
          deviceTemplateName: string; projectName: string; placementName: string): Recallable =
  ## disassociateDeviceFromPlacement
  ## Removes a physical device from a placement.
  ##   deviceTemplateName: string (required)
  ##                     : The device ID that should be removed from the placement.
  ##   projectName: string (required)
  ##              : The name of the project that contains the placement.
  ##   placementName: string (required)
  ##                : The name of the placement that the device should be removed from.
  var path_599994 = newJObject()
  add(path_599994, "deviceTemplateName", newJString(deviceTemplateName))
  add(path_599994, "projectName", newJString(projectName))
  add(path_599994, "placementName", newJString(placementName))
  result = call_599993.call(path_599994, nil, nil, nil, nil)

var disassociateDeviceFromPlacement* = Call_DisassociateDeviceFromPlacement_599979(
    name: "disassociateDeviceFromPlacement", meth: HttpMethod.HttpDelete,
    host: "projects.iot1click.amazonaws.com", route: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}",
    validator: validate_DisassociateDeviceFromPlacement_599980, base: "/",
    url: url_DisassociateDeviceFromPlacement_599981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlacement_600012 = ref object of OpenApiRestCall_599368
proc url_CreatePlacement_600014(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePlacement_600013(path: JsonNode; query: JsonNode;
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
  var valid_600015 = path.getOrDefault("projectName")
  valid_600015 = validateParameter(valid_600015, JString, required = true,
                                 default = nil)
  if valid_600015 != nil:
    section.add "projectName", valid_600015
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
  var valid_600016 = header.getOrDefault("X-Amz-Date")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Date", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Security-Token")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Security-Token", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600024: Call_CreatePlacement_600012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty placement.
  ## 
  let valid = call_600024.validator(path, query, header, formData, body)
  let scheme = call_600024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600024.url(scheme.get, call_600024.host, call_600024.base,
                         call_600024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600024, url, valid)

proc call*(call_600025: Call_CreatePlacement_600012; projectName: string;
          body: JsonNode): Recallable =
  ## createPlacement
  ## Creates an empty placement.
  ##   projectName: string (required)
  ##              : The name of the project in which to create the placement.
  ##   body: JObject (required)
  var path_600026 = newJObject()
  var body_600027 = newJObject()
  add(path_600026, "projectName", newJString(projectName))
  if body != nil:
    body_600027 = body
  result = call_600025.call(path_600026, nil, nil, nil, body_600027)

var createPlacement* = Call_CreatePlacement_600012(name: "createPlacement",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_CreatePlacement_600013, base: "/", url: url_CreatePlacement_600014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlacements_599995 = ref object of OpenApiRestCall_599368
proc url_ListPlacements_599997(protocol: Scheme; host: string; base: string;
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

proc validate_ListPlacements_599996(path: JsonNode; query: JsonNode;
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
  var valid_599998 = path.getOrDefault("projectName")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = nil)
  if valid_599998 != nil:
    section.add "projectName", valid_599998
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: JString
  ##            : The token to retrieve the next set of results.
  section = newJObject()
  var valid_599999 = query.getOrDefault("maxResults")
  valid_599999 = validateParameter(valid_599999, JInt, required = false, default = nil)
  if valid_599999 != nil:
    section.add "maxResults", valid_599999
  var valid_600000 = query.getOrDefault("nextToken")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "nextToken", valid_600000
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
  var valid_600001 = header.getOrDefault("X-Amz-Date")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Date", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Security-Token")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Security-Token", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Content-Sha256", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Algorithm")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Algorithm", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Signature")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Signature", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-SignedHeaders", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Credential")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Credential", valid_600007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600008: Call_ListPlacements_599995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the placement(s) of a project.
  ## 
  let valid = call_600008.validator(path, query, header, formData, body)
  let scheme = call_600008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600008.url(scheme.get, call_600008.host, call_600008.base,
                         call_600008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600008, url, valid)

proc call*(call_600009: Call_ListPlacements_599995; projectName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listPlacements
  ## Lists the placement(s) of a project.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  ##   projectName: string (required)
  ##              : The project containing the placements to be listed.
  var path_600010 = newJObject()
  var query_600011 = newJObject()
  add(query_600011, "maxResults", newJInt(maxResults))
  add(query_600011, "nextToken", newJString(nextToken))
  add(path_600010, "projectName", newJString(projectName))
  result = call_600009.call(path_600010, query_600011, nil, nil, nil)

var listPlacements* = Call_ListPlacements_599995(name: "listPlacements",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements",
    validator: validate_ListPlacements_599996, base: "/", url: url_ListPlacements_599997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_600043 = ref object of OpenApiRestCall_599368
proc url_CreateProject_600045(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_600044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600054: Call_CreateProject_600043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_CreateProject_600043; body: JsonNode): Recallable =
  ## createProject
  ## Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
  ##   body: JObject (required)
  var body_600056 = newJObject()
  if body != nil:
    body_600056 = body
  result = call_600055.call(nil, nil, nil, nil, body_600056)

var createProject* = Call_CreateProject_600043(name: "createProject",
    meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_CreateProject_600044, base: "/",
    url: url_CreateProject_600045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_600028 = ref object of OpenApiRestCall_599368
proc url_ListProjects_600030(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_600029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600031 = query.getOrDefault("maxResults")
  valid_600031 = validateParameter(valid_600031, JInt, required = false, default = nil)
  if valid_600031 != nil:
    section.add "maxResults", valid_600031
  var valid_600032 = query.getOrDefault("nextToken")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "nextToken", valid_600032
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
  var valid_600033 = header.getOrDefault("X-Amz-Date")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Date", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Security-Token")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Security-Token", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Content-Sha256", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Algorithm")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Algorithm", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Signature")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Signature", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-SignedHeaders", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Credential")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Credential", valid_600039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600040: Call_ListProjects_600028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ## 
  let valid = call_600040.validator(path, query, header, formData, body)
  let scheme = call_600040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600040.url(scheme.get, call_600040.host, call_600040.base,
                         call_600040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600040, url, valid)

proc call*(call_600041: Call_ListProjects_600028; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ## Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
  ##   maxResults: int
  ##             : The maximum number of results to return per request. If not set, a default value of 100 is used.
  ##   nextToken: string
  ##            : The token to retrieve the next set of results.
  var query_600042 = newJObject()
  add(query_600042, "maxResults", newJInt(maxResults))
  add(query_600042, "nextToken", newJString(nextToken))
  result = call_600041.call(nil, query_600042, nil, nil, nil)

var listProjects* = Call_ListProjects_600028(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects", validator: validate_ListProjects_600029, base: "/",
    url: url_ListProjects_600030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePlacement_600072 = ref object of OpenApiRestCall_599368
proc url_UpdatePlacement_600074(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePlacement_600073(path: JsonNode; query: JsonNode;
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
  var valid_600075 = path.getOrDefault("projectName")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = nil)
  if valid_600075 != nil:
    section.add "projectName", valid_600075
  var valid_600076 = path.getOrDefault("placementName")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = nil)
  if valid_600076 != nil:
    section.add "placementName", valid_600076
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
  var valid_600077 = header.getOrDefault("X-Amz-Date")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Date", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Security-Token")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Security-Token", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Content-Sha256", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Algorithm")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Algorithm", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Signature")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Signature", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-SignedHeaders", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Credential")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Credential", valid_600083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600085: Call_UpdatePlacement_600072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ## 
  let valid = call_600085.validator(path, query, header, formData, body)
  let scheme = call_600085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600085.url(scheme.get, call_600085.host, call_600085.base,
                         call_600085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600085, url, valid)

proc call*(call_600086: Call_UpdatePlacement_600072; projectName: string;
          body: JsonNode; placementName: string): Recallable =
  ## updatePlacement
  ## Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
  ##   projectName: string (required)
  ##              : The name of the project containing the placement to be updated.
  ##   body: JObject (required)
  ##   placementName: string (required)
  ##                : The name of the placement to update.
  var path_600087 = newJObject()
  var body_600088 = newJObject()
  add(path_600087, "projectName", newJString(projectName))
  if body != nil:
    body_600088 = body
  add(path_600087, "placementName", newJString(placementName))
  result = call_600086.call(path_600087, nil, nil, nil, body_600088)

var updatePlacement* = Call_UpdatePlacement_600072(name: "updatePlacement",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_UpdatePlacement_600073, base: "/", url: url_UpdatePlacement_600074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlacement_600057 = ref object of OpenApiRestCall_599368
proc url_DescribePlacement_600059(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePlacement_600058(path: JsonNode; query: JsonNode;
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
  var valid_600060 = path.getOrDefault("projectName")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "projectName", valid_600060
  var valid_600061 = path.getOrDefault("placementName")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "placementName", valid_600061
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
  var valid_600062 = header.getOrDefault("X-Amz-Date")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Date", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Security-Token")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Security-Token", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Content-Sha256", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Algorithm")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Algorithm", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Signature")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Signature", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-SignedHeaders", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Credential")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Credential", valid_600068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_DescribePlacement_600057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a placement in a project.
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_DescribePlacement_600057; projectName: string;
          placementName: string): Recallable =
  ## describePlacement
  ## Describes a placement in a project.
  ##   projectName: string (required)
  ##              : The project containing the placement to be described.
  ##   placementName: string (required)
  ##                : The name of the placement within a project.
  var path_600071 = newJObject()
  add(path_600071, "projectName", newJString(projectName))
  add(path_600071, "placementName", newJString(placementName))
  result = call_600070.call(path_600071, nil, nil, nil, nil)

var describePlacement* = Call_DescribePlacement_600057(name: "describePlacement",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DescribePlacement_600058, base: "/",
    url: url_DescribePlacement_600059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlacement_600089 = ref object of OpenApiRestCall_599368
proc url_DeletePlacement_600091(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePlacement_600090(path: JsonNode; query: JsonNode;
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
  var valid_600092 = path.getOrDefault("projectName")
  valid_600092 = validateParameter(valid_600092, JString, required = true,
                                 default = nil)
  if valid_600092 != nil:
    section.add "projectName", valid_600092
  var valid_600093 = path.getOrDefault("placementName")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = nil)
  if valid_600093 != nil:
    section.add "placementName", valid_600093
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
  var valid_600094 = header.getOrDefault("X-Amz-Date")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Date", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Security-Token")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Security-Token", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Content-Sha256", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Algorithm")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Algorithm", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Signature")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Signature", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-SignedHeaders", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Credential")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Credential", valid_600100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600101: Call_DeletePlacement_600089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_600101.validator(path, query, header, formData, body)
  let scheme = call_600101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600101.url(scheme.get, call_600101.host, call_600101.base,
                         call_600101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600101, url, valid)

proc call*(call_600102: Call_DeletePlacement_600089; projectName: string;
          placementName: string): Recallable =
  ## deletePlacement
  ## <p>Deletes a placement. To delete a placement, it must not have any devices associated with it.</p> <note> <p>When you delete a placement, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The project containing the empty placement to delete.
  ##   placementName: string (required)
  ##                : The name of the empty placement to delete.
  var path_600103 = newJObject()
  add(path_600103, "projectName", newJString(projectName))
  add(path_600103, "placementName", newJString(placementName))
  result = call_600102.call(path_600103, nil, nil, nil, nil)

var deletePlacement* = Call_DeletePlacement_600089(name: "deletePlacement",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}",
    validator: validate_DeletePlacement_600090, base: "/", url: url_DeletePlacement_600091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_600118 = ref object of OpenApiRestCall_599368
proc url_UpdateProject_600120(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_600119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600121 = path.getOrDefault("projectName")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = nil)
  if valid_600121 != nil:
    section.add "projectName", valid_600121
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
  var valid_600122 = header.getOrDefault("X-Amz-Date")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Date", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Security-Token")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Security-Token", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Content-Sha256", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Algorithm")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Algorithm", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Signature")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Signature", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-SignedHeaders", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Credential")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Credential", valid_600128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600130: Call_UpdateProject_600118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ## 
  let valid = call_600130.validator(path, query, header, formData, body)
  let scheme = call_600130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600130.url(scheme.get, call_600130.host, call_600130.base,
                         call_600130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600130, url, valid)

proc call*(call_600131: Call_UpdateProject_600118; projectName: string;
          body: JsonNode): Recallable =
  ## updateProject
  ## Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., <code>""</code>).
  ##   projectName: string (required)
  ##              : The name of the project to be updated.
  ##   body: JObject (required)
  var path_600132 = newJObject()
  var body_600133 = newJObject()
  add(path_600132, "projectName", newJString(projectName))
  if body != nil:
    body_600133 = body
  result = call_600131.call(path_600132, nil, nil, nil, body_600133)

var updateProject* = Call_UpdateProject_600118(name: "updateProject",
    meth: HttpMethod.HttpPut, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_UpdateProject_600119,
    base: "/", url: url_UpdateProject_600120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_600104 = ref object of OpenApiRestCall_599368
proc url_DescribeProject_600106(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProject_600105(path: JsonNode; query: JsonNode;
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
  var valid_600107 = path.getOrDefault("projectName")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "projectName", valid_600107
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
  var valid_600108 = header.getOrDefault("X-Amz-Date")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Date", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Security-Token")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Security-Token", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Content-Sha256", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Algorithm")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Algorithm", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Signature")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Signature", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-SignedHeaders", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Credential")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Credential", valid_600114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600115: Call_DescribeProject_600104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object describing a project.
  ## 
  let valid = call_600115.validator(path, query, header, formData, body)
  let scheme = call_600115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600115.url(scheme.get, call_600115.host, call_600115.base,
                         call_600115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600115, url, valid)

proc call*(call_600116: Call_DescribeProject_600104; projectName: string): Recallable =
  ## describeProject
  ## Returns an object describing a project.
  ##   projectName: string (required)
  ##              : The name of the project to be described.
  var path_600117 = newJObject()
  add(path_600117, "projectName", newJString(projectName))
  result = call_600116.call(path_600117, nil, nil, nil, nil)

var describeProject* = Call_DescribeProject_600104(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DescribeProject_600105,
    base: "/", url: url_DescribeProject_600106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_600134 = ref object of OpenApiRestCall_599368
proc url_DeleteProject_600136(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_600135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600137 = path.getOrDefault("projectName")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "projectName", valid_600137
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
  var valid_600138 = header.getOrDefault("X-Amz-Date")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Date", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Security-Token")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Security-Token", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Content-Sha256", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Algorithm")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Algorithm", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Signature")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Signature", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-SignedHeaders", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Credential")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Credential", valid_600144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600145: Call_DeleteProject_600134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ## 
  let valid = call_600145.validator(path, query, header, formData, body)
  let scheme = call_600145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600145.url(scheme.get, call_600145.host, call_600145.base,
                         call_600145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600145, url, valid)

proc call*(call_600146: Call_DeleteProject_600134; projectName: string): Recallable =
  ## deleteProject
  ## <p>Deletes a project. To delete a project, it must not have any placements associated with it.</p> <note> <p>When you delete a project, all associated data becomes irretrievable.</p> </note>
  ##   projectName: string (required)
  ##              : The name of the empty project to delete.
  var path_600147 = newJObject()
  add(path_600147, "projectName", newJString(projectName))
  result = call_600146.call(path_600147, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_600134(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}", validator: validate_DeleteProject_600135,
    base: "/", url: url_DeleteProject_600136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevicesInPlacement_600148 = ref object of OpenApiRestCall_599368
proc url_GetDevicesInPlacement_600150(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevicesInPlacement_600149(path: JsonNode; query: JsonNode;
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
  var valid_600151 = path.getOrDefault("projectName")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = nil)
  if valid_600151 != nil:
    section.add "projectName", valid_600151
  var valid_600152 = path.getOrDefault("placementName")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = nil)
  if valid_600152 != nil:
    section.add "placementName", valid_600152
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
  var valid_600153 = header.getOrDefault("X-Amz-Date")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Date", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Security-Token")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Security-Token", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Content-Sha256", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Algorithm")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Algorithm", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Signature")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Signature", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-SignedHeaders", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Credential")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Credential", valid_600159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600160: Call_GetDevicesInPlacement_600148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an object enumerating the devices in a placement.
  ## 
  let valid = call_600160.validator(path, query, header, formData, body)
  let scheme = call_600160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600160.url(scheme.get, call_600160.host, call_600160.base,
                         call_600160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600160, url, valid)

proc call*(call_600161: Call_GetDevicesInPlacement_600148; projectName: string;
          placementName: string): Recallable =
  ## getDevicesInPlacement
  ## Returns an object enumerating the devices in a placement.
  ##   projectName: string (required)
  ##              : The name of the project containing the placement.
  ##   placementName: string (required)
  ##                : The name of the placement to get the devices from.
  var path_600162 = newJObject()
  add(path_600162, "projectName", newJString(projectName))
  add(path_600162, "placementName", newJString(placementName))
  result = call_600161.call(path_600162, nil, nil, nil, nil)

var getDevicesInPlacement* = Call_GetDevicesInPlacement_600148(
    name: "getDevicesInPlacement", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com",
    route: "/projects/{projectName}/placements/{placementName}/devices",
    validator: validate_GetDevicesInPlacement_600149, base: "/",
    url: url_GetDevicesInPlacement_600150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600177 = ref object of OpenApiRestCall_599368
proc url_TagResource_600179(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600180 = path.getOrDefault("resourceArn")
  valid_600180 = validateParameter(valid_600180, JString, required = true,
                                 default = nil)
  if valid_600180 != nil:
    section.add "resourceArn", valid_600180
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
  var valid_600181 = header.getOrDefault("X-Amz-Date")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Date", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Security-Token")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Security-Token", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Content-Sha256", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Algorithm")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Algorithm", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Signature")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Signature", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-SignedHeaders", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Credential")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Credential", valid_600187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600189: Call_TagResource_600177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ## 
  let valid = call_600189.validator(path, query, header, formData, body)
  let scheme = call_600189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600189.url(scheme.get, call_600189.host, call_600189.base,
                         call_600189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600189, url, valid)

proc call*(call_600190: Call_TagResource_600177; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the resouce for which tag(s) should be added or modified.
  var path_600191 = newJObject()
  var body_600192 = newJObject()
  if body != nil:
    body_600192 = body
  add(path_600191, "resourceArn", newJString(resourceArn))
  result = call_600190.call(path_600191, nil, nil, nil, body_600192)

var tagResource* = Call_TagResource_600177(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "projects.iot1click.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600178,
                                        base: "/", url: url_TagResource_600179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600163 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600165(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600164(path: JsonNode; query: JsonNode;
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
  var valid_600166 = path.getOrDefault("resourceArn")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = nil)
  if valid_600166 != nil:
    section.add "resourceArn", valid_600166
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
  var valid_600167 = header.getOrDefault("X-Amz-Date")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Date", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Security-Token")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Security-Token", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Content-Sha256", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Algorithm")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Algorithm", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Signature")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Signature", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-SignedHeaders", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Credential")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Credential", valid_600173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600174: Call_ListTagsForResource_600163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ## 
  let valid = call_600174.validator(path, query, header, formData, body)
  let scheme = call_600174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600174.url(scheme.get, call_600174.host, call_600174.base,
                         call_600174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600174, url, valid)

proc call*(call_600175: Call_ListTagsForResource_600163; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata key/value pairs) which you have assigned to the resource.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tags you want to list.
  var path_600176 = newJObject()
  add(path_600176, "resourceArn", newJString(resourceArn))
  result = call_600175.call(path_600176, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600163(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "projects.iot1click.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600164, base: "/",
    url: url_ListTagsForResource_600165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600193 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600195(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600196 = path.getOrDefault("resourceArn")
  valid_600196 = validateParameter(valid_600196, JString, required = true,
                                 default = nil)
  if valid_600196 != nil:
    section.add "resourceArn", valid_600196
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600197 = query.getOrDefault("tagKeys")
  valid_600197 = validateParameter(valid_600197, JArray, required = true, default = nil)
  if valid_600197 != nil:
    section.add "tagKeys", valid_600197
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
  var valid_600198 = header.getOrDefault("X-Amz-Date")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Date", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Security-Token")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Security-Token", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Content-Sha256", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Algorithm")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Algorithm", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Signature")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Signature", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-SignedHeaders", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Credential")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Credential", valid_600204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600205: Call_UntagResource_600193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ## 
  let valid = call_600205.validator(path, query, header, formData, body)
  let scheme = call_600205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600205.url(scheme.get, call_600205.host, call_600205.base,
                         call_600205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600205, url, valid)

proc call*(call_600206: Call_UntagResource_600193; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags (metadata key/value pairs) from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of those tags which you want to remove.
  ##   resourceArn: string (required)
  ##              : The ARN of the resource whose tag you want to remove.
  var path_600207 = newJObject()
  var query_600208 = newJObject()
  if tagKeys != nil:
    query_600208.add "tagKeys", tagKeys
  add(path_600207, "resourceArn", newJString(resourceArn))
  result = call_600206.call(path_600207, query_600208, nil, nil, nil)

var untagResource* = Call_UntagResource_600193(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "projects.iot1click.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600194,
    base: "/", url: url_UntagResource_600195, schemes: {Scheme.Https, Scheme.Http})
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
