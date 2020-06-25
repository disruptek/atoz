
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Greengrass
## version: 2017-06-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS IoT Greengrass seamlessly extends AWS onto physical devices so they can act locally on the data they generate, while still using the cloud for management, analytics, and durable storage. AWS IoT Greengrass ensures your devices can respond quickly to local events and operate with intermittent connectivity. AWS IoT Greengrass minimizes the cost of transmitting data to the cloud by allowing you to author AWS Lambda functions that execute locally.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/greengrass/
type
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "greengrass.ap-northeast-1.amazonaws.com", "ap-southeast-1": "greengrass.ap-southeast-1.amazonaws.com",
                           "us-west-2": "greengrass.us-west-2.amazonaws.com",
                           "eu-west-2": "greengrass.eu-west-2.amazonaws.com", "ap-northeast-3": "greengrass.ap-northeast-3.amazonaws.com", "eu-central-1": "greengrass.eu-central-1.amazonaws.com",
                           "us-east-2": "greengrass.us-east-2.amazonaws.com",
                           "us-east-1": "greengrass.us-east-1.amazonaws.com", "cn-northwest-1": "greengrass.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "greengrass.ap-south-1.amazonaws.com",
                           "eu-north-1": "greengrass.eu-north-1.amazonaws.com", "ap-northeast-2": "greengrass.ap-northeast-2.amazonaws.com",
                           "us-west-1": "greengrass.us-west-1.amazonaws.com", "us-gov-east-1": "greengrass.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "greengrass.eu-west-3.amazonaws.com", "cn-north-1": "greengrass.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "greengrass.sa-east-1.amazonaws.com",
                           "eu-west-1": "greengrass.eu-west-1.amazonaws.com", "us-gov-west-1": "greengrass.us-gov-west-1.amazonaws.com", "ap-southeast-2": "greengrass.ap-southeast-2.amazonaws.com", "ca-central-1": "greengrass.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "greengrass.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "greengrass.ap-southeast-1.amazonaws.com",
      "us-west-2": "greengrass.us-west-2.amazonaws.com",
      "eu-west-2": "greengrass.eu-west-2.amazonaws.com",
      "ap-northeast-3": "greengrass.ap-northeast-3.amazonaws.com",
      "eu-central-1": "greengrass.eu-central-1.amazonaws.com",
      "us-east-2": "greengrass.us-east-2.amazonaws.com",
      "us-east-1": "greengrass.us-east-1.amazonaws.com",
      "cn-northwest-1": "greengrass.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "greengrass.ap-south-1.amazonaws.com",
      "eu-north-1": "greengrass.eu-north-1.amazonaws.com",
      "ap-northeast-2": "greengrass.ap-northeast-2.amazonaws.com",
      "us-west-1": "greengrass.us-west-1.amazonaws.com",
      "us-gov-east-1": "greengrass.us-gov-east-1.amazonaws.com",
      "eu-west-3": "greengrass.eu-west-3.amazonaws.com",
      "cn-north-1": "greengrass.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "greengrass.sa-east-1.amazonaws.com",
      "eu-west-1": "greengrass.eu-west-1.amazonaws.com",
      "us-gov-west-1": "greengrass.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "greengrass.ap-southeast-2.amazonaws.com",
      "ca-central-1": "greengrass.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "greengrass"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateRoleToGroup_21626013 = ref object of OpenApiRestCall_21625418
proc url_AssociateRoleToGroup_21626015(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateRoleToGroup_21626014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626016 = path.getOrDefault("GroupId")
  valid_21626016 = validateParameter(valid_21626016, JString, required = true,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "GroupId", valid_21626016
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
  var valid_21626017 = header.getOrDefault("X-Amz-Date")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Date", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Security-Token", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Algorithm", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Signature")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Signature", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Credential")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Credential", valid_21626023
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

proc call*(call_21626025: Call_AssociateRoleToGroup_21626013; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_21626025.validator(path, query, header, formData, body, _)
  let scheme = call_21626025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626025.makeUrl(scheme.get, call_21626025.host, call_21626025.base,
                               call_21626025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626025, uri, valid, _)

proc call*(call_21626026: Call_AssociateRoleToGroup_21626013; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21626027 = newJObject()
  var body_21626028 = newJObject()
  add(path_21626027, "GroupId", newJString(GroupId))
  if body != nil:
    body_21626028 = body
  result = call_21626026.call(path_21626027, nil, nil, nil, body_21626028)

var associateRoleToGroup* = Call_AssociateRoleToGroup_21626013(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_21626014, base: "/",
    makeUrl: url_AssociateRoleToGroup_21626015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetAssociatedRole_21625764(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAssociatedRole_21625763(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the role associated with a particular group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21625878 = path.getOrDefault("GroupId")
  valid_21625878 = validateParameter(valid_21625878, JString, required = true,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "GroupId", valid_21625878
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
  var valid_21625879 = header.getOrDefault("X-Amz-Date")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Date", valid_21625879
  var valid_21625880 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625880 = validateParameter(valid_21625880, JString, required = false,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "X-Amz-Security-Token", valid_21625880
  var valid_21625881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625881 = validateParameter(valid_21625881, JString, required = false,
                                   default = nil)
  if valid_21625881 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625881
  var valid_21625882 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Algorithm", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Signature")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Signature", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Credential")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Credential", valid_21625885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625910: Call_GetAssociatedRole_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_21625910.validator(path, query, header, formData, body, _)
  let scheme = call_21625910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625910.makeUrl(scheme.get, call_21625910.host, call_21625910.base,
                               call_21625910.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625910, uri, valid, _)

proc call*(call_21625973: Call_GetAssociatedRole_21625762; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21625975 = newJObject()
  add(path_21625975, "GroupId", newJString(GroupId))
  result = call_21625973.call(path_21625975, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_21625762(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_21625763, base: "/",
    makeUrl: url_GetAssociatedRole_21625764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_21626029 = ref object of OpenApiRestCall_21625418
proc url_DisassociateRoleFromGroup_21626031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateRoleFromGroup_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disassociates the role from a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626032 = path.getOrDefault("GroupId")
  valid_21626032 = validateParameter(valid_21626032, JString, required = true,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "GroupId", valid_21626032
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
  var valid_21626033 = header.getOrDefault("X-Amz-Date")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Date", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Security-Token", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626040: Call_DisassociateRoleFromGroup_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_21626040.validator(path, query, header, formData, body, _)
  let scheme = call_21626040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626040.makeUrl(scheme.get, call_21626040.host, call_21626040.base,
                               call_21626040.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626040, uri, valid, _)

proc call*(call_21626041: Call_DisassociateRoleFromGroup_21626029; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21626042 = newJObject()
  add(path_21626042, "GroupId", newJString(GroupId))
  result = call_21626041.call(path_21626042, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_21626029(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_21626030, base: "/",
    makeUrl: url_DisassociateRoleFromGroup_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_21626055 = ref object of OpenApiRestCall_21625418
proc url_AssociateServiceRoleToAccount_21626057(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceRoleToAccount_21626056(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
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
  var valid_21626058 = header.getOrDefault("X-Amz-Date")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Date", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Security-Token", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Algorithm", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Signature")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Signature", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Credential")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Credential", valid_21626064
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

proc call*(call_21626066: Call_AssociateServiceRoleToAccount_21626055;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_21626066.validator(path, query, header, formData, body, _)
  let scheme = call_21626066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626066.makeUrl(scheme.get, call_21626066.host, call_21626066.base,
                               call_21626066.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626066, uri, valid, _)

proc call*(call_21626067: Call_AssociateServiceRoleToAccount_21626055;
          body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_21626068 = newJObject()
  if body != nil:
    body_21626068 = body
  result = call_21626067.call(nil, nil, nil, nil, body_21626068)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_21626055(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_21626056, base: "/",
    makeUrl: url_AssociateServiceRoleToAccount_21626057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_21626043 = ref object of OpenApiRestCall_21625418
proc url_GetServiceRoleForAccount_21626045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceRoleForAccount_21626044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the service role that is attached to your account.
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
  var valid_21626046 = header.getOrDefault("X-Amz-Date")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Date", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Security-Token", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Algorithm", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Signature")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Signature", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Credential")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Credential", valid_21626052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626053: Call_GetServiceRoleForAccount_21626043;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_21626053.validator(path, query, header, formData, body, _)
  let scheme = call_21626053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626053.makeUrl(scheme.get, call_21626053.host, call_21626053.base,
                               call_21626053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626053, uri, valid, _)

proc call*(call_21626054: Call_GetServiceRoleForAccount_21626043): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_21626054.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_21626043(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_21626044, base: "/",
    makeUrl: url_GetServiceRoleForAccount_21626045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_21626069 = ref object of OpenApiRestCall_21625418
proc url_DisassociateServiceRoleFromAccount_21626071(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_21626070(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
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
  var valid_21626072 = header.getOrDefault("X-Amz-Date")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Date", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Security-Token", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Algorithm", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Signature")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Signature", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Credential")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Credential", valid_21626078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626079: Call_DisassociateServiceRoleFromAccount_21626069;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_21626079.validator(path, query, header, formData, body, _)
  let scheme = call_21626079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626079.makeUrl(scheme.get, call_21626079.host, call_21626079.base,
                               call_21626079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626079, uri, valid, _)

proc call*(call_21626080: Call_DisassociateServiceRoleFromAccount_21626069): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_21626080.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_21626069(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_21626070, base: "/",
    makeUrl: url_DisassociateServiceRoleFromAccount_21626071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_21626097 = ref object of OpenApiRestCall_21625418
proc url_CreateConnectorDefinition_21626099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnectorDefinition_21626098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amzn-Client-Token", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Signature")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Signature", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Credential")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Credential", valid_21626107
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

proc call*(call_21626109: Call_CreateConnectorDefinition_21626097;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_21626109.validator(path, query, header, formData, body, _)
  let scheme = call_21626109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626109.makeUrl(scheme.get, call_21626109.host, call_21626109.base,
                               call_21626109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626109, uri, valid, _)

proc call*(call_21626110: Call_CreateConnectorDefinition_21626097; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_21626111 = newJObject()
  if body != nil:
    body_21626111 = body
  result = call_21626110.call(nil, nil, nil, nil, body_21626111)

var createConnectorDefinition* = Call_CreateConnectorDefinition_21626097(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_21626098, base: "/",
    makeUrl: url_CreateConnectorDefinition_21626099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_21626081 = ref object of OpenApiRestCall_21625418
proc url_ListConnectorDefinitions_21626083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnectorDefinitions_21626082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of connector definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626084 = query.getOrDefault("NextToken")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "NextToken", valid_21626084
  var valid_21626085 = query.getOrDefault("MaxResults")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "MaxResults", valid_21626085
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
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626093: Call_ListConnectorDefinitions_21626081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_21626093.validator(path, query, header, formData, body, _)
  let scheme = call_21626093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626093.makeUrl(scheme.get, call_21626093.host, call_21626093.base,
                               call_21626093.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626093, uri, valid, _)

proc call*(call_21626094: Call_ListConnectorDefinitions_21626081;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626095 = newJObject()
  add(query_21626095, "NextToken", newJString(NextToken))
  add(query_21626095, "MaxResults", newJString(MaxResults))
  result = call_21626094.call(nil, query_21626095, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_21626081(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_21626082, base: "/",
    makeUrl: url_ListConnectorDefinitions_21626083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_21626129 = ref object of OpenApiRestCall_21625418
proc url_CreateConnectorDefinitionVersion_21626131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConnectorDefinitionVersion_21626130(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_21626132 = path.getOrDefault("ConnectorDefinitionId")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "ConnectorDefinitionId", valid_21626132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626133 = header.getOrDefault("X-Amz-Date")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Date", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Security-Token", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Algorithm", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amzn-Client-Token", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Signature")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Signature", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Credential")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Credential", valid_21626140
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

proc call*(call_21626142: Call_CreateConnectorDefinitionVersion_21626129;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_CreateConnectorDefinitionVersion_21626129;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_21626144 = newJObject()
  var body_21626145 = newJObject()
  add(path_21626144, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_21626145 = body
  result = call_21626143.call(path_21626144, nil, nil, nil, body_21626145)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_21626129(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_21626130, base: "/",
    makeUrl: url_CreateConnectorDefinitionVersion_21626131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_21626112 = ref object of OpenApiRestCall_21625418
proc url_ListConnectorDefinitionVersions_21626114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConnectorDefinitionVersions_21626113(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_21626115 = path.getOrDefault("ConnectorDefinitionId")
  valid_21626115 = validateParameter(valid_21626115, JString, required = true,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "ConnectorDefinitionId", valid_21626115
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626116 = query.getOrDefault("NextToken")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "NextToken", valid_21626116
  var valid_21626117 = query.getOrDefault("MaxResults")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "MaxResults", valid_21626117
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
  var valid_21626118 = header.getOrDefault("X-Amz-Date")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Date", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Security-Token", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626125: Call_ListConnectorDefinitionVersions_21626112;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_ListConnectorDefinitionVersions_21626112;
          ConnectorDefinitionId: string; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listConnectorDefinitionVersions
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626127 = newJObject()
  var query_21626128 = newJObject()
  add(query_21626128, "NextToken", newJString(NextToken))
  add(path_21626127, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(query_21626128, "MaxResults", newJString(MaxResults))
  result = call_21626126.call(path_21626127, query_21626128, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_21626112(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_21626113, base: "/",
    makeUrl: url_ListConnectorDefinitionVersions_21626114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_21626161 = ref object of OpenApiRestCall_21625418
proc url_CreateCoreDefinition_21626163(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCoreDefinition_21626162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626164 = header.getOrDefault("X-Amz-Date")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Date", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Security-Token", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Algorithm", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amzn-Client-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Signature")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Signature", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Credential")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Credential", valid_21626171
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

proc call*(call_21626173: Call_CreateCoreDefinition_21626161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_21626173.validator(path, query, header, formData, body, _)
  let scheme = call_21626173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626173.makeUrl(scheme.get, call_21626173.host, call_21626173.base,
                               call_21626173.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626173, uri, valid, _)

proc call*(call_21626174: Call_CreateCoreDefinition_21626161; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_21626175 = newJObject()
  if body != nil:
    body_21626175 = body
  result = call_21626174.call(nil, nil, nil, nil, body_21626175)

var createCoreDefinition* = Call_CreateCoreDefinition_21626161(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_21626162, base: "/",
    makeUrl: url_CreateCoreDefinition_21626163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_21626146 = ref object of OpenApiRestCall_21625418
proc url_ListCoreDefinitions_21626148(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCoreDefinitions_21626147(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of core definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626149 = query.getOrDefault("NextToken")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "NextToken", valid_21626149
  var valid_21626150 = query.getOrDefault("MaxResults")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "MaxResults", valid_21626150
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
  var valid_21626151 = header.getOrDefault("X-Amz-Date")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Date", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Security-Token", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Algorithm", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Signature")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Signature", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Credential")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Credential", valid_21626157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626158: Call_ListCoreDefinitions_21626146; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_ListCoreDefinitions_21626146;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626160 = newJObject()
  add(query_21626160, "NextToken", newJString(NextToken))
  add(query_21626160, "MaxResults", newJString(MaxResults))
  result = call_21626159.call(nil, query_21626160, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_21626146(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_21626147, base: "/",
    makeUrl: url_ListCoreDefinitions_21626148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_21626193 = ref object of OpenApiRestCall_21625418
proc url_CreateCoreDefinitionVersion_21626195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCoreDefinitionVersion_21626194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21626196 = path.getOrDefault("CoreDefinitionId")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "CoreDefinitionId", valid_21626196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amzn-Client-Token", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CreateCoreDefinitionVersion_21626193;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateCoreDefinitionVersion_21626193;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_21626208 = newJObject()
  var body_21626209 = newJObject()
  add(path_21626208, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_21626209 = body
  result = call_21626207.call(path_21626208, nil, nil, nil, body_21626209)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_21626193(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_21626194, base: "/",
    makeUrl: url_CreateCoreDefinitionVersion_21626195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_21626176 = ref object of OpenApiRestCall_21625418
proc url_ListCoreDefinitionVersions_21626178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListCoreDefinitionVersions_21626177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the versions of a core definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21626179 = path.getOrDefault("CoreDefinitionId")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "CoreDefinitionId", valid_21626179
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626180 = query.getOrDefault("NextToken")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "NextToken", valid_21626180
  var valid_21626181 = query.getOrDefault("MaxResults")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "MaxResults", valid_21626181
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Algorithm", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Signature")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Signature", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Credential")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Credential", valid_21626188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626189: Call_ListCoreDefinitionVersions_21626176;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_21626189.validator(path, query, header, formData, body, _)
  let scheme = call_21626189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626189.makeUrl(scheme.get, call_21626189.host, call_21626189.base,
                               call_21626189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626189, uri, valid, _)

proc call*(call_21626190: Call_ListCoreDefinitionVersions_21626176;
          CoreDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626191 = newJObject()
  var query_21626192 = newJObject()
  add(path_21626191, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(query_21626192, "NextToken", newJString(NextToken))
  add(query_21626192, "MaxResults", newJString(MaxResults))
  result = call_21626190.call(path_21626191, query_21626192, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_21626176(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_21626177, base: "/",
    makeUrl: url_ListCoreDefinitionVersions_21626178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_21626227 = ref object of OpenApiRestCall_21625418
proc url_CreateDeployment_21626229(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_21626228(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626230 = path.getOrDefault("GroupId")
  valid_21626230 = validateParameter(valid_21626230, JString, required = true,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "GroupId", valid_21626230
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626231 = header.getOrDefault("X-Amz-Date")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Date", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Security-Token", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Algorithm", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amzn-Client-Token", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Signature")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Signature", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Credential")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Credential", valid_21626238
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

proc call*(call_21626240: Call_CreateDeployment_21626227; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_21626240.validator(path, query, header, formData, body, _)
  let scheme = call_21626240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626240.makeUrl(scheme.get, call_21626240.host, call_21626240.base,
                               call_21626240.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626240, uri, valid, _)

proc call*(call_21626241: Call_CreateDeployment_21626227; GroupId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21626242 = newJObject()
  var body_21626243 = newJObject()
  add(path_21626242, "GroupId", newJString(GroupId))
  if body != nil:
    body_21626243 = body
  result = call_21626241.call(path_21626242, nil, nil, nil, body_21626243)

var createDeployment* = Call_CreateDeployment_21626227(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_21626228, base: "/",
    makeUrl: url_CreateDeployment_21626229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_21626210 = ref object of OpenApiRestCall_21625418
proc url_ListDeployments_21626212(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeployments_21626211(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a history of deployments for the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626213 = path.getOrDefault("GroupId")
  valid_21626213 = validateParameter(valid_21626213, JString, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "GroupId", valid_21626213
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626214 = query.getOrDefault("NextToken")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "NextToken", valid_21626214
  var valid_21626215 = query.getOrDefault("MaxResults")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "MaxResults", valid_21626215
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
  var valid_21626216 = header.getOrDefault("X-Amz-Date")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Date", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Security-Token", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Algorithm", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Signature")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Signature", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Credential")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Credential", valid_21626222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626223: Call_ListDeployments_21626210; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_ListDeployments_21626210; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626225 = newJObject()
  var query_21626226 = newJObject()
  add(path_21626225, "GroupId", newJString(GroupId))
  add(query_21626226, "NextToken", newJString(NextToken))
  add(query_21626226, "MaxResults", newJString(MaxResults))
  result = call_21626224.call(path_21626225, query_21626226, nil, nil, nil)

var listDeployments* = Call_ListDeployments_21626210(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_21626211, base: "/",
    makeUrl: url_ListDeployments_21626212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_21626259 = ref object of OpenApiRestCall_21625418
proc url_CreateDeviceDefinition_21626261(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeviceDefinition_21626260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626262 = header.getOrDefault("X-Amz-Date")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Date", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Security-Token", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Algorithm", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amzn-Client-Token", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Signature")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Signature", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Credential")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Credential", valid_21626269
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

proc call*(call_21626271: Call_CreateDeviceDefinition_21626259;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_21626271.validator(path, query, header, formData, body, _)
  let scheme = call_21626271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626271.makeUrl(scheme.get, call_21626271.host, call_21626271.base,
                               call_21626271.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626271, uri, valid, _)

proc call*(call_21626272: Call_CreateDeviceDefinition_21626259; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_21626273 = newJObject()
  if body != nil:
    body_21626273 = body
  result = call_21626272.call(nil, nil, nil, nil, body_21626273)

var createDeviceDefinition* = Call_CreateDeviceDefinition_21626259(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_21626260, base: "/",
    makeUrl: url_CreateDeviceDefinition_21626261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_21626244 = ref object of OpenApiRestCall_21625418
proc url_ListDeviceDefinitions_21626246(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceDefinitions_21626245(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of device definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626247 = query.getOrDefault("NextToken")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "NextToken", valid_21626247
  var valid_21626248 = query.getOrDefault("MaxResults")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "MaxResults", valid_21626248
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
  var valid_21626249 = header.getOrDefault("X-Amz-Date")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Date", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Security-Token", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Algorithm", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Signature")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Signature", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Credential")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Credential", valid_21626255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626256: Call_ListDeviceDefinitions_21626244;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_21626256.validator(path, query, header, formData, body, _)
  let scheme = call_21626256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626256.makeUrl(scheme.get, call_21626256.host, call_21626256.base,
                               call_21626256.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626256, uri, valid, _)

proc call*(call_21626257: Call_ListDeviceDefinitions_21626244;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626258 = newJObject()
  add(query_21626258, "NextToken", newJString(NextToken))
  add(query_21626258, "MaxResults", newJString(MaxResults))
  result = call_21626257.call(nil, query_21626258, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_21626244(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_21626245, base: "/",
    makeUrl: url_ListDeviceDefinitions_21626246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_21626291 = ref object of OpenApiRestCall_21625418
proc url_CreateDeviceDefinitionVersion_21626293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeviceDefinitionVersion_21626292(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a device definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21626294 = path.getOrDefault("DeviceDefinitionId")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "DeviceDefinitionId", valid_21626294
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626295 = header.getOrDefault("X-Amz-Date")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Date", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Security-Token", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Algorithm", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amzn-Client-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Signature")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Signature", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Credential")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Credential", valid_21626302
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

proc call*(call_21626304: Call_CreateDeviceDefinitionVersion_21626291;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_21626304.validator(path, query, header, formData, body, _)
  let scheme = call_21626304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626304.makeUrl(scheme.get, call_21626304.host, call_21626304.base,
                               call_21626304.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626304, uri, valid, _)

proc call*(call_21626305: Call_CreateDeviceDefinitionVersion_21626291;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_21626306 = newJObject()
  var body_21626307 = newJObject()
  add(path_21626306, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_21626307 = body
  result = call_21626305.call(path_21626306, nil, nil, nil, body_21626307)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_21626291(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_21626292, base: "/",
    makeUrl: url_CreateDeviceDefinitionVersion_21626293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_21626274 = ref object of OpenApiRestCall_21625418
proc url_ListDeviceDefinitionVersions_21626276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeviceDefinitionVersions_21626275(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a device definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21626277 = path.getOrDefault("DeviceDefinitionId")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "DeviceDefinitionId", valid_21626277
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626278 = query.getOrDefault("NextToken")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "NextToken", valid_21626278
  var valid_21626279 = query.getOrDefault("MaxResults")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "MaxResults", valid_21626279
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
  var valid_21626280 = header.getOrDefault("X-Amz-Date")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Date", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Security-Token", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Algorithm", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Signature")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Signature", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Credential")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Credential", valid_21626286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626287: Call_ListDeviceDefinitionVersions_21626274;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_21626287.validator(path, query, header, formData, body, _)
  let scheme = call_21626287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626287.makeUrl(scheme.get, call_21626287.host, call_21626287.base,
                               call_21626287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626287, uri, valid, _)

proc call*(call_21626288: Call_ListDeviceDefinitionVersions_21626274;
          DeviceDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626289 = newJObject()
  var query_21626290 = newJObject()
  add(path_21626289, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_21626290, "NextToken", newJString(NextToken))
  add(query_21626290, "MaxResults", newJString(MaxResults))
  result = call_21626288.call(path_21626289, query_21626290, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_21626274(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_21626275, base: "/",
    makeUrl: url_ListDeviceDefinitionVersions_21626276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_21626323 = ref object of OpenApiRestCall_21625418
proc url_CreateFunctionDefinition_21626325(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunctionDefinition_21626324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626326 = header.getOrDefault("X-Amz-Date")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Date", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Security-Token", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Algorithm", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amzn-Client-Token", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Signature")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Signature", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Credential")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Credential", valid_21626333
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

proc call*(call_21626335: Call_CreateFunctionDefinition_21626323;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_21626335.validator(path, query, header, formData, body, _)
  let scheme = call_21626335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626335.makeUrl(scheme.get, call_21626335.host, call_21626335.base,
                               call_21626335.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626335, uri, valid, _)

proc call*(call_21626336: Call_CreateFunctionDefinition_21626323; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_21626337 = newJObject()
  if body != nil:
    body_21626337 = body
  result = call_21626336.call(nil, nil, nil, nil, body_21626337)

var createFunctionDefinition* = Call_CreateFunctionDefinition_21626323(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_21626324, base: "/",
    makeUrl: url_CreateFunctionDefinition_21626325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_21626308 = ref object of OpenApiRestCall_21625418
proc url_ListFunctionDefinitions_21626310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctionDefinitions_21626309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of Lambda function definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626311 = query.getOrDefault("NextToken")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "NextToken", valid_21626311
  var valid_21626312 = query.getOrDefault("MaxResults")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "MaxResults", valid_21626312
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
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626320: Call_ListFunctionDefinitions_21626308;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_21626320.validator(path, query, header, formData, body, _)
  let scheme = call_21626320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626320.makeUrl(scheme.get, call_21626320.host, call_21626320.base,
                               call_21626320.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626320, uri, valid, _)

proc call*(call_21626321: Call_ListFunctionDefinitions_21626308;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626322 = newJObject()
  add(query_21626322, "NextToken", newJString(NextToken))
  add(query_21626322, "MaxResults", newJString(MaxResults))
  result = call_21626321.call(nil, query_21626322, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_21626308(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_21626309, base: "/",
    makeUrl: url_ListFunctionDefinitions_21626310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_21626355 = ref object of OpenApiRestCall_21625418
proc url_CreateFunctionDefinitionVersion_21626357(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunctionDefinitionVersion_21626356(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_21626358 = path.getOrDefault("FunctionDefinitionId")
  valid_21626358 = validateParameter(valid_21626358, JString, required = true,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "FunctionDefinitionId", valid_21626358
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626359 = header.getOrDefault("X-Amz-Date")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Date", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Security-Token", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Algorithm", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amzn-Client-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Signature")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Signature", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Credential")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Credential", valid_21626366
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

proc call*(call_21626368: Call_CreateFunctionDefinitionVersion_21626355;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_21626368.validator(path, query, header, formData, body, _)
  let scheme = call_21626368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626368.makeUrl(scheme.get, call_21626368.host, call_21626368.base,
                               call_21626368.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626368, uri, valid, _)

proc call*(call_21626369: Call_CreateFunctionDefinitionVersion_21626355;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_21626370 = newJObject()
  var body_21626371 = newJObject()
  add(path_21626370, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_21626371 = body
  result = call_21626369.call(path_21626370, nil, nil, nil, body_21626371)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_21626355(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_21626356, base: "/",
    makeUrl: url_CreateFunctionDefinitionVersion_21626357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_21626338 = ref object of OpenApiRestCall_21625418
proc url_ListFunctionDefinitionVersions_21626340(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionDefinitionVersions_21626339(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_21626341 = path.getOrDefault("FunctionDefinitionId")
  valid_21626341 = validateParameter(valid_21626341, JString, required = true,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "FunctionDefinitionId", valid_21626341
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626342 = query.getOrDefault("NextToken")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "NextToken", valid_21626342
  var valid_21626343 = query.getOrDefault("MaxResults")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "MaxResults", valid_21626343
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
  var valid_21626344 = header.getOrDefault("X-Amz-Date")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Date", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Security-Token", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Algorithm", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Signature")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Signature", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Credential")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Credential", valid_21626350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626351: Call_ListFunctionDefinitionVersions_21626338;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_21626351.validator(path, query, header, formData, body, _)
  let scheme = call_21626351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626351.makeUrl(scheme.get, call_21626351.host, call_21626351.base,
                               call_21626351.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626351, uri, valid, _)

proc call*(call_21626352: Call_ListFunctionDefinitionVersions_21626338;
          FunctionDefinitionId: string; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listFunctionDefinitionVersions
  ## Lists the versions of a Lambda function definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626353 = newJObject()
  var query_21626354 = newJObject()
  add(query_21626354, "NextToken", newJString(NextToken))
  add(path_21626353, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  add(query_21626354, "MaxResults", newJString(MaxResults))
  result = call_21626352.call(path_21626353, query_21626354, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_21626338(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_21626339, base: "/",
    makeUrl: url_ListFunctionDefinitionVersions_21626340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_21626387 = ref object of OpenApiRestCall_21625418
proc url_CreateGroup_21626389(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_21626388(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626390 = header.getOrDefault("X-Amz-Date")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Date", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Security-Token", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Algorithm", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amzn-Client-Token", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
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

proc call*(call_21626399: Call_CreateGroup_21626387; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_21626399.validator(path, query, header, formData, body, _)
  let scheme = call_21626399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626399.makeUrl(scheme.get, call_21626399.host, call_21626399.base,
                               call_21626399.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626399, uri, valid, _)

proc call*(call_21626400: Call_CreateGroup_21626387; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_21626401 = newJObject()
  if body != nil:
    body_21626401 = body
  result = call_21626400.call(nil, nil, nil, nil, body_21626401)

var createGroup* = Call_CreateGroup_21626387(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups", validator: validate_CreateGroup_21626388,
    base: "/", makeUrl: url_CreateGroup_21626389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_21626372 = ref object of OpenApiRestCall_21625418
proc url_ListGroups_21626374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_21626373(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626375 = query.getOrDefault("NextToken")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "NextToken", valid_21626375
  var valid_21626376 = query.getOrDefault("MaxResults")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "MaxResults", valid_21626376
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
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Algorithm", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Signature")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Signature", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Credential")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Credential", valid_21626383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626384: Call_ListGroups_21626372; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_21626384.validator(path, query, header, formData, body, _)
  let scheme = call_21626384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626384.makeUrl(scheme.get, call_21626384.host, call_21626384.base,
                               call_21626384.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626384, uri, valid, _)

proc call*(call_21626385: Call_ListGroups_21626372; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626386 = newJObject()
  add(query_21626386, "NextToken", newJString(NextToken))
  add(query_21626386, "MaxResults", newJString(MaxResults))
  result = call_21626385.call(nil, query_21626386, nil, nil, nil)

var listGroups* = Call_ListGroups_21626372(name: "listGroups",
                                        meth: HttpMethod.HttpGet,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_ListGroups_21626373,
                                        base: "/", makeUrl: url_ListGroups_21626374,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_21626416 = ref object of OpenApiRestCall_21625418
proc url_CreateGroupCertificateAuthority_21626418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/certificateauthorities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupCertificateAuthority_21626417(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626419 = path.getOrDefault("GroupId")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "GroupId", valid_21626419
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626420 = header.getOrDefault("X-Amz-Date")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Date", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Security-Token", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Algorithm", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amzn-Client-Token", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Signature")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Signature", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Credential")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Credential", valid_21626427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626428: Call_CreateGroupCertificateAuthority_21626416;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_21626428.validator(path, query, header, formData, body, _)
  let scheme = call_21626428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626428.makeUrl(scheme.get, call_21626428.host, call_21626428.base,
                               call_21626428.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626428, uri, valid, _)

proc call*(call_21626429: Call_CreateGroupCertificateAuthority_21626416;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21626430 = newJObject()
  add(path_21626430, "GroupId", newJString(GroupId))
  result = call_21626429.call(path_21626430, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_21626416(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_21626417, base: "/",
    makeUrl: url_CreateGroupCertificateAuthority_21626418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_21626402 = ref object of OpenApiRestCall_21625418
proc url_ListGroupCertificateAuthorities_21626404(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/certificateauthorities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupCertificateAuthorities_21626403(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the current CAs for a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626405 = path.getOrDefault("GroupId")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "GroupId", valid_21626405
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
  var valid_21626406 = header.getOrDefault("X-Amz-Date")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Date", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Security-Token", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Algorithm", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Signature")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Signature", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Credential")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Credential", valid_21626412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626413: Call_ListGroupCertificateAuthorities_21626402;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_21626413.validator(path, query, header, formData, body, _)
  let scheme = call_21626413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626413.makeUrl(scheme.get, call_21626413.host, call_21626413.base,
                               call_21626413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626413, uri, valid, _)

proc call*(call_21626414: Call_ListGroupCertificateAuthorities_21626402;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21626415 = newJObject()
  add(path_21626415, "GroupId", newJString(GroupId))
  result = call_21626414.call(path_21626415, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_21626402(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_21626403, base: "/",
    makeUrl: url_ListGroupCertificateAuthorities_21626404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_21626448 = ref object of OpenApiRestCall_21625418
proc url_CreateGroupVersion_21626450(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupVersion_21626449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a version of a group which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626451 = path.getOrDefault("GroupId")
  valid_21626451 = validateParameter(valid_21626451, JString, required = true,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "GroupId", valid_21626451
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Algorithm", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amzn-Client-Token", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
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

proc call*(call_21626461: Call_CreateGroupVersion_21626448; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_CreateGroupVersion_21626448; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21626463 = newJObject()
  var body_21626464 = newJObject()
  add(path_21626463, "GroupId", newJString(GroupId))
  if body != nil:
    body_21626464 = body
  result = call_21626462.call(path_21626463, nil, nil, nil, body_21626464)

var createGroupVersion* = Call_CreateGroupVersion_21626448(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_21626449, base: "/",
    makeUrl: url_CreateGroupVersion_21626450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_21626431 = ref object of OpenApiRestCall_21625418
proc url_ListGroupVersions_21626433(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupVersions_21626432(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the versions of a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626434 = path.getOrDefault("GroupId")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "GroupId", valid_21626434
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626435 = query.getOrDefault("NextToken")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "NextToken", valid_21626435
  var valid_21626436 = query.getOrDefault("MaxResults")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "MaxResults", valid_21626436
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Algorithm", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Signature")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Signature", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Credential")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Credential", valid_21626443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626444: Call_ListGroupVersions_21626431; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_21626444.validator(path, query, header, formData, body, _)
  let scheme = call_21626444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626444.makeUrl(scheme.get, call_21626444.host, call_21626444.base,
                               call_21626444.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626444, uri, valid, _)

proc call*(call_21626445: Call_ListGroupVersions_21626431; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626446 = newJObject()
  var query_21626447 = newJObject()
  add(path_21626446, "GroupId", newJString(GroupId))
  add(query_21626447, "NextToken", newJString(NextToken))
  add(query_21626447, "MaxResults", newJString(MaxResults))
  result = call_21626445.call(path_21626446, query_21626447, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_21626431(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_21626432, base: "/",
    makeUrl: url_ListGroupVersions_21626433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_21626480 = ref object of OpenApiRestCall_21625418
proc url_CreateLoggerDefinition_21626482(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoggerDefinition_21626481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626483 = header.getOrDefault("X-Amz-Date")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Date", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Security-Token", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amzn-Client-Token", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Signature")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Signature", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Credential")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Credential", valid_21626490
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

proc call*(call_21626492: Call_CreateLoggerDefinition_21626480;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_21626492.validator(path, query, header, formData, body, _)
  let scheme = call_21626492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626492.makeUrl(scheme.get, call_21626492.host, call_21626492.base,
                               call_21626492.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626492, uri, valid, _)

proc call*(call_21626493: Call_CreateLoggerDefinition_21626480; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_21626494 = newJObject()
  if body != nil:
    body_21626494 = body
  result = call_21626493.call(nil, nil, nil, nil, body_21626494)

var createLoggerDefinition* = Call_CreateLoggerDefinition_21626480(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_21626481, base: "/",
    makeUrl: url_CreateLoggerDefinition_21626482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_21626465 = ref object of OpenApiRestCall_21625418
proc url_ListLoggerDefinitions_21626467(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggerDefinitions_21626466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of logger definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626468 = query.getOrDefault("NextToken")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "NextToken", valid_21626468
  var valid_21626469 = query.getOrDefault("MaxResults")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "MaxResults", valid_21626469
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
  var valid_21626470 = header.getOrDefault("X-Amz-Date")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Date", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Security-Token", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Algorithm", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Signature")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Signature", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Credential")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Credential", valid_21626476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626477: Call_ListLoggerDefinitions_21626465;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_21626477.validator(path, query, header, formData, body, _)
  let scheme = call_21626477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626477.makeUrl(scheme.get, call_21626477.host, call_21626477.base,
                               call_21626477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626477, uri, valid, _)

proc call*(call_21626478: Call_ListLoggerDefinitions_21626465;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626479 = newJObject()
  add(query_21626479, "NextToken", newJString(NextToken))
  add(query_21626479, "MaxResults", newJString(MaxResults))
  result = call_21626478.call(nil, query_21626479, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_21626465(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_21626466, base: "/",
    makeUrl: url_ListLoggerDefinitions_21626467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_21626512 = ref object of OpenApiRestCall_21625418
proc url_CreateLoggerDefinitionVersion_21626514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLoggerDefinitionVersion_21626513(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_21626515 = path.getOrDefault("LoggerDefinitionId")
  valid_21626515 = validateParameter(valid_21626515, JString, required = true,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "LoggerDefinitionId", valid_21626515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626516 = header.getOrDefault("X-Amz-Date")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Date", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Security-Token", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Algorithm", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amzn-Client-Token", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Signature")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Signature", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Credential")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Credential", valid_21626523
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

proc call*(call_21626525: Call_CreateLoggerDefinitionVersion_21626512;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_21626525.validator(path, query, header, formData, body, _)
  let scheme = call_21626525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626525.makeUrl(scheme.get, call_21626525.host, call_21626525.base,
                               call_21626525.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626525, uri, valid, _)

proc call*(call_21626526: Call_CreateLoggerDefinitionVersion_21626512;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_21626527 = newJObject()
  var body_21626528 = newJObject()
  add(path_21626527, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_21626528 = body
  result = call_21626526.call(path_21626527, nil, nil, nil, body_21626528)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_21626512(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_21626513, base: "/",
    makeUrl: url_CreateLoggerDefinitionVersion_21626514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_21626495 = ref object of OpenApiRestCall_21625418
proc url_ListLoggerDefinitionVersions_21626497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLoggerDefinitionVersions_21626496(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a logger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_21626498 = path.getOrDefault("LoggerDefinitionId")
  valid_21626498 = validateParameter(valid_21626498, JString, required = true,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "LoggerDefinitionId", valid_21626498
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626499 = query.getOrDefault("NextToken")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "NextToken", valid_21626499
  var valid_21626500 = query.getOrDefault("MaxResults")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "MaxResults", valid_21626500
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
  var valid_21626501 = header.getOrDefault("X-Amz-Date")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Date", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Security-Token", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Algorithm", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Signature")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Signature", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Credential")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Credential", valid_21626507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626508: Call_ListLoggerDefinitionVersions_21626495;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_21626508.validator(path, query, header, formData, body, _)
  let scheme = call_21626508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626508.makeUrl(scheme.get, call_21626508.host, call_21626508.base,
                               call_21626508.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626508, uri, valid, _)

proc call*(call_21626509: Call_ListLoggerDefinitionVersions_21626495;
          LoggerDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626510 = newJObject()
  var query_21626511 = newJObject()
  add(query_21626511, "NextToken", newJString(NextToken))
  add(path_21626510, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_21626511, "MaxResults", newJString(MaxResults))
  result = call_21626509.call(path_21626510, query_21626511, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_21626495(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_21626496, base: "/",
    makeUrl: url_ListLoggerDefinitionVersions_21626497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_21626544 = ref object of OpenApiRestCall_21625418
proc url_CreateResourceDefinition_21626546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDefinition_21626545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626547 = header.getOrDefault("X-Amz-Date")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Date", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Security-Token", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Algorithm", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amzn-Client-Token", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Signature")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Signature", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Credential")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Credential", valid_21626554
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

proc call*(call_21626556: Call_CreateResourceDefinition_21626544;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_21626556.validator(path, query, header, formData, body, _)
  let scheme = call_21626556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626556.makeUrl(scheme.get, call_21626556.host, call_21626556.base,
                               call_21626556.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626556, uri, valid, _)

proc call*(call_21626557: Call_CreateResourceDefinition_21626544; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_21626558 = newJObject()
  if body != nil:
    body_21626558 = body
  result = call_21626557.call(nil, nil, nil, nil, body_21626558)

var createResourceDefinition* = Call_CreateResourceDefinition_21626544(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_21626545, base: "/",
    makeUrl: url_CreateResourceDefinition_21626546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_21626529 = ref object of OpenApiRestCall_21625418
proc url_ListResourceDefinitions_21626531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDefinitions_21626530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of resource definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626532 = query.getOrDefault("NextToken")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "NextToken", valid_21626532
  var valid_21626533 = query.getOrDefault("MaxResults")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "MaxResults", valid_21626533
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
  var valid_21626534 = header.getOrDefault("X-Amz-Date")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Date", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Security-Token", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Algorithm", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Signature")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Signature", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Credential")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Credential", valid_21626540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626541: Call_ListResourceDefinitions_21626529;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_21626541.validator(path, query, header, formData, body, _)
  let scheme = call_21626541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626541.makeUrl(scheme.get, call_21626541.host, call_21626541.base,
                               call_21626541.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626541, uri, valid, _)

proc call*(call_21626542: Call_ListResourceDefinitions_21626529;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626543 = newJObject()
  add(query_21626543, "NextToken", newJString(NextToken))
  add(query_21626543, "MaxResults", newJString(MaxResults))
  result = call_21626542.call(nil, query_21626543, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_21626529(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_21626530, base: "/",
    makeUrl: url_ListResourceDefinitions_21626531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_21626576 = ref object of OpenApiRestCall_21625418
proc url_CreateResourceDefinitionVersion_21626578(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResourceDefinitionVersion_21626577(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_21626579 = path.getOrDefault("ResourceDefinitionId")
  valid_21626579 = validateParameter(valid_21626579, JString, required = true,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "ResourceDefinitionId", valid_21626579
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626580 = header.getOrDefault("X-Amz-Date")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Date", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Security-Token", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Algorithm", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amzn-Client-Token", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Signature")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Signature", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Credential")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Credential", valid_21626587
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

proc call*(call_21626589: Call_CreateResourceDefinitionVersion_21626576;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_21626589.validator(path, query, header, formData, body, _)
  let scheme = call_21626589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626589.makeUrl(scheme.get, call_21626589.host, call_21626589.base,
                               call_21626589.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626589, uri, valid, _)

proc call*(call_21626590: Call_CreateResourceDefinitionVersion_21626576;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_21626591 = newJObject()
  var body_21626592 = newJObject()
  add(path_21626591, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_21626592 = body
  result = call_21626590.call(path_21626591, nil, nil, nil, body_21626592)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_21626576(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_21626577, base: "/",
    makeUrl: url_CreateResourceDefinitionVersion_21626578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_21626559 = ref object of OpenApiRestCall_21625418
proc url_ListResourceDefinitionVersions_21626561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceDefinitionVersions_21626560(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_21626562 = path.getOrDefault("ResourceDefinitionId")
  valid_21626562 = validateParameter(valid_21626562, JString, required = true,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "ResourceDefinitionId", valid_21626562
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626563 = query.getOrDefault("NextToken")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "NextToken", valid_21626563
  var valid_21626564 = query.getOrDefault("MaxResults")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "MaxResults", valid_21626564
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
  var valid_21626565 = header.getOrDefault("X-Amz-Date")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Date", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Security-Token", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Algorithm", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Signature")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Signature", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Credential")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Credential", valid_21626571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626572: Call_ListResourceDefinitionVersions_21626559;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_21626572.validator(path, query, header, formData, body, _)
  let scheme = call_21626572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626572.makeUrl(scheme.get, call_21626572.host, call_21626572.base,
                               call_21626572.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626572, uri, valid, _)

proc call*(call_21626573: Call_ListResourceDefinitionVersions_21626559;
          ResourceDefinitionId: string; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listResourceDefinitionVersions
  ## Lists the versions of a resource definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626574 = newJObject()
  var query_21626575 = newJObject()
  add(query_21626575, "NextToken", newJString(NextToken))
  add(path_21626574, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  add(query_21626575, "MaxResults", newJString(MaxResults))
  result = call_21626573.call(path_21626574, query_21626575, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_21626559(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_21626560, base: "/",
    makeUrl: url_ListResourceDefinitionVersions_21626561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_21626593 = ref object of OpenApiRestCall_21625418
proc url_CreateSoftwareUpdateJob_21626595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSoftwareUpdateJob_21626594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626596 = header.getOrDefault("X-Amz-Date")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Date", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Security-Token", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Algorithm", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amzn-Client-Token", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Signature")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Signature", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Credential")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Credential", valid_21626603
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

proc call*(call_21626605: Call_CreateSoftwareUpdateJob_21626593;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_21626605.validator(path, query, header, formData, body, _)
  let scheme = call_21626605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626605.makeUrl(scheme.get, call_21626605.host, call_21626605.base,
                               call_21626605.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626605, uri, valid, _)

proc call*(call_21626606: Call_CreateSoftwareUpdateJob_21626593; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_21626607 = newJObject()
  if body != nil:
    body_21626607 = body
  result = call_21626606.call(nil, nil, nil, nil, body_21626607)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_21626593(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_21626594, base: "/",
    makeUrl: url_CreateSoftwareUpdateJob_21626595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_21626623 = ref object of OpenApiRestCall_21625418
proc url_CreateSubscriptionDefinition_21626625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubscriptionDefinition_21626624(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626626 = header.getOrDefault("X-Amz-Date")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Date", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Security-Token", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Algorithm", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amzn-Client-Token", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Signature")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Signature", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Credential")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Credential", valid_21626633
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

proc call*(call_21626635: Call_CreateSubscriptionDefinition_21626623;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_21626635.validator(path, query, header, formData, body, _)
  let scheme = call_21626635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626635.makeUrl(scheme.get, call_21626635.host, call_21626635.base,
                               call_21626635.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626635, uri, valid, _)

proc call*(call_21626636: Call_CreateSubscriptionDefinition_21626623;
          body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_21626637 = newJObject()
  if body != nil:
    body_21626637 = body
  result = call_21626636.call(nil, nil, nil, nil, body_21626637)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_21626623(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_21626624, base: "/",
    makeUrl: url_CreateSubscriptionDefinition_21626625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_21626608 = ref object of OpenApiRestCall_21625418
proc url_ListSubscriptionDefinitions_21626610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscriptionDefinitions_21626609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of subscription definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626611 = query.getOrDefault("NextToken")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "NextToken", valid_21626611
  var valid_21626612 = query.getOrDefault("MaxResults")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "MaxResults", valid_21626612
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
  var valid_21626613 = header.getOrDefault("X-Amz-Date")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Date", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Security-Token", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Algorithm", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Signature")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Signature", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Credential")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Credential", valid_21626619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626620: Call_ListSubscriptionDefinitions_21626608;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_21626620.validator(path, query, header, formData, body, _)
  let scheme = call_21626620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626620.makeUrl(scheme.get, call_21626620.host, call_21626620.base,
                               call_21626620.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626620, uri, valid, _)

proc call*(call_21626621: Call_ListSubscriptionDefinitions_21626608;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21626622 = newJObject()
  add(query_21626622, "NextToken", newJString(NextToken))
  add(query_21626622, "MaxResults", newJString(MaxResults))
  result = call_21626621.call(nil, query_21626622, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_21626608(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_21626609, base: "/",
    makeUrl: url_ListSubscriptionDefinitions_21626610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_21626655 = ref object of OpenApiRestCall_21625418
proc url_CreateSubscriptionDefinitionVersion_21626657(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSubscriptionDefinitionVersion_21626656(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21626658 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "SubscriptionDefinitionId", valid_21626658
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626659 = header.getOrDefault("X-Amz-Date")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Date", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Security-Token", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Algorithm", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amzn-Client-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Signature")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Signature", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Credential")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Credential", valid_21626666
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

proc call*(call_21626668: Call_CreateSubscriptionDefinitionVersion_21626655;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_21626668.validator(path, query, header, formData, body, _)
  let scheme = call_21626668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626668.makeUrl(scheme.get, call_21626668.host, call_21626668.base,
                               call_21626668.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626668, uri, valid, _)

proc call*(call_21626669: Call_CreateSubscriptionDefinitionVersion_21626655;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_21626670 = newJObject()
  var body_21626671 = newJObject()
  add(path_21626670, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_21626671 = body
  result = call_21626669.call(path_21626670, nil, nil, nil, body_21626671)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_21626655(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_21626656, base: "/",
    makeUrl: url_CreateSubscriptionDefinitionVersion_21626657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_21626638 = ref object of OpenApiRestCall_21625418
proc url_ListSubscriptionDefinitionVersions_21626640(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSubscriptionDefinitionVersions_21626639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the versions of a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21626641 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "SubscriptionDefinitionId", valid_21626641
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21626642 = query.getOrDefault("NextToken")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "NextToken", valid_21626642
  var valid_21626643 = query.getOrDefault("MaxResults")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "MaxResults", valid_21626643
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
  var valid_21626644 = header.getOrDefault("X-Amz-Date")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Date", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Security-Token", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Algorithm", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Signature")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Signature", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Credential")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Credential", valid_21626650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626651: Call_ListSubscriptionDefinitionVersions_21626638;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_ListSubscriptionDefinitionVersions_21626638;
          SubscriptionDefinitionId: string; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listSubscriptionDefinitionVersions
  ## Lists the versions of a subscription definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_21626653 = newJObject()
  var query_21626654 = newJObject()
  add(query_21626654, "NextToken", newJString(NextToken))
  add(path_21626653, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(query_21626654, "MaxResults", newJString(MaxResults))
  result = call_21626652.call(path_21626653, query_21626654, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_21626638(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_21626639, base: "/",
    makeUrl: url_ListSubscriptionDefinitionVersions_21626640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_21626686 = ref object of OpenApiRestCall_21625418
proc url_UpdateConnectorDefinition_21626688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConnectorDefinition_21626687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_21626689 = path.getOrDefault("ConnectorDefinitionId")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "ConnectorDefinitionId", valid_21626689
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
  var valid_21626690 = header.getOrDefault("X-Amz-Date")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Date", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Security-Token", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Algorithm", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Signature")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Signature", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Credential")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Credential", valid_21626696
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

proc call*(call_21626698: Call_UpdateConnectorDefinition_21626686;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_21626698.validator(path, query, header, formData, body, _)
  let scheme = call_21626698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626698.makeUrl(scheme.get, call_21626698.host, call_21626698.base,
                               call_21626698.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626698, uri, valid, _)

proc call*(call_21626699: Call_UpdateConnectorDefinition_21626686;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_21626700 = newJObject()
  var body_21626701 = newJObject()
  add(path_21626700, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_21626701 = body
  result = call_21626699.call(path_21626700, nil, nil, nil, body_21626701)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_21626686(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_21626687, base: "/",
    makeUrl: url_UpdateConnectorDefinition_21626688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_21626672 = ref object of OpenApiRestCall_21625418
proc url_GetConnectorDefinition_21626674(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinition_21626673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_21626675 = path.getOrDefault("ConnectorDefinitionId")
  valid_21626675 = validateParameter(valid_21626675, JString, required = true,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "ConnectorDefinitionId", valid_21626675
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
  var valid_21626676 = header.getOrDefault("X-Amz-Date")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Date", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Security-Token", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Algorithm", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Signature")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Signature", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Credential")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Credential", valid_21626682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626683: Call_GetConnectorDefinition_21626672;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_GetConnectorDefinition_21626672;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_21626685 = newJObject()
  add(path_21626685, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_21626684.call(path_21626685, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_21626672(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_21626673, base: "/",
    makeUrl: url_GetConnectorDefinition_21626674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_21626702 = ref object of OpenApiRestCall_21625418
proc url_DeleteConnectorDefinition_21626704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConnectorDefinition_21626703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_21626705 = path.getOrDefault("ConnectorDefinitionId")
  valid_21626705 = validateParameter(valid_21626705, JString, required = true,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "ConnectorDefinitionId", valid_21626705
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
  var valid_21626706 = header.getOrDefault("X-Amz-Date")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Date", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Security-Token", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Algorithm", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Signature")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Signature", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Credential")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Credential", valid_21626712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626713: Call_DeleteConnectorDefinition_21626702;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_21626713.validator(path, query, header, formData, body, _)
  let scheme = call_21626713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626713.makeUrl(scheme.get, call_21626713.host, call_21626713.base,
                               call_21626713.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626713, uri, valid, _)

proc call*(call_21626714: Call_DeleteConnectorDefinition_21626702;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_21626715 = newJObject()
  add(path_21626715, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_21626714.call(path_21626715, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_21626702(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_21626703, base: "/",
    makeUrl: url_DeleteConnectorDefinition_21626704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_21626730 = ref object of OpenApiRestCall_21625418
proc url_UpdateCoreDefinition_21626732(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCoreDefinition_21626731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a core definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21626733 = path.getOrDefault("CoreDefinitionId")
  valid_21626733 = validateParameter(valid_21626733, JString, required = true,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "CoreDefinitionId", valid_21626733
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
  var valid_21626734 = header.getOrDefault("X-Amz-Date")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Date", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Security-Token", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Algorithm", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Signature")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Signature", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Credential")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Credential", valid_21626740
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

proc call*(call_21626742: Call_UpdateCoreDefinition_21626730; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_21626742.validator(path, query, header, formData, body, _)
  let scheme = call_21626742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626742.makeUrl(scheme.get, call_21626742.host, call_21626742.base,
                               call_21626742.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626742, uri, valid, _)

proc call*(call_21626743: Call_UpdateCoreDefinition_21626730;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_21626744 = newJObject()
  var body_21626745 = newJObject()
  add(path_21626744, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_21626745 = body
  result = call_21626743.call(path_21626744, nil, nil, nil, body_21626745)

var updateCoreDefinition* = Call_UpdateCoreDefinition_21626730(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_21626731, base: "/",
    makeUrl: url_UpdateCoreDefinition_21626732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_21626716 = ref object of OpenApiRestCall_21625418
proc url_GetCoreDefinition_21626718(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCoreDefinition_21626717(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a core definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21626719 = path.getOrDefault("CoreDefinitionId")
  valid_21626719 = validateParameter(valid_21626719, JString, required = true,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "CoreDefinitionId", valid_21626719
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
  var valid_21626720 = header.getOrDefault("X-Amz-Date")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Date", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Security-Token", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Algorithm", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Signature")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Signature", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Credential")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Credential", valid_21626726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626727: Call_GetCoreDefinition_21626716; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_21626727.validator(path, query, header, formData, body, _)
  let scheme = call_21626727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626727.makeUrl(scheme.get, call_21626727.host, call_21626727.base,
                               call_21626727.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626727, uri, valid, _)

proc call*(call_21626728: Call_GetCoreDefinition_21626716; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_21626729 = newJObject()
  add(path_21626729, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_21626728.call(path_21626729, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_21626716(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_21626717, base: "/",
    makeUrl: url_GetCoreDefinition_21626718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_21626746 = ref object of OpenApiRestCall_21625418
proc url_DeleteCoreDefinition_21626748(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCoreDefinition_21626747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a core definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21626749 = path.getOrDefault("CoreDefinitionId")
  valid_21626749 = validateParameter(valid_21626749, JString, required = true,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "CoreDefinitionId", valid_21626749
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
  var valid_21626750 = header.getOrDefault("X-Amz-Date")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Date", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Security-Token", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Algorithm", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Signature")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Signature", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Credential")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Credential", valid_21626756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626757: Call_DeleteCoreDefinition_21626746; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_21626757.validator(path, query, header, formData, body, _)
  let scheme = call_21626757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626757.makeUrl(scheme.get, call_21626757.host, call_21626757.base,
                               call_21626757.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626757, uri, valid, _)

proc call*(call_21626758: Call_DeleteCoreDefinition_21626746;
          CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_21626759 = newJObject()
  add(path_21626759, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_21626758.call(path_21626759, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_21626746(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_21626747, base: "/",
    makeUrl: url_DeleteCoreDefinition_21626748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_21626774 = ref object of OpenApiRestCall_21625418
proc url_UpdateDeviceDefinition_21626776(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeviceDefinition_21626775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a device definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21626777 = path.getOrDefault("DeviceDefinitionId")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "DeviceDefinitionId", valid_21626777
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
  var valid_21626778 = header.getOrDefault("X-Amz-Date")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Date", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Security-Token", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Algorithm", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Signature")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Signature", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Credential")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Credential", valid_21626784
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

proc call*(call_21626786: Call_UpdateDeviceDefinition_21626774;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_21626786.validator(path, query, header, formData, body, _)
  let scheme = call_21626786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626786.makeUrl(scheme.get, call_21626786.host, call_21626786.base,
                               call_21626786.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626786, uri, valid, _)

proc call*(call_21626787: Call_UpdateDeviceDefinition_21626774;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_21626788 = newJObject()
  var body_21626789 = newJObject()
  add(path_21626788, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_21626789 = body
  result = call_21626787.call(path_21626788, nil, nil, nil, body_21626789)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_21626774(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_21626775, base: "/",
    makeUrl: url_UpdateDeviceDefinition_21626776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_21626760 = ref object of OpenApiRestCall_21625418
proc url_GetDeviceDefinition_21626762(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceDefinition_21626761(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a device definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21626763 = path.getOrDefault("DeviceDefinitionId")
  valid_21626763 = validateParameter(valid_21626763, JString, required = true,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "DeviceDefinitionId", valid_21626763
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
  var valid_21626764 = header.getOrDefault("X-Amz-Date")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Date", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Security-Token", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Algorithm", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Signature")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Signature", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Credential")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Credential", valid_21626770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626771: Call_GetDeviceDefinition_21626760; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_21626771.validator(path, query, header, formData, body, _)
  let scheme = call_21626771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626771.makeUrl(scheme.get, call_21626771.host, call_21626771.base,
                               call_21626771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626771, uri, valid, _)

proc call*(call_21626772: Call_GetDeviceDefinition_21626760;
          DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_21626773 = newJObject()
  add(path_21626773, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_21626772.call(path_21626773, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_21626760(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_21626761, base: "/",
    makeUrl: url_GetDeviceDefinition_21626762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_21626790 = ref object of OpenApiRestCall_21625418
proc url_DeleteDeviceDefinition_21626792(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeviceDefinition_21626791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a device definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21626793 = path.getOrDefault("DeviceDefinitionId")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "DeviceDefinitionId", valid_21626793
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
  var valid_21626794 = header.getOrDefault("X-Amz-Date")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Date", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Security-Token", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Algorithm", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Signature")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Signature", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Credential")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Credential", valid_21626800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626801: Call_DeleteDeviceDefinition_21626790;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_21626801.validator(path, query, header, formData, body, _)
  let scheme = call_21626801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626801.makeUrl(scheme.get, call_21626801.host, call_21626801.base,
                               call_21626801.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626801, uri, valid, _)

proc call*(call_21626802: Call_DeleteDeviceDefinition_21626790;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_21626803 = newJObject()
  add(path_21626803, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_21626802.call(path_21626803, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_21626790(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_21626791, base: "/",
    makeUrl: url_DeleteDeviceDefinition_21626792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_21626818 = ref object of OpenApiRestCall_21625418
proc url_UpdateFunctionDefinition_21626820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionDefinition_21626819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_21626821 = path.getOrDefault("FunctionDefinitionId")
  valid_21626821 = validateParameter(valid_21626821, JString, required = true,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "FunctionDefinitionId", valid_21626821
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
  var valid_21626822 = header.getOrDefault("X-Amz-Date")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Date", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Security-Token", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Algorithm", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Signature")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Signature", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Credential")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Credential", valid_21626828
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

proc call*(call_21626830: Call_UpdateFunctionDefinition_21626818;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_21626830.validator(path, query, header, formData, body, _)
  let scheme = call_21626830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626830.makeUrl(scheme.get, call_21626830.host, call_21626830.base,
                               call_21626830.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626830, uri, valid, _)

proc call*(call_21626831: Call_UpdateFunctionDefinition_21626818;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_21626832 = newJObject()
  var body_21626833 = newJObject()
  add(path_21626832, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_21626833 = body
  result = call_21626831.call(path_21626832, nil, nil, nil, body_21626833)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_21626818(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_21626819, base: "/",
    makeUrl: url_UpdateFunctionDefinition_21626820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_21626804 = ref object of OpenApiRestCall_21625418
proc url_GetFunctionDefinition_21626806(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinition_21626805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_21626807 = path.getOrDefault("FunctionDefinitionId")
  valid_21626807 = validateParameter(valid_21626807, JString, required = true,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "FunctionDefinitionId", valid_21626807
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
  var valid_21626808 = header.getOrDefault("X-Amz-Date")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Date", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Security-Token", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Algorithm", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Signature")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Signature", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Credential")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Credential", valid_21626814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626815: Call_GetFunctionDefinition_21626804;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_21626815.validator(path, query, header, formData, body, _)
  let scheme = call_21626815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626815.makeUrl(scheme.get, call_21626815.host, call_21626815.base,
                               call_21626815.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626815, uri, valid, _)

proc call*(call_21626816: Call_GetFunctionDefinition_21626804;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_21626817 = newJObject()
  add(path_21626817, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_21626816.call(path_21626817, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_21626804(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_21626805, base: "/",
    makeUrl: url_GetFunctionDefinition_21626806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_21626834 = ref object of OpenApiRestCall_21625418
proc url_DeleteFunctionDefinition_21626836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionDefinition_21626835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_21626837 = path.getOrDefault("FunctionDefinitionId")
  valid_21626837 = validateParameter(valid_21626837, JString, required = true,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "FunctionDefinitionId", valid_21626837
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
  var valid_21626838 = header.getOrDefault("X-Amz-Date")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Date", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Security-Token", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Algorithm", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Signature")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Signature", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Credential")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Credential", valid_21626844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626845: Call_DeleteFunctionDefinition_21626834;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_21626845.validator(path, query, header, formData, body, _)
  let scheme = call_21626845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626845.makeUrl(scheme.get, call_21626845.host, call_21626845.base,
                               call_21626845.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626845, uri, valid, _)

proc call*(call_21626846: Call_DeleteFunctionDefinition_21626834;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_21626847 = newJObject()
  add(path_21626847, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_21626846.call(path_21626847, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_21626834(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_21626835, base: "/",
    makeUrl: url_DeleteFunctionDefinition_21626836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_21626862 = ref object of OpenApiRestCall_21625418
proc url_UpdateGroup_21626864(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_21626863(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626865 = path.getOrDefault("GroupId")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "GroupId", valid_21626865
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
  var valid_21626866 = header.getOrDefault("X-Amz-Date")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Date", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Security-Token", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Algorithm", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Signature")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Signature", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Credential")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Credential", valid_21626872
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

proc call*(call_21626874: Call_UpdateGroup_21626862; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a group.
  ## 
  let valid = call_21626874.validator(path, query, header, formData, body, _)
  let scheme = call_21626874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626874.makeUrl(scheme.get, call_21626874.host, call_21626874.base,
                               call_21626874.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626874, uri, valid, _)

proc call*(call_21626875: Call_UpdateGroup_21626862; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21626876 = newJObject()
  var body_21626877 = newJObject()
  add(path_21626876, "GroupId", newJString(GroupId))
  if body != nil:
    body_21626877 = body
  result = call_21626875.call(path_21626876, nil, nil, nil, body_21626877)

var updateGroup* = Call_UpdateGroup_21626862(name: "updateGroup",
    meth: HttpMethod.HttpPut, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}", validator: validate_UpdateGroup_21626863,
    base: "/", makeUrl: url_UpdateGroup_21626864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_21626848 = ref object of OpenApiRestCall_21625418
proc url_GetGroup_21626850(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroup_21626849(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626851 = path.getOrDefault("GroupId")
  valid_21626851 = validateParameter(valid_21626851, JString, required = true,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "GroupId", valid_21626851
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
  var valid_21626852 = header.getOrDefault("X-Amz-Date")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Date", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Security-Token", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Algorithm", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Signature")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Signature", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Credential")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Credential", valid_21626858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626859: Call_GetGroup_21626848; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_21626859.validator(path, query, header, formData, body, _)
  let scheme = call_21626859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626859.makeUrl(scheme.get, call_21626859.host, call_21626859.base,
                               call_21626859.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626859, uri, valid, _)

proc call*(call_21626860: Call_GetGroup_21626848; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21626861 = newJObject()
  add(path_21626861, "GroupId", newJString(GroupId))
  result = call_21626860.call(path_21626861, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_21626848(name: "getGroup", meth: HttpMethod.HttpGet,
                                    host: "greengrass.amazonaws.com",
                                    route: "/greengrass/groups/{GroupId}",
                                    validator: validate_GetGroup_21626849,
                                    base: "/", makeUrl: url_GetGroup_21626850,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_21626878 = ref object of OpenApiRestCall_21625418
proc url_DeleteGroup_21626880(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_21626879(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21626881 = path.getOrDefault("GroupId")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "GroupId", valid_21626881
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
  var valid_21626882 = header.getOrDefault("X-Amz-Date")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Date", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Security-Token", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Algorithm", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Signature")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Signature", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Credential")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Credential", valid_21626888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626889: Call_DeleteGroup_21626878; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_21626889.validator(path, query, header, formData, body, _)
  let scheme = call_21626889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626889.makeUrl(scheme.get, call_21626889.host, call_21626889.base,
                               call_21626889.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626889, uri, valid, _)

proc call*(call_21626890: Call_DeleteGroup_21626878; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21626891 = newJObject()
  add(path_21626891, "GroupId", newJString(GroupId))
  result = call_21626890.call(path_21626891, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_21626878(name: "deleteGroup",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}", validator: validate_DeleteGroup_21626879,
    base: "/", makeUrl: url_DeleteGroup_21626880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_21626906 = ref object of OpenApiRestCall_21625418
proc url_UpdateLoggerDefinition_21626908(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLoggerDefinition_21626907(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a logger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_21626909 = path.getOrDefault("LoggerDefinitionId")
  valid_21626909 = validateParameter(valid_21626909, JString, required = true,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "LoggerDefinitionId", valid_21626909
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
  var valid_21626910 = header.getOrDefault("X-Amz-Date")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Date", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Security-Token", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Algorithm", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Signature")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Signature", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Credential")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Credential", valid_21626916
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

proc call*(call_21626918: Call_UpdateLoggerDefinition_21626906;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_21626918.validator(path, query, header, formData, body, _)
  let scheme = call_21626918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626918.makeUrl(scheme.get, call_21626918.host, call_21626918.base,
                               call_21626918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626918, uri, valid, _)

proc call*(call_21626919: Call_UpdateLoggerDefinition_21626906;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_21626920 = newJObject()
  var body_21626921 = newJObject()
  add(path_21626920, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_21626921 = body
  result = call_21626919.call(path_21626920, nil, nil, nil, body_21626921)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_21626906(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_21626907, base: "/",
    makeUrl: url_UpdateLoggerDefinition_21626908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_21626892 = ref object of OpenApiRestCall_21625418
proc url_GetLoggerDefinition_21626894(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLoggerDefinition_21626893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a logger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_21626895 = path.getOrDefault("LoggerDefinitionId")
  valid_21626895 = validateParameter(valid_21626895, JString, required = true,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "LoggerDefinitionId", valid_21626895
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
  var valid_21626896 = header.getOrDefault("X-Amz-Date")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Date", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Security-Token", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Algorithm", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Signature")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Signature", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Credential")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Credential", valid_21626902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626903: Call_GetLoggerDefinition_21626892; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_21626903.validator(path, query, header, formData, body, _)
  let scheme = call_21626903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626903.makeUrl(scheme.get, call_21626903.host, call_21626903.base,
                               call_21626903.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626903, uri, valid, _)

proc call*(call_21626904: Call_GetLoggerDefinition_21626892;
          LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_21626905 = newJObject()
  add(path_21626905, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_21626904.call(path_21626905, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_21626892(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_21626893, base: "/",
    makeUrl: url_GetLoggerDefinition_21626894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_21626922 = ref object of OpenApiRestCall_21625418
proc url_DeleteLoggerDefinition_21626924(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLoggerDefinition_21626923(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a logger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_21626925 = path.getOrDefault("LoggerDefinitionId")
  valid_21626925 = validateParameter(valid_21626925, JString, required = true,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "LoggerDefinitionId", valid_21626925
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
  var valid_21626926 = header.getOrDefault("X-Amz-Date")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Date", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Security-Token", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Algorithm", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Signature")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Signature", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Credential")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Credential", valid_21626932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626933: Call_DeleteLoggerDefinition_21626922;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_21626933.validator(path, query, header, formData, body, _)
  let scheme = call_21626933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626933.makeUrl(scheme.get, call_21626933.host, call_21626933.base,
                               call_21626933.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626933, uri, valid, _)

proc call*(call_21626934: Call_DeleteLoggerDefinition_21626922;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_21626935 = newJObject()
  add(path_21626935, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_21626934.call(path_21626935, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_21626922(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_21626923, base: "/",
    makeUrl: url_DeleteLoggerDefinition_21626924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_21626950 = ref object of OpenApiRestCall_21625418
proc url_UpdateResourceDefinition_21626952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResourceDefinition_21626951(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_21626953 = path.getOrDefault("ResourceDefinitionId")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "ResourceDefinitionId", valid_21626953
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
  var valid_21626954 = header.getOrDefault("X-Amz-Date")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Date", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Security-Token", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Algorithm", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Signature")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Signature", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Credential")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Credential", valid_21626960
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

proc call*(call_21626962: Call_UpdateResourceDefinition_21626950;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_21626962.validator(path, query, header, formData, body, _)
  let scheme = call_21626962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626962.makeUrl(scheme.get, call_21626962.host, call_21626962.base,
                               call_21626962.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626962, uri, valid, _)

proc call*(call_21626963: Call_UpdateResourceDefinition_21626950;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_21626964 = newJObject()
  var body_21626965 = newJObject()
  add(path_21626964, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_21626965 = body
  result = call_21626963.call(path_21626964, nil, nil, nil, body_21626965)

var updateResourceDefinition* = Call_UpdateResourceDefinition_21626950(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_21626951, base: "/",
    makeUrl: url_UpdateResourceDefinition_21626952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_21626936 = ref object of OpenApiRestCall_21625418
proc url_GetResourceDefinition_21626938(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinition_21626937(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_21626939 = path.getOrDefault("ResourceDefinitionId")
  valid_21626939 = validateParameter(valid_21626939, JString, required = true,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "ResourceDefinitionId", valid_21626939
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
  var valid_21626940 = header.getOrDefault("X-Amz-Date")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Date", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Security-Token", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Algorithm", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Signature")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Signature", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Credential")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Credential", valid_21626946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626947: Call_GetResourceDefinition_21626936;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_21626947.validator(path, query, header, formData, body, _)
  let scheme = call_21626947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626947.makeUrl(scheme.get, call_21626947.host, call_21626947.base,
                               call_21626947.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626947, uri, valid, _)

proc call*(call_21626948: Call_GetResourceDefinition_21626936;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_21626949 = newJObject()
  add(path_21626949, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_21626948.call(path_21626949, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_21626936(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_21626937, base: "/",
    makeUrl: url_GetResourceDefinition_21626938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_21626966 = ref object of OpenApiRestCall_21625418
proc url_DeleteResourceDefinition_21626968(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResourceDefinition_21626967(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_21626969 = path.getOrDefault("ResourceDefinitionId")
  valid_21626969 = validateParameter(valid_21626969, JString, required = true,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "ResourceDefinitionId", valid_21626969
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
  var valid_21626970 = header.getOrDefault("X-Amz-Date")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Date", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Security-Token", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Algorithm", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Signature")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Signature", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Credential")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Credential", valid_21626976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626977: Call_DeleteResourceDefinition_21626966;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_21626977.validator(path, query, header, formData, body, _)
  let scheme = call_21626977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626977.makeUrl(scheme.get, call_21626977.host, call_21626977.base,
                               call_21626977.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626977, uri, valid, _)

proc call*(call_21626978: Call_DeleteResourceDefinition_21626966;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_21626979 = newJObject()
  add(path_21626979, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_21626978.call(path_21626979, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_21626966(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_21626967, base: "/",
    makeUrl: url_DeleteResourceDefinition_21626968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_21626994 = ref object of OpenApiRestCall_21625418
proc url_UpdateSubscriptionDefinition_21626996(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSubscriptionDefinition_21626995(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21626997 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21626997 = validateParameter(valid_21626997, JString, required = true,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "SubscriptionDefinitionId", valid_21626997
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
  var valid_21626998 = header.getOrDefault("X-Amz-Date")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Date", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Security-Token", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Algorithm", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Signature")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Signature", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Credential")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Credential", valid_21627004
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

proc call*(call_21627006: Call_UpdateSubscriptionDefinition_21626994;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_21627006.validator(path, query, header, formData, body, _)
  let scheme = call_21627006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627006.makeUrl(scheme.get, call_21627006.host, call_21627006.base,
                               call_21627006.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627006, uri, valid, _)

proc call*(call_21627007: Call_UpdateSubscriptionDefinition_21626994;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_21627008 = newJObject()
  var body_21627009 = newJObject()
  add(path_21627008, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_21627009 = body
  result = call_21627007.call(path_21627008, nil, nil, nil, body_21627009)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_21626994(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_21626995, base: "/",
    makeUrl: url_UpdateSubscriptionDefinition_21626996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_21626980 = ref object of OpenApiRestCall_21625418
proc url_GetSubscriptionDefinition_21626982(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSubscriptionDefinition_21626981(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21626983 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21626983 = validateParameter(valid_21626983, JString, required = true,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "SubscriptionDefinitionId", valid_21626983
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
  var valid_21626984 = header.getOrDefault("X-Amz-Date")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Date", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Security-Token", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Algorithm", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Signature")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Signature", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Credential")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Credential", valid_21626990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626991: Call_GetSubscriptionDefinition_21626980;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_21626991.validator(path, query, header, formData, body, _)
  let scheme = call_21626991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626991.makeUrl(scheme.get, call_21626991.host, call_21626991.base,
                               call_21626991.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626991, uri, valid, _)

proc call*(call_21626992: Call_GetSubscriptionDefinition_21626980;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_21626993 = newJObject()
  add(path_21626993, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_21626992.call(path_21626993, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_21626980(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_21626981, base: "/",
    makeUrl: url_GetSubscriptionDefinition_21626982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_21627010 = ref object of OpenApiRestCall_21625418
proc url_DeleteSubscriptionDefinition_21627012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSubscriptionDefinition_21627011(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21627013 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21627013 = validateParameter(valid_21627013, JString, required = true,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "SubscriptionDefinitionId", valid_21627013
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
  var valid_21627014 = header.getOrDefault("X-Amz-Date")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Date", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Security-Token", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Algorithm", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Signature")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Signature", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Credential")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Credential", valid_21627020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627021: Call_DeleteSubscriptionDefinition_21627010;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_21627021.validator(path, query, header, formData, body, _)
  let scheme = call_21627021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627021.makeUrl(scheme.get, call_21627021.host, call_21627021.base,
                               call_21627021.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627021, uri, valid, _)

proc call*(call_21627022: Call_DeleteSubscriptionDefinition_21627010;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_21627023 = newJObject()
  add(path_21627023, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_21627022.call(path_21627023, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_21627010(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_21627011, base: "/",
    makeUrl: url_DeleteSubscriptionDefinition_21627012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_21627024 = ref object of OpenApiRestCall_21625418
proc url_GetBulkDeploymentStatus_21627026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "BulkDeploymentId" in path,
        "`BulkDeploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/bulk/deployments/"),
               (kind: VariableSegment, value: "BulkDeploymentId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkDeploymentStatus_21627025(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the status of a bulk deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   BulkDeploymentId: JString (required)
  ##                   : The ID of the bulk deployment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `BulkDeploymentId` field"
  var valid_21627027 = path.getOrDefault("BulkDeploymentId")
  valid_21627027 = validateParameter(valid_21627027, JString, required = true,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "BulkDeploymentId", valid_21627027
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
  var valid_21627028 = header.getOrDefault("X-Amz-Date")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Date", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Security-Token", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Algorithm", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-Signature")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Signature", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Credential")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Credential", valid_21627034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627035: Call_GetBulkDeploymentStatus_21627024;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_21627035.validator(path, query, header, formData, body, _)
  let scheme = call_21627035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627035.makeUrl(scheme.get, call_21627035.host, call_21627035.base,
                               call_21627035.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627035, uri, valid, _)

proc call*(call_21627036: Call_GetBulkDeploymentStatus_21627024;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_21627037 = newJObject()
  add(path_21627037, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_21627036.call(path_21627037, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_21627024(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_21627025, base: "/",
    makeUrl: url_GetBulkDeploymentStatus_21627026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_21627052 = ref object of OpenApiRestCall_21625418
proc url_UpdateConnectivityInfo_21627054(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ThingName" in path, "`ThingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/things/"),
               (kind: VariableSegment, value: "ThingName"),
               (kind: ConstantSegment, value: "/connectivityInfo")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConnectivityInfo_21627053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ThingName: JString (required)
  ##            : The thing name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ThingName` field"
  var valid_21627055 = path.getOrDefault("ThingName")
  valid_21627055 = validateParameter(valid_21627055, JString, required = true,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "ThingName", valid_21627055
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
  var valid_21627056 = header.getOrDefault("X-Amz-Date")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Date", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Security-Token", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Algorithm", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Signature")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Signature", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-Credential")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-Credential", valid_21627062
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

proc call*(call_21627064: Call_UpdateConnectivityInfo_21627052;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_21627064.validator(path, query, header, formData, body, _)
  let scheme = call_21627064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627064.makeUrl(scheme.get, call_21627064.host, call_21627064.base,
                               call_21627064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627064, uri, valid, _)

proc call*(call_21627065: Call_UpdateConnectivityInfo_21627052; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_21627066 = newJObject()
  var body_21627067 = newJObject()
  add(path_21627066, "ThingName", newJString(ThingName))
  if body != nil:
    body_21627067 = body
  result = call_21627065.call(path_21627066, nil, nil, nil, body_21627067)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_21627052(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_21627053, base: "/",
    makeUrl: url_UpdateConnectivityInfo_21627054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_21627038 = ref object of OpenApiRestCall_21625418
proc url_GetConnectivityInfo_21627040(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ThingName" in path, "`ThingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/things/"),
               (kind: VariableSegment, value: "ThingName"),
               (kind: ConstantSegment, value: "/connectivityInfo")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectivityInfo_21627039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the connectivity information for a core.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ThingName: JString (required)
  ##            : The thing name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ThingName` field"
  var valid_21627041 = path.getOrDefault("ThingName")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "ThingName", valid_21627041
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
  var valid_21627042 = header.getOrDefault("X-Amz-Date")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Date", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Security-Token", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Algorithm", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Signature")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Signature", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Credential")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Credential", valid_21627048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627049: Call_GetConnectivityInfo_21627038; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_21627049.validator(path, query, header, formData, body, _)
  let scheme = call_21627049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627049.makeUrl(scheme.get, call_21627049.host, call_21627049.base,
                               call_21627049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627049, uri, valid, _)

proc call*(call_21627050: Call_GetConnectivityInfo_21627038; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_21627051 = newJObject()
  add(path_21627051, "ThingName", newJString(ThingName))
  result = call_21627050.call(path_21627051, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_21627038(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_21627039, base: "/",
    makeUrl: url_GetConnectivityInfo_21627040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_21627068 = ref object of OpenApiRestCall_21625418
proc url_GetConnectorDefinitionVersion_21627070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  assert "ConnectorDefinitionVersionId" in path,
        "`ConnectorDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "ConnectorDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinitionVersion_21627069(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionVersionId: JString (required)
  ##                               : The ID of the connector definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListConnectorDefinitionVersions'' requests. If the version is the last one that was associated with a connector definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionVersionId` field"
  var valid_21627071 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_21627071 = validateParameter(valid_21627071, JString, required = true,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "ConnectorDefinitionVersionId", valid_21627071
  var valid_21627072 = path.getOrDefault("ConnectorDefinitionId")
  valid_21627072 = validateParameter(valid_21627072, JString, required = true,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "ConnectorDefinitionId", valid_21627072
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_21627073 = query.getOrDefault("NextToken")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "NextToken", valid_21627073
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
  var valid_21627074 = header.getOrDefault("X-Amz-Date")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Date", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Security-Token", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Algorithm", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Signature")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Signature", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Credential")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Credential", valid_21627080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627081: Call_GetConnectorDefinitionVersion_21627068;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_21627081.validator(path, query, header, formData, body, _)
  let scheme = call_21627081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627081.makeUrl(scheme.get, call_21627081.host, call_21627081.base,
                               call_21627081.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627081, uri, valid, _)

proc call*(call_21627082: Call_GetConnectorDefinitionVersion_21627068;
          ConnectorDefinitionVersionId: string; ConnectorDefinitionId: string;
          NextToken: string = ""): Recallable =
  ## getConnectorDefinitionVersion
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ConnectorDefinitionVersionId: string (required)
  ##                               : The ID of the connector definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListConnectorDefinitionVersions'' requests. If the version is the last one that was associated with a connector definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_21627083 = newJObject()
  var query_21627084 = newJObject()
  add(query_21627084, "NextToken", newJString(NextToken))
  add(path_21627083, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(path_21627083, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_21627082.call(path_21627083, query_21627084, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_21627068(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_21627069, base: "/",
    makeUrl: url_GetConnectorDefinitionVersion_21627070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_21627085 = ref object of OpenApiRestCall_21625418
proc url_GetCoreDefinitionVersion_21627087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  assert "CoreDefinitionVersionId" in path,
        "`CoreDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "CoreDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCoreDefinitionVersion_21627086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a core definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  ##   CoreDefinitionVersionId: JString (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_21627088 = path.getOrDefault("CoreDefinitionId")
  valid_21627088 = validateParameter(valid_21627088, JString, required = true,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "CoreDefinitionId", valid_21627088
  var valid_21627089 = path.getOrDefault("CoreDefinitionVersionId")
  valid_21627089 = validateParameter(valid_21627089, JString, required = true,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "CoreDefinitionVersionId", valid_21627089
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
  var valid_21627090 = header.getOrDefault("X-Amz-Date")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Date", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Security-Token", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-Algorithm", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Signature")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Signature", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Credential")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Credential", valid_21627096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627097: Call_GetCoreDefinitionVersion_21627085;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_21627097.validator(path, query, header, formData, body, _)
  let scheme = call_21627097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627097.makeUrl(scheme.get, call_21627097.host, call_21627097.base,
                               call_21627097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627097, uri, valid, _)

proc call*(call_21627098: Call_GetCoreDefinitionVersion_21627085;
          CoreDefinitionId: string; CoreDefinitionVersionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_21627099 = newJObject()
  add(path_21627099, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(path_21627099, "CoreDefinitionVersionId",
      newJString(CoreDefinitionVersionId))
  result = call_21627098.call(path_21627099, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_21627085(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_21627086, base: "/",
    makeUrl: url_GetCoreDefinitionVersion_21627087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_21627100 = ref object of OpenApiRestCall_21625418
proc url_GetDeploymentStatus_21627102(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  assert "DeploymentId" in path, "`DeploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "DeploymentId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeploymentStatus_21627101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the status of a deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: JString (required)
  ##               : The ID of the deployment.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21627103 = path.getOrDefault("GroupId")
  valid_21627103 = validateParameter(valid_21627103, JString, required = true,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "GroupId", valid_21627103
  var valid_21627104 = path.getOrDefault("DeploymentId")
  valid_21627104 = validateParameter(valid_21627104, JString, required = true,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "DeploymentId", valid_21627104
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
  var valid_21627105 = header.getOrDefault("X-Amz-Date")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Date", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Security-Token", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Algorithm", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Signature")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Signature", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Credential")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-Credential", valid_21627111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627112: Call_GetDeploymentStatus_21627100; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_21627112.validator(path, query, header, formData, body, _)
  let scheme = call_21627112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627112.makeUrl(scheme.get, call_21627112.host, call_21627112.base,
                               call_21627112.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627112, uri, valid, _)

proc call*(call_21627113: Call_GetDeploymentStatus_21627100; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_21627114 = newJObject()
  add(path_21627114, "GroupId", newJString(GroupId))
  add(path_21627114, "DeploymentId", newJString(DeploymentId))
  result = call_21627113.call(path_21627114, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_21627100(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_21627101, base: "/",
    makeUrl: url_GetDeploymentStatus_21627102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_21627115 = ref object of OpenApiRestCall_21625418
proc url_GetDeviceDefinitionVersion_21627117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  assert "DeviceDefinitionVersionId" in path,
        "`DeviceDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "DeviceDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceDefinitionVersion_21627116(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a device definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
  ##                     : The ID of the device definition.
  ##   DeviceDefinitionVersionId: JString (required)
  ##                            : The ID of the device definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListDeviceDefinitionVersions'' requests. If the version is the last one that was associated with a device definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_21627118 = path.getOrDefault("DeviceDefinitionId")
  valid_21627118 = validateParameter(valid_21627118, JString, required = true,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "DeviceDefinitionId", valid_21627118
  var valid_21627119 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_21627119 = validateParameter(valid_21627119, JString, required = true,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "DeviceDefinitionVersionId", valid_21627119
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_21627120 = query.getOrDefault("NextToken")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "NextToken", valid_21627120
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
  var valid_21627121 = header.getOrDefault("X-Amz-Date")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Date", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Security-Token", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Algorithm", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Signature")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Signature", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Credential")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Credential", valid_21627127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627128: Call_GetDeviceDefinitionVersion_21627115;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_21627128.validator(path, query, header, formData, body, _)
  let scheme = call_21627128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627128.makeUrl(scheme.get, call_21627128.host, call_21627128.base,
                               call_21627128.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627128, uri, valid, _)

proc call*(call_21627129: Call_GetDeviceDefinitionVersion_21627115;
          DeviceDefinitionId: string; DeviceDefinitionVersionId: string;
          NextToken: string = ""): Recallable =
  ## getDeviceDefinitionVersion
  ## Retrieves information about a device definition version.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   DeviceDefinitionVersionId: string (required)
  ##                            : The ID of the device definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListDeviceDefinitionVersions'' requests. If the version is the last one that was associated with a device definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_21627130 = newJObject()
  var query_21627131 = newJObject()
  add(path_21627130, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_21627131, "NextToken", newJString(NextToken))
  add(path_21627130, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_21627129.call(path_21627130, query_21627131, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_21627115(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_21627116, base: "/",
    makeUrl: url_GetDeviceDefinitionVersion_21627117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_21627132 = ref object of OpenApiRestCall_21625418
proc url_GetFunctionDefinitionVersion_21627134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  assert "FunctionDefinitionVersionId" in path,
        "`FunctionDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "FunctionDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinitionVersion_21627133(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionVersionId: JString (required)
  ##                              : The ID of the function definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListFunctionDefinitionVersions'' requests. If the version is the last one that was associated with a function definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionVersionId` field"
  var valid_21627135 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_21627135 = validateParameter(valid_21627135, JString, required = true,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "FunctionDefinitionVersionId", valid_21627135
  var valid_21627136 = path.getOrDefault("FunctionDefinitionId")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "FunctionDefinitionId", valid_21627136
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_21627137 = query.getOrDefault("NextToken")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "NextToken", valid_21627137
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
  var valid_21627138 = header.getOrDefault("X-Amz-Date")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Date", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Security-Token", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Algorithm", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Signature")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Signature", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Credential")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Credential", valid_21627144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627145: Call_GetFunctionDefinitionVersion_21627132;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_21627145.validator(path, query, header, formData, body, _)
  let scheme = call_21627145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627145.makeUrl(scheme.get, call_21627145.host, call_21627145.base,
                               call_21627145.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627145, uri, valid, _)

proc call*(call_21627146: Call_GetFunctionDefinitionVersion_21627132;
          FunctionDefinitionVersionId: string; FunctionDefinitionId: string;
          NextToken: string = ""): Recallable =
  ## getFunctionDefinitionVersion
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ##   FunctionDefinitionVersionId: string (required)
  ##                              : The ID of the function definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListFunctionDefinitionVersions'' requests. If the version is the last one that was associated with a function definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_21627147 = newJObject()
  var query_21627148 = newJObject()
  add(path_21627147, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_21627148, "NextToken", newJString(NextToken))
  add(path_21627147, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_21627146.call(path_21627147, query_21627148, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_21627132(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_21627133, base: "/",
    makeUrl: url_GetFunctionDefinitionVersion_21627134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_21627149 = ref object of OpenApiRestCall_21625418
proc url_GetGroupCertificateAuthority_21627151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  assert "CertificateAuthorityId" in path,
        "`CertificateAuthorityId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/certificateauthorities/"),
               (kind: VariableSegment, value: "CertificateAuthorityId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupCertificateAuthority_21627150(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: JString (required)
  ##                         : The ID of the certificate authority.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21627152 = path.getOrDefault("GroupId")
  valid_21627152 = validateParameter(valid_21627152, JString, required = true,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "GroupId", valid_21627152
  var valid_21627153 = path.getOrDefault("CertificateAuthorityId")
  valid_21627153 = validateParameter(valid_21627153, JString, required = true,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "CertificateAuthorityId", valid_21627153
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
  var valid_21627154 = header.getOrDefault("X-Amz-Date")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Date", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Security-Token", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Algorithm", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Signature")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Signature", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Credential")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Credential", valid_21627160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627161: Call_GetGroupCertificateAuthority_21627149;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_21627161.validator(path, query, header, formData, body, _)
  let scheme = call_21627161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627161.makeUrl(scheme.get, call_21627161.host, call_21627161.base,
                               call_21627161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627161, uri, valid, _)

proc call*(call_21627162: Call_GetGroupCertificateAuthority_21627149;
          GroupId: string; CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_21627163 = newJObject()
  add(path_21627163, "GroupId", newJString(GroupId))
  add(path_21627163, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_21627162.call(path_21627163, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_21627149(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_21627150, base: "/",
    makeUrl: url_GetGroupCertificateAuthority_21627151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_21627178 = ref object of OpenApiRestCall_21625418
proc url_UpdateGroupCertificateConfiguration_21627180(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"), (kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroupCertificateConfiguration_21627179(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the Certificate expiry time for a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21627181 = path.getOrDefault("GroupId")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "GroupId", valid_21627181
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
  var valid_21627182 = header.getOrDefault("X-Amz-Date")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-Date", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Security-Token", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Algorithm", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Signature")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Signature", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Credential")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Credential", valid_21627188
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

proc call*(call_21627190: Call_UpdateGroupCertificateConfiguration_21627178;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_21627190.validator(path, query, header, formData, body, _)
  let scheme = call_21627190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627190.makeUrl(scheme.get, call_21627190.host, call_21627190.base,
                               call_21627190.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627190, uri, valid, _)

proc call*(call_21627191: Call_UpdateGroupCertificateConfiguration_21627178;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21627192 = newJObject()
  var body_21627193 = newJObject()
  add(path_21627192, "GroupId", newJString(GroupId))
  if body != nil:
    body_21627193 = body
  result = call_21627191.call(path_21627192, nil, nil, nil, body_21627193)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_21627178(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_21627179, base: "/",
    makeUrl: url_UpdateGroupCertificateConfiguration_21627180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_21627164 = ref object of OpenApiRestCall_21625418
proc url_GetGroupCertificateConfiguration_21627166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"), (kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupCertificateConfiguration_21627165(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21627167 = path.getOrDefault("GroupId")
  valid_21627167 = validateParameter(valid_21627167, JString, required = true,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "GroupId", valid_21627167
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
  var valid_21627168 = header.getOrDefault("X-Amz-Date")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Date", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Security-Token", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-Algorithm", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Signature")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Signature", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Credential")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Credential", valid_21627174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627175: Call_GetGroupCertificateConfiguration_21627164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_21627175.validator(path, query, header, formData, body, _)
  let scheme = call_21627175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627175.makeUrl(scheme.get, call_21627175.host, call_21627175.base,
                               call_21627175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627175, uri, valid, _)

proc call*(call_21627176: Call_GetGroupCertificateConfiguration_21627164;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21627177 = newJObject()
  add(path_21627177, "GroupId", newJString(GroupId))
  result = call_21627176.call(path_21627177, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_21627164(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_21627165, base: "/",
    makeUrl: url_GetGroupCertificateConfiguration_21627166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_21627194 = ref object of OpenApiRestCall_21625418
proc url_GetGroupVersion_21627196(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  assert "GroupVersionId" in path, "`GroupVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "GroupVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupVersion_21627195(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a group version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupVersionId: JString (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `GroupVersionId` field"
  var valid_21627197 = path.getOrDefault("GroupVersionId")
  valid_21627197 = validateParameter(valid_21627197, JString, required = true,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "GroupVersionId", valid_21627197
  var valid_21627198 = path.getOrDefault("GroupId")
  valid_21627198 = validateParameter(valid_21627198, JString, required = true,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "GroupId", valid_21627198
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
  var valid_21627199 = header.getOrDefault("X-Amz-Date")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "X-Amz-Date", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Security-Token", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627201 = validateParameter(valid_21627201, JString, required = false,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Algorithm", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Signature")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Signature", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Credential")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-Credential", valid_21627205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627206: Call_GetGroupVersion_21627194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_21627206.validator(path, query, header, formData, body, _)
  let scheme = call_21627206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627206.makeUrl(scheme.get, call_21627206.host, call_21627206.base,
                               call_21627206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627206, uri, valid, _)

proc call*(call_21627207: Call_GetGroupVersion_21627194; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_21627208 = newJObject()
  add(path_21627208, "GroupVersionId", newJString(GroupVersionId))
  add(path_21627208, "GroupId", newJString(GroupId))
  result = call_21627207.call(path_21627208, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_21627194(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_21627195, base: "/",
    makeUrl: url_GetGroupVersion_21627196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_21627209 = ref object of OpenApiRestCall_21625418
proc url_GetLoggerDefinitionVersion_21627211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  assert "LoggerDefinitionVersionId" in path,
        "`LoggerDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "LoggerDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLoggerDefinitionVersion_21627210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a logger definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionVersionId: JString (required)
  ##                            : The ID of the logger definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListLoggerDefinitionVersions'' requests. If the version is the last one that was associated with a logger definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   LoggerDefinitionId: JString (required)
  ##                     : The ID of the logger definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionVersionId` field"
  var valid_21627212 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_21627212 = validateParameter(valid_21627212, JString, required = true,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "LoggerDefinitionVersionId", valid_21627212
  var valid_21627213 = path.getOrDefault("LoggerDefinitionId")
  valid_21627213 = validateParameter(valid_21627213, JString, required = true,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "LoggerDefinitionId", valid_21627213
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_21627214 = query.getOrDefault("NextToken")
  valid_21627214 = validateParameter(valid_21627214, JString, required = false,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "NextToken", valid_21627214
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
  var valid_21627215 = header.getOrDefault("X-Amz-Date")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "X-Amz-Date", valid_21627215
  var valid_21627216 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Security-Token", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Algorithm", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Signature")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Signature", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Credential")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Credential", valid_21627221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627222: Call_GetLoggerDefinitionVersion_21627209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_21627222.validator(path, query, header, formData, body, _)
  let scheme = call_21627222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627222.makeUrl(scheme.get, call_21627222.host, call_21627222.base,
                               call_21627222.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627222, uri, valid, _)

proc call*(call_21627223: Call_GetLoggerDefinitionVersion_21627209;
          LoggerDefinitionVersionId: string; LoggerDefinitionId: string;
          NextToken: string = ""): Recallable =
  ## getLoggerDefinitionVersion
  ## Retrieves information about a logger definition version.
  ##   LoggerDefinitionVersionId: string (required)
  ##                            : The ID of the logger definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListLoggerDefinitionVersions'' requests. If the version is the last one that was associated with a logger definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_21627224 = newJObject()
  var query_21627225 = newJObject()
  add(path_21627224, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_21627225, "NextToken", newJString(NextToken))
  add(path_21627224, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_21627223.call(path_21627224, query_21627225, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_21627209(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_21627210, base: "/",
    makeUrl: url_GetLoggerDefinitionVersion_21627211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_21627226 = ref object of OpenApiRestCall_21625418
proc url_GetResourceDefinitionVersion_21627228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  assert "ResourceDefinitionVersionId" in path,
        "`ResourceDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "ResourceDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinitionVersion_21627227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionVersionId: JString (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionVersionId` field"
  var valid_21627229 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_21627229 = validateParameter(valid_21627229, JString, required = true,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "ResourceDefinitionVersionId", valid_21627229
  var valid_21627230 = path.getOrDefault("ResourceDefinitionId")
  valid_21627230 = validateParameter(valid_21627230, JString, required = true,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "ResourceDefinitionId", valid_21627230
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
  var valid_21627231 = header.getOrDefault("X-Amz-Date")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Date", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Security-Token", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Algorithm", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Signature")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Signature", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Credential")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Credential", valid_21627237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627238: Call_GetResourceDefinitionVersion_21627226;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_21627238.validator(path, query, header, formData, body, _)
  let scheme = call_21627238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627238.makeUrl(scheme.get, call_21627238.host, call_21627238.base,
                               call_21627238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627238, uri, valid, _)

proc call*(call_21627239: Call_GetResourceDefinitionVersion_21627226;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_21627240 = newJObject()
  add(path_21627240, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_21627240, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_21627239.call(path_21627240, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_21627226(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_21627227, base: "/",
    makeUrl: url_GetResourceDefinitionVersion_21627228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_21627241 = ref object of OpenApiRestCall_21625418
proc url_GetSubscriptionDefinitionVersion_21627243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscriptionDefinitionId" in path,
        "`SubscriptionDefinitionId` is a required path parameter"
  assert "SubscriptionDefinitionVersionId" in path,
        "`SubscriptionDefinitionVersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/greengrass/definition/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionDefinitionId"),
               (kind: ConstantSegment, value: "/versions/"), (kind: VariableSegment,
        value: "SubscriptionDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSubscriptionDefinitionVersion_21627242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a subscription definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  ##   SubscriptionDefinitionVersionId: JString (required)
  ##                                  : The ID of the subscription definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListSubscriptionDefinitionVersions'' requests. If the version is the last one that was associated with a subscription definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_21627244 = path.getOrDefault("SubscriptionDefinitionId")
  valid_21627244 = validateParameter(valid_21627244, JString, required = true,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "SubscriptionDefinitionId", valid_21627244
  var valid_21627245 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_21627245 = validateParameter(valid_21627245, JString, required = true,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_21627245
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_21627246 = query.getOrDefault("NextToken")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "NextToken", valid_21627246
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
  var valid_21627247 = header.getOrDefault("X-Amz-Date")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "X-Amz-Date", valid_21627247
  var valid_21627248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "X-Amz-Security-Token", valid_21627248
  var valid_21627249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627249
  var valid_21627250 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627250 = validateParameter(valid_21627250, JString, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "X-Amz-Algorithm", valid_21627250
  var valid_21627251 = header.getOrDefault("X-Amz-Signature")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-Signature", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627252
  var valid_21627253 = header.getOrDefault("X-Amz-Credential")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Credential", valid_21627253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627254: Call_GetSubscriptionDefinitionVersion_21627241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_21627254.validator(path, query, header, formData, body, _)
  let scheme = call_21627254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627254.makeUrl(scheme.get, call_21627254.host, call_21627254.base,
                               call_21627254.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627254, uri, valid, _)

proc call*(call_21627255: Call_GetSubscriptionDefinitionVersion_21627241;
          SubscriptionDefinitionId: string;
          SubscriptionDefinitionVersionId: string; NextToken: string = ""): Recallable =
  ## getSubscriptionDefinitionVersion
  ## Retrieves information about a subscription definition version.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   SubscriptionDefinitionVersionId: string (required)
  ##                                  : The ID of the subscription definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListSubscriptionDefinitionVersions'' requests. If the version is the last one that was associated with a subscription definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_21627256 = newJObject()
  var query_21627257 = newJObject()
  add(query_21627257, "NextToken", newJString(NextToken))
  add(path_21627256, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(path_21627256, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  result = call_21627255.call(path_21627256, query_21627257, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_21627241(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_21627242, base: "/",
    makeUrl: url_GetSubscriptionDefinitionVersion_21627243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_21627258 = ref object of OpenApiRestCall_21625418
proc url_ListBulkDeploymentDetailedReports_21627260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "BulkDeploymentId" in path,
        "`BulkDeploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/bulk/deployments/"),
               (kind: VariableSegment, value: "BulkDeploymentId"),
               (kind: ConstantSegment, value: "/detailed-reports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBulkDeploymentDetailedReports_21627259(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   BulkDeploymentId: JString (required)
  ##                   : The ID of the bulk deployment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `BulkDeploymentId` field"
  var valid_21627261 = path.getOrDefault("BulkDeploymentId")
  valid_21627261 = validateParameter(valid_21627261, JString, required = true,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "BulkDeploymentId", valid_21627261
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21627262 = query.getOrDefault("NextToken")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "NextToken", valid_21627262
  var valid_21627263 = query.getOrDefault("MaxResults")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "MaxResults", valid_21627263
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
  var valid_21627264 = header.getOrDefault("X-Amz-Date")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Date", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Security-Token", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Algorithm", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-Signature")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Signature", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627269
  var valid_21627270 = header.getOrDefault("X-Amz-Credential")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "X-Amz-Credential", valid_21627270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627271: Call_ListBulkDeploymentDetailedReports_21627258;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_21627271.validator(path, query, header, formData, body, _)
  let scheme = call_21627271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627271.makeUrl(scheme.get, call_21627271.host, call_21627271.base,
                               call_21627271.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627271, uri, valid, _)

proc call*(call_21627272: Call_ListBulkDeploymentDetailedReports_21627258;
          BulkDeploymentId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_21627273 = newJObject()
  var query_21627274 = newJObject()
  add(query_21627274, "NextToken", newJString(NextToken))
  add(query_21627274, "MaxResults", newJString(MaxResults))
  add(path_21627273, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_21627272.call(path_21627273, query_21627274, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_21627258(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_21627259, base: "/",
    makeUrl: url_ListBulkDeploymentDetailedReports_21627260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_21627290 = ref object of OpenApiRestCall_21625418
proc url_StartBulkDeployment_21627292(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBulkDeployment_21627291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627293 = header.getOrDefault("X-Amz-Date")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Date", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Security-Token", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Algorithm", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amzn-Client-Token", valid_21627297
  var valid_21627298 = header.getOrDefault("X-Amz-Signature")
  valid_21627298 = validateParameter(valid_21627298, JString, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "X-Amz-Signature", valid_21627298
  var valid_21627299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627299
  var valid_21627300 = header.getOrDefault("X-Amz-Credential")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "X-Amz-Credential", valid_21627300
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

proc call*(call_21627302: Call_StartBulkDeployment_21627290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_21627302.validator(path, query, header, formData, body, _)
  let scheme = call_21627302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627302.makeUrl(scheme.get, call_21627302.host, call_21627302.base,
                               call_21627302.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627302, uri, valid, _)

proc call*(call_21627303: Call_StartBulkDeployment_21627290; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_21627304 = newJObject()
  if body != nil:
    body_21627304 = body
  result = call_21627303.call(nil, nil, nil, nil, body_21627304)

var startBulkDeployment* = Call_StartBulkDeployment_21627290(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_21627291, base: "/",
    makeUrl: url_StartBulkDeployment_21627292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_21627275 = ref object of OpenApiRestCall_21625418
proc url_ListBulkDeployments_21627277(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBulkDeployments_21627276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of bulk deployments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_21627278 = query.getOrDefault("NextToken")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "NextToken", valid_21627278
  var valid_21627279 = query.getOrDefault("MaxResults")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "MaxResults", valid_21627279
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
  var valid_21627280 = header.getOrDefault("X-Amz-Date")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Date", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Security-Token", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-Algorithm", valid_21627283
  var valid_21627284 = header.getOrDefault("X-Amz-Signature")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-Signature", valid_21627284
  var valid_21627285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627285 = validateParameter(valid_21627285, JString, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627285
  var valid_21627286 = header.getOrDefault("X-Amz-Credential")
  valid_21627286 = validateParameter(valid_21627286, JString, required = false,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "X-Amz-Credential", valid_21627286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627287: Call_ListBulkDeployments_21627275; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_21627287.validator(path, query, header, formData, body, _)
  let scheme = call_21627287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627287.makeUrl(scheme.get, call_21627287.host, call_21627287.base,
                               call_21627287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627287, uri, valid, _)

proc call*(call_21627288: Call_ListBulkDeployments_21627275;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_21627289 = newJObject()
  add(query_21627289, "NextToken", newJString(NextToken))
  add(query_21627289, "MaxResults", newJString(MaxResults))
  result = call_21627288.call(nil, query_21627289, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_21627275(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_21627276, base: "/",
    makeUrl: url_ListBulkDeployments_21627277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627319 = ref object of OpenApiRestCall_21625418
proc url_TagResource_21627321(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21627320(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627322 = path.getOrDefault("resource-arn")
  valid_21627322 = validateParameter(valid_21627322, JString, required = true,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "resource-arn", valid_21627322
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
  var valid_21627323 = header.getOrDefault("X-Amz-Date")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Date", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Security-Token", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-Algorithm", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Signature")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Signature", valid_21627327
  var valid_21627328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-Credential")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-Credential", valid_21627329
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

proc call*(call_21627331: Call_TagResource_21627319; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_21627331.validator(path, query, header, formData, body, _)
  let scheme = call_21627331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627331.makeUrl(scheme.get, call_21627331.host, call_21627331.base,
                               call_21627331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627331, uri, valid, _)

proc call*(call_21627332: Call_TagResource_21627319; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_21627333 = newJObject()
  var body_21627334 = newJObject()
  add(path_21627333, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21627334 = body
  result = call_21627332.call(path_21627333, nil, nil, nil, body_21627334)

var tagResource* = Call_TagResource_21627319(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_21627320,
    base: "/", makeUrl: url_TagResource_21627321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21627305 = ref object of OpenApiRestCall_21625418
proc url_ListTagsForResource_21627307(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21627306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627308 = path.getOrDefault("resource-arn")
  valid_21627308 = validateParameter(valid_21627308, JString, required = true,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "resource-arn", valid_21627308
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
  var valid_21627309 = header.getOrDefault("X-Amz-Date")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Date", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Security-Token", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Algorithm", valid_21627312
  var valid_21627313 = header.getOrDefault("X-Amz-Signature")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-Signature", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627314
  var valid_21627315 = header.getOrDefault("X-Amz-Credential")
  valid_21627315 = validateParameter(valid_21627315, JString, required = false,
                                   default = nil)
  if valid_21627315 != nil:
    section.add "X-Amz-Credential", valid_21627315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627316: Call_ListTagsForResource_21627305; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_21627316.validator(path, query, header, formData, body, _)
  let scheme = call_21627316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627316.makeUrl(scheme.get, call_21627316.host, call_21627316.base,
                               call_21627316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627316, uri, valid, _)

proc call*(call_21627317: Call_ListTagsForResource_21627305; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21627318 = newJObject()
  add(path_21627318, "resource-arn", newJString(resourceArn))
  result = call_21627317.call(path_21627318, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21627305(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21627306, base: "/",
    makeUrl: url_ListTagsForResource_21627307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_21627335 = ref object of OpenApiRestCall_21625418
proc url_ResetDeployments_21627337(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments/$reset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ResetDeployments_21627336(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Resets a group's deployments.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_21627338 = path.getOrDefault("GroupId")
  valid_21627338 = validateParameter(valid_21627338, JString, required = true,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "GroupId", valid_21627338
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627339 = header.getOrDefault("X-Amz-Date")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-Date", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-Security-Token", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627341
  var valid_21627342 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "X-Amz-Algorithm", valid_21627342
  var valid_21627343 = header.getOrDefault("X-Amzn-Client-Token")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "X-Amzn-Client-Token", valid_21627343
  var valid_21627344 = header.getOrDefault("X-Amz-Signature")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "X-Amz-Signature", valid_21627344
  var valid_21627345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627345 = validateParameter(valid_21627345, JString, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627345
  var valid_21627346 = header.getOrDefault("X-Amz-Credential")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "X-Amz-Credential", valid_21627346
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

proc call*(call_21627348: Call_ResetDeployments_21627335; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_21627348.validator(path, query, header, formData, body, _)
  let scheme = call_21627348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627348.makeUrl(scheme.get, call_21627348.host, call_21627348.base,
                               call_21627348.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627348, uri, valid, _)

proc call*(call_21627349: Call_ResetDeployments_21627335; GroupId: string;
          body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_21627350 = newJObject()
  var body_21627351 = newJObject()
  add(path_21627350, "GroupId", newJString(GroupId))
  if body != nil:
    body_21627351 = body
  result = call_21627349.call(path_21627350, nil, nil, nil, body_21627351)

var resetDeployments* = Call_ResetDeployments_21627335(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_21627336, base: "/",
    makeUrl: url_ResetDeployments_21627337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_21627352 = ref object of OpenApiRestCall_21625418
proc url_StopBulkDeployment_21627354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "BulkDeploymentId" in path,
        "`BulkDeploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/bulk/deployments/"),
               (kind: VariableSegment, value: "BulkDeploymentId"),
               (kind: ConstantSegment, value: "/$stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopBulkDeployment_21627353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   BulkDeploymentId: JString (required)
  ##                   : The ID of the bulk deployment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `BulkDeploymentId` field"
  var valid_21627355 = path.getOrDefault("BulkDeploymentId")
  valid_21627355 = validateParameter(valid_21627355, JString, required = true,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "BulkDeploymentId", valid_21627355
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
  var valid_21627356 = header.getOrDefault("X-Amz-Date")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-Date", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Security-Token", valid_21627357
  var valid_21627358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-Algorithm", valid_21627359
  var valid_21627360 = header.getOrDefault("X-Amz-Signature")
  valid_21627360 = validateParameter(valid_21627360, JString, required = false,
                                   default = nil)
  if valid_21627360 != nil:
    section.add "X-Amz-Signature", valid_21627360
  var valid_21627361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627361 = validateParameter(valid_21627361, JString, required = false,
                                   default = nil)
  if valid_21627361 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627361
  var valid_21627362 = header.getOrDefault("X-Amz-Credential")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "X-Amz-Credential", valid_21627362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627363: Call_StopBulkDeployment_21627352; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_21627363.validator(path, query, header, formData, body, _)
  let scheme = call_21627363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627363.makeUrl(scheme.get, call_21627363.host, call_21627363.base,
                               call_21627363.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627363, uri, valid, _)

proc call*(call_21627364: Call_StopBulkDeployment_21627352;
          BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_21627365 = newJObject()
  add(path_21627365, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_21627364.call(path_21627365, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_21627352(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_21627353, base: "/",
    makeUrl: url_StopBulkDeployment_21627354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627366 = ref object of OpenApiRestCall_21625418
proc url_UntagResource_21627368(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21627367(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627369 = path.getOrDefault("resource-arn")
  valid_21627369 = validateParameter(valid_21627369, JString, required = true,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "resource-arn", valid_21627369
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21627370 = query.getOrDefault("tagKeys")
  valid_21627370 = validateParameter(valid_21627370, JArray, required = true,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "tagKeys", valid_21627370
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
  var valid_21627371 = header.getOrDefault("X-Amz-Date")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Date", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Security-Token", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-Algorithm", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Signature")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Signature", valid_21627375
  var valid_21627376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627376 = validateParameter(valid_21627376, JString, required = false,
                                   default = nil)
  if valid_21627376 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627376
  var valid_21627377 = header.getOrDefault("X-Amz-Credential")
  valid_21627377 = validateParameter(valid_21627377, JString, required = false,
                                   default = nil)
  if valid_21627377 != nil:
    section.add "X-Amz-Credential", valid_21627377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627378: Call_UntagResource_21627366; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_21627378.validator(path, query, header, formData, body, _)
  let scheme = call_21627378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627378.makeUrl(scheme.get, call_21627378.host, call_21627378.base,
                               call_21627378.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627378, uri, valid, _)

proc call*(call_21627379: Call_UntagResource_21627366; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21627380 = newJObject()
  var query_21627381 = newJObject()
  if tagKeys != nil:
    query_21627381.add "tagKeys", tagKeys
  add(path_21627380, "resource-arn", newJString(resourceArn))
  result = call_21627379.call(path_21627380, query_21627381, nil, nil, nil)

var untagResource* = Call_UntagResource_21627366(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21627367,
    base: "/", makeUrl: url_UntagResource_21627368,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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