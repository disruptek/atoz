
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656035 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656035](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656035): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "greengrass.ap-northeast-1.amazonaws.com", "ap-southeast-1": "greengrass.ap-southeast-1.amazonaws.com", "us-west-2": "greengrass.us-west-2.amazonaws.com", "eu-west-2": "greengrass.eu-west-2.amazonaws.com", "ap-northeast-3": "greengrass.ap-northeast-3.amazonaws.com", "eu-central-1": "greengrass.eu-central-1.amazonaws.com", "us-east-2": "greengrass.us-east-2.amazonaws.com", "us-east-1": "greengrass.us-east-1.amazonaws.com", "cn-northwest-1": "greengrass.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "greengrass.ap-south-1.amazonaws.com", "eu-north-1": "greengrass.eu-north-1.amazonaws.com", "ap-northeast-2": "greengrass.ap-northeast-2.amazonaws.com", "us-west-1": "greengrass.us-west-1.amazonaws.com", "us-gov-east-1": "greengrass.us-gov-east-1.amazonaws.com", "eu-west-3": "greengrass.eu-west-3.amazonaws.com", "cn-north-1": "greengrass.cn-north-1.amazonaws.com.cn", "sa-east-1": "greengrass.sa-east-1.amazonaws.com", "eu-west-1": "greengrass.eu-west-1.amazonaws.com", "us-gov-west-1": "greengrass.us-gov-west-1.amazonaws.com", "ap-southeast-2": "greengrass.ap-southeast-2.amazonaws.com", "ca-central-1": "greengrass.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateRoleToGroup_402656478 = ref object of OpenApiRestCall_402656035
proc url_AssociateRoleToGroup_402656480(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_AssociateRoleToGroup_402656479(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656481 = path.getOrDefault("GroupId")
  valid_402656481 = validateParameter(valid_402656481, JString, required = true,
                                      default = nil)
  if valid_402656481 != nil:
    section.add "GroupId", valid_402656481
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
  var valid_402656482 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Security-Token", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Signature")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Signature", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Algorithm", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Date")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Date", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Credential")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Credential", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656488
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

proc call*(call_402656490: Call_AssociateRoleToGroup_402656478;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
                                                                                         ## 
  let valid = call_402656490.validator(path, query, header, formData, body, _)
  let scheme = call_402656490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656490.makeUrl(scheme.get, call_402656490.host, call_402656490.base,
                                   call_402656490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656490, uri, valid, _)

proc call*(call_402656491: Call_AssociateRoleToGroup_402656478; body: JsonNode;
           GroupId: string): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   
                                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                               ## GroupId: string (required)
                                                                                                                                                                                                                                               ##          
                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                               ## ID 
                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                               ## Greengrass 
                                                                                                                                                                                                                                               ## group.
  var path_402656492 = newJObject()
  var body_402656493 = newJObject()
  if body != nil:
    body_402656493 = body
  add(path_402656492, "GroupId", newJString(GroupId))
  result = call_402656491.call(path_402656492, nil, nil, nil, body_402656493)

var associateRoleToGroup* = Call_AssociateRoleToGroup_402656478(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_402656479, base: "/",
    makeUrl: url_AssociateRoleToGroup_402656480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_402656285 = ref object of OpenApiRestCall_402656035
proc url_GetAssociatedRole_402656287(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetAssociatedRole_402656286(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the role associated with a particular group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656377 = path.getOrDefault("GroupId")
  valid_402656377 = validateParameter(valid_402656377, JString, required = true,
                                      default = nil)
  if valid_402656377 != nil:
    section.add "GroupId", valid_402656377
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
  var valid_402656378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Security-Token", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Signature")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Signature", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Algorithm", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Date")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Date", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Credential")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Credential", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656398: Call_GetAssociatedRole_402656285;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the role associated with a particular group.
                                                                                         ## 
  let valid = call_402656398.validator(path, query, header, formData, body, _)
  let scheme = call_402656398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656398.makeUrl(scheme.get, call_402656398.host, call_402656398.base,
                                   call_402656398.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656398, uri, valid, _)

proc call*(call_402656447: Call_GetAssociatedRole_402656285; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
                                                           ##          : The ID of the Greengrass group.
  var path_402656448 = newJObject()
  add(path_402656448, "GroupId", newJString(GroupId))
  result = call_402656447.call(path_402656448, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_402656285(
    name: "getAssociatedRole", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_402656286, base: "/",
    makeUrl: url_GetAssociatedRole_402656287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_402656494 = ref object of OpenApiRestCall_402656035
proc url_DisassociateRoleFromGroup_402656496(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_402656495(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the role from a group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656497 = path.getOrDefault("GroupId")
  valid_402656497 = validateParameter(valid_402656497, JString, required = true,
                                      default = nil)
  if valid_402656497 != nil:
    section.add "GroupId", valid_402656497
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
  var valid_402656498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Security-Token", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Signature")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Signature", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Algorithm", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Date")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Date", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Credential")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Credential", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656505: Call_DisassociateRoleFromGroup_402656494;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the role from a group.
                                                                                         ## 
  let valid = call_402656505.validator(path, query, header, formData, body, _)
  let scheme = call_402656505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656505.makeUrl(scheme.get, call_402656505.host, call_402656505.base,
                                   call_402656505.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656505, uri, valid, _)

proc call*(call_402656506: Call_DisassociateRoleFromGroup_402656494;
           GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
                                         ##          : The ID of the Greengrass group.
  var path_402656507 = newJObject()
  add(path_402656507, "GroupId", newJString(GroupId))
  result = call_402656506.call(path_402656507, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_402656494(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_402656495, base: "/",
    makeUrl: url_DisassociateRoleFromGroup_402656496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_402656520 = ref object of OpenApiRestCall_402656035
proc url_AssociateServiceRoleToAccount_402656522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceRoleToAccount_402656521(path: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_AssociateServiceRoleToAccount_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_AssociateServiceRoleToAccount_402656520;
           body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   
                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_402656520(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_402656521, base: "/",
    makeUrl: url_AssociateServiceRoleToAccount_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_402656508 = ref object of OpenApiRestCall_402656035
proc url_GetServiceRoleForAccount_402656510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceRoleForAccount_402656509(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the service role that is attached to your account.
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
  var valid_402656511 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Security-Token", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Signature")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Signature", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Algorithm", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Date")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Date", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Credential")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Credential", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656518: Call_GetServiceRoleForAccount_402656508;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the service role that is attached to your account.
                                                                                         ## 
  let valid = call_402656518.validator(path, query, header, formData, body, _)
  let scheme = call_402656518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656518.makeUrl(scheme.get, call_402656518.host, call_402656518.base,
                                   call_402656518.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656518, uri, valid, _)

proc call*(call_402656519: Call_GetServiceRoleForAccount_402656508): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_402656519.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_402656508(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_402656509, base: "/",
    makeUrl: url_GetServiceRoleForAccount_402656510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_402656534 = ref object of OpenApiRestCall_402656035
proc url_DisassociateServiceRoleFromAccount_402656536(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_402656535(path: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Security-Token", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Signature")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Signature", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Algorithm", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Date")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Date", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Credential")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Credential", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656544: Call_DisassociateServiceRoleFromAccount_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_DisassociateServiceRoleFromAccount_402656534): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_402656545.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_402656534(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_402656535, base: "/",
    makeUrl: url_DisassociateServiceRoleFromAccount_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_402656561 = ref object of OpenApiRestCall_402656035
proc url_CreateConnectorDefinition_402656563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnectorDefinition_402656562(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amzn-Client-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
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

proc call*(call_402656573: Call_CreateConnectorDefinition_402656561;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
                                                                                         ## 
  let valid = call_402656573.validator(path, query, header, formData, body, _)
  let scheme = call_402656573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656573.makeUrl(scheme.get, call_402656573.host, call_402656573.base,
                                   call_402656573.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656573, uri, valid, _)

proc call*(call_402656574: Call_CreateConnectorDefinition_402656561;
           body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var body_402656575 = newJObject()
  if body != nil:
    body_402656575 = body
  result = call_402656574.call(nil, nil, nil, nil, body_402656575)

var createConnectorDefinition* = Call_CreateConnectorDefinition_402656561(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_402656562, base: "/",
    makeUrl: url_CreateConnectorDefinition_402656563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_402656546 = ref object of OpenApiRestCall_402656035
proc url_ListConnectorDefinitions_402656548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnectorDefinitions_402656547(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a list of connector definitions.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656549 = query.getOrDefault("MaxResults")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "MaxResults", valid_402656549
  var valid_402656550 = query.getOrDefault("NextToken")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "NextToken", valid_402656550
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
  var valid_402656551 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Security-Token", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Signature")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Signature", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Algorithm", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Date")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Date", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Credential")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Credential", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656558: Call_ListConnectorDefinitions_402656546;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of connector definitions.
                                                                                         ## 
  let valid = call_402656558.validator(path, query, header, formData, body, _)
  let scheme = call_402656558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656558.makeUrl(scheme.get, call_402656558.host, call_402656558.base,
                                   call_402656558.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656558, uri, valid, _)

proc call*(call_402656559: Call_ListConnectorDefinitions_402656546;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
                                               ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                         ## NextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## token 
                                                                                                                         ## for 
                                                                                                                         ## the 
                                                                                                                         ## next 
                                                                                                                         ## set 
                                                                                                                         ## of 
                                                                                                                         ## results, 
                                                                                                                         ## or 
                                                                                                                         ## ''null'' 
                                                                                                                         ## if 
                                                                                                                         ## there 
                                                                                                                         ## are 
                                                                                                                         ## no 
                                                                                                                         ## additional 
                                                                                                                         ## results.
  var query_402656560 = newJObject()
  add(query_402656560, "MaxResults", newJString(MaxResults))
  add(query_402656560, "NextToken", newJString(NextToken))
  result = call_402656559.call(nil, query_402656560, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_402656546(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_402656547, base: "/",
    makeUrl: url_ListConnectorDefinitions_402656548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_402656593 = ref object of OpenApiRestCall_402656035
proc url_CreateConnectorDefinitionVersion_402656595(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
         "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
                 (kind: VariableSegment, value: "ConnectorDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConnectorDefinitionVersion_402656594(path: JsonNode;
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
  var valid_402656596 = path.getOrDefault("ConnectorDefinitionId")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = nil)
  if valid_402656596 != nil:
    section.add "ConnectorDefinitionId", valid_402656596
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Security-Token", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amzn-Client-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_CreateConnectorDefinitionVersion_402656593;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a connector definition which has already been defined.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateConnectorDefinitionVersion_402656593;
           ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   
                                                                                ## ConnectorDefinitionId: string (required)
                                                                                ##                        
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## connector 
                                                                                ## definition.
  ##   
                                                                                              ## body: JObject (required)
  var path_402656608 = newJObject()
  var body_402656609 = newJObject()
  add(path_402656608, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_402656609 = body
  result = call_402656607.call(path_402656608, nil, nil, nil, body_402656609)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_402656593(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_402656594, base: "/",
    makeUrl: url_CreateConnectorDefinitionVersion_402656595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_402656576 = ref object of OpenApiRestCall_402656035
proc url_ListConnectorDefinitionVersions_402656578(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
         "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
                 (kind: VariableSegment, value: "ConnectorDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConnectorDefinitionVersions_402656577(path: JsonNode;
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
  var valid_402656579 = path.getOrDefault("ConnectorDefinitionId")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "ConnectorDefinitionId", valid_402656579
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656580 = query.getOrDefault("MaxResults")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "MaxResults", valid_402656580
  var valid_402656581 = query.getOrDefault("NextToken")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "NextToken", valid_402656581
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
  var valid_402656582 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Security-Token", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Signature")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Signature", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Algorithm", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Date")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Date", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Credential")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Credential", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656589: Call_ListConnectorDefinitionVersions_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
                                                                                         ## 
  let valid = call_402656589.validator(path, query, header, formData, body, _)
  let scheme = call_402656589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656589.makeUrl(scheme.get, call_402656589.host, call_402656589.base,
                                   call_402656589.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656589, uri, valid, _)

proc call*(call_402656590: Call_ListConnectorDefinitionVersions_402656576;
           ConnectorDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listConnectorDefinitionVersions
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ##   
                                                                                                                                                                                                                                          ## ConnectorDefinitionId: string (required)
                                                                                                                                                                                                                                          ##                        
                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                          ## ID 
                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                          ## connector 
                                                                                                                                                                                                                                          ## definition.
  ##   
                                                                                                                                                                                                                                                        ## MaxResults: string
                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                        ## maximum 
                                                                                                                                                                                                                                                        ## number 
                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                        ## be 
                                                                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                                                                        ## per 
                                                                                                                                                                                                                                                        ## request.
  ##   
                                                                                                                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                   ## token 
                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                   ## results, 
                                                                                                                                                                                                                                                                   ## or 
                                                                                                                                                                                                                                                                   ## ''null'' 
                                                                                                                                                                                                                                                                   ## if 
                                                                                                                                                                                                                                                                   ## there 
                                                                                                                                                                                                                                                                   ## are 
                                                                                                                                                                                                                                                                   ## no 
                                                                                                                                                                                                                                                                   ## additional 
                                                                                                                                                                                                                                                                   ## results.
  var path_402656591 = newJObject()
  var query_402656592 = newJObject()
  add(path_402656591, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(query_402656592, "MaxResults", newJString(MaxResults))
  add(query_402656592, "NextToken", newJString(NextToken))
  result = call_402656590.call(path_402656591, query_402656592, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_402656576(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_402656577, base: "/",
    makeUrl: url_ListConnectorDefinitionVersions_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_402656625 = ref object of OpenApiRestCall_402656035
proc url_CreateCoreDefinition_402656627(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCoreDefinition_402656626(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amzn-Client-Token", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Signature")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Signature", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Algorithm", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Date")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Date", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Credential")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Credential", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
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

proc call*(call_402656637: Call_CreateCoreDefinition_402656625;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
                                                                                         ## 
  let valid = call_402656637.validator(path, query, header, formData, body, _)
  let scheme = call_402656637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656637.makeUrl(scheme.get, call_402656637.host, call_402656637.base,
                                   call_402656637.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656637, uri, valid, _)

proc call*(call_402656638: Call_CreateCoreDefinition_402656625; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   
                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656639 = newJObject()
  if body != nil:
    body_402656639 = body
  result = call_402656638.call(nil, nil, nil, nil, body_402656639)

var createCoreDefinition* = Call_CreateCoreDefinition_402656625(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_402656626, base: "/",
    makeUrl: url_CreateCoreDefinition_402656627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_402656610 = ref object of OpenApiRestCall_402656035
proc url_ListCoreDefinitions_402656612(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCoreDefinitions_402656611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of core definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656613 = query.getOrDefault("MaxResults")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "MaxResults", valid_402656613
  var valid_402656614 = query.getOrDefault("NextToken")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "NextToken", valid_402656614
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
  var valid_402656615 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Security-Token", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Signature")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Signature", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Algorithm", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Date")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Date", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Credential")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Credential", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656622: Call_ListCoreDefinitions_402656610;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of core definitions.
                                                                                         ## 
  let valid = call_402656622.validator(path, query, header, formData, body, _)
  let scheme = call_402656622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656622.makeUrl(scheme.get, call_402656622.host, call_402656622.base,
                                   call_402656622.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656622, uri, valid, _)

proc call*(call_402656623: Call_ListCoreDefinitions_402656610;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
                                          ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                    ## NextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## token 
                                                                                                                    ## for 
                                                                                                                    ## the 
                                                                                                                    ## next 
                                                                                                                    ## set 
                                                                                                                    ## of 
                                                                                                                    ## results, 
                                                                                                                    ## or 
                                                                                                                    ## ''null'' 
                                                                                                                    ## if 
                                                                                                                    ## there 
                                                                                                                    ## are 
                                                                                                                    ## no 
                                                                                                                    ## additional 
                                                                                                                    ## results.
  var query_402656624 = newJObject()
  add(query_402656624, "MaxResults", newJString(MaxResults))
  add(query_402656624, "NextToken", newJString(NextToken))
  result = call_402656623.call(nil, query_402656624, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_402656610(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_402656611, base: "/",
    makeUrl: url_ListCoreDefinitions_402656612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_402656657 = ref object of OpenApiRestCall_402656035
proc url_CreateCoreDefinitionVersion_402656659(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_402656658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656660 = path.getOrDefault("CoreDefinitionId")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "CoreDefinitionId", valid_402656660
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amzn-Client-Token", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Signature")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Signature", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Algorithm", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Date")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Date", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Credential")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Credential", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656668
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

proc call*(call_402656670: Call_CreateCoreDefinitionVersion_402656657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
                                                                                         ## 
  let valid = call_402656670.validator(path, query, header, formData, body, _)
  let scheme = call_402656670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656670.makeUrl(scheme.get, call_402656670.host, call_402656670.base,
                                   call_402656670.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656670, uri, valid, _)

proc call*(call_402656671: Call_CreateCoreDefinitionVersion_402656657;
           CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   
                                                                                                                                           ## CoreDefinitionId: string (required)
                                                                                                                                           ##                   
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## ID 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## core 
                                                                                                                                           ## definition.
  ##   
                                                                                                                                                         ## body: JObject (required)
  var path_402656672 = newJObject()
  var body_402656673 = newJObject()
  add(path_402656672, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_402656673 = body
  result = call_402656671.call(path_402656672, nil, nil, nil, body_402656673)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_402656657(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_402656658, base: "/",
    makeUrl: url_CreateCoreDefinitionVersion_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_402656640 = ref object of OpenApiRestCall_402656035
proc url_ListCoreDefinitionVersions_402656642(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_402656641(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656643 = path.getOrDefault("CoreDefinitionId")
  valid_402656643 = validateParameter(valid_402656643, JString, required = true,
                                      default = nil)
  if valid_402656643 != nil:
    section.add "CoreDefinitionId", valid_402656643
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656644 = query.getOrDefault("MaxResults")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "MaxResults", valid_402656644
  var valid_402656645 = query.getOrDefault("NextToken")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "NextToken", valid_402656645
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
  var valid_402656646 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Security-Token", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Signature")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Signature", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Algorithm", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Date")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Date", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Credential")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Credential", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656653: Call_ListCoreDefinitionVersions_402656640;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a core definition.
                                                                                         ## 
  let valid = call_402656653.validator(path, query, header, formData, body, _)
  let scheme = call_402656653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656653.makeUrl(scheme.get, call_402656653.host, call_402656653.base,
                                   call_402656653.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656653, uri, valid, _)

proc call*(call_402656654: Call_ListCoreDefinitionVersions_402656640;
           CoreDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   CoreDefinitionId: string (required)
                                             ##                   : The ID of the core definition.
  ##   
                                                                                                  ## MaxResults: string
                                                                                                  ##             
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## maximum 
                                                                                                  ## number 
                                                                                                  ## of 
                                                                                                  ## results 
                                                                                                  ## to 
                                                                                                  ## be 
                                                                                                  ## returned 
                                                                                                  ## per 
                                                                                                  ## request.
  ##   
                                                                                                             ## NextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## token 
                                                                                                             ## for 
                                                                                                             ## the 
                                                                                                             ## next 
                                                                                                             ## set 
                                                                                                             ## of 
                                                                                                             ## results, 
                                                                                                             ## or 
                                                                                                             ## ''null'' 
                                                                                                             ## if 
                                                                                                             ## there 
                                                                                                             ## are 
                                                                                                             ## no 
                                                                                                             ## additional 
                                                                                                             ## results.
  var path_402656655 = newJObject()
  var query_402656656 = newJObject()
  add(path_402656655, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(query_402656656, "MaxResults", newJString(MaxResults))
  add(query_402656656, "NextToken", newJString(NextToken))
  result = call_402656654.call(path_402656655, query_402656656, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_402656640(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_402656641, base: "/",
    makeUrl: url_ListCoreDefinitionVersions_402656642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_402656691 = ref object of OpenApiRestCall_402656035
proc url_CreateDeployment_402656693(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_CreateDeployment_402656692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656694 = path.getOrDefault("GroupId")
  valid_402656694 = validateParameter(valid_402656694, JString, required = true,
                                      default = nil)
  if valid_402656694 != nil:
    section.add "GroupId", valid_402656694
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656695 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Security-Token", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amzn-Client-Token", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Signature")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Signature", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Algorithm", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Date")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Date", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Credential")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Credential", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656702
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

proc call*(call_402656704: Call_CreateDeployment_402656691;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
                                                                                         ## 
  let valid = call_402656704.validator(path, query, header, formData, body, _)
  let scheme = call_402656704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656704.makeUrl(scheme.get, call_402656704.host, call_402656704.base,
                                   call_402656704.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656704, uri, valid, _)

proc call*(call_402656705: Call_CreateDeployment_402656691; body: JsonNode;
           GroupId: string): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   
                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                ## GroupId: string (required)
                                                                                                                                                                                ##          
                                                                                                                                                                                ## : 
                                                                                                                                                                                ## The 
                                                                                                                                                                                ## ID 
                                                                                                                                                                                ## of 
                                                                                                                                                                                ## the 
                                                                                                                                                                                ## Greengrass 
                                                                                                                                                                                ## group.
  var path_402656706 = newJObject()
  var body_402656707 = newJObject()
  if body != nil:
    body_402656707 = body
  add(path_402656706, "GroupId", newJString(GroupId))
  result = call_402656705.call(path_402656706, nil, nil, nil, body_402656707)

var createDeployment* = Call_CreateDeployment_402656691(
    name: "createDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_402656692, base: "/",
    makeUrl: url_CreateDeployment_402656693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_402656674 = ref object of OpenApiRestCall_402656035
proc url_ListDeployments_402656676(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_ListDeployments_402656675(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656677 = path.getOrDefault("GroupId")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "GroupId", valid_402656677
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656678 = query.getOrDefault("MaxResults")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "MaxResults", valid_402656678
  var valid_402656679 = query.getOrDefault("NextToken")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "NextToken", valid_402656679
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
  var valid_402656680 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Security-Token", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Signature")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Signature", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Algorithm", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Date")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Date", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Credential")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Credential", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656687: Call_ListDeployments_402656674; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a history of deployments for the group.
                                                                                         ## 
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_ListDeployments_402656674; GroupId: string;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   MaxResults: string
                                                    ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## token 
                                                                                                                              ## for 
                                                                                                                              ## the 
                                                                                                                              ## next 
                                                                                                                              ## set 
                                                                                                                              ## of 
                                                                                                                              ## results, 
                                                                                                                              ## or 
                                                                                                                              ## ''null'' 
                                                                                                                              ## if 
                                                                                                                              ## there 
                                                                                                                              ## are 
                                                                                                                              ## no 
                                                                                                                              ## additional 
                                                                                                                              ## results.
  ##   
                                                                                                                                         ## GroupId: string (required)
                                                                                                                                         ##          
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## ID 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## Greengrass 
                                                                                                                                         ## group.
  var path_402656689 = newJObject()
  var query_402656690 = newJObject()
  add(query_402656690, "MaxResults", newJString(MaxResults))
  add(query_402656690, "NextToken", newJString(NextToken))
  add(path_402656689, "GroupId", newJString(GroupId))
  result = call_402656688.call(path_402656689, query_402656690, nil, nil, nil)

var listDeployments* = Call_ListDeployments_402656674(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_402656675, base: "/",
    makeUrl: url_ListDeployments_402656676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_402656723 = ref object of OpenApiRestCall_402656035
proc url_CreateDeviceDefinition_402656725(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeviceDefinition_402656724(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656726 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Security-Token", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amzn-Client-Token", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Signature")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Signature", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Algorithm", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Date")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Date", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Credential")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Credential", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656733
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

proc call*(call_402656735: Call_CreateDeviceDefinition_402656723;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
                                                                                         ## 
  let valid = call_402656735.validator(path, query, header, formData, body, _)
  let scheme = call_402656735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656735.makeUrl(scheme.get, call_402656735.host, call_402656735.base,
                                   call_402656735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656735, uri, valid, _)

proc call*(call_402656736: Call_CreateDeviceDefinition_402656723; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   
                                                                                                                                                            ## body: JObject (required)
  var body_402656737 = newJObject()
  if body != nil:
    body_402656737 = body
  result = call_402656736.call(nil, nil, nil, nil, body_402656737)

var createDeviceDefinition* = Call_CreateDeviceDefinition_402656723(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_402656724, base: "/",
    makeUrl: url_CreateDeviceDefinition_402656725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_402656708 = ref object of OpenApiRestCall_402656035
proc url_ListDeviceDefinitions_402656710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceDefinitions_402656709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of device definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656711 = query.getOrDefault("MaxResults")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "MaxResults", valid_402656711
  var valid_402656712 = query.getOrDefault("NextToken")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "NextToken", valid_402656712
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
  var valid_402656713 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Security-Token", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Signature")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Signature", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Algorithm", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Date")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Date", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Credential")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Credential", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656720: Call_ListDeviceDefinitions_402656708;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of device definitions.
                                                                                         ## 
  let valid = call_402656720.validator(path, query, header, formData, body, _)
  let scheme = call_402656720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656720.makeUrl(scheme.get, call_402656720.host, call_402656720.base,
                                   call_402656720.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656720, uri, valid, _)

proc call*(call_402656721: Call_ListDeviceDefinitions_402656708;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
                                            ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## token 
                                                                                                                      ## for 
                                                                                                                      ## the 
                                                                                                                      ## next 
                                                                                                                      ## set 
                                                                                                                      ## of 
                                                                                                                      ## results, 
                                                                                                                      ## or 
                                                                                                                      ## ''null'' 
                                                                                                                      ## if 
                                                                                                                      ## there 
                                                                                                                      ## are 
                                                                                                                      ## no 
                                                                                                                      ## additional 
                                                                                                                      ## results.
  var query_402656722 = newJObject()
  add(query_402656722, "MaxResults", newJString(MaxResults))
  add(query_402656722, "NextToken", newJString(NextToken))
  result = call_402656721.call(nil, query_402656722, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_402656708(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_402656709, base: "/",
    makeUrl: url_ListDeviceDefinitions_402656710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_402656755 = ref object of OpenApiRestCall_402656035
proc url_CreateDeviceDefinitionVersion_402656757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
         "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
                 (kind: VariableSegment, value: "DeviceDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeviceDefinitionVersion_402656756(path: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402656758 = path.getOrDefault("DeviceDefinitionId")
  valid_402656758 = validateParameter(valid_402656758, JString, required = true,
                                      default = nil)
  if valid_402656758 != nil:
    section.add "DeviceDefinitionId", valid_402656758
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amzn-Client-Token", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Signature")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Signature", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Algorithm", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Date")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Date", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Credential")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Credential", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656766
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

proc call*(call_402656768: Call_CreateDeviceDefinitionVersion_402656755;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a device definition that has already been defined.
                                                                                         ## 
  let valid = call_402656768.validator(path, query, header, formData, body, _)
  let scheme = call_402656768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656768.makeUrl(scheme.get, call_402656768.host, call_402656768.base,
                                   call_402656768.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656768, uri, valid, _)

proc call*(call_402656769: Call_CreateDeviceDefinitionVersion_402656755;
           DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   
                                                                            ## DeviceDefinitionId: string (required)
                                                                            ##                     
                                                                            ## : 
                                                                            ## The 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## device 
                                                                            ## definition.
  ##   
                                                                                          ## body: JObject (required)
  var path_402656770 = newJObject()
  var body_402656771 = newJObject()
  add(path_402656770, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_402656771 = body
  result = call_402656769.call(path_402656770, nil, nil, nil, body_402656771)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_402656755(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_402656756, base: "/",
    makeUrl: url_CreateDeviceDefinitionVersion_402656757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_402656738 = ref object of OpenApiRestCall_402656035
proc url_ListDeviceDefinitionVersions_402656740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
         "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
                 (kind: VariableSegment, value: "DeviceDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeviceDefinitionVersions_402656739(path: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402656741 = path.getOrDefault("DeviceDefinitionId")
  valid_402656741 = validateParameter(valid_402656741, JString, required = true,
                                      default = nil)
  if valid_402656741 != nil:
    section.add "DeviceDefinitionId", valid_402656741
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656742 = query.getOrDefault("MaxResults")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "MaxResults", valid_402656742
  var valid_402656743 = query.getOrDefault("NextToken")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "NextToken", valid_402656743
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
  var valid_402656744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Security-Token", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Signature")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Signature", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Algorithm", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Date")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Date", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Credential")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Credential", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656751: Call_ListDeviceDefinitionVersions_402656738;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a device definition.
                                                                                         ## 
  let valid = call_402656751.validator(path, query, header, formData, body, _)
  let scheme = call_402656751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656751.makeUrl(scheme.get, call_402656751.host, call_402656751.base,
                                   call_402656751.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656751, uri, valid, _)

proc call*(call_402656752: Call_ListDeviceDefinitionVersions_402656738;
           DeviceDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   MaxResults: string
                                               ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                         ## DeviceDefinitionId: string (required)
                                                                                                                         ##                     
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## ID 
                                                                                                                         ## of 
                                                                                                                         ## the 
                                                                                                                         ## device 
                                                                                                                         ## definition.
  ##   
                                                                                                                                       ## NextToken: string
                                                                                                                                       ##            
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## token 
                                                                                                                                       ## for 
                                                                                                                                       ## the 
                                                                                                                                       ## next 
                                                                                                                                       ## set 
                                                                                                                                       ## of 
                                                                                                                                       ## results, 
                                                                                                                                       ## or 
                                                                                                                                       ## ''null'' 
                                                                                                                                       ## if 
                                                                                                                                       ## there 
                                                                                                                                       ## are 
                                                                                                                                       ## no 
                                                                                                                                       ## additional 
                                                                                                                                       ## results.
  var path_402656753 = newJObject()
  var query_402656754 = newJObject()
  add(query_402656754, "MaxResults", newJString(MaxResults))
  add(path_402656753, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_402656754, "NextToken", newJString(NextToken))
  result = call_402656752.call(path_402656753, query_402656754, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_402656738(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_402656739, base: "/",
    makeUrl: url_ListDeviceDefinitionVersions_402656740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_402656787 = ref object of OpenApiRestCall_402656035
proc url_CreateFunctionDefinition_402656789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunctionDefinition_402656788(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656790 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Security-Token", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amzn-Client-Token", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Signature")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Signature", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Algorithm", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Date")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Date", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Credential")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Credential", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656797
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

proc call*(call_402656799: Call_CreateFunctionDefinition_402656787;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
                                                                                         ## 
  let valid = call_402656799.validator(path, query, header, formData, body, _)
  let scheme = call_402656799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656799.makeUrl(scheme.get, call_402656799.host, call_402656799.base,
                                   call_402656799.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656799, uri, valid, _)

proc call*(call_402656800: Call_CreateFunctionDefinition_402656787;
           body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   
                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656801 = newJObject()
  if body != nil:
    body_402656801 = body
  result = call_402656800.call(nil, nil, nil, nil, body_402656801)

var createFunctionDefinition* = Call_CreateFunctionDefinition_402656787(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_402656788, base: "/",
    makeUrl: url_CreateFunctionDefinition_402656789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_402656772 = ref object of OpenApiRestCall_402656035
proc url_ListFunctionDefinitions_402656774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctionDefinitions_402656773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of Lambda function definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656775 = query.getOrDefault("MaxResults")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "MaxResults", valid_402656775
  var valid_402656776 = query.getOrDefault("NextToken")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "NextToken", valid_402656776
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
  var valid_402656777 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Security-Token", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Signature")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Signature", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Algorithm", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Date")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Date", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Credential")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Credential", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656784: Call_ListFunctionDefinitions_402656772;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of Lambda function definitions.
                                                                                         ## 
  let valid = call_402656784.validator(path, query, header, formData, body, _)
  let scheme = call_402656784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656784.makeUrl(scheme.get, call_402656784.host, call_402656784.base,
                                   call_402656784.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656784, uri, valid, _)

proc call*(call_402656785: Call_ListFunctionDefinitions_402656772;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
                                                     ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                               ## NextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## token 
                                                                                                                               ## for 
                                                                                                                               ## the 
                                                                                                                               ## next 
                                                                                                                               ## set 
                                                                                                                               ## of 
                                                                                                                               ## results, 
                                                                                                                               ## or 
                                                                                                                               ## ''null'' 
                                                                                                                               ## if 
                                                                                                                               ## there 
                                                                                                                               ## are 
                                                                                                                               ## no 
                                                                                                                               ## additional 
                                                                                                                               ## results.
  var query_402656786 = newJObject()
  add(query_402656786, "MaxResults", newJString(MaxResults))
  add(query_402656786, "NextToken", newJString(NextToken))
  result = call_402656785.call(nil, query_402656786, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_402656772(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_402656773, base: "/",
    makeUrl: url_ListFunctionDefinitions_402656774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_402656819 = ref object of OpenApiRestCall_402656035
proc url_CreateFunctionDefinitionVersion_402656821(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
         "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
                 (kind: VariableSegment, value: "FunctionDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunctionDefinitionVersion_402656820(path: JsonNode;
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
  var valid_402656822 = path.getOrDefault("FunctionDefinitionId")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true,
                                      default = nil)
  if valid_402656822 != nil:
    section.add "FunctionDefinitionId", valid_402656822
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amzn-Client-Token", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Signature")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Signature", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Algorithm", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Date")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Date", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Credential")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Credential", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656830
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

proc call*(call_402656832: Call_CreateFunctionDefinitionVersion_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
                                                                                         ## 
  let valid = call_402656832.validator(path, query, header, formData, body, _)
  let scheme = call_402656832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656832.makeUrl(scheme.get, call_402656832.host, call_402656832.base,
                                   call_402656832.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656832, uri, valid, _)

proc call*(call_402656833: Call_CreateFunctionDefinitionVersion_402656819;
           body: JsonNode; FunctionDefinitionId: string): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   
                                                                                     ## body: JObject (required)
  ##   
                                                                                                                ## FunctionDefinitionId: string (required)
                                                                                                                ##                       
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## ID 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## Lambda 
                                                                                                                ## function 
                                                                                                                ## definition.
  var path_402656834 = newJObject()
  var body_402656835 = newJObject()
  if body != nil:
    body_402656835 = body
  add(path_402656834, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402656833.call(path_402656834, nil, nil, nil, body_402656835)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_402656819(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_402656820, base: "/",
    makeUrl: url_CreateFunctionDefinitionVersion_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_402656802 = ref object of OpenApiRestCall_402656035
proc url_ListFunctionDefinitionVersions_402656804(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
         "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
                 (kind: VariableSegment, value: "FunctionDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionDefinitionVersions_402656803(path: JsonNode;
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
  var valid_402656805 = path.getOrDefault("FunctionDefinitionId")
  valid_402656805 = validateParameter(valid_402656805, JString, required = true,
                                      default = nil)
  if valid_402656805 != nil:
    section.add "FunctionDefinitionId", valid_402656805
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656806 = query.getOrDefault("MaxResults")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "MaxResults", valid_402656806
  var valid_402656807 = query.getOrDefault("NextToken")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "NextToken", valid_402656807
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
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656815: Call_ListFunctionDefinitionVersions_402656802;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a Lambda function definition.
                                                                                         ## 
  let valid = call_402656815.validator(path, query, header, formData, body, _)
  let scheme = call_402656815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656815.makeUrl(scheme.get, call_402656815.host, call_402656815.base,
                                   call_402656815.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656815, uri, valid, _)

proc call*(call_402656816: Call_ListFunctionDefinitionVersions_402656802;
           FunctionDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listFunctionDefinitionVersions
  ## Lists the versions of a Lambda function definition.
  ##   MaxResults: string
                                                        ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                                  ## NextToken: string
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## token 
                                                                                                                                  ## for 
                                                                                                                                  ## the 
                                                                                                                                  ## next 
                                                                                                                                  ## set 
                                                                                                                                  ## of 
                                                                                                                                  ## results, 
                                                                                                                                  ## or 
                                                                                                                                  ## ''null'' 
                                                                                                                                  ## if 
                                                                                                                                  ## there 
                                                                                                                                  ## are 
                                                                                                                                  ## no 
                                                                                                                                  ## additional 
                                                                                                                                  ## results.
  ##   
                                                                                                                                             ## FunctionDefinitionId: string (required)
                                                                                                                                             ##                       
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## ID 
                                                                                                                                             ## of 
                                                                                                                                             ## the 
                                                                                                                                             ## Lambda 
                                                                                                                                             ## function 
                                                                                                                                             ## definition.
  var path_402656817 = newJObject()
  var query_402656818 = newJObject()
  add(query_402656818, "MaxResults", newJString(MaxResults))
  add(query_402656818, "NextToken", newJString(NextToken))
  add(path_402656817, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402656816.call(path_402656817, query_402656818, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_402656802(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_402656803, base: "/",
    makeUrl: url_ListFunctionDefinitionVersions_402656804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_402656851 = ref object of OpenApiRestCall_402656035
proc url_CreateGroup_402656853(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_402656852(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656854 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Security-Token", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amzn-Client-Token", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Signature")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Signature", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Algorithm", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Date")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Date", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Credential")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Credential", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656861
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

proc call*(call_402656863: Call_CreateGroup_402656851; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
                                                                                         ## 
  let valid = call_402656863.validator(path, query, header, formData, body, _)
  let scheme = call_402656863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656863.makeUrl(scheme.get, call_402656863.host, call_402656863.base,
                                   call_402656863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656863, uri, valid, _)

proc call*(call_402656864: Call_CreateGroup_402656851; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   
                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656865 = newJObject()
  if body != nil:
    body_402656865 = body
  result = call_402656864.call(nil, nil, nil, nil, body_402656865)

var createGroup* = Call_CreateGroup_402656851(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups", validator: validate_CreateGroup_402656852,
    base: "/", makeUrl: url_CreateGroup_402656853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_402656836 = ref object of OpenApiRestCall_402656035
proc url_ListGroups_402656838(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_402656837(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of groups.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656839 = query.getOrDefault("MaxResults")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "MaxResults", valid_402656839
  var valid_402656840 = query.getOrDefault("NextToken")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "NextToken", valid_402656840
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
  var valid_402656841 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Security-Token", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Signature")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Signature", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Algorithm", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Date")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Date", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Credential")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Credential", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656848: Call_ListGroups_402656836; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of groups.
                                                                                         ## 
  let valid = call_402656848.validator(path, query, header, formData, body, _)
  let scheme = call_402656848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656848.makeUrl(scheme.get, call_402656848.host, call_402656848.base,
                                   call_402656848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656848, uri, valid, _)

proc call*(call_402656849: Call_ListGroups_402656836; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
                                ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                          ## NextToken: string
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## token 
                                                                                                          ## for 
                                                                                                          ## the 
                                                                                                          ## next 
                                                                                                          ## set 
                                                                                                          ## of 
                                                                                                          ## results, 
                                                                                                          ## or 
                                                                                                          ## ''null'' 
                                                                                                          ## if 
                                                                                                          ## there 
                                                                                                          ## are 
                                                                                                          ## no 
                                                                                                          ## additional 
                                                                                                          ## results.
  var query_402656850 = newJObject()
  add(query_402656850, "MaxResults", newJString(MaxResults))
  add(query_402656850, "NextToken", newJString(NextToken))
  result = call_402656849.call(nil, query_402656850, nil, nil, nil)

var listGroups* = Call_ListGroups_402656836(name: "listGroups",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups", validator: validate_ListGroups_402656837,
    base: "/", makeUrl: url_ListGroups_402656838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_402656880 = ref object of OpenApiRestCall_402656035
proc url_CreateGroupCertificateAuthority_402656882(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateGroupCertificateAuthority_402656881(path: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656883 = path.getOrDefault("GroupId")
  valid_402656883 = validateParameter(valid_402656883, JString, required = true,
                                      default = nil)
  if valid_402656883 != nil:
    section.add "GroupId", valid_402656883
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656884 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Security-Token", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amzn-Client-Token", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Signature")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Signature", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Algorithm", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Date")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Date", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Credential")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Credential", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656892: Call_CreateGroupCertificateAuthority_402656880;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
                                                                                         ## 
  let valid = call_402656892.validator(path, query, header, formData, body, _)
  let scheme = call_402656892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656892.makeUrl(scheme.get, call_402656892.host, call_402656892.base,
                                   call_402656892.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656892, uri, valid, _)

proc call*(call_402656893: Call_CreateGroupCertificateAuthority_402656880;
           GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   
                                                                                        ## GroupId: string (required)
                                                                                        ##          
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ID 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## Greengrass 
                                                                                        ## group.
  var path_402656894 = newJObject()
  add(path_402656894, "GroupId", newJString(GroupId))
  result = call_402656893.call(path_402656894, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_402656880(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_402656881, base: "/",
    makeUrl: url_CreateGroupCertificateAuthority_402656882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_402656866 = ref object of OpenApiRestCall_402656035
proc url_ListGroupCertificateAuthorities_402656868(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListGroupCertificateAuthorities_402656867(path: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656869 = path.getOrDefault("GroupId")
  valid_402656869 = validateParameter(valid_402656869, JString, required = true,
                                      default = nil)
  if valid_402656869 != nil:
    section.add "GroupId", valid_402656869
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
  var valid_402656870 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Security-Token", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Signature")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Signature", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Algorithm", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Date")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Date", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Credential")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Credential", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656877: Call_ListGroupCertificateAuthorities_402656866;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current CAs for a group.
                                                                                         ## 
  let valid = call_402656877.validator(path, query, header, formData, body, _)
  let scheme = call_402656877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656877.makeUrl(scheme.get, call_402656877.host, call_402656877.base,
                                   call_402656877.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656877, uri, valid, _)

proc call*(call_402656878: Call_ListGroupCertificateAuthorities_402656866;
           GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
                                           ##          : The ID of the Greengrass group.
  var path_402656879 = newJObject()
  add(path_402656879, "GroupId", newJString(GroupId))
  result = call_402656878.call(path_402656879, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_402656866(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_402656867, base: "/",
    makeUrl: url_ListGroupCertificateAuthorities_402656868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_402656912 = ref object of OpenApiRestCall_402656035
proc url_CreateGroupVersion_402656914(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateGroupVersion_402656913(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656915 = path.getOrDefault("GroupId")
  valid_402656915 = validateParameter(valid_402656915, JString, required = true,
                                      default = nil)
  if valid_402656915 != nil:
    section.add "GroupId", valid_402656915
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656916 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Security-Token", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amzn-Client-Token", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Signature")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Signature", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Algorithm", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Date")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Date", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Credential")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Credential", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656923
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

proc call*(call_402656925: Call_CreateGroupVersion_402656912;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a group which has already been defined.
                                                                                         ## 
  let valid = call_402656925.validator(path, query, header, formData, body, _)
  let scheme = call_402656925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656925.makeUrl(scheme.get, call_402656925.host, call_402656925.base,
                                   call_402656925.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656925, uri, valid, _)

proc call*(call_402656926: Call_CreateGroupVersion_402656912; body: JsonNode;
           GroupId: string): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   body: JObject (required)
  ##   GroupId: string (required)
                               ##          : The ID of the Greengrass group.
  var path_402656927 = newJObject()
  var body_402656928 = newJObject()
  if body != nil:
    body_402656928 = body
  add(path_402656927, "GroupId", newJString(GroupId))
  result = call_402656926.call(path_402656927, nil, nil, nil, body_402656928)

var createGroupVersion* = Call_CreateGroupVersion_402656912(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_402656913, base: "/",
    makeUrl: url_CreateGroupVersion_402656914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_402656895 = ref object of OpenApiRestCall_402656035
proc url_ListGroupVersions_402656897(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListGroupVersions_402656896(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the versions of a group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402656898 = path.getOrDefault("GroupId")
  valid_402656898 = validateParameter(valid_402656898, JString, required = true,
                                      default = nil)
  if valid_402656898 != nil:
    section.add "GroupId", valid_402656898
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656899 = query.getOrDefault("MaxResults")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "MaxResults", valid_402656899
  var valid_402656900 = query.getOrDefault("NextToken")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "NextToken", valid_402656900
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
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656908: Call_ListGroupVersions_402656895;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a group.
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_ListGroupVersions_402656895; GroupId: string;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   MaxResults: string
                                   ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                             ## NextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## token 
                                                                                                             ## for 
                                                                                                             ## the 
                                                                                                             ## next 
                                                                                                             ## set 
                                                                                                             ## of 
                                                                                                             ## results, 
                                                                                                             ## or 
                                                                                                             ## ''null'' 
                                                                                                             ## if 
                                                                                                             ## there 
                                                                                                             ## are 
                                                                                                             ## no 
                                                                                                             ## additional 
                                                                                                             ## results.
  ##   
                                                                                                                        ## GroupId: string (required)
                                                                                                                        ##          
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## ID 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## Greengrass 
                                                                                                                        ## group.
  var path_402656910 = newJObject()
  var query_402656911 = newJObject()
  add(query_402656911, "MaxResults", newJString(MaxResults))
  add(query_402656911, "NextToken", newJString(NextToken))
  add(path_402656910, "GroupId", newJString(GroupId))
  result = call_402656909.call(path_402656910, query_402656911, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_402656895(
    name: "listGroupVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_402656896, base: "/",
    makeUrl: url_ListGroupVersions_402656897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_402656944 = ref object of OpenApiRestCall_402656035
proc url_CreateLoggerDefinition_402656946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoggerDefinition_402656945(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656947 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Security-Token", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amzn-Client-Token", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Signature")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Signature", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Algorithm", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Date")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Date", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Credential")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Credential", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656954
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

proc call*(call_402656956: Call_CreateLoggerDefinition_402656944;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
                                                                                         ## 
  let valid = call_402656956.validator(path, query, header, formData, body, _)
  let scheme = call_402656956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656956.makeUrl(scheme.get, call_402656956.host, call_402656956.base,
                                   call_402656956.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656956, uri, valid, _)

proc call*(call_402656957: Call_CreateLoggerDefinition_402656944; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   
                                                                                                                                                            ## body: JObject (required)
  var body_402656958 = newJObject()
  if body != nil:
    body_402656958 = body
  result = call_402656957.call(nil, nil, nil, nil, body_402656958)

var createLoggerDefinition* = Call_CreateLoggerDefinition_402656944(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_402656945, base: "/",
    makeUrl: url_CreateLoggerDefinition_402656946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_402656929 = ref object of OpenApiRestCall_402656035
proc url_ListLoggerDefinitions_402656931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggerDefinitions_402656930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of logger definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656932 = query.getOrDefault("MaxResults")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "MaxResults", valid_402656932
  var valid_402656933 = query.getOrDefault("NextToken")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "NextToken", valid_402656933
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
  var valid_402656934 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Security-Token", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Signature")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Signature", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Algorithm", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Date")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Date", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Credential")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Credential", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656941: Call_ListLoggerDefinitions_402656929;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of logger definitions.
                                                                                         ## 
  let valid = call_402656941.validator(path, query, header, formData, body, _)
  let scheme = call_402656941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656941.makeUrl(scheme.get, call_402656941.host, call_402656941.base,
                                   call_402656941.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656941, uri, valid, _)

proc call*(call_402656942: Call_ListLoggerDefinitions_402656929;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
                                            ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## token 
                                                                                                                      ## for 
                                                                                                                      ## the 
                                                                                                                      ## next 
                                                                                                                      ## set 
                                                                                                                      ## of 
                                                                                                                      ## results, 
                                                                                                                      ## or 
                                                                                                                      ## ''null'' 
                                                                                                                      ## if 
                                                                                                                      ## there 
                                                                                                                      ## are 
                                                                                                                      ## no 
                                                                                                                      ## additional 
                                                                                                                      ## results.
  var query_402656943 = newJObject()
  add(query_402656943, "MaxResults", newJString(MaxResults))
  add(query_402656943, "NextToken", newJString(NextToken))
  result = call_402656942.call(nil, query_402656943, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_402656929(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_402656930, base: "/",
    makeUrl: url_ListLoggerDefinitions_402656931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_402656976 = ref object of OpenApiRestCall_402656035
proc url_CreateLoggerDefinitionVersion_402656978(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
         "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
                 (kind: VariableSegment, value: "LoggerDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLoggerDefinitionVersion_402656977(path: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402656979 = path.getOrDefault("LoggerDefinitionId")
  valid_402656979 = validateParameter(valid_402656979, JString, required = true,
                                      default = nil)
  if valid_402656979 != nil:
    section.add "LoggerDefinitionId", valid_402656979
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656980 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Security-Token", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amzn-Client-Token", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Signature")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Signature", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Algorithm", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Date")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Date", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Credential")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Credential", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656987
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

proc call*(call_402656989: Call_CreateLoggerDefinitionVersion_402656976;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a logger definition that has already been defined.
                                                                                         ## 
  let valid = call_402656989.validator(path, query, header, formData, body, _)
  let scheme = call_402656989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656989.makeUrl(scheme.get, call_402656989.host, call_402656989.base,
                                   call_402656989.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656989, uri, valid, _)

proc call*(call_402656990: Call_CreateLoggerDefinitionVersion_402656976;
           LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   
                                                                            ## LoggerDefinitionId: string (required)
                                                                            ##                     
                                                                            ## : 
                                                                            ## The 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## logger 
                                                                            ## definition.
  ##   
                                                                                          ## body: JObject (required)
  var path_402656991 = newJObject()
  var body_402656992 = newJObject()
  add(path_402656991, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_402656992 = body
  result = call_402656990.call(path_402656991, nil, nil, nil, body_402656992)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_402656976(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_402656977, base: "/",
    makeUrl: url_CreateLoggerDefinitionVersion_402656978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_402656959 = ref object of OpenApiRestCall_402656035
proc url_ListLoggerDefinitionVersions_402656961(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
         "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
                 (kind: VariableSegment, value: "LoggerDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLoggerDefinitionVersions_402656960(path: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402656962 = path.getOrDefault("LoggerDefinitionId")
  valid_402656962 = validateParameter(valid_402656962, JString, required = true,
                                      default = nil)
  if valid_402656962 != nil:
    section.add "LoggerDefinitionId", valid_402656962
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656963 = query.getOrDefault("MaxResults")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "MaxResults", valid_402656963
  var valid_402656964 = query.getOrDefault("NextToken")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "NextToken", valid_402656964
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
  var valid_402656965 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Security-Token", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Signature")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Signature", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Algorithm", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Date")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Date", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Credential")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Credential", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656972: Call_ListLoggerDefinitionVersions_402656959;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a logger definition.
                                                                                         ## 
  let valid = call_402656972.validator(path, query, header, formData, body, _)
  let scheme = call_402656972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656972.makeUrl(scheme.get, call_402656972.host, call_402656972.base,
                                   call_402656972.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656972, uri, valid, _)

proc call*(call_402656973: Call_ListLoggerDefinitionVersions_402656959;
           LoggerDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   LoggerDefinitionId: string (required)
                                               ##                     : The ID of the logger definition.
  ##   
                                                                                                        ## MaxResults: string
                                                                                                        ##             
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## maximum 
                                                                                                        ## number 
                                                                                                        ## of 
                                                                                                        ## results 
                                                                                                        ## to 
                                                                                                        ## be 
                                                                                                        ## returned 
                                                                                                        ## per 
                                                                                                        ## request.
  ##   
                                                                                                                   ## NextToken: string
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## token 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## next 
                                                                                                                   ## set 
                                                                                                                   ## of 
                                                                                                                   ## results, 
                                                                                                                   ## or 
                                                                                                                   ## ''null'' 
                                                                                                                   ## if 
                                                                                                                   ## there 
                                                                                                                   ## are 
                                                                                                                   ## no 
                                                                                                                   ## additional 
                                                                                                                   ## results.
  var path_402656974 = newJObject()
  var query_402656975 = newJObject()
  add(path_402656974, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_402656975, "MaxResults", newJString(MaxResults))
  add(query_402656975, "NextToken", newJString(NextToken))
  result = call_402656973.call(path_402656974, query_402656975, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_402656959(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_402656960, base: "/",
    makeUrl: url_ListLoggerDefinitionVersions_402656961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_402657008 = ref object of OpenApiRestCall_402656035
proc url_CreateResourceDefinition_402657010(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDefinition_402657009(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657011 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Security-Token", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amzn-Client-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
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

proc call*(call_402657020: Call_CreateResourceDefinition_402657008;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
                                                                                         ## 
  let valid = call_402657020.validator(path, query, header, formData, body, _)
  let scheme = call_402657020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657020.makeUrl(scheme.get, call_402657020.host, call_402657020.base,
                                   call_402657020.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657020, uri, valid, _)

proc call*(call_402657021: Call_CreateResourceDefinition_402657008;
           body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   
                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657022 = newJObject()
  if body != nil:
    body_402657022 = body
  result = call_402657021.call(nil, nil, nil, nil, body_402657022)

var createResourceDefinition* = Call_CreateResourceDefinition_402657008(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_402657009, base: "/",
    makeUrl: url_CreateResourceDefinition_402657010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_402656993 = ref object of OpenApiRestCall_402656035
proc url_ListResourceDefinitions_402656995(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDefinitions_402656994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of resource definitions.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402656996 = query.getOrDefault("MaxResults")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "MaxResults", valid_402656996
  var valid_402656997 = query.getOrDefault("NextToken")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "NextToken", valid_402656997
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
  var valid_402656998 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Security-Token", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Signature")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Signature", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Algorithm", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Date")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Date", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Credential")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Credential", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657005: Call_ListResourceDefinitions_402656993;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of resource definitions.
                                                                                         ## 
  let valid = call_402657005.validator(path, query, header, formData, body, _)
  let scheme = call_402657005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657005.makeUrl(scheme.get, call_402657005.host, call_402657005.base,
                                   call_402657005.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657005, uri, valid, _)

proc call*(call_402657006: Call_ListResourceDefinitions_402656993;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
                                              ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## token 
                                                                                                                        ## for 
                                                                                                                        ## the 
                                                                                                                        ## next 
                                                                                                                        ## set 
                                                                                                                        ## of 
                                                                                                                        ## results, 
                                                                                                                        ## or 
                                                                                                                        ## ''null'' 
                                                                                                                        ## if 
                                                                                                                        ## there 
                                                                                                                        ## are 
                                                                                                                        ## no 
                                                                                                                        ## additional 
                                                                                                                        ## results.
  var query_402657007 = newJObject()
  add(query_402657007, "MaxResults", newJString(MaxResults))
  add(query_402657007, "NextToken", newJString(NextToken))
  result = call_402657006.call(nil, query_402657007, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_402656993(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_402656994, base: "/",
    makeUrl: url_ListResourceDefinitions_402656995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_402657040 = ref object of OpenApiRestCall_402656035
proc url_CreateResourceDefinitionVersion_402657042(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
         "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
                 (kind: VariableSegment, value: "ResourceDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResourceDefinitionVersion_402657041(path: JsonNode;
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
  var valid_402657043 = path.getOrDefault("ResourceDefinitionId")
  valid_402657043 = validateParameter(valid_402657043, JString, required = true,
                                      default = nil)
  if valid_402657043 != nil:
    section.add "ResourceDefinitionId", valid_402657043
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657044 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Security-Token", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amzn-Client-Token", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Signature")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Signature", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Algorithm", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Date")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Date", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Credential")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Credential", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657051
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

proc call*(call_402657053: Call_CreateResourceDefinitionVersion_402657040;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a resource definition that has already been defined.
                                                                                         ## 
  let valid = call_402657053.validator(path, query, header, formData, body, _)
  let scheme = call_402657053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657053.makeUrl(scheme.get, call_402657053.host, call_402657053.base,
                                   call_402657053.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657053, uri, valid, _)

proc call*(call_402657054: Call_CreateResourceDefinitionVersion_402657040;
           body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   
                                                                              ## body: JObject (required)
  ##   
                                                                                                         ## ResourceDefinitionId: string (required)
                                                                                                         ##                       
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## ID 
                                                                                                         ## of 
                                                                                                         ## the 
                                                                                                         ## resource 
                                                                                                         ## definition.
  var path_402657055 = newJObject()
  var body_402657056 = newJObject()
  if body != nil:
    body_402657056 = body
  add(path_402657055, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657054.call(path_402657055, nil, nil, nil, body_402657056)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_402657040(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_402657041, base: "/",
    makeUrl: url_CreateResourceDefinitionVersion_402657042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_402657023 = ref object of OpenApiRestCall_402656035
proc url_ListResourceDefinitionVersions_402657025(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
         "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
                 (kind: VariableSegment, value: "ResourceDefinitionId"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceDefinitionVersions_402657024(path: JsonNode;
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
  var valid_402657026 = path.getOrDefault("ResourceDefinitionId")
  valid_402657026 = validateParameter(valid_402657026, JString, required = true,
                                      default = nil)
  if valid_402657026 != nil:
    section.add "ResourceDefinitionId", valid_402657026
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402657027 = query.getOrDefault("MaxResults")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "MaxResults", valid_402657027
  var valid_402657028 = query.getOrDefault("NextToken")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "NextToken", valid_402657028
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
  var valid_402657029 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Security-Token", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Signature")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Signature", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Algorithm", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Date")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Date", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Credential")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Credential", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657036: Call_ListResourceDefinitionVersions_402657023;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a resource definition.
                                                                                         ## 
  let valid = call_402657036.validator(path, query, header, formData, body, _)
  let scheme = call_402657036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657036.makeUrl(scheme.get, call_402657036.host, call_402657036.base,
                                   call_402657036.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657036, uri, valid, _)

proc call*(call_402657037: Call_ListResourceDefinitionVersions_402657023;
           ResourceDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listResourceDefinitionVersions
  ## Lists the versions of a resource definition.
  ##   MaxResults: string
                                                 ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                           ## NextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## token 
                                                                                                                           ## for 
                                                                                                                           ## the 
                                                                                                                           ## next 
                                                                                                                           ## set 
                                                                                                                           ## of 
                                                                                                                           ## results, 
                                                                                                                           ## or 
                                                                                                                           ## ''null'' 
                                                                                                                           ## if 
                                                                                                                           ## there 
                                                                                                                           ## are 
                                                                                                                           ## no 
                                                                                                                           ## additional 
                                                                                                                           ## results.
  ##   
                                                                                                                                      ## ResourceDefinitionId: string (required)
                                                                                                                                      ##                       
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## ID 
                                                                                                                                      ## of 
                                                                                                                                      ## the 
                                                                                                                                      ## resource 
                                                                                                                                      ## definition.
  var path_402657038 = newJObject()
  var query_402657039 = newJObject()
  add(query_402657039, "MaxResults", newJString(MaxResults))
  add(query_402657039, "NextToken", newJString(NextToken))
  add(path_402657038, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657037.call(path_402657038, query_402657039, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_402657023(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_402657024, base: "/",
    makeUrl: url_ListResourceDefinitionVersions_402657025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_402657057 = ref object of OpenApiRestCall_402656035
proc url_CreateSoftwareUpdateJob_402657059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSoftwareUpdateJob_402657058(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657060 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Security-Token", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amzn-Client-Token", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Signature")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Signature", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Algorithm", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Date")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Date", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Credential")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Credential", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657067
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

proc call*(call_402657069: Call_CreateSoftwareUpdateJob_402657057;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
                                                                                         ## 
  let valid = call_402657069.validator(path, query, header, formData, body, _)
  let scheme = call_402657069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657069.makeUrl(scheme.get, call_402657069.host, call_402657069.base,
                                   call_402657069.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657069, uri, valid, _)

proc call*(call_402657070: Call_CreateSoftwareUpdateJob_402657057;
           body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   
                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657071 = newJObject()
  if body != nil:
    body_402657071 = body
  result = call_402657070.call(nil, nil, nil, nil, body_402657071)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_402657057(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_402657058, base: "/",
    makeUrl: url_CreateSoftwareUpdateJob_402657059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_402657087 = ref object of OpenApiRestCall_402656035
proc url_CreateSubscriptionDefinition_402657089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubscriptionDefinition_402657088(path: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657090 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Security-Token", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amzn-Client-Token", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Signature")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Signature", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Algorithm", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Date")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Date", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Credential")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Credential", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657097
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

proc call*(call_402657099: Call_CreateSubscriptionDefinition_402657087;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
                                                                                         ## 
  let valid = call_402657099.validator(path, query, header, formData, body, _)
  let scheme = call_402657099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657099.makeUrl(scheme.get, call_402657099.host, call_402657099.base,
                                   call_402657099.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657099, uri, valid, _)

proc call*(call_402657100: Call_CreateSubscriptionDefinition_402657087;
           body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   
                                                                                                                                                                              ## body: JObject (required)
  var body_402657101 = newJObject()
  if body != nil:
    body_402657101 = body
  result = call_402657100.call(nil, nil, nil, nil, body_402657101)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_402657087(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_402657088, base: "/",
    makeUrl: url_CreateSubscriptionDefinition_402657089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_402657072 = ref object of OpenApiRestCall_402656035
proc url_ListSubscriptionDefinitions_402657074(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscriptionDefinitions_402657073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a list of subscription definitions.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402657075 = query.getOrDefault("MaxResults")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "MaxResults", valid_402657075
  var valid_402657076 = query.getOrDefault("NextToken")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "NextToken", valid_402657076
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
  var valid_402657077 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Security-Token", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Signature")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Signature", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Algorithm", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Date")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Date", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Credential")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Credential", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657084: Call_ListSubscriptionDefinitions_402657072;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of subscription definitions.
                                                                                         ## 
  let valid = call_402657084.validator(path, query, header, formData, body, _)
  let scheme = call_402657084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657084.makeUrl(scheme.get, call_402657084.host, call_402657084.base,
                                   call_402657084.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657084, uri, valid, _)

proc call*(call_402657085: Call_ListSubscriptionDefinitions_402657072;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
                                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                            ## NextToken: string
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## The 
                                                                                                                            ## token 
                                                                                                                            ## for 
                                                                                                                            ## the 
                                                                                                                            ## next 
                                                                                                                            ## set 
                                                                                                                            ## of 
                                                                                                                            ## results, 
                                                                                                                            ## or 
                                                                                                                            ## ''null'' 
                                                                                                                            ## if 
                                                                                                                            ## there 
                                                                                                                            ## are 
                                                                                                                            ## no 
                                                                                                                            ## additional 
                                                                                                                            ## results.
  var query_402657086 = newJObject()
  add(query_402657086, "MaxResults", newJString(MaxResults))
  add(query_402657086, "NextToken", newJString(NextToken))
  result = call_402657085.call(nil, query_402657086, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_402657072(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_402657073, base: "/",
    makeUrl: url_ListSubscriptionDefinitions_402657074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_402657119 = ref object of OpenApiRestCall_402656035
proc url_CreateSubscriptionDefinitionVersion_402657121(protocol: Scheme;
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

proc validate_CreateSubscriptionDefinitionVersion_402657120(path: JsonNode;
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
  var valid_402657122 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657122 = validateParameter(valid_402657122, JString, required = true,
                                      default = nil)
  if valid_402657122 != nil:
    section.add "SubscriptionDefinitionId", valid_402657122
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657123 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Security-Token", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amzn-Client-Token", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Signature")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Signature", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Algorithm", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Date")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Date", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-Credential")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Credential", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657130
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

proc call*(call_402657132: Call_CreateSubscriptionDefinitionVersion_402657119;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
                                                                                         ## 
  let valid = call_402657132.validator(path, query, header, formData, body, _)
  let scheme = call_402657132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657132.makeUrl(scheme.get, call_402657132.host, call_402657132.base,
                                   call_402657132.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657132, uri, valid, _)

proc call*(call_402657133: Call_CreateSubscriptionDefinitionVersion_402657119;
           body: JsonNode; SubscriptionDefinitionId: string): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   
                                                                                   ## body: JObject (required)
  ##   
                                                                                                              ## SubscriptionDefinitionId: string (required)
                                                                                                              ##                           
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## subscription 
                                                                                                              ## definition.
  var path_402657134 = newJObject()
  var body_402657135 = newJObject()
  if body != nil:
    body_402657135 = body
  add(path_402657134, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657133.call(path_402657134, nil, nil, nil, body_402657135)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_402657119(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_402657120,
    base: "/", makeUrl: url_CreateSubscriptionDefinitionVersion_402657121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_402657102 = ref object of OpenApiRestCall_402656035
proc url_ListSubscriptionDefinitionVersions_402657104(protocol: Scheme;
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

proc validate_ListSubscriptionDefinitionVersions_402657103(path: JsonNode;
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
  var valid_402657105 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657105 = validateParameter(valid_402657105, JString, required = true,
                                      default = nil)
  if valid_402657105 != nil:
    section.add "SubscriptionDefinitionId", valid_402657105
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402657106 = query.getOrDefault("MaxResults")
  valid_402657106 = validateParameter(valid_402657106, JString,
                                      required = false, default = nil)
  if valid_402657106 != nil:
    section.add "MaxResults", valid_402657106
  var valid_402657107 = query.getOrDefault("NextToken")
  valid_402657107 = validateParameter(valid_402657107, JString,
                                      required = false, default = nil)
  if valid_402657107 != nil:
    section.add "NextToken", valid_402657107
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
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657115: Call_ListSubscriptionDefinitionVersions_402657102;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of a subscription definition.
                                                                                         ## 
  let valid = call_402657115.validator(path, query, header, formData, body, _)
  let scheme = call_402657115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657115.makeUrl(scheme.get, call_402657115.host, call_402657115.base,
                                   call_402657115.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657115, uri, valid, _)

proc call*(call_402657116: Call_ListSubscriptionDefinitionVersions_402657102;
           SubscriptionDefinitionId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitionVersions
  ## Lists the versions of a subscription definition.
  ##   MaxResults: string
                                                     ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                               ## NextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## token 
                                                                                                                               ## for 
                                                                                                                               ## the 
                                                                                                                               ## next 
                                                                                                                               ## set 
                                                                                                                               ## of 
                                                                                                                               ## results, 
                                                                                                                               ## or 
                                                                                                                               ## ''null'' 
                                                                                                                               ## if 
                                                                                                                               ## there 
                                                                                                                               ## are 
                                                                                                                               ## no 
                                                                                                                               ## additional 
                                                                                                                               ## results.
  ##   
                                                                                                                                          ## SubscriptionDefinitionId: string (required)
                                                                                                                                          ##                           
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## ID 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## subscription 
                                                                                                                                          ## definition.
  var path_402657117 = newJObject()
  var query_402657118 = newJObject()
  add(query_402657118, "MaxResults", newJString(MaxResults))
  add(query_402657118, "NextToken", newJString(NextToken))
  add(path_402657117, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657116.call(path_402657117, query_402657118, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_402657102(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_402657103, base: "/",
    makeUrl: url_ListSubscriptionDefinitionVersions_402657104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_402657150 = ref object of OpenApiRestCall_402656035
proc url_UpdateConnectorDefinition_402657152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
         "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
                 (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConnectorDefinition_402657151(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a connector definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
                                 ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_402657153 = path.getOrDefault("ConnectorDefinitionId")
  valid_402657153 = validateParameter(valid_402657153, JString, required = true,
                                      default = nil)
  if valid_402657153 != nil:
    section.add "ConnectorDefinitionId", valid_402657153
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
  var valid_402657154 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Security-Token", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Signature")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Signature", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Algorithm", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Date")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Date", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Credential")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Credential", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657160
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

proc call*(call_402657162: Call_UpdateConnectorDefinition_402657150;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a connector definition.
                                                                                         ## 
  let valid = call_402657162.validator(path, query, header, formData, body, _)
  let scheme = call_402657162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657162.makeUrl(scheme.get, call_402657162.host, call_402657162.base,
                                   call_402657162.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657162, uri, valid, _)

proc call*(call_402657163: Call_UpdateConnectorDefinition_402657150;
           ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
                                    ##                        : The ID of the connector definition.
  ##   
                                                                                                   ## body: JObject (required)
  var path_402657164 = newJObject()
  var body_402657165 = newJObject()
  add(path_402657164, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_402657165 = body
  result = call_402657163.call(path_402657164, nil, nil, nil, body_402657165)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_402657150(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_402657151, base: "/",
    makeUrl: url_UpdateConnectorDefinition_402657152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_402657136 = ref object of OpenApiRestCall_402656035
proc url_GetConnectorDefinition_402657138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
         "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
                 (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinition_402657137(path: JsonNode; query: JsonNode;
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
  var valid_402657139 = path.getOrDefault("ConnectorDefinitionId")
  valid_402657139 = validateParameter(valid_402657139, JString, required = true,
                                      default = nil)
  if valid_402657139 != nil:
    section.add "ConnectorDefinitionId", valid_402657139
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
  var valid_402657140 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Security-Token", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Signature")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Signature", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Algorithm", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Date")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Date", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Credential")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Credential", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657147: Call_GetConnectorDefinition_402657136;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a connector definition.
                                                                                         ## 
  let valid = call_402657147.validator(path, query, header, formData, body, _)
  let scheme = call_402657147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657147.makeUrl(scheme.get, call_402657147.host, call_402657147.base,
                                   call_402657147.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657147, uri, valid, _)

proc call*(call_402657148: Call_GetConnectorDefinition_402657136;
           ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
                                                        ##                        : The ID of the connector definition.
  var path_402657149 = newJObject()
  add(path_402657149, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_402657148.call(path_402657149, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_402657136(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_402657137, base: "/",
    makeUrl: url_GetConnectorDefinition_402657138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_402657166 = ref object of OpenApiRestCall_402656035
proc url_DeleteConnectorDefinition_402657168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
         "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
                 (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConnectorDefinition_402657167(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a connector definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
                                 ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_402657169 = path.getOrDefault("ConnectorDefinitionId")
  valid_402657169 = validateParameter(valid_402657169, JString, required = true,
                                      default = nil)
  if valid_402657169 != nil:
    section.add "ConnectorDefinitionId", valid_402657169
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
  var valid_402657170 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Security-Token", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-Signature")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-Signature", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Algorithm", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Date")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Date", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Credential")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Credential", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657177: Call_DeleteConnectorDefinition_402657166;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a connector definition.
                                                                                         ## 
  let valid = call_402657177.validator(path, query, header, formData, body, _)
  let scheme = call_402657177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657177.makeUrl(scheme.get, call_402657177.host, call_402657177.base,
                                   call_402657177.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657177, uri, valid, _)

proc call*(call_402657178: Call_DeleteConnectorDefinition_402657166;
           ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
                                    ##                        : The ID of the connector definition.
  var path_402657179 = newJObject()
  add(path_402657179, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_402657178.call(path_402657179, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_402657166(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_402657167, base: "/",
    makeUrl: url_DeleteConnectorDefinition_402657168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_402657194 = ref object of OpenApiRestCall_402656035
proc url_UpdateCoreDefinition_402657196(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateCoreDefinition_402657195(path: JsonNode; query: JsonNode;
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
  var valid_402657197 = path.getOrDefault("CoreDefinitionId")
  valid_402657197 = validateParameter(valid_402657197, JString, required = true,
                                      default = nil)
  if valid_402657197 != nil:
    section.add "CoreDefinitionId", valid_402657197
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
  var valid_402657198 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Security-Token", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Signature")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Signature", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Algorithm", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-Date")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-Date", valid_402657202
  var valid_402657203 = header.getOrDefault("X-Amz-Credential")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Credential", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657204
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

proc call*(call_402657206: Call_UpdateCoreDefinition_402657194;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a core definition.
                                                                                         ## 
  let valid = call_402657206.validator(path, query, header, formData, body, _)
  let scheme = call_402657206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657206.makeUrl(scheme.get, call_402657206.host, call_402657206.base,
                                   call_402657206.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657206, uri, valid, _)

proc call*(call_402657207: Call_UpdateCoreDefinition_402657194;
           CoreDefinitionId: string; body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
                               ##                   : The ID of the core definition.
  ##   
                                                                                    ## body: JObject (required)
  var path_402657208 = newJObject()
  var body_402657209 = newJObject()
  add(path_402657208, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_402657209 = body
  result = call_402657207.call(path_402657208, nil, nil, nil, body_402657209)

var updateCoreDefinition* = Call_UpdateCoreDefinition_402657194(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_402657195, base: "/",
    makeUrl: url_UpdateCoreDefinition_402657196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_402657180 = ref object of OpenApiRestCall_402656035
proc url_GetCoreDefinition_402657182(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetCoreDefinition_402657181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657183 = path.getOrDefault("CoreDefinitionId")
  valid_402657183 = validateParameter(valid_402657183, JString, required = true,
                                      default = nil)
  if valid_402657183 != nil:
    section.add "CoreDefinitionId", valid_402657183
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
  var valid_402657184 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Security-Token", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Signature")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Signature", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657186
  var valid_402657187 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-Algorithm", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Date")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Date", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Credential")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Credential", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657191: Call_GetCoreDefinition_402657180;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a core definition version.
                                                                                         ## 
  let valid = call_402657191.validator(path, query, header, formData, body, _)
  let scheme = call_402657191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657191.makeUrl(scheme.get, call_402657191.host, call_402657191.base,
                                   call_402657191.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657191, uri, valid, _)

proc call*(call_402657192: Call_GetCoreDefinition_402657180;
           CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
                                                           ##                   : The ID of the core definition.
  var path_402657193 = newJObject()
  add(path_402657193, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_402657192.call(path_402657193, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_402657180(
    name: "getCoreDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_402657181, base: "/",
    makeUrl: url_GetCoreDefinition_402657182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_402657210 = ref object of OpenApiRestCall_402656035
proc url_DeleteCoreDefinition_402657212(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteCoreDefinition_402657211(path: JsonNode; query: JsonNode;
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
  var valid_402657213 = path.getOrDefault("CoreDefinitionId")
  valid_402657213 = validateParameter(valid_402657213, JString, required = true,
                                      default = nil)
  if valid_402657213 != nil:
    section.add "CoreDefinitionId", valid_402657213
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
  var valid_402657214 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Security-Token", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Signature")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Signature", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Algorithm", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Date")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Date", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-Credential")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-Credential", valid_402657219
  var valid_402657220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657220 = validateParameter(valid_402657220, JString,
                                      required = false, default = nil)
  if valid_402657220 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657221: Call_DeleteCoreDefinition_402657210;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a core definition.
                                                                                         ## 
  let valid = call_402657221.validator(path, query, header, formData, body, _)
  let scheme = call_402657221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657221.makeUrl(scheme.get, call_402657221.host, call_402657221.base,
                                   call_402657221.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657221, uri, valid, _)

proc call*(call_402657222: Call_DeleteCoreDefinition_402657210;
           CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
                               ##                   : The ID of the core definition.
  var path_402657223 = newJObject()
  add(path_402657223, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_402657222.call(path_402657223, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_402657210(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_402657211, base: "/",
    makeUrl: url_DeleteCoreDefinition_402657212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_402657238 = ref object of OpenApiRestCall_402656035
proc url_UpdateDeviceDefinition_402657240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
         "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
                 (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeviceDefinition_402657239(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402657241 = path.getOrDefault("DeviceDefinitionId")
  valid_402657241 = validateParameter(valid_402657241, JString, required = true,
                                      default = nil)
  if valid_402657241 != nil:
    section.add "DeviceDefinitionId", valid_402657241
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
  var valid_402657242 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657242 = validateParameter(valid_402657242, JString,
                                      required = false, default = nil)
  if valid_402657242 != nil:
    section.add "X-Amz-Security-Token", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Signature")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Signature", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Algorithm", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Date")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Date", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Credential")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Credential", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657248
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

proc call*(call_402657250: Call_UpdateDeviceDefinition_402657238;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a device definition.
                                                                                         ## 
  let valid = call_402657250.validator(path, query, header, formData, body, _)
  let scheme = call_402657250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657250.makeUrl(scheme.get, call_402657250.host, call_402657250.base,
                                   call_402657250.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657250, uri, valid, _)

proc call*(call_402657251: Call_UpdateDeviceDefinition_402657238;
           DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
                                 ##                     : The ID of the device definition.
  ##   
                                                                                          ## body: JObject (required)
  var path_402657252 = newJObject()
  var body_402657253 = newJObject()
  add(path_402657252, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_402657253 = body
  result = call_402657251.call(path_402657252, nil, nil, nil, body_402657253)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_402657238(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_402657239, base: "/",
    makeUrl: url_UpdateDeviceDefinition_402657240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_402657224 = ref object of OpenApiRestCall_402656035
proc url_GetDeviceDefinition_402657226(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
         "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
                 (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceDefinition_402657225(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402657227 = path.getOrDefault("DeviceDefinitionId")
  valid_402657227 = validateParameter(valid_402657227, JString, required = true,
                                      default = nil)
  if valid_402657227 != nil:
    section.add "DeviceDefinitionId", valid_402657227
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
  var valid_402657228 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Security-Token", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Signature")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Signature", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Algorithm", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Date")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Date", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Credential")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Credential", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657235: Call_GetDeviceDefinition_402657224;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a device definition.
                                                                                         ## 
  let valid = call_402657235.validator(path, query, header, formData, body, _)
  let scheme = call_402657235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657235.makeUrl(scheme.get, call_402657235.host, call_402657235.base,
                                   call_402657235.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657235, uri, valid, _)

proc call*(call_402657236: Call_GetDeviceDefinition_402657224;
           DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
                                                     ##                     : The ID of the device definition.
  var path_402657237 = newJObject()
  add(path_402657237, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_402657236.call(path_402657237, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_402657224(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_402657225, base: "/",
    makeUrl: url_GetDeviceDefinition_402657226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_402657254 = ref object of OpenApiRestCall_402656035
proc url_DeleteDeviceDefinition_402657256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
         "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
                 (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeviceDefinition_402657255(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402657257 = path.getOrDefault("DeviceDefinitionId")
  valid_402657257 = validateParameter(valid_402657257, JString, required = true,
                                      default = nil)
  if valid_402657257 != nil:
    section.add "DeviceDefinitionId", valid_402657257
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
  var valid_402657258 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Security-Token", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Signature")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Signature", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Algorithm", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Date")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Date", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Credential")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Credential", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657265: Call_DeleteDeviceDefinition_402657254;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a device definition.
                                                                                         ## 
  let valid = call_402657265.validator(path, query, header, formData, body, _)
  let scheme = call_402657265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657265.makeUrl(scheme.get, call_402657265.host, call_402657265.base,
                                   call_402657265.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657265, uri, valid, _)

proc call*(call_402657266: Call_DeleteDeviceDefinition_402657254;
           DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
                                 ##                     : The ID of the device definition.
  var path_402657267 = newJObject()
  add(path_402657267, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_402657266.call(path_402657267, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_402657254(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_402657255, base: "/",
    makeUrl: url_DeleteDeviceDefinition_402657256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_402657282 = ref object of OpenApiRestCall_402656035
proc url_UpdateFunctionDefinition_402657284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
         "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
                 (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionDefinition_402657283(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a Lambda function definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
                                 ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_402657285 = path.getOrDefault("FunctionDefinitionId")
  valid_402657285 = validateParameter(valid_402657285, JString, required = true,
                                      default = nil)
  if valid_402657285 != nil:
    section.add "FunctionDefinitionId", valid_402657285
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
  var valid_402657286 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657286 = validateParameter(valid_402657286, JString,
                                      required = false, default = nil)
  if valid_402657286 != nil:
    section.add "X-Amz-Security-Token", valid_402657286
  var valid_402657287 = header.getOrDefault("X-Amz-Signature")
  valid_402657287 = validateParameter(valid_402657287, JString,
                                      required = false, default = nil)
  if valid_402657287 != nil:
    section.add "X-Amz-Signature", valid_402657287
  var valid_402657288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657288
  var valid_402657289 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657289 = validateParameter(valid_402657289, JString,
                                      required = false, default = nil)
  if valid_402657289 != nil:
    section.add "X-Amz-Algorithm", valid_402657289
  var valid_402657290 = header.getOrDefault("X-Amz-Date")
  valid_402657290 = validateParameter(valid_402657290, JString,
                                      required = false, default = nil)
  if valid_402657290 != nil:
    section.add "X-Amz-Date", valid_402657290
  var valid_402657291 = header.getOrDefault("X-Amz-Credential")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Credential", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657292
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

proc call*(call_402657294: Call_UpdateFunctionDefinition_402657282;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Lambda function definition.
                                                                                         ## 
  let valid = call_402657294.validator(path, query, header, formData, body, _)
  let scheme = call_402657294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657294.makeUrl(scheme.get, call_402657294.host, call_402657294.base,
                                   call_402657294.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657294, uri, valid, _)

proc call*(call_402657295: Call_UpdateFunctionDefinition_402657282;
           body: JsonNode; FunctionDefinitionId: string): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   body: JObject (required)
  ##   FunctionDefinitionId: string (required)
                               ##                       : The ID of the Lambda function definition.
  var path_402657296 = newJObject()
  var body_402657297 = newJObject()
  if body != nil:
    body_402657297 = body
  add(path_402657296, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402657295.call(path_402657296, nil, nil, nil, body_402657297)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_402657282(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_402657283, base: "/",
    makeUrl: url_UpdateFunctionDefinition_402657284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_402657268 = ref object of OpenApiRestCall_402656035
proc url_GetFunctionDefinition_402657270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
         "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
                 (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinition_402657269(path: JsonNode; query: JsonNode;
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
  var valid_402657271 = path.getOrDefault("FunctionDefinitionId")
  valid_402657271 = validateParameter(valid_402657271, JString, required = true,
                                      default = nil)
  if valid_402657271 != nil:
    section.add "FunctionDefinitionId", valid_402657271
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
  var valid_402657272 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657272 = validateParameter(valid_402657272, JString,
                                      required = false, default = nil)
  if valid_402657272 != nil:
    section.add "X-Amz-Security-Token", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-Signature")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-Signature", valid_402657273
  var valid_402657274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657274 = validateParameter(valid_402657274, JString,
                                      required = false, default = nil)
  if valid_402657274 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657274
  var valid_402657275 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "X-Amz-Algorithm", valid_402657275
  var valid_402657276 = header.getOrDefault("X-Amz-Date")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Date", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Credential")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Credential", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657279: Call_GetFunctionDefinition_402657268;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
                                                                                         ## 
  let valid = call_402657279.validator(path, query, header, formData, body, _)
  let scheme = call_402657279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657279.makeUrl(scheme.get, call_402657279.host, call_402657279.base,
                                   call_402657279.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657279, uri, valid, _)

proc call*(call_402657280: Call_GetFunctionDefinition_402657268;
           FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   
                                                                                                              ## FunctionDefinitionId: string (required)
                                                                                                              ##                       
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## Lambda 
                                                                                                              ## function 
                                                                                                              ## definition.
  var path_402657281 = newJObject()
  add(path_402657281, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402657280.call(path_402657281, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_402657268(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_402657269, base: "/",
    makeUrl: url_GetFunctionDefinition_402657270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_402657298 = ref object of OpenApiRestCall_402656035
proc url_DeleteFunctionDefinition_402657300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
         "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
                 (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionDefinition_402657299(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a Lambda function definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
                                 ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_402657301 = path.getOrDefault("FunctionDefinitionId")
  valid_402657301 = validateParameter(valid_402657301, JString, required = true,
                                      default = nil)
  if valid_402657301 != nil:
    section.add "FunctionDefinitionId", valid_402657301
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
  var valid_402657302 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657302 = validateParameter(valid_402657302, JString,
                                      required = false, default = nil)
  if valid_402657302 != nil:
    section.add "X-Amz-Security-Token", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-Signature")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-Signature", valid_402657303
  var valid_402657304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657304 = validateParameter(valid_402657304, JString,
                                      required = false, default = nil)
  if valid_402657304 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657304
  var valid_402657305 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657305 = validateParameter(valid_402657305, JString,
                                      required = false, default = nil)
  if valid_402657305 != nil:
    section.add "X-Amz-Algorithm", valid_402657305
  var valid_402657306 = header.getOrDefault("X-Amz-Date")
  valid_402657306 = validateParameter(valid_402657306, JString,
                                      required = false, default = nil)
  if valid_402657306 != nil:
    section.add "X-Amz-Date", valid_402657306
  var valid_402657307 = header.getOrDefault("X-Amz-Credential")
  valid_402657307 = validateParameter(valid_402657307, JString,
                                      required = false, default = nil)
  if valid_402657307 != nil:
    section.add "X-Amz-Credential", valid_402657307
  var valid_402657308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657309: Call_DeleteFunctionDefinition_402657298;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Lambda function definition.
                                                                                         ## 
  let valid = call_402657309.validator(path, query, header, formData, body, _)
  let scheme = call_402657309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657309.makeUrl(scheme.get, call_402657309.host, call_402657309.base,
                                   call_402657309.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657309, uri, valid, _)

proc call*(call_402657310: Call_DeleteFunctionDefinition_402657298;
           FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
                                          ##                       : The ID of the Lambda function definition.
  var path_402657311 = newJObject()
  add(path_402657311, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402657310.call(path_402657311, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_402657298(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_402657299, base: "/",
    makeUrl: url_DeleteFunctionDefinition_402657300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_402657326 = ref object of OpenApiRestCall_402656035
proc url_UpdateGroup_402657328(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_402657327(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657329 = path.getOrDefault("GroupId")
  valid_402657329 = validateParameter(valid_402657329, JString, required = true,
                                      default = nil)
  if valid_402657329 != nil:
    section.add "GroupId", valid_402657329
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
  var valid_402657330 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "X-Amz-Security-Token", valid_402657330
  var valid_402657331 = header.getOrDefault("X-Amz-Signature")
  valid_402657331 = validateParameter(valid_402657331, JString,
                                      required = false, default = nil)
  if valid_402657331 != nil:
    section.add "X-Amz-Signature", valid_402657331
  var valid_402657332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657332 = validateParameter(valid_402657332, JString,
                                      required = false, default = nil)
  if valid_402657332 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Algorithm", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Date")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Date", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Credential")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Credential", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657336
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

proc call*(call_402657338: Call_UpdateGroup_402657326; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a group.
                                                                                         ## 
  let valid = call_402657338.validator(path, query, header, formData, body, _)
  let scheme = call_402657338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657338.makeUrl(scheme.get, call_402657338.host, call_402657338.base,
                                   call_402657338.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657338, uri, valid, _)

proc call*(call_402657339: Call_UpdateGroup_402657326; body: JsonNode;
           GroupId: string): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   body: JObject (required)
  ##   GroupId: string (required)
                               ##          : The ID of the Greengrass group.
  var path_402657340 = newJObject()
  var body_402657341 = newJObject()
  if body != nil:
    body_402657341 = body
  add(path_402657340, "GroupId", newJString(GroupId))
  result = call_402657339.call(path_402657340, nil, nil, nil, body_402657341)

var updateGroup* = Call_UpdateGroup_402657326(name: "updateGroup",
    meth: HttpMethod.HttpPut, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}", validator: validate_UpdateGroup_402657327,
    base: "/", makeUrl: url_UpdateGroup_402657328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_402657312 = ref object of OpenApiRestCall_402656035
proc url_GetGroup_402657314(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroup_402657313(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657315 = path.getOrDefault("GroupId")
  valid_402657315 = validateParameter(valid_402657315, JString, required = true,
                                      default = nil)
  if valid_402657315 != nil:
    section.add "GroupId", valid_402657315
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
  var valid_402657316 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "X-Amz-Security-Token", valid_402657316
  var valid_402657317 = header.getOrDefault("X-Amz-Signature")
  valid_402657317 = validateParameter(valid_402657317, JString,
                                      required = false, default = nil)
  if valid_402657317 != nil:
    section.add "X-Amz-Signature", valid_402657317
  var valid_402657318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Algorithm", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Date")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Date", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Credential")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Credential", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657323: Call_GetGroup_402657312; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a group.
                                                                                         ## 
  let valid = call_402657323.validator(path, query, header, formData, body, _)
  let scheme = call_402657323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657323.makeUrl(scheme.get, call_402657323.host, call_402657323.base,
                                   call_402657323.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657323, uri, valid, _)

proc call*(call_402657324: Call_GetGroup_402657312; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
                                         ##          : The ID of the Greengrass group.
  var path_402657325 = newJObject()
  add(path_402657325, "GroupId", newJString(GroupId))
  result = call_402657324.call(path_402657325, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_402657312(name: "getGroup",
                                        meth: HttpMethod.HttpGet,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_GetGroup_402657313,
                                        base: "/", makeUrl: url_GetGroup_402657314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_402657342 = ref object of OpenApiRestCall_402656035
proc url_DeleteGroup_402657344(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_402657343(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657345 = path.getOrDefault("GroupId")
  valid_402657345 = validateParameter(valid_402657345, JString, required = true,
                                      default = nil)
  if valid_402657345 != nil:
    section.add "GroupId", valid_402657345
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
  var valid_402657346 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657346 = validateParameter(valid_402657346, JString,
                                      required = false, default = nil)
  if valid_402657346 != nil:
    section.add "X-Amz-Security-Token", valid_402657346
  var valid_402657347 = header.getOrDefault("X-Amz-Signature")
  valid_402657347 = validateParameter(valid_402657347, JString,
                                      required = false, default = nil)
  if valid_402657347 != nil:
    section.add "X-Amz-Signature", valid_402657347
  var valid_402657348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657348
  var valid_402657349 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "X-Amz-Algorithm", valid_402657349
  var valid_402657350 = header.getOrDefault("X-Amz-Date")
  valid_402657350 = validateParameter(valid_402657350, JString,
                                      required = false, default = nil)
  if valid_402657350 != nil:
    section.add "X-Amz-Date", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Credential")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Credential", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657353: Call_DeleteGroup_402657342; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a group.
                                                                                         ## 
  let valid = call_402657353.validator(path, query, header, formData, body, _)
  let scheme = call_402657353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657353.makeUrl(scheme.get, call_402657353.host, call_402657353.base,
                                   call_402657353.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657353, uri, valid, _)

proc call*(call_402657354: Call_DeleteGroup_402657342; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
                     ##          : The ID of the Greengrass group.
  var path_402657355 = newJObject()
  add(path_402657355, "GroupId", newJString(GroupId))
  result = call_402657354.call(path_402657355, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_402657342(name: "deleteGroup",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}", validator: validate_DeleteGroup_402657343,
    base: "/", makeUrl: url_DeleteGroup_402657344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_402657370 = ref object of OpenApiRestCall_402656035
proc url_UpdateLoggerDefinition_402657372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
         "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
                 (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLoggerDefinition_402657371(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402657373 = path.getOrDefault("LoggerDefinitionId")
  valid_402657373 = validateParameter(valid_402657373, JString, required = true,
                                      default = nil)
  if valid_402657373 != nil:
    section.add "LoggerDefinitionId", valid_402657373
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
  var valid_402657374 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-Security-Token", valid_402657374
  var valid_402657375 = header.getOrDefault("X-Amz-Signature")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-Signature", valid_402657375
  var valid_402657376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657376 = validateParameter(valid_402657376, JString,
                                      required = false, default = nil)
  if valid_402657376 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657376
  var valid_402657377 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-Algorithm", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Date")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Date", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-Credential")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Credential", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657380
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

proc call*(call_402657382: Call_UpdateLoggerDefinition_402657370;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a logger definition.
                                                                                         ## 
  let valid = call_402657382.validator(path, query, header, formData, body, _)
  let scheme = call_402657382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657382.makeUrl(scheme.get, call_402657382.host, call_402657382.base,
                                   call_402657382.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657382, uri, valid, _)

proc call*(call_402657383: Call_UpdateLoggerDefinition_402657370;
           LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
                                 ##                     : The ID of the logger definition.
  ##   
                                                                                          ## body: JObject (required)
  var path_402657384 = newJObject()
  var body_402657385 = newJObject()
  add(path_402657384, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_402657385 = body
  result = call_402657383.call(path_402657384, nil, nil, nil, body_402657385)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_402657370(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_402657371, base: "/",
    makeUrl: url_UpdateLoggerDefinition_402657372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_402657356 = ref object of OpenApiRestCall_402656035
proc url_GetLoggerDefinition_402657358(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
         "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
                 (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLoggerDefinition_402657357(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402657359 = path.getOrDefault("LoggerDefinitionId")
  valid_402657359 = validateParameter(valid_402657359, JString, required = true,
                                      default = nil)
  if valid_402657359 != nil:
    section.add "LoggerDefinitionId", valid_402657359
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
  var valid_402657360 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657360 = validateParameter(valid_402657360, JString,
                                      required = false, default = nil)
  if valid_402657360 != nil:
    section.add "X-Amz-Security-Token", valid_402657360
  var valid_402657361 = header.getOrDefault("X-Amz-Signature")
  valid_402657361 = validateParameter(valid_402657361, JString,
                                      required = false, default = nil)
  if valid_402657361 != nil:
    section.add "X-Amz-Signature", valid_402657361
  var valid_402657362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657362 = validateParameter(valid_402657362, JString,
                                      required = false, default = nil)
  if valid_402657362 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Algorithm", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-Date")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Date", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Credential")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Credential", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657367: Call_GetLoggerDefinition_402657356;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a logger definition.
                                                                                         ## 
  let valid = call_402657367.validator(path, query, header, formData, body, _)
  let scheme = call_402657367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657367.makeUrl(scheme.get, call_402657367.host, call_402657367.base,
                                   call_402657367.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657367, uri, valid, _)

proc call*(call_402657368: Call_GetLoggerDefinition_402657356;
           LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
                                                     ##                     : The ID of the logger definition.
  var path_402657369 = newJObject()
  add(path_402657369, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_402657368.call(path_402657369, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_402657356(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_402657357, base: "/",
    makeUrl: url_GetLoggerDefinition_402657358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_402657386 = ref object of OpenApiRestCall_402656035
proc url_DeleteLoggerDefinition_402657388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
         "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
                 (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLoggerDefinition_402657387(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402657389 = path.getOrDefault("LoggerDefinitionId")
  valid_402657389 = validateParameter(valid_402657389, JString, required = true,
                                      default = nil)
  if valid_402657389 != nil:
    section.add "LoggerDefinitionId", valid_402657389
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
  var valid_402657390 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-Security-Token", valid_402657390
  var valid_402657391 = header.getOrDefault("X-Amz-Signature")
  valid_402657391 = validateParameter(valid_402657391, JString,
                                      required = false, default = nil)
  if valid_402657391 != nil:
    section.add "X-Amz-Signature", valid_402657391
  var valid_402657392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657392 = validateParameter(valid_402657392, JString,
                                      required = false, default = nil)
  if valid_402657392 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657392
  var valid_402657393 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "X-Amz-Algorithm", valid_402657393
  var valid_402657394 = header.getOrDefault("X-Amz-Date")
  valid_402657394 = validateParameter(valid_402657394, JString,
                                      required = false, default = nil)
  if valid_402657394 != nil:
    section.add "X-Amz-Date", valid_402657394
  var valid_402657395 = header.getOrDefault("X-Amz-Credential")
  valid_402657395 = validateParameter(valid_402657395, JString,
                                      required = false, default = nil)
  if valid_402657395 != nil:
    section.add "X-Amz-Credential", valid_402657395
  var valid_402657396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657397: Call_DeleteLoggerDefinition_402657386;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a logger definition.
                                                                                         ## 
  let valid = call_402657397.validator(path, query, header, formData, body, _)
  let scheme = call_402657397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657397.makeUrl(scheme.get, call_402657397.host, call_402657397.base,
                                   call_402657397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657397, uri, valid, _)

proc call*(call_402657398: Call_DeleteLoggerDefinition_402657386;
           LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
                                 ##                     : The ID of the logger definition.
  var path_402657399 = newJObject()
  add(path_402657399, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_402657398.call(path_402657399, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_402657386(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_402657387, base: "/",
    makeUrl: url_DeleteLoggerDefinition_402657388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_402657414 = ref object of OpenApiRestCall_402656035
proc url_UpdateResourceDefinition_402657416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
         "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
                 (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResourceDefinition_402657415(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a resource definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
                                 ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_402657417 = path.getOrDefault("ResourceDefinitionId")
  valid_402657417 = validateParameter(valid_402657417, JString, required = true,
                                      default = nil)
  if valid_402657417 != nil:
    section.add "ResourceDefinitionId", valid_402657417
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
  var valid_402657418 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Security-Token", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Signature")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Signature", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Algorithm", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Date")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Date", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Credential")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Credential", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657424
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

proc call*(call_402657426: Call_UpdateResourceDefinition_402657414;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a resource definition.
                                                                                         ## 
  let valid = call_402657426.validator(path, query, header, formData, body, _)
  let scheme = call_402657426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657426.makeUrl(scheme.get, call_402657426.host, call_402657426.base,
                                   call_402657426.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657426, uri, valid, _)

proc call*(call_402657427: Call_UpdateResourceDefinition_402657414;
           body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
                               ##                       : The ID of the resource definition.
  var path_402657428 = newJObject()
  var body_402657429 = newJObject()
  if body != nil:
    body_402657429 = body
  add(path_402657428, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657427.call(path_402657428, nil, nil, nil, body_402657429)

var updateResourceDefinition* = Call_UpdateResourceDefinition_402657414(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_402657415, base: "/",
    makeUrl: url_UpdateResourceDefinition_402657416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_402657400 = ref object of OpenApiRestCall_402656035
proc url_GetResourceDefinition_402657402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
         "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
                 (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinition_402657401(path: JsonNode; query: JsonNode;
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
  var valid_402657403 = path.getOrDefault("ResourceDefinitionId")
  valid_402657403 = validateParameter(valid_402657403, JString, required = true,
                                      default = nil)
  if valid_402657403 != nil:
    section.add "ResourceDefinitionId", valid_402657403
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
  var valid_402657404 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Security-Token", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Signature")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Signature", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-Algorithm", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-Date")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Date", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-Credential")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Credential", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657411: Call_GetResourceDefinition_402657400;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
                                                                                         ## 
  let valid = call_402657411.validator(path, query, header, formData, body, _)
  let scheme = call_402657411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657411.makeUrl(scheme.get, call_402657411.host, call_402657411.base,
                                   call_402657411.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657411, uri, valid, _)

proc call*(call_402657412: Call_GetResourceDefinition_402657400;
           ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   
                                                                                                       ## ResourceDefinitionId: string (required)
                                                                                                       ##                       
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## ID 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## resource 
                                                                                                       ## definition.
  var path_402657413 = newJObject()
  add(path_402657413, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657412.call(path_402657413, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_402657400(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_402657401, base: "/",
    makeUrl: url_GetResourceDefinition_402657402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_402657430 = ref object of OpenApiRestCall_402656035
proc url_DeleteResourceDefinition_402657432(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
         "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
                 (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResourceDefinition_402657431(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a resource definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
                                 ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_402657433 = path.getOrDefault("ResourceDefinitionId")
  valid_402657433 = validateParameter(valid_402657433, JString, required = true,
                                      default = nil)
  if valid_402657433 != nil:
    section.add "ResourceDefinitionId", valid_402657433
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
  var valid_402657434 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Security-Token", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-Signature")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-Signature", valid_402657435
  var valid_402657436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657436
  var valid_402657437 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Algorithm", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Date")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Date", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Credential")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Credential", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657441: Call_DeleteResourceDefinition_402657430;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a resource definition.
                                                                                         ## 
  let valid = call_402657441.validator(path, query, header, formData, body, _)
  let scheme = call_402657441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657441.makeUrl(scheme.get, call_402657441.host, call_402657441.base,
                                   call_402657441.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657441, uri, valid, _)

proc call*(call_402657442: Call_DeleteResourceDefinition_402657430;
           ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
                                   ##                       : The ID of the resource definition.
  var path_402657443 = newJObject()
  add(path_402657443, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657442.call(path_402657443, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_402657430(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_402657431, base: "/",
    makeUrl: url_DeleteResourceDefinition_402657432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_402657458 = ref object of OpenApiRestCall_402656035
proc url_UpdateSubscriptionDefinition_402657460(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_402657459(path: JsonNode;
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
  var valid_402657461 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657461 = validateParameter(valid_402657461, JString, required = true,
                                      default = nil)
  if valid_402657461 != nil:
    section.add "SubscriptionDefinitionId", valid_402657461
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
  var valid_402657462 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "X-Amz-Security-Token", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-Signature")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Signature", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Algorithm", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Date")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Date", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Credential")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Credential", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657468
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

proc call*(call_402657470: Call_UpdateSubscriptionDefinition_402657458;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a subscription definition.
                                                                                         ## 
  let valid = call_402657470.validator(path, query, header, formData, body, _)
  let scheme = call_402657470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657470.makeUrl(scheme.get, call_402657470.host, call_402657470.base,
                                   call_402657470.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657470, uri, valid, _)

proc call*(call_402657471: Call_UpdateSubscriptionDefinition_402657458;
           body: JsonNode; SubscriptionDefinitionId: string): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   body: JObject (required)
  ##   SubscriptionDefinitionId: string (required)
                               ##                           : The ID of the subscription definition.
  var path_402657472 = newJObject()
  var body_402657473 = newJObject()
  if body != nil:
    body_402657473 = body
  add(path_402657472, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657471.call(path_402657472, nil, nil, nil, body_402657473)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_402657458(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_402657459, base: "/",
    makeUrl: url_UpdateSubscriptionDefinition_402657460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_402657444 = ref object of OpenApiRestCall_402656035
proc url_GetSubscriptionDefinition_402657446(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_402657445(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a subscription definition.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
                                 ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_402657447 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657447 = validateParameter(valid_402657447, JString, required = true,
                                      default = nil)
  if valid_402657447 != nil:
    section.add "SubscriptionDefinitionId", valid_402657447
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
  var valid_402657448 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Security-Token", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Signature")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Signature", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Algorithm", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Date")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Date", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Credential")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Credential", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657455: Call_GetSubscriptionDefinition_402657444;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a subscription definition.
                                                                                         ## 
  let valid = call_402657455.validator(path, query, header, formData, body, _)
  let scheme = call_402657455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657455.makeUrl(scheme.get, call_402657455.host, call_402657455.base,
                                   call_402657455.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657455, uri, valid, _)

proc call*(call_402657456: Call_GetSubscriptionDefinition_402657444;
           SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   
                                                           ## SubscriptionDefinitionId: string (required)
                                                           ##                           
                                                           ## : 
                                                           ## The ID of the subscription definition.
  var path_402657457 = newJObject()
  add(path_402657457, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657456.call(path_402657457, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_402657444(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_402657445, base: "/",
    makeUrl: url_GetSubscriptionDefinition_402657446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_402657474 = ref object of OpenApiRestCall_402656035
proc url_DeleteSubscriptionDefinition_402657476(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_402657475(path: JsonNode;
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
  var valid_402657477 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657477 = validateParameter(valid_402657477, JString, required = true,
                                      default = nil)
  if valid_402657477 != nil:
    section.add "SubscriptionDefinitionId", valid_402657477
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
  var valid_402657478 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "X-Amz-Security-Token", valid_402657478
  var valid_402657479 = header.getOrDefault("X-Amz-Signature")
  valid_402657479 = validateParameter(valid_402657479, JString,
                                      required = false, default = nil)
  if valid_402657479 != nil:
    section.add "X-Amz-Signature", valid_402657479
  var valid_402657480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657480 = validateParameter(valid_402657480, JString,
                                      required = false, default = nil)
  if valid_402657480 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657480
  var valid_402657481 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657481 = validateParameter(valid_402657481, JString,
                                      required = false, default = nil)
  if valid_402657481 != nil:
    section.add "X-Amz-Algorithm", valid_402657481
  var valid_402657482 = header.getOrDefault("X-Amz-Date")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "X-Amz-Date", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Credential")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Credential", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657485: Call_DeleteSubscriptionDefinition_402657474;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a subscription definition.
                                                                                         ## 
  let valid = call_402657485.validator(path, query, header, formData, body, _)
  let scheme = call_402657485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657485.makeUrl(scheme.get, call_402657485.host, call_402657485.base,
                                   call_402657485.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657485, uri, valid, _)

proc call*(call_402657486: Call_DeleteSubscriptionDefinition_402657474;
           SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
                                       ##                           : The ID of the subscription definition.
  var path_402657487 = newJObject()
  add(path_402657487, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657486.call(path_402657487, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_402657474(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_402657475, base: "/",
    makeUrl: url_DeleteSubscriptionDefinition_402657476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_402657488 = ref object of OpenApiRestCall_402656035
proc url_GetBulkDeploymentStatus_402657490(protocol: Scheme; host: string;
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

proc validate_GetBulkDeploymentStatus_402657489(path: JsonNode; query: JsonNode;
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
  var valid_402657491 = path.getOrDefault("BulkDeploymentId")
  valid_402657491 = validateParameter(valid_402657491, JString, required = true,
                                      default = nil)
  if valid_402657491 != nil:
    section.add "BulkDeploymentId", valid_402657491
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
  var valid_402657492 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-Security-Token", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-Signature")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-Signature", valid_402657493
  var valid_402657494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657494 = validateParameter(valid_402657494, JString,
                                      required = false, default = nil)
  if valid_402657494 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657494
  var valid_402657495 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657495 = validateParameter(valid_402657495, JString,
                                      required = false, default = nil)
  if valid_402657495 != nil:
    section.add "X-Amz-Algorithm", valid_402657495
  var valid_402657496 = header.getOrDefault("X-Amz-Date")
  valid_402657496 = validateParameter(valid_402657496, JString,
                                      required = false, default = nil)
  if valid_402657496 != nil:
    section.add "X-Amz-Date", valid_402657496
  var valid_402657497 = header.getOrDefault("X-Amz-Credential")
  valid_402657497 = validateParameter(valid_402657497, JString,
                                      required = false, default = nil)
  if valid_402657497 != nil:
    section.add "X-Amz-Credential", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657499: Call_GetBulkDeploymentStatus_402657488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the status of a bulk deployment.
                                                                                         ## 
  let valid = call_402657499.validator(path, query, header, formData, body, _)
  let scheme = call_402657499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657499.makeUrl(scheme.get, call_402657499.host, call_402657499.base,
                                   call_402657499.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657499, uri, valid, _)

proc call*(call_402657500: Call_GetBulkDeploymentStatus_402657488;
           BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
                                             ##                   : The ID of the bulk deployment.
  var path_402657501 = newJObject()
  add(path_402657501, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_402657500.call(path_402657501, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_402657488(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_402657489, base: "/",
    makeUrl: url_GetBulkDeploymentStatus_402657490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_402657516 = ref object of OpenApiRestCall_402656035
proc url_UpdateConnectivityInfo_402657518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateConnectivityInfo_402657517(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `ThingName` field"
  var valid_402657519 = path.getOrDefault("ThingName")
  valid_402657519 = validateParameter(valid_402657519, JString, required = true,
                                      default = nil)
  if valid_402657519 != nil:
    section.add "ThingName", valid_402657519
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
  var valid_402657520 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657520 = validateParameter(valid_402657520, JString,
                                      required = false, default = nil)
  if valid_402657520 != nil:
    section.add "X-Amz-Security-Token", valid_402657520
  var valid_402657521 = header.getOrDefault("X-Amz-Signature")
  valid_402657521 = validateParameter(valid_402657521, JString,
                                      required = false, default = nil)
  if valid_402657521 != nil:
    section.add "X-Amz-Signature", valid_402657521
  var valid_402657522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657522
  var valid_402657523 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657523 = validateParameter(valid_402657523, JString,
                                      required = false, default = nil)
  if valid_402657523 != nil:
    section.add "X-Amz-Algorithm", valid_402657523
  var valid_402657524 = header.getOrDefault("X-Amz-Date")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Date", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Credential")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Credential", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657526
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

proc call*(call_402657528: Call_UpdateConnectivityInfo_402657516;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
                                                                                         ## 
  let valid = call_402657528.validator(path, query, header, formData, body, _)
  let scheme = call_402657528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657528.makeUrl(scheme.get, call_402657528.host, call_402657528.base,
                                   call_402657528.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657528, uri, valid, _)

proc call*(call_402657529: Call_UpdateConnectivityInfo_402657516;
           body: JsonNode; ThingName: string): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   
                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                      ## ThingName: string (required)
                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                      ## thing 
                                                                                                                                                                                                                                      ## name.
  var path_402657530 = newJObject()
  var body_402657531 = newJObject()
  if body != nil:
    body_402657531 = body
  add(path_402657530, "ThingName", newJString(ThingName))
  result = call_402657529.call(path_402657530, nil, nil, nil, body_402657531)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_402657516(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_402657517, base: "/",
    makeUrl: url_UpdateConnectivityInfo_402657518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_402657502 = ref object of OpenApiRestCall_402656035
proc url_GetConnectivityInfo_402657504(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetConnectivityInfo_402657503(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `ThingName` field"
  var valid_402657505 = path.getOrDefault("ThingName")
  valid_402657505 = validateParameter(valid_402657505, JString, required = true,
                                      default = nil)
  if valid_402657505 != nil:
    section.add "ThingName", valid_402657505
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
  var valid_402657506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "X-Amz-Security-Token", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-Signature")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-Signature", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657508
  var valid_402657509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657509 = validateParameter(valid_402657509, JString,
                                      required = false, default = nil)
  if valid_402657509 != nil:
    section.add "X-Amz-Algorithm", valid_402657509
  var valid_402657510 = header.getOrDefault("X-Amz-Date")
  valid_402657510 = validateParameter(valid_402657510, JString,
                                      required = false, default = nil)
  if valid_402657510 != nil:
    section.add "X-Amz-Date", valid_402657510
  var valid_402657511 = header.getOrDefault("X-Amz-Credential")
  valid_402657511 = validateParameter(valid_402657511, JString,
                                      required = false, default = nil)
  if valid_402657511 != nil:
    section.add "X-Amz-Credential", valid_402657511
  var valid_402657512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657513: Call_GetConnectivityInfo_402657502;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the connectivity information for a core.
                                                                                         ## 
  let valid = call_402657513.validator(path, query, header, formData, body, _)
  let scheme = call_402657513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657513.makeUrl(scheme.get, call_402657513.host, call_402657513.base,
                                   call_402657513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657513, uri, valid, _)

proc call*(call_402657514: Call_GetConnectivityInfo_402657502; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
                                                       ##            : The thing name.
  var path_402657515 = newJObject()
  add(path_402657515, "ThingName", newJString(ThingName))
  result = call_402657514.call(path_402657515, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_402657502(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_402657503, base: "/",
    makeUrl: url_GetConnectivityInfo_402657504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_402657532 = ref object of OpenApiRestCall_402656035
proc url_GetConnectorDefinitionVersion_402657534(protocol: Scheme; host: string;
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
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/connectors/"),
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

proc validate_GetConnectorDefinitionVersion_402657533(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
                                 ##                        : The ID of the connector definition.
  ##   
                                                                                                ## ConnectorDefinitionVersionId: JString (required)
                                                                                                ##                               
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## ID 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## connector 
                                                                                                ## definition 
                                                                                                ## version. 
                                                                                                ## This 
                                                                                                ## value 
                                                                                                ## maps 
                                                                                                ## to 
                                                                                                ## the 
                                                                                                ## ''Version'' 
                                                                                                ## property 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## corresponding 
                                                                                                ## ''VersionInformation'' 
                                                                                                ## object, 
                                                                                                ## which 
                                                                                                ## is 
                                                                                                ## returned 
                                                                                                ## by 
                                                                                                ## ''ListConnectorDefinitionVersions'' 
                                                                                                ## requests. 
                                                                                                ## If 
                                                                                                ## the 
                                                                                                ## version 
                                                                                                ## is 
                                                                                                ## the 
                                                                                                ## last 
                                                                                                ## one 
                                                                                                ## that 
                                                                                                ## was 
                                                                                                ## associated 
                                                                                                ## with 
                                                                                                ## a 
                                                                                                ## connector 
                                                                                                ## definition, 
                                                                                                ## the 
                                                                                                ## value 
                                                                                                ## also 
                                                                                                ## maps 
                                                                                                ## to 
                                                                                                ## the 
                                                                                                ## ''LatestVersion'' 
                                                                                                ## property 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## corresponding 
                                                                                                ## ''DefinitionInformation'' 
                                                                                                ## object.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_402657535 = path.getOrDefault("ConnectorDefinitionId")
  valid_402657535 = validateParameter(valid_402657535, JString, required = true,
                                      default = nil)
  if valid_402657535 != nil:
    section.add "ConnectorDefinitionId", valid_402657535
  var valid_402657536 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_402657536 = validateParameter(valid_402657536, JString, required = true,
                                      default = nil)
  if valid_402657536 != nil:
    section.add "ConnectorDefinitionVersionId", valid_402657536
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_402657537 = query.getOrDefault("NextToken")
  valid_402657537 = validateParameter(valid_402657537, JString,
                                      required = false, default = nil)
  if valid_402657537 != nil:
    section.add "NextToken", valid_402657537
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
  var valid_402657538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657538 = validateParameter(valid_402657538, JString,
                                      required = false, default = nil)
  if valid_402657538 != nil:
    section.add "X-Amz-Security-Token", valid_402657538
  var valid_402657539 = header.getOrDefault("X-Amz-Signature")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "X-Amz-Signature", valid_402657539
  var valid_402657540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657540
  var valid_402657541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Algorithm", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Date")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Date", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Credential")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Credential", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657545: Call_GetConnectorDefinitionVersion_402657532;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
                                                                                         ## 
  let valid = call_402657545.validator(path, query, header, formData, body, _)
  let scheme = call_402657545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657545.makeUrl(scheme.get, call_402657545.host, call_402657545.base,
                                   call_402657545.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657545, uri, valid, _)

proc call*(call_402657546: Call_GetConnectorDefinitionVersion_402657532;
           ConnectorDefinitionId: string; ConnectorDefinitionVersionId: string;
           NextToken: string = ""): Recallable =
  ## getConnectorDefinitionVersion
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ##   
                                                                                                                                                                                                                                              ## ConnectorDefinitionId: string (required)
                                                                                                                                                                                                                                              ##                        
                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                              ## connector 
                                                                                                                                                                                                                                              ## definition.
  ##   
                                                                                                                                                                                                                                                            ## ConnectorDefinitionVersionId: string (required)
                                                                                                                                                                                                                                                            ##                               
                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## connector 
                                                                                                                                                                                                                                                            ## definition 
                                                                                                                                                                                                                                                            ## version. 
                                                                                                                                                                                                                                                            ## This 
                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                            ## maps 
                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## ''Version'' 
                                                                                                                                                                                                                                                            ## property 
                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## corresponding 
                                                                                                                                                                                                                                                            ## ''VersionInformation'' 
                                                                                                                                                                                                                                                            ## object, 
                                                                                                                                                                                                                                                            ## which 
                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                                            ## ''ListConnectorDefinitionVersions'' 
                                                                                                                                                                                                                                                            ## requests. 
                                                                                                                                                                                                                                                            ## If 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## version 
                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## last 
                                                                                                                                                                                                                                                            ## one 
                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                            ## was 
                                                                                                                                                                                                                                                            ## associated 
                                                                                                                                                                                                                                                            ## with 
                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                            ## connector 
                                                                                                                                                                                                                                                            ## definition, 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                            ## also 
                                                                                                                                                                                                                                                            ## maps 
                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## ''LatestVersion'' 
                                                                                                                                                                                                                                                            ## property 
                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## corresponding 
                                                                                                                                                                                                                                                            ## ''DefinitionInformation'' 
                                                                                                                                                                                                                                                            ## object.
  ##   
                                                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                      ## token 
                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## next 
                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                      ## results, 
                                                                                                                                                                                                                                                                      ## or 
                                                                                                                                                                                                                                                                      ## ''null'' 
                                                                                                                                                                                                                                                                      ## if 
                                                                                                                                                                                                                                                                      ## there 
                                                                                                                                                                                                                                                                      ## are 
                                                                                                                                                                                                                                                                      ## no 
                                                                                                                                                                                                                                                                      ## additional 
                                                                                                                                                                                                                                                                      ## results.
  var path_402657547 = newJObject()
  var query_402657548 = newJObject()
  add(path_402657547, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(path_402657547, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_402657548, "NextToken", newJString(NextToken))
  result = call_402657546.call(path_402657547, query_402657548, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_402657532(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_402657533, base: "/",
    makeUrl: url_GetConnectorDefinitionVersion_402657534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_402657549 = ref object of OpenApiRestCall_402656035
proc url_GetCoreDefinitionVersion_402657551(protocol: Scheme; host: string;
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

proc validate_GetCoreDefinitionVersion_402657550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a core definition version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionId: JString (required)
                                 ##                   : The ID of the core definition.
  ##   
                                                                                      ## CoreDefinitionVersionId: JString (required)
                                                                                      ##                          
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## ID 
                                                                                      ## of 
                                                                                      ## the 
                                                                                      ## core 
                                                                                      ## definition 
                                                                                      ## version. 
                                                                                      ## This 
                                                                                      ## value 
                                                                                      ## maps 
                                                                                      ## to 
                                                                                      ## the 
                                                                                      ## ''Version'' 
                                                                                      ## property 
                                                                                      ## of 
                                                                                      ## the 
                                                                                      ## corresponding 
                                                                                      ## ''VersionInformation'' 
                                                                                      ## object, 
                                                                                      ## which 
                                                                                      ## is 
                                                                                      ## returned 
                                                                                      ## by 
                                                                                      ## ''ListCoreDefinitionVersions'' 
                                                                                      ## requests. 
                                                                                      ## If 
                                                                                      ## the 
                                                                                      ## version 
                                                                                      ## is 
                                                                                      ## the 
                                                                                      ## last 
                                                                                      ## one 
                                                                                      ## that 
                                                                                      ## was 
                                                                                      ## associated 
                                                                                      ## with 
                                                                                      ## a 
                                                                                      ## core 
                                                                                      ## definition, 
                                                                                      ## the 
                                                                                      ## value 
                                                                                      ## also 
                                                                                      ## maps 
                                                                                      ## to 
                                                                                      ## the 
                                                                                      ## ''LatestVersion'' 
                                                                                      ## property 
                                                                                      ## of 
                                                                                      ## the 
                                                                                      ## corresponding 
                                                                                      ## ''DefinitionInformation'' 
                                                                                      ## object.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `CoreDefinitionId` field"
  var valid_402657552 = path.getOrDefault("CoreDefinitionId")
  valid_402657552 = validateParameter(valid_402657552, JString, required = true,
                                      default = nil)
  if valid_402657552 != nil:
    section.add "CoreDefinitionId", valid_402657552
  var valid_402657553 = path.getOrDefault("CoreDefinitionVersionId")
  valid_402657553 = validateParameter(valid_402657553, JString, required = true,
                                      default = nil)
  if valid_402657553 != nil:
    section.add "CoreDefinitionVersionId", valid_402657553
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
  var valid_402657554 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657554 = validateParameter(valid_402657554, JString,
                                      required = false, default = nil)
  if valid_402657554 != nil:
    section.add "X-Amz-Security-Token", valid_402657554
  var valid_402657555 = header.getOrDefault("X-Amz-Signature")
  valid_402657555 = validateParameter(valid_402657555, JString,
                                      required = false, default = nil)
  if valid_402657555 != nil:
    section.add "X-Amz-Signature", valid_402657555
  var valid_402657556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657556 = validateParameter(valid_402657556, JString,
                                      required = false, default = nil)
  if valid_402657556 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657556
  var valid_402657557 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657557 = validateParameter(valid_402657557, JString,
                                      required = false, default = nil)
  if valid_402657557 != nil:
    section.add "X-Amz-Algorithm", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-Date")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-Date", valid_402657558
  var valid_402657559 = header.getOrDefault("X-Amz-Credential")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-Credential", valid_402657559
  var valid_402657560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657561: Call_GetCoreDefinitionVersion_402657549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a core definition version.
                                                                                         ## 
  let valid = call_402657561.validator(path, query, header, formData, body, _)
  let scheme = call_402657561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657561.makeUrl(scheme.get, call_402657561.host, call_402657561.base,
                                   call_402657561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657561, uri, valid, _)

proc call*(call_402657562: Call_GetCoreDefinitionVersion_402657549;
           CoreDefinitionId: string; CoreDefinitionVersionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
                                                           ##                   : The ID of the core definition.
  ##   
                                                                                                                ## CoreDefinitionVersionId: string (required)
                                                                                                                ##                          
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## ID 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## core 
                                                                                                                ## definition 
                                                                                                                ## version. 
                                                                                                                ## This 
                                                                                                                ## value 
                                                                                                                ## maps 
                                                                                                                ## to 
                                                                                                                ## the 
                                                                                                                ## ''Version'' 
                                                                                                                ## property 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## corresponding 
                                                                                                                ## ''VersionInformation'' 
                                                                                                                ## object, 
                                                                                                                ## which 
                                                                                                                ## is 
                                                                                                                ## returned 
                                                                                                                ## by 
                                                                                                                ## ''ListCoreDefinitionVersions'' 
                                                                                                                ## requests. 
                                                                                                                ## If 
                                                                                                                ## the 
                                                                                                                ## version 
                                                                                                                ## is 
                                                                                                                ## the 
                                                                                                                ## last 
                                                                                                                ## one 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## associated 
                                                                                                                ## with 
                                                                                                                ## a 
                                                                                                                ## core 
                                                                                                                ## definition, 
                                                                                                                ## the 
                                                                                                                ## value 
                                                                                                                ## also 
                                                                                                                ## maps 
                                                                                                                ## to 
                                                                                                                ## the 
                                                                                                                ## ''LatestVersion'' 
                                                                                                                ## property 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## corresponding 
                                                                                                                ## ''DefinitionInformation'' 
                                                                                                                ## object.
  var path_402657563 = newJObject()
  add(path_402657563, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(path_402657563, "CoreDefinitionVersionId",
      newJString(CoreDefinitionVersionId))
  result = call_402657562.call(path_402657563, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_402657549(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_402657550, base: "/",
    makeUrl: url_GetCoreDefinitionVersion_402657551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_402657564 = ref object of OpenApiRestCall_402656035
proc url_GetDeploymentStatus_402657566(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetDeploymentStatus_402657565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the status of a deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  ##   
                                                                              ## DeploymentId: JString (required)
                                                                              ##               
                                                                              ## : 
                                                                              ## The 
                                                                              ## ID 
                                                                              ## of 
                                                                              ## the 
                                                                              ## deployment.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657567 = path.getOrDefault("GroupId")
  valid_402657567 = validateParameter(valid_402657567, JString, required = true,
                                      default = nil)
  if valid_402657567 != nil:
    section.add "GroupId", valid_402657567
  var valid_402657568 = path.getOrDefault("DeploymentId")
  valid_402657568 = validateParameter(valid_402657568, JString, required = true,
                                      default = nil)
  if valid_402657568 != nil:
    section.add "DeploymentId", valid_402657568
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
  var valid_402657569 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657569 = validateParameter(valid_402657569, JString,
                                      required = false, default = nil)
  if valid_402657569 != nil:
    section.add "X-Amz-Security-Token", valid_402657569
  var valid_402657570 = header.getOrDefault("X-Amz-Signature")
  valid_402657570 = validateParameter(valid_402657570, JString,
                                      required = false, default = nil)
  if valid_402657570 != nil:
    section.add "X-Amz-Signature", valid_402657570
  var valid_402657571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657571 = validateParameter(valid_402657571, JString,
                                      required = false, default = nil)
  if valid_402657571 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657571
  var valid_402657572 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657572 = validateParameter(valid_402657572, JString,
                                      required = false, default = nil)
  if valid_402657572 != nil:
    section.add "X-Amz-Algorithm", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-Date")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-Date", valid_402657573
  var valid_402657574 = header.getOrDefault("X-Amz-Credential")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-Credential", valid_402657574
  var valid_402657575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657576: Call_GetDeploymentStatus_402657564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the status of a deployment.
                                                                                         ## 
  let valid = call_402657576.validator(path, query, header, formData, body, _)
  let scheme = call_402657576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657576.makeUrl(scheme.get, call_402657576.host, call_402657576.base,
                                   call_402657576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657576, uri, valid, _)

proc call*(call_402657577: Call_GetDeploymentStatus_402657564; GroupId: string;
           DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
                                        ##          : The ID of the Greengrass group.
  ##   
                                                                                     ## DeploymentId: string (required)
                                                                                     ##               
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## ID 
                                                                                     ## of 
                                                                                     ## the 
                                                                                     ## deployment.
  var path_402657578 = newJObject()
  add(path_402657578, "GroupId", newJString(GroupId))
  add(path_402657578, "DeploymentId", newJString(DeploymentId))
  result = call_402657577.call(path_402657578, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_402657564(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_402657565, base: "/",
    makeUrl: url_GetDeploymentStatus_402657566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_402657579 = ref object of OpenApiRestCall_402656035
proc url_GetDeviceDefinitionVersion_402657581(protocol: Scheme; host: string;
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
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/devices/"),
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

proc validate_GetDeviceDefinitionVersion_402657580(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a device definition version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeviceDefinitionId: JString (required)
                                 ##                     : The ID of the device definition.
  ##   
                                                                                          ## DeviceDefinitionVersionId: JString (required)
                                                                                          ##                            
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## ID 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## device 
                                                                                          ## definition 
                                                                                          ## version. 
                                                                                          ## This 
                                                                                          ## value 
                                                                                          ## maps 
                                                                                          ## to 
                                                                                          ## the 
                                                                                          ## ''Version'' 
                                                                                          ## property 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## corresponding 
                                                                                          ## ''VersionInformation'' 
                                                                                          ## object, 
                                                                                          ## which 
                                                                                          ## is 
                                                                                          ## returned 
                                                                                          ## by 
                                                                                          ## ''ListDeviceDefinitionVersions'' 
                                                                                          ## requests. 
                                                                                          ## If 
                                                                                          ## the 
                                                                                          ## version 
                                                                                          ## is 
                                                                                          ## the 
                                                                                          ## last 
                                                                                          ## one 
                                                                                          ## that 
                                                                                          ## was 
                                                                                          ## associated 
                                                                                          ## with 
                                                                                          ## a 
                                                                                          ## device 
                                                                                          ## definition, 
                                                                                          ## the 
                                                                                          ## value 
                                                                                          ## also 
                                                                                          ## maps 
                                                                                          ## to 
                                                                                          ## the 
                                                                                          ## ''LatestVersion'' 
                                                                                          ## property 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## corresponding 
                                                                                          ## ''DefinitionInformation'' 
                                                                                          ## object.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeviceDefinitionId` field"
  var valid_402657582 = path.getOrDefault("DeviceDefinitionId")
  valid_402657582 = validateParameter(valid_402657582, JString, required = true,
                                      default = nil)
  if valid_402657582 != nil:
    section.add "DeviceDefinitionId", valid_402657582
  var valid_402657583 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_402657583 = validateParameter(valid_402657583, JString, required = true,
                                      default = nil)
  if valid_402657583 != nil:
    section.add "DeviceDefinitionVersionId", valid_402657583
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_402657584 = query.getOrDefault("NextToken")
  valid_402657584 = validateParameter(valid_402657584, JString,
                                      required = false, default = nil)
  if valid_402657584 != nil:
    section.add "NextToken", valid_402657584
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
  var valid_402657585 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657585 = validateParameter(valid_402657585, JString,
                                      required = false, default = nil)
  if valid_402657585 != nil:
    section.add "X-Amz-Security-Token", valid_402657585
  var valid_402657586 = header.getOrDefault("X-Amz-Signature")
  valid_402657586 = validateParameter(valid_402657586, JString,
                                      required = false, default = nil)
  if valid_402657586 != nil:
    section.add "X-Amz-Signature", valid_402657586
  var valid_402657587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657587 = validateParameter(valid_402657587, JString,
                                      required = false, default = nil)
  if valid_402657587 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-Algorithm", valid_402657588
  var valid_402657589 = header.getOrDefault("X-Amz-Date")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "X-Amz-Date", valid_402657589
  var valid_402657590 = header.getOrDefault("X-Amz-Credential")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "X-Amz-Credential", valid_402657590
  var valid_402657591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657591 = validateParameter(valid_402657591, JString,
                                      required = false, default = nil)
  if valid_402657591 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657592: Call_GetDeviceDefinitionVersion_402657579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a device definition version.
                                                                                         ## 
  let valid = call_402657592.validator(path, query, header, formData, body, _)
  let scheme = call_402657592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657592.makeUrl(scheme.get, call_402657592.host, call_402657592.base,
                                   call_402657592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657592, uri, valid, _)

proc call*(call_402657593: Call_GetDeviceDefinitionVersion_402657579;
           DeviceDefinitionId: string; DeviceDefinitionVersionId: string;
           NextToken: string = ""): Recallable =
  ## getDeviceDefinitionVersion
  ## Retrieves information about a device definition version.
  ##   DeviceDefinitionId: string (required)
                                                             ##                     : The ID of the device definition.
  ##   
                                                                                                                      ## DeviceDefinitionVersionId: string (required)
                                                                                                                      ##                            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## ID 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## device 
                                                                                                                      ## definition 
                                                                                                                      ## version. 
                                                                                                                      ## This 
                                                                                                                      ## value 
                                                                                                                      ## maps 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## ''Version'' 
                                                                                                                      ## property 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## corresponding 
                                                                                                                      ## ''VersionInformation'' 
                                                                                                                      ## object, 
                                                                                                                      ## which 
                                                                                                                      ## is 
                                                                                                                      ## returned 
                                                                                                                      ## by 
                                                                                                                      ## ''ListDeviceDefinitionVersions'' 
                                                                                                                      ## requests. 
                                                                                                                      ## If 
                                                                                                                      ## the 
                                                                                                                      ## version 
                                                                                                                      ## is 
                                                                                                                      ## the 
                                                                                                                      ## last 
                                                                                                                      ## one 
                                                                                                                      ## that 
                                                                                                                      ## was 
                                                                                                                      ## associated 
                                                                                                                      ## with 
                                                                                                                      ## a 
                                                                                                                      ## device 
                                                                                                                      ## definition, 
                                                                                                                      ## the 
                                                                                                                      ## value 
                                                                                                                      ## also 
                                                                                                                      ## maps 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## ''LatestVersion'' 
                                                                                                                      ## property 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## corresponding 
                                                                                                                      ## ''DefinitionInformation'' 
                                                                                                                      ## object.
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## token 
                                                                                                                                ## for 
                                                                                                                                ## the 
                                                                                                                                ## next 
                                                                                                                                ## set 
                                                                                                                                ## of 
                                                                                                                                ## results, 
                                                                                                                                ## or 
                                                                                                                                ## ''null'' 
                                                                                                                                ## if 
                                                                                                                                ## there 
                                                                                                                                ## are 
                                                                                                                                ## no 
                                                                                                                                ## additional 
                                                                                                                                ## results.
  var path_402657594 = newJObject()
  var query_402657595 = newJObject()
  add(path_402657594, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(path_402657594, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  add(query_402657595, "NextToken", newJString(NextToken))
  result = call_402657593.call(path_402657594, query_402657595, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_402657579(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_402657580, base: "/",
    makeUrl: url_GetDeviceDefinitionVersion_402657581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_402657596 = ref object of OpenApiRestCall_402656035
proc url_GetFunctionDefinitionVersion_402657598(protocol: Scheme; host: string;
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
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/functions/"),
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

proc validate_GetFunctionDefinitionVersion_402657597(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionVersionId: JString (required)
                                 ##                              : The ID of the function definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by 
                                 ## ''ListFunctionDefinitionVersions'' 
                                 ## requests. If the version is the last one that was 
                                 ## associated 
                                 ## with a function definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   
                                                                                                                                                                            ## FunctionDefinitionId: JString (required)
                                                                                                                                                                            ##                       
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## The 
                                                                                                                                                                            ## ID 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## the 
                                                                                                                                                                            ## Lambda 
                                                                                                                                                                            ## function 
                                                                                                                                                                            ## definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionVersionId` field"
  var valid_402657599 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_402657599 = validateParameter(valid_402657599, JString, required = true,
                                      default = nil)
  if valid_402657599 != nil:
    section.add "FunctionDefinitionVersionId", valid_402657599
  var valid_402657600 = path.getOrDefault("FunctionDefinitionId")
  valid_402657600 = validateParameter(valid_402657600, JString, required = true,
                                      default = nil)
  if valid_402657600 != nil:
    section.add "FunctionDefinitionId", valid_402657600
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_402657601 = query.getOrDefault("NextToken")
  valid_402657601 = validateParameter(valid_402657601, JString,
                                      required = false, default = nil)
  if valid_402657601 != nil:
    section.add "NextToken", valid_402657601
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
  var valid_402657602 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657602 = validateParameter(valid_402657602, JString,
                                      required = false, default = nil)
  if valid_402657602 != nil:
    section.add "X-Amz-Security-Token", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Signature")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Signature", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657604
  var valid_402657605 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "X-Amz-Algorithm", valid_402657605
  var valid_402657606 = header.getOrDefault("X-Amz-Date")
  valid_402657606 = validateParameter(valid_402657606, JString,
                                      required = false, default = nil)
  if valid_402657606 != nil:
    section.add "X-Amz-Date", valid_402657606
  var valid_402657607 = header.getOrDefault("X-Amz-Credential")
  valid_402657607 = validateParameter(valid_402657607, JString,
                                      required = false, default = nil)
  if valid_402657607 != nil:
    section.add "X-Amz-Credential", valid_402657607
  var valid_402657608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657609: Call_GetFunctionDefinitionVersion_402657596;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
                                                                                         ## 
  let valid = call_402657609.validator(path, query, header, formData, body, _)
  let scheme = call_402657609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657609.makeUrl(scheme.get, call_402657609.host, call_402657609.base,
                                   call_402657609.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657609, uri, valid, _)

proc call*(call_402657610: Call_GetFunctionDefinitionVersion_402657596;
           FunctionDefinitionVersionId: string; FunctionDefinitionId: string;
           NextToken: string = ""): Recallable =
  ## getFunctionDefinitionVersion
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ##   
                                                                                                                                                             ## FunctionDefinitionVersionId: string (required)
                                                                                                                                                             ##                              
                                                                                                                                                             ## : 
                                                                                                                                                             ## The 
                                                                                                                                                             ## ID 
                                                                                                                                                             ## of 
                                                                                                                                                             ## the 
                                                                                                                                                             ## function 
                                                                                                                                                             ## definition 
                                                                                                                                                             ## version. 
                                                                                                                                                             ## This 
                                                                                                                                                             ## value 
                                                                                                                                                             ## maps 
                                                                                                                                                             ## to 
                                                                                                                                                             ## the 
                                                                                                                                                             ## ''Version'' 
                                                                                                                                                             ## property 
                                                                                                                                                             ## of 
                                                                                                                                                             ## the 
                                                                                                                                                             ## corresponding 
                                                                                                                                                             ## ''VersionInformation'' 
                                                                                                                                                             ## object, 
                                                                                                                                                             ## which 
                                                                                                                                                             ## is 
                                                                                                                                                             ## returned 
                                                                                                                                                             ## by 
                                                                                                                                                             ## ''ListFunctionDefinitionVersions'' 
                                                                                                                                                             ## requests. 
                                                                                                                                                             ## If 
                                                                                                                                                             ## the 
                                                                                                                                                             ## version 
                                                                                                                                                             ## is 
                                                                                                                                                             ## the 
                                                                                                                                                             ## last 
                                                                                                                                                             ## one 
                                                                                                                                                             ## that 
                                                                                                                                                             ## was 
                                                                                                                                                             ## associated 
                                                                                                                                                             ## with 
                                                                                                                                                             ## a 
                                                                                                                                                             ## function 
                                                                                                                                                             ## definition, 
                                                                                                                                                             ## the 
                                                                                                                                                             ## value 
                                                                                                                                                             ## also 
                                                                                                                                                             ## maps 
                                                                                                                                                             ## to 
                                                                                                                                                             ## the 
                                                                                                                                                             ## ''LatestVersion'' 
                                                                                                                                                             ## property 
                                                                                                                                                             ## of 
                                                                                                                                                             ## the 
                                                                                                                                                             ## corresponding 
                                                                                                                                                             ## ''DefinitionInformation'' 
                                                                                                                                                             ## object.
  ##   
                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                       ##            
                                                                                                                                                                       ## : 
                                                                                                                                                                       ## The 
                                                                                                                                                                       ## token 
                                                                                                                                                                       ## for 
                                                                                                                                                                       ## the 
                                                                                                                                                                       ## next 
                                                                                                                                                                       ## set 
                                                                                                                                                                       ## of 
                                                                                                                                                                       ## results, 
                                                                                                                                                                       ## or 
                                                                                                                                                                       ## ''null'' 
                                                                                                                                                                       ## if 
                                                                                                                                                                       ## there 
                                                                                                                                                                       ## are 
                                                                                                                                                                       ## no 
                                                                                                                                                                       ## additional 
                                                                                                                                                                       ## results.
  ##   
                                                                                                                                                                                  ## FunctionDefinitionId: string (required)
                                                                                                                                                                                  ##                       
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## ID 
                                                                                                                                                                                  ## of 
                                                                                                                                                                                  ## the 
                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                  ## function 
                                                                                                                                                                                  ## definition.
  var path_402657611 = newJObject()
  var query_402657612 = newJObject()
  add(path_402657611, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_402657612, "NextToken", newJString(NextToken))
  add(path_402657611, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_402657610.call(path_402657611, query_402657612, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_402657596(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_402657597, base: "/",
    makeUrl: url_GetFunctionDefinitionVersion_402657598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_402657613 = ref object of OpenApiRestCall_402656035
proc url_GetGroupCertificateAuthority_402657615(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_402657614(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CertificateAuthorityId: JString (required)
                                 ##                         : The ID of the certificate authority.
  ##   
                                                                                                  ## GroupId: JString (required)
                                                                                                  ##          
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## ID 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## Greengrass 
                                                                                                  ## group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `CertificateAuthorityId` field"
  var valid_402657616 = path.getOrDefault("CertificateAuthorityId")
  valid_402657616 = validateParameter(valid_402657616, JString, required = true,
                                      default = nil)
  if valid_402657616 != nil:
    section.add "CertificateAuthorityId", valid_402657616
  var valid_402657617 = path.getOrDefault("GroupId")
  valid_402657617 = validateParameter(valid_402657617, JString, required = true,
                                      default = nil)
  if valid_402657617 != nil:
    section.add "GroupId", valid_402657617
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
  var valid_402657618 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "X-Amz-Security-Token", valid_402657618
  var valid_402657619 = header.getOrDefault("X-Amz-Signature")
  valid_402657619 = validateParameter(valid_402657619, JString,
                                      required = false, default = nil)
  if valid_402657619 != nil:
    section.add "X-Amz-Signature", valid_402657619
  var valid_402657620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657620 = validateParameter(valid_402657620, JString,
                                      required = false, default = nil)
  if valid_402657620 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657620
  var valid_402657621 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657621 = validateParameter(valid_402657621, JString,
                                      required = false, default = nil)
  if valid_402657621 != nil:
    section.add "X-Amz-Algorithm", valid_402657621
  var valid_402657622 = header.getOrDefault("X-Amz-Date")
  valid_402657622 = validateParameter(valid_402657622, JString,
                                      required = false, default = nil)
  if valid_402657622 != nil:
    section.add "X-Amz-Date", valid_402657622
  var valid_402657623 = header.getOrDefault("X-Amz-Credential")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-Credential", valid_402657623
  var valid_402657624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657625: Call_GetGroupCertificateAuthority_402657613;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
                                                                                         ## 
  let valid = call_402657625.validator(path, query, header, formData, body, _)
  let scheme = call_402657625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657625.makeUrl(scheme.get, call_402657625.host, call_402657625.base,
                                   call_402657625.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657625, uri, valid, _)

proc call*(call_402657626: Call_GetGroupCertificateAuthority_402657613;
           CertificateAuthorityId: string; GroupId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   
                                                                                ## CertificateAuthorityId: string (required)
                                                                                ##                         
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## certificate 
                                                                                ## authority.
  ##   
                                                                                             ## GroupId: string (required)
                                                                                             ##          
                                                                                             ## : 
                                                                                             ## The 
                                                                                             ## ID 
                                                                                             ## of 
                                                                                             ## the 
                                                                                             ## Greengrass 
                                                                                             ## group.
  var path_402657627 = newJObject()
  add(path_402657627, "CertificateAuthorityId",
      newJString(CertificateAuthorityId))
  add(path_402657627, "GroupId", newJString(GroupId))
  result = call_402657626.call(path_402657627, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_402657613(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_402657614, base: "/",
    makeUrl: url_GetGroupCertificateAuthority_402657615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_402657642 = ref object of OpenApiRestCall_402656035
proc url_UpdateGroupCertificateConfiguration_402657644(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
                 (kind: VariableSegment, value: "GroupId"), (
        kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroupCertificateConfiguration_402657643(path: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657645 = path.getOrDefault("GroupId")
  valid_402657645 = validateParameter(valid_402657645, JString, required = true,
                                      default = nil)
  if valid_402657645 != nil:
    section.add "GroupId", valid_402657645
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
  var valid_402657646 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657646 = validateParameter(valid_402657646, JString,
                                      required = false, default = nil)
  if valid_402657646 != nil:
    section.add "X-Amz-Security-Token", valid_402657646
  var valid_402657647 = header.getOrDefault("X-Amz-Signature")
  valid_402657647 = validateParameter(valid_402657647, JString,
                                      required = false, default = nil)
  if valid_402657647 != nil:
    section.add "X-Amz-Signature", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Algorithm", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-Date")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-Date", valid_402657650
  var valid_402657651 = header.getOrDefault("X-Amz-Credential")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Credential", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657652
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

proc call*(call_402657654: Call_UpdateGroupCertificateConfiguration_402657642;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the Certificate expiry time for a group.
                                                                                         ## 
  let valid = call_402657654.validator(path, query, header, formData, body, _)
  let scheme = call_402657654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657654.makeUrl(scheme.get, call_402657654.host, call_402657654.base,
                                   call_402657654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657654, uri, valid, _)

proc call*(call_402657655: Call_UpdateGroupCertificateConfiguration_402657642;
           body: JsonNode; GroupId: string): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   body: JObject (required)
  ##   GroupId: string (required)
                               ##          : The ID of the Greengrass group.
  var path_402657656 = newJObject()
  var body_402657657 = newJObject()
  if body != nil:
    body_402657657 = body
  add(path_402657656, "GroupId", newJString(GroupId))
  result = call_402657655.call(path_402657656, nil, nil, nil, body_402657657)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_402657642(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_402657643,
    base: "/", makeUrl: url_UpdateGroupCertificateConfiguration_402657644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_402657628 = ref object of OpenApiRestCall_402656035
proc url_GetGroupCertificateConfiguration_402657630(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
                 (kind: VariableSegment, value: "GroupId"), (
        kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupCertificateConfiguration_402657629(path: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657631 = path.getOrDefault("GroupId")
  valid_402657631 = validateParameter(valid_402657631, JString, required = true,
                                      default = nil)
  if valid_402657631 != nil:
    section.add "GroupId", valid_402657631
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
  var valid_402657632 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657632 = validateParameter(valid_402657632, JString,
                                      required = false, default = nil)
  if valid_402657632 != nil:
    section.add "X-Amz-Security-Token", valid_402657632
  var valid_402657633 = header.getOrDefault("X-Amz-Signature")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "X-Amz-Signature", valid_402657633
  var valid_402657634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657634 = validateParameter(valid_402657634, JString,
                                      required = false, default = nil)
  if valid_402657634 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657634
  var valid_402657635 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657635 = validateParameter(valid_402657635, JString,
                                      required = false, default = nil)
  if valid_402657635 != nil:
    section.add "X-Amz-Algorithm", valid_402657635
  var valid_402657636 = header.getOrDefault("X-Amz-Date")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "X-Amz-Date", valid_402657636
  var valid_402657637 = header.getOrDefault("X-Amz-Credential")
  valid_402657637 = validateParameter(valid_402657637, JString,
                                      required = false, default = nil)
  if valid_402657637 != nil:
    section.add "X-Amz-Credential", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657639: Call_GetGroupCertificateConfiguration_402657628;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
                                                                                         ## 
  let valid = call_402657639.validator(path, query, header, formData, body, _)
  let scheme = call_402657639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657639.makeUrl(scheme.get, call_402657639.host, call_402657639.base,
                                   call_402657639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657639, uri, valid, _)

proc call*(call_402657640: Call_GetGroupCertificateConfiguration_402657628;
           GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
                                                                      ##          : The ID of the Greengrass group.
  var path_402657641 = newJObject()
  add(path_402657641, "GroupId", newJString(GroupId))
  result = call_402657640.call(path_402657641, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_402657628(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_402657629, base: "/",
    makeUrl: url_GetGroupCertificateConfiguration_402657630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_402657658 = ref object of OpenApiRestCall_402656035
proc url_GetGroupVersion_402657660(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  assert "GroupVersionId" in path,
         "`GroupVersionId` is a required path parameter"
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

proc validate_GetGroupVersion_402657659(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## GroupId: JString (required)
                                                                                                                                                                                                                                                                                                                                                                                                                ##          
                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                ## Greengrass 
                                                                                                                                                                                                                                                                                                                                                                                                                ## group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupVersionId` field"
  var valid_402657661 = path.getOrDefault("GroupVersionId")
  valid_402657661 = validateParameter(valid_402657661, JString, required = true,
                                      default = nil)
  if valid_402657661 != nil:
    section.add "GroupVersionId", valid_402657661
  var valid_402657662 = path.getOrDefault("GroupId")
  valid_402657662 = validateParameter(valid_402657662, JString, required = true,
                                      default = nil)
  if valid_402657662 != nil:
    section.add "GroupId", valid_402657662
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
  var valid_402657663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Security-Token", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Signature")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Signature", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-Algorithm", valid_402657666
  var valid_402657667 = header.getOrDefault("X-Amz-Date")
  valid_402657667 = validateParameter(valid_402657667, JString,
                                      required = false, default = nil)
  if valid_402657667 != nil:
    section.add "X-Amz-Date", valid_402657667
  var valid_402657668 = header.getOrDefault("X-Amz-Credential")
  valid_402657668 = validateParameter(valid_402657668, JString,
                                      required = false, default = nil)
  if valid_402657668 != nil:
    section.add "X-Amz-Credential", valid_402657668
  var valid_402657669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657669 = validateParameter(valid_402657669, JString,
                                      required = false, default = nil)
  if valid_402657669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657670: Call_GetGroupVersion_402657658; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a group version.
                                                                                         ## 
  let valid = call_402657670.validator(path, query, header, formData, body, _)
  let scheme = call_402657670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657670.makeUrl(scheme.get, call_402657670.host, call_402657670.base,
                                   call_402657670.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657670, uri, valid, _)

proc call*(call_402657671: Call_GetGroupVersion_402657658;
           GroupVersionId: string; GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
                                                 ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## GroupId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## Greengrass 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## group.
  var path_402657672 = newJObject()
  add(path_402657672, "GroupVersionId", newJString(GroupVersionId))
  add(path_402657672, "GroupId", newJString(GroupId))
  result = call_402657671.call(path_402657672, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_402657658(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_402657659, base: "/",
    makeUrl: url_GetGroupVersion_402657660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_402657673 = ref object of OpenApiRestCall_402656035
proc url_GetLoggerDefinitionVersion_402657675(protocol: Scheme; host: string;
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
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/loggers/"),
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

proc validate_GetLoggerDefinitionVersion_402657674(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a logger definition version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LoggerDefinitionId: JString (required)
                                 ##                     : The ID of the logger definition.
  ##   
                                                                                          ## LoggerDefinitionVersionId: JString (required)
                                                                                          ##                            
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## ID 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## logger 
                                                                                          ## definition 
                                                                                          ## version. 
                                                                                          ## This 
                                                                                          ## value 
                                                                                          ## maps 
                                                                                          ## to 
                                                                                          ## the 
                                                                                          ## ''Version'' 
                                                                                          ## property 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## corresponding 
                                                                                          ## ''VersionInformation'' 
                                                                                          ## object, 
                                                                                          ## which 
                                                                                          ## is 
                                                                                          ## returned 
                                                                                          ## by 
                                                                                          ## ''ListLoggerDefinitionVersions'' 
                                                                                          ## requests. 
                                                                                          ## If 
                                                                                          ## the 
                                                                                          ## version 
                                                                                          ## is 
                                                                                          ## the 
                                                                                          ## last 
                                                                                          ## one 
                                                                                          ## that 
                                                                                          ## was 
                                                                                          ## associated 
                                                                                          ## with 
                                                                                          ## a 
                                                                                          ## logger 
                                                                                          ## definition, 
                                                                                          ## the 
                                                                                          ## value 
                                                                                          ## also 
                                                                                          ## maps 
                                                                                          ## to 
                                                                                          ## the 
                                                                                          ## ''LatestVersion'' 
                                                                                          ## property 
                                                                                          ## of 
                                                                                          ## the 
                                                                                          ## corresponding 
                                                                                          ## ''DefinitionInformation'' 
                                                                                          ## object.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LoggerDefinitionId` field"
  var valid_402657676 = path.getOrDefault("LoggerDefinitionId")
  valid_402657676 = validateParameter(valid_402657676, JString, required = true,
                                      default = nil)
  if valid_402657676 != nil:
    section.add "LoggerDefinitionId", valid_402657676
  var valid_402657677 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_402657677 = validateParameter(valid_402657677, JString, required = true,
                                      default = nil)
  if valid_402657677 != nil:
    section.add "LoggerDefinitionVersionId", valid_402657677
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_402657678 = query.getOrDefault("NextToken")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "NextToken", valid_402657678
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
  var valid_402657679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Security-Token", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Signature")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Signature", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657681
  var valid_402657682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657682 = validateParameter(valid_402657682, JString,
                                      required = false, default = nil)
  if valid_402657682 != nil:
    section.add "X-Amz-Algorithm", valid_402657682
  var valid_402657683 = header.getOrDefault("X-Amz-Date")
  valid_402657683 = validateParameter(valid_402657683, JString,
                                      required = false, default = nil)
  if valid_402657683 != nil:
    section.add "X-Amz-Date", valid_402657683
  var valid_402657684 = header.getOrDefault("X-Amz-Credential")
  valid_402657684 = validateParameter(valid_402657684, JString,
                                      required = false, default = nil)
  if valid_402657684 != nil:
    section.add "X-Amz-Credential", valid_402657684
  var valid_402657685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657685 = validateParameter(valid_402657685, JString,
                                      required = false, default = nil)
  if valid_402657685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657686: Call_GetLoggerDefinitionVersion_402657673;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a logger definition version.
                                                                                         ## 
  let valid = call_402657686.validator(path, query, header, formData, body, _)
  let scheme = call_402657686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657686.makeUrl(scheme.get, call_402657686.host, call_402657686.base,
                                   call_402657686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657686, uri, valid, _)

proc call*(call_402657687: Call_GetLoggerDefinitionVersion_402657673;
           LoggerDefinitionId: string; LoggerDefinitionVersionId: string;
           NextToken: string = ""): Recallable =
  ## getLoggerDefinitionVersion
  ## Retrieves information about a logger definition version.
  ##   LoggerDefinitionId: string (required)
                                                             ##                     : The ID of the logger definition.
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## token 
                                                                                                                      ## for 
                                                                                                                      ## the 
                                                                                                                      ## next 
                                                                                                                      ## set 
                                                                                                                      ## of 
                                                                                                                      ## results, 
                                                                                                                      ## or 
                                                                                                                      ## ''null'' 
                                                                                                                      ## if 
                                                                                                                      ## there 
                                                                                                                      ## are 
                                                                                                                      ## no 
                                                                                                                      ## additional 
                                                                                                                      ## results.
  ##   
                                                                                                                                 ## LoggerDefinitionVersionId: string (required)
                                                                                                                                 ##                            
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## ID 
                                                                                                                                 ## of 
                                                                                                                                 ## the 
                                                                                                                                 ## logger 
                                                                                                                                 ## definition 
                                                                                                                                 ## version. 
                                                                                                                                 ## This 
                                                                                                                                 ## value 
                                                                                                                                 ## maps 
                                                                                                                                 ## to 
                                                                                                                                 ## the 
                                                                                                                                 ## ''Version'' 
                                                                                                                                 ## property 
                                                                                                                                 ## of 
                                                                                                                                 ## the 
                                                                                                                                 ## corresponding 
                                                                                                                                 ## ''VersionInformation'' 
                                                                                                                                 ## object, 
                                                                                                                                 ## which 
                                                                                                                                 ## is 
                                                                                                                                 ## returned 
                                                                                                                                 ## by 
                                                                                                                                 ## ''ListLoggerDefinitionVersions'' 
                                                                                                                                 ## requests. 
                                                                                                                                 ## If 
                                                                                                                                 ## the 
                                                                                                                                 ## version 
                                                                                                                                 ## is 
                                                                                                                                 ## the 
                                                                                                                                 ## last 
                                                                                                                                 ## one 
                                                                                                                                 ## that 
                                                                                                                                 ## was 
                                                                                                                                 ## associated 
                                                                                                                                 ## with 
                                                                                                                                 ## a 
                                                                                                                                 ## logger 
                                                                                                                                 ## definition, 
                                                                                                                                 ## the 
                                                                                                                                 ## value 
                                                                                                                                 ## also 
                                                                                                                                 ## maps 
                                                                                                                                 ## to 
                                                                                                                                 ## the 
                                                                                                                                 ## ''LatestVersion'' 
                                                                                                                                 ## property 
                                                                                                                                 ## of 
                                                                                                                                 ## the 
                                                                                                                                 ## corresponding 
                                                                                                                                 ## ''DefinitionInformation'' 
                                                                                                                                 ## object.
  var path_402657688 = newJObject()
  var query_402657689 = newJObject()
  add(path_402657688, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_402657689, "NextToken", newJString(NextToken))
  add(path_402657688, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  result = call_402657687.call(path_402657688, query_402657689, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_402657673(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_402657674, base: "/",
    makeUrl: url_GetLoggerDefinitionVersion_402657675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_402657690 = ref object of OpenApiRestCall_402656035
proc url_GetResourceDefinitionVersion_402657692(protocol: Scheme; host: string;
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
    segments = @[(kind: ConstantSegment,
                  value: "/greengrass/definition/resources/"),
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

proc validate_GetResourceDefinitionVersion_402657691(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionVersionId: JString (required)
                                 ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by 
                                 ## ''ListResourceDefinitionVersions'' 
                                 ## requests. If the version is the last one that was 
                                 ## associated 
                                 ## with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   
                                                                                                                                                                            ## ResourceDefinitionId: JString (required)
                                                                                                                                                                            ##                       
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## The 
                                                                                                                                                                            ## ID 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## the 
                                                                                                                                                                            ## resource 
                                                                                                                                                                            ## definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionVersionId` field"
  var valid_402657693 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_402657693 = validateParameter(valid_402657693, JString, required = true,
                                      default = nil)
  if valid_402657693 != nil:
    section.add "ResourceDefinitionVersionId", valid_402657693
  var valid_402657694 = path.getOrDefault("ResourceDefinitionId")
  valid_402657694 = validateParameter(valid_402657694, JString, required = true,
                                      default = nil)
  if valid_402657694 != nil:
    section.add "ResourceDefinitionId", valid_402657694
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
  var valid_402657695 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Security-Token", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Signature")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Signature", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-Algorithm", valid_402657698
  var valid_402657699 = header.getOrDefault("X-Amz-Date")
  valid_402657699 = validateParameter(valid_402657699, JString,
                                      required = false, default = nil)
  if valid_402657699 != nil:
    section.add "X-Amz-Date", valid_402657699
  var valid_402657700 = header.getOrDefault("X-Amz-Credential")
  valid_402657700 = validateParameter(valid_402657700, JString,
                                      required = false, default = nil)
  if valid_402657700 != nil:
    section.add "X-Amz-Credential", valid_402657700
  var valid_402657701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657701 = validateParameter(valid_402657701, JString,
                                      required = false, default = nil)
  if valid_402657701 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657702: Call_GetResourceDefinitionVersion_402657690;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
                                                                                         ## 
  let valid = call_402657702.validator(path, query, header, formData, body, _)
  let scheme = call_402657702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657702.makeUrl(scheme.get, call_402657702.host, call_402657702.base,
                                   call_402657702.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657702, uri, valid, _)

proc call*(call_402657703: Call_GetResourceDefinitionVersion_402657690;
           ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   
                                                                                                                      ## ResourceDefinitionVersionId: string (required)
                                                                                                                      ##                              
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## ID 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## resource 
                                                                                                                      ## definition 
                                                                                                                      ## version. 
                                                                                                                      ## This 
                                                                                                                      ## value 
                                                                                                                      ## maps 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## ''Version'' 
                                                                                                                      ## property 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## corresponding 
                                                                                                                      ## ''VersionInformation'' 
                                                                                                                      ## object, 
                                                                                                                      ## which 
                                                                                                                      ## is 
                                                                                                                      ## returned 
                                                                                                                      ## by 
                                                                                                                      ## ''ListResourceDefinitionVersions'' 
                                                                                                                      ## requests. 
                                                                                                                      ## If 
                                                                                                                      ## the 
                                                                                                                      ## version 
                                                                                                                      ## is 
                                                                                                                      ## the 
                                                                                                                      ## last 
                                                                                                                      ## one 
                                                                                                                      ## that 
                                                                                                                      ## was 
                                                                                                                      ## associated 
                                                                                                                      ## with 
                                                                                                                      ## a 
                                                                                                                      ## resource 
                                                                                                                      ## definition, 
                                                                                                                      ## the 
                                                                                                                      ## value 
                                                                                                                      ## also 
                                                                                                                      ## maps 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## ''LatestVersion'' 
                                                                                                                      ## property 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## corresponding 
                                                                                                                      ## ''DefinitionInformation'' 
                                                                                                                      ## object.
  ##   
                                                                                                                                ## ResourceDefinitionId: string (required)
                                                                                                                                ##                       
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## ID 
                                                                                                                                ## of 
                                                                                                                                ## the 
                                                                                                                                ## resource 
                                                                                                                                ## definition.
  var path_402657704 = newJObject()
  add(path_402657704, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_402657704, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_402657703.call(path_402657704, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_402657690(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_402657691, base: "/",
    makeUrl: url_GetResourceDefinitionVersion_402657692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_402657705 = ref object of OpenApiRestCall_402656035
proc url_GetSubscriptionDefinitionVersion_402657707(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
                 (kind: ConstantSegment, value: "/versions/"), (
        kind: VariableSegment, value: "SubscriptionDefinitionVersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSubscriptionDefinitionVersion_402657706(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a subscription definition version.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionVersionId: JString (required)
                                 ##                                  : The ID of the subscription definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by 
                                 ## ''ListSubscriptionDefinitionVersions'' 
                                 ## requests. If the 
                                 ## version is the last one that was associated with a subscription definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   
                                                                                                                                                                                                                            ## SubscriptionDefinitionId: JString (required)
                                                                                                                                                                                                                            ##                           
                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                            ## subscription 
                                                                                                                                                                                                                            ## definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionVersionId` field"
  var valid_402657708 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_402657708 = validateParameter(valid_402657708, JString, required = true,
                                      default = nil)
  if valid_402657708 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_402657708
  var valid_402657709 = path.getOrDefault("SubscriptionDefinitionId")
  valid_402657709 = validateParameter(valid_402657709, JString, required = true,
                                      default = nil)
  if valid_402657709 != nil:
    section.add "SubscriptionDefinitionId", valid_402657709
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_402657710 = query.getOrDefault("NextToken")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "NextToken", valid_402657710
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
  var valid_402657711 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-Security-Token", valid_402657711
  var valid_402657712 = header.getOrDefault("X-Amz-Signature")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "X-Amz-Signature", valid_402657712
  var valid_402657713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657713 = validateParameter(valid_402657713, JString,
                                      required = false, default = nil)
  if valid_402657713 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657713
  var valid_402657714 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "X-Amz-Algorithm", valid_402657714
  var valid_402657715 = header.getOrDefault("X-Amz-Date")
  valid_402657715 = validateParameter(valid_402657715, JString,
                                      required = false, default = nil)
  if valid_402657715 != nil:
    section.add "X-Amz-Date", valid_402657715
  var valid_402657716 = header.getOrDefault("X-Amz-Credential")
  valid_402657716 = validateParameter(valid_402657716, JString,
                                      required = false, default = nil)
  if valid_402657716 != nil:
    section.add "X-Amz-Credential", valid_402657716
  var valid_402657717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657717 = validateParameter(valid_402657717, JString,
                                      required = false, default = nil)
  if valid_402657717 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657718: Call_GetSubscriptionDefinitionVersion_402657705;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a subscription definition version.
                                                                                         ## 
  let valid = call_402657718.validator(path, query, header, formData, body, _)
  let scheme = call_402657718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657718.makeUrl(scheme.get, call_402657718.host, call_402657718.base,
                                   call_402657718.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657718, uri, valid, _)

proc call*(call_402657719: Call_GetSubscriptionDefinitionVersion_402657705;
           SubscriptionDefinitionVersionId: string;
           SubscriptionDefinitionId: string; NextToken: string = ""): Recallable =
  ## getSubscriptionDefinitionVersion
  ## Retrieves information about a subscription definition version.
  ##   
                                                                   ## SubscriptionDefinitionVersionId: string (required)
                                                                   ##                                  
                                                                   ## : 
                                                                   ## The ID of the 
                                                                   ## subscription 
                                                                   ## definition 
                                                                   ## version. 
                                                                   ## This 
                                                                   ## value maps to the 
                                                                   ## ''Version'' 
                                                                   ## property 
                                                                   ## of 
                                                                   ## the 
                                                                   ## corresponding 
                                                                   ## ''VersionInformation'' 
                                                                   ## object, 
                                                                   ## which is 
                                                                   ## returned 
                                                                   ## by 
                                                                   ## ''ListSubscriptionDefinitionVersions'' 
                                                                   ## requests. 
                                                                   ## If 
                                                                   ## the version is the last one that was 
                                                                   ## associated 
                                                                   ## with 
                                                                   ## a 
                                                                   ## subscription 
                                                                   ## definition, 
                                                                   ## the 
                                                                   ## value also maps to the 
                                                                   ## ''LatestVersion'' 
                                                                   ## property 
                                                                   ## of 
                                                                   ## the 
                                                                   ## corresponding 
                                                                   ## ''DefinitionInformation'' 
                                                                   ## object.
  ##   
                                                                             ## NextToken: string
                                                                             ##            
                                                                             ## : 
                                                                             ## The 
                                                                             ## token 
                                                                             ## for 
                                                                             ## the 
                                                                             ## next 
                                                                             ## set 
                                                                             ## of 
                                                                             ## results, 
                                                                             ## or 
                                                                             ## ''null'' 
                                                                             ## if 
                                                                             ## there 
                                                                             ## are 
                                                                             ## no 
                                                                             ## additional 
                                                                             ## results.
  ##   
                                                                                        ## SubscriptionDefinitionId: string (required)
                                                                                        ##                           
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ID 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## subscription 
                                                                                        ## definition.
  var path_402657720 = newJObject()
  var query_402657721 = newJObject()
  add(path_402657720, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_402657721, "NextToken", newJString(NextToken))
  add(path_402657720, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_402657719.call(path_402657720, query_402657721, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_402657705(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_402657706, base: "/",
    makeUrl: url_GetSubscriptionDefinitionVersion_402657707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_402657722 = ref object of OpenApiRestCall_402656035
proc url_ListBulkDeploymentDetailedReports_402657724(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListBulkDeploymentDetailedReports_402657723(path: JsonNode;
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
  var valid_402657725 = path.getOrDefault("BulkDeploymentId")
  valid_402657725 = validateParameter(valid_402657725, JString, required = true,
                                      default = nil)
  if valid_402657725 != nil:
    section.add "BulkDeploymentId", valid_402657725
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402657726 = query.getOrDefault("MaxResults")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "MaxResults", valid_402657726
  var valid_402657727 = query.getOrDefault("NextToken")
  valid_402657727 = validateParameter(valid_402657727, JString,
                                      required = false, default = nil)
  if valid_402657727 != nil:
    section.add "NextToken", valid_402657727
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
  var valid_402657728 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Security-Token", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-Signature")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-Signature", valid_402657729
  var valid_402657730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657730 = validateParameter(valid_402657730, JString,
                                      required = false, default = nil)
  if valid_402657730 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657730
  var valid_402657731 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657731 = validateParameter(valid_402657731, JString,
                                      required = false, default = nil)
  if valid_402657731 != nil:
    section.add "X-Amz-Algorithm", valid_402657731
  var valid_402657732 = header.getOrDefault("X-Amz-Date")
  valid_402657732 = validateParameter(valid_402657732, JString,
                                      required = false, default = nil)
  if valid_402657732 != nil:
    section.add "X-Amz-Date", valid_402657732
  var valid_402657733 = header.getOrDefault("X-Amz-Credential")
  valid_402657733 = validateParameter(valid_402657733, JString,
                                      required = false, default = nil)
  if valid_402657733 != nil:
    section.add "X-Amz-Credential", valid_402657733
  var valid_402657734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657734 = validateParameter(valid_402657734, JString,
                                      required = false, default = nil)
  if valid_402657734 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657735: Call_ListBulkDeploymentDetailedReports_402657722;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
                                                                                         ## 
  let valid = call_402657735.validator(path, query, header, formData, body, _)
  let scheme = call_402657735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657735.makeUrl(scheme.get, call_402657735.host, call_402657735.base,
                                   call_402657735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657735, uri, valid, _)

proc call*(call_402657736: Call_ListBulkDeploymentDetailedReports_402657722;
           BulkDeploymentId: string; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   
                                                                                                                                         ## BulkDeploymentId: string (required)
                                                                                                                                         ##                   
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## ID 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## bulk 
                                                                                                                                         ## deployment.
  ##   
                                                                                                                                                       ## MaxResults: string
                                                                                                                                                       ##             
                                                                                                                                                       ## : 
                                                                                                                                                       ## The 
                                                                                                                                                       ## maximum 
                                                                                                                                                       ## number 
                                                                                                                                                       ## of 
                                                                                                                                                       ## results 
                                                                                                                                                       ## to 
                                                                                                                                                       ## be 
                                                                                                                                                       ## returned 
                                                                                                                                                       ## per 
                                                                                                                                                       ## request.
  ##   
                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                  ##            
                                                                                                                                                                  ## : 
                                                                                                                                                                  ## The 
                                                                                                                                                                  ## token 
                                                                                                                                                                  ## for 
                                                                                                                                                                  ## the 
                                                                                                                                                                  ## next 
                                                                                                                                                                  ## set 
                                                                                                                                                                  ## of 
                                                                                                                                                                  ## results, 
                                                                                                                                                                  ## or 
                                                                                                                                                                  ## ''null'' 
                                                                                                                                                                  ## if 
                                                                                                                                                                  ## there 
                                                                                                                                                                  ## are 
                                                                                                                                                                  ## no 
                                                                                                                                                                  ## additional 
                                                                                                                                                                  ## results.
  var path_402657737 = newJObject()
  var query_402657738 = newJObject()
  add(path_402657737, "BulkDeploymentId", newJString(BulkDeploymentId))
  add(query_402657738, "MaxResults", newJString(MaxResults))
  add(query_402657738, "NextToken", newJString(NextToken))
  result = call_402657736.call(path_402657737, query_402657738, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_402657722(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_402657723, base: "/",
    makeUrl: url_ListBulkDeploymentDetailedReports_402657724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_402657754 = ref object of OpenApiRestCall_402656035
proc url_StartBulkDeployment_402657756(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBulkDeployment_402657755(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657757 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657757 = validateParameter(valid_402657757, JString,
                                      required = false, default = nil)
  if valid_402657757 != nil:
    section.add "X-Amz-Security-Token", valid_402657757
  var valid_402657758 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657758 = validateParameter(valid_402657758, JString,
                                      required = false, default = nil)
  if valid_402657758 != nil:
    section.add "X-Amzn-Client-Token", valid_402657758
  var valid_402657759 = header.getOrDefault("X-Amz-Signature")
  valid_402657759 = validateParameter(valid_402657759, JString,
                                      required = false, default = nil)
  if valid_402657759 != nil:
    section.add "X-Amz-Signature", valid_402657759
  var valid_402657760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657760 = validateParameter(valid_402657760, JString,
                                      required = false, default = nil)
  if valid_402657760 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657760
  var valid_402657761 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657761 = validateParameter(valid_402657761, JString,
                                      required = false, default = nil)
  if valid_402657761 != nil:
    section.add "X-Amz-Algorithm", valid_402657761
  var valid_402657762 = header.getOrDefault("X-Amz-Date")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "X-Amz-Date", valid_402657762
  var valid_402657763 = header.getOrDefault("X-Amz-Credential")
  valid_402657763 = validateParameter(valid_402657763, JString,
                                      required = false, default = nil)
  if valid_402657763 != nil:
    section.add "X-Amz-Credential", valid_402657763
  var valid_402657764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657764 = validateParameter(valid_402657764, JString,
                                      required = false, default = nil)
  if valid_402657764 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657764
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

proc call*(call_402657766: Call_StartBulkDeployment_402657754;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
                                                                                         ## 
  let valid = call_402657766.validator(path, query, header, formData, body, _)
  let scheme = call_402657766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657766.makeUrl(scheme.get, call_402657766.host, call_402657766.base,
                                   call_402657766.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657766, uri, valid, _)

proc call*(call_402657767: Call_StartBulkDeployment_402657754; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402657768 = newJObject()
  if body != nil:
    body_402657768 = body
  result = call_402657767.call(nil, nil, nil, nil, body_402657768)

var startBulkDeployment* = Call_StartBulkDeployment_402657754(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_402657755, base: "/",
    makeUrl: url_StartBulkDeployment_402657756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_402657739 = ref object of OpenApiRestCall_402656035
proc url_ListBulkDeployments_402657741(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBulkDeployments_402657740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of bulk deployments.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                            ## NextToken: JString
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results, 
                                                                                                            ## or 
                                                                                                            ## ''null'' 
                                                                                                            ## if 
                                                                                                            ## there 
                                                                                                            ## are 
                                                                                                            ## no 
                                                                                                            ## additional 
                                                                                                            ## results.
  section = newJObject()
  var valid_402657742 = query.getOrDefault("MaxResults")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "MaxResults", valid_402657742
  var valid_402657743 = query.getOrDefault("NextToken")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "NextToken", valid_402657743
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
  var valid_402657744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "X-Amz-Security-Token", valid_402657744
  var valid_402657745 = header.getOrDefault("X-Amz-Signature")
  valid_402657745 = validateParameter(valid_402657745, JString,
                                      required = false, default = nil)
  if valid_402657745 != nil:
    section.add "X-Amz-Signature", valid_402657745
  var valid_402657746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657746
  var valid_402657747 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657747 = validateParameter(valid_402657747, JString,
                                      required = false, default = nil)
  if valid_402657747 != nil:
    section.add "X-Amz-Algorithm", valid_402657747
  var valid_402657748 = header.getOrDefault("X-Amz-Date")
  valid_402657748 = validateParameter(valid_402657748, JString,
                                      required = false, default = nil)
  if valid_402657748 != nil:
    section.add "X-Amz-Date", valid_402657748
  var valid_402657749 = header.getOrDefault("X-Amz-Credential")
  valid_402657749 = validateParameter(valid_402657749, JString,
                                      required = false, default = nil)
  if valid_402657749 != nil:
    section.add "X-Amz-Credential", valid_402657749
  var valid_402657750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657750 = validateParameter(valid_402657750, JString,
                                      required = false, default = nil)
  if valid_402657750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657751: Call_ListBulkDeployments_402657739;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of bulk deployments.
                                                                                         ## 
  let valid = call_402657751.validator(path, query, header, formData, body, _)
  let scheme = call_402657751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657751.makeUrl(scheme.get, call_402657751.host, call_402657751.base,
                                   call_402657751.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657751, uri, valid, _)

proc call*(call_402657752: Call_ListBulkDeployments_402657739;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
                                        ##             : The maximum number of results to be returned per request.
  ##   
                                                                                                                  ## NextToken: string
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## token 
                                                                                                                  ## for 
                                                                                                                  ## the 
                                                                                                                  ## next 
                                                                                                                  ## set 
                                                                                                                  ## of 
                                                                                                                  ## results, 
                                                                                                                  ## or 
                                                                                                                  ## ''null'' 
                                                                                                                  ## if 
                                                                                                                  ## there 
                                                                                                                  ## are 
                                                                                                                  ## no 
                                                                                                                  ## additional 
                                                                                                                  ## results.
  var query_402657753 = newJObject()
  add(query_402657753, "MaxResults", newJString(MaxResults))
  add(query_402657753, "NextToken", newJString(NextToken))
  result = call_402657752.call(nil, query_402657753, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_402657739(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_402657740, base: "/",
    makeUrl: url_ListBulkDeployments_402657741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657783 = ref object of OpenApiRestCall_402656035
proc url_TagResource_402657785(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402657784(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657786 = path.getOrDefault("resource-arn")
  valid_402657786 = validateParameter(valid_402657786, JString, required = true,
                                      default = nil)
  if valid_402657786 != nil:
    section.add "resource-arn", valid_402657786
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
  var valid_402657787 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "X-Amz-Security-Token", valid_402657787
  var valid_402657788 = header.getOrDefault("X-Amz-Signature")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "X-Amz-Signature", valid_402657788
  var valid_402657789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657789 = validateParameter(valid_402657789, JString,
                                      required = false, default = nil)
  if valid_402657789 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657789
  var valid_402657790 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657790 = validateParameter(valid_402657790, JString,
                                      required = false, default = nil)
  if valid_402657790 != nil:
    section.add "X-Amz-Algorithm", valid_402657790
  var valid_402657791 = header.getOrDefault("X-Amz-Date")
  valid_402657791 = validateParameter(valid_402657791, JString,
                                      required = false, default = nil)
  if valid_402657791 != nil:
    section.add "X-Amz-Date", valid_402657791
  var valid_402657792 = header.getOrDefault("X-Amz-Credential")
  valid_402657792 = validateParameter(valid_402657792, JString,
                                      required = false, default = nil)
  if valid_402657792 != nil:
    section.add "X-Amz-Credential", valid_402657792
  var valid_402657793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657793 = validateParameter(valid_402657793, JString,
                                      required = false, default = nil)
  if valid_402657793 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657793
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

proc call*(call_402657795: Call_TagResource_402657783; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
                                                                                         ## 
  let valid = call_402657795.validator(path, query, header, formData, body, _)
  let scheme = call_402657795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657795.makeUrl(scheme.get, call_402657795.host, call_402657795.base,
                                   call_402657795.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657795, uri, valid, _)

proc call*(call_402657796: Call_TagResource_402657783; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   
                                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                             ## resourceArn: string (required)
                                                                                                                                                                                                                                                                             ##              
                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                             ## Amazon 
                                                                                                                                                                                                                                                                             ## Resource 
                                                                                                                                                                                                                                                                             ## Name 
                                                                                                                                                                                                                                                                             ## (ARN) 
                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                             ## resource.
  var path_402657797 = newJObject()
  var body_402657798 = newJObject()
  if body != nil:
    body_402657798 = body
  add(path_402657797, "resource-arn", newJString(resourceArn))
  result = call_402657796.call(path_402657797, nil, nil, nil, body_402657798)

var tagResource* = Call_TagResource_402657783(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_402657784,
    base: "/", makeUrl: url_TagResource_402657785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657769 = ref object of OpenApiRestCall_402656035
proc url_ListTagsForResource_402657771(protocol: Scheme; host: string;
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

proc validate_ListTagsForResource_402657770(path: JsonNode; query: JsonNode;
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
  var valid_402657772 = path.getOrDefault("resource-arn")
  valid_402657772 = validateParameter(valid_402657772, JString, required = true,
                                      default = nil)
  if valid_402657772 != nil:
    section.add "resource-arn", valid_402657772
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
  var valid_402657773 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657773 = validateParameter(valid_402657773, JString,
                                      required = false, default = nil)
  if valid_402657773 != nil:
    section.add "X-Amz-Security-Token", valid_402657773
  var valid_402657774 = header.getOrDefault("X-Amz-Signature")
  valid_402657774 = validateParameter(valid_402657774, JString,
                                      required = false, default = nil)
  if valid_402657774 != nil:
    section.add "X-Amz-Signature", valid_402657774
  var valid_402657775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657775 = validateParameter(valid_402657775, JString,
                                      required = false, default = nil)
  if valid_402657775 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657775
  var valid_402657776 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657776 = validateParameter(valid_402657776, JString,
                                      required = false, default = nil)
  if valid_402657776 != nil:
    section.add "X-Amz-Algorithm", valid_402657776
  var valid_402657777 = header.getOrDefault("X-Amz-Date")
  valid_402657777 = validateParameter(valid_402657777, JString,
                                      required = false, default = nil)
  if valid_402657777 != nil:
    section.add "X-Amz-Date", valid_402657777
  var valid_402657778 = header.getOrDefault("X-Amz-Credential")
  valid_402657778 = validateParameter(valid_402657778, JString,
                                      required = false, default = nil)
  if valid_402657778 != nil:
    section.add "X-Amz-Credential", valid_402657778
  var valid_402657779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657779 = validateParameter(valid_402657779, JString,
                                      required = false, default = nil)
  if valid_402657779 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657780: Call_ListTagsForResource_402657769;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
                                                                                         ## 
  let valid = call_402657780.validator(path, query, header, formData, body, _)
  let scheme = call_402657780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657780.makeUrl(scheme.get, call_402657780.host, call_402657780.base,
                                   call_402657780.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657780, uri, valid, _)

proc call*(call_402657781: Call_ListTagsForResource_402657769;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
                                                          ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402657782 = newJObject()
  add(path_402657782, "resource-arn", newJString(resourceArn))
  result = call_402657781.call(path_402657782, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402657769(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402657770, base: "/",
    makeUrl: url_ListTagsForResource_402657771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_402657799 = ref object of OpenApiRestCall_402656035
proc url_ResetDeployments_402657801(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_ResetDeployments_402657800(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Resets a group's deployments.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
                                 ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `GroupId` field"
  var valid_402657802 = path.getOrDefault("GroupId")
  valid_402657802 = validateParameter(valid_402657802, JString, required = true,
                                      default = nil)
  if valid_402657802 != nil:
    section.add "GroupId", valid_402657802
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amzn-Client-Token: JString
                                    ##                      : A client token used to correlate requests and responses.
  ##   
                                                                                                                      ## X-Amz-Signature: JString
  ##   
                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657803 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657803 = validateParameter(valid_402657803, JString,
                                      required = false, default = nil)
  if valid_402657803 != nil:
    section.add "X-Amz-Security-Token", valid_402657803
  var valid_402657804 = header.getOrDefault("X-Amzn-Client-Token")
  valid_402657804 = validateParameter(valid_402657804, JString,
                                      required = false, default = nil)
  if valid_402657804 != nil:
    section.add "X-Amzn-Client-Token", valid_402657804
  var valid_402657805 = header.getOrDefault("X-Amz-Signature")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "X-Amz-Signature", valid_402657805
  var valid_402657806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657806 = validateParameter(valid_402657806, JString,
                                      required = false, default = nil)
  if valid_402657806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657806
  var valid_402657807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657807 = validateParameter(valid_402657807, JString,
                                      required = false, default = nil)
  if valid_402657807 != nil:
    section.add "X-Amz-Algorithm", valid_402657807
  var valid_402657808 = header.getOrDefault("X-Amz-Date")
  valid_402657808 = validateParameter(valid_402657808, JString,
                                      required = false, default = nil)
  if valid_402657808 != nil:
    section.add "X-Amz-Date", valid_402657808
  var valid_402657809 = header.getOrDefault("X-Amz-Credential")
  valid_402657809 = validateParameter(valid_402657809, JString,
                                      required = false, default = nil)
  if valid_402657809 != nil:
    section.add "X-Amz-Credential", valid_402657809
  var valid_402657810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657810
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

proc call*(call_402657812: Call_ResetDeployments_402657799;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets a group's deployments.
                                                                                         ## 
  let valid = call_402657812.validator(path, query, header, formData, body, _)
  let scheme = call_402657812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657812.makeUrl(scheme.get, call_402657812.host, call_402657812.base,
                                   call_402657812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657812, uri, valid, _)

proc call*(call_402657813: Call_ResetDeployments_402657799; body: JsonNode;
           GroupId: string): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   body: JObject (required)
  ##   GroupId: string (required)
                               ##          : The ID of the Greengrass group.
  var path_402657814 = newJObject()
  var body_402657815 = newJObject()
  if body != nil:
    body_402657815 = body
  add(path_402657814, "GroupId", newJString(GroupId))
  result = call_402657813.call(path_402657814, nil, nil, nil, body_402657815)

var resetDeployments* = Call_ResetDeployments_402657799(
    name: "resetDeployments", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_402657800, base: "/",
    makeUrl: url_ResetDeployments_402657801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_402657816 = ref object of OpenApiRestCall_402656035
proc url_StopBulkDeployment_402657818(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_StopBulkDeployment_402657817(path: JsonNode; query: JsonNode;
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
  var valid_402657819 = path.getOrDefault("BulkDeploymentId")
  valid_402657819 = validateParameter(valid_402657819, JString, required = true,
                                      default = nil)
  if valid_402657819 != nil:
    section.add "BulkDeploymentId", valid_402657819
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
  var valid_402657820 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657820 = validateParameter(valid_402657820, JString,
                                      required = false, default = nil)
  if valid_402657820 != nil:
    section.add "X-Amz-Security-Token", valid_402657820
  var valid_402657821 = header.getOrDefault("X-Amz-Signature")
  valid_402657821 = validateParameter(valid_402657821, JString,
                                      required = false, default = nil)
  if valid_402657821 != nil:
    section.add "X-Amz-Signature", valid_402657821
  var valid_402657822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657822 = validateParameter(valid_402657822, JString,
                                      required = false, default = nil)
  if valid_402657822 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657822
  var valid_402657823 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657823 = validateParameter(valid_402657823, JString,
                                      required = false, default = nil)
  if valid_402657823 != nil:
    section.add "X-Amz-Algorithm", valid_402657823
  var valid_402657824 = header.getOrDefault("X-Amz-Date")
  valid_402657824 = validateParameter(valid_402657824, JString,
                                      required = false, default = nil)
  if valid_402657824 != nil:
    section.add "X-Amz-Date", valid_402657824
  var valid_402657825 = header.getOrDefault("X-Amz-Credential")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Credential", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657827: Call_StopBulkDeployment_402657816;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
                                                                                         ## 
  let valid = call_402657827.validator(path, query, header, formData, body, _)
  let scheme = call_402657827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657827.makeUrl(scheme.get, call_402657827.host, call_402657827.base,
                                   call_402657827.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657827, uri, valid, _)

proc call*(call_402657828: Call_StopBulkDeployment_402657816;
           BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   
                                                                                                                                                                                                                                                                                                               ## BulkDeploymentId: string (required)
                                                                                                                                                                                                                                                                                                               ##                   
                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                               ## ID 
                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                               ## bulk 
                                                                                                                                                                                                                                                                                                               ## deployment.
  var path_402657829 = newJObject()
  add(path_402657829, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_402657828.call(path_402657829, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_402657816(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_402657817, base: "/",
    makeUrl: url_StopBulkDeployment_402657818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657830 = ref object of OpenApiRestCall_402656035
proc url_UntagResource_402657832(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402657831(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657833 = path.getOrDefault("resource-arn")
  valid_402657833 = validateParameter(valid_402657833, JString, required = true,
                                      default = nil)
  if valid_402657833 != nil:
    section.add "resource-arn", valid_402657833
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657834 = query.getOrDefault("tagKeys")
  valid_402657834 = validateParameter(valid_402657834, JArray, required = true,
                                      default = nil)
  if valid_402657834 != nil:
    section.add "tagKeys", valid_402657834
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
  var valid_402657835 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657835 = validateParameter(valid_402657835, JString,
                                      required = false, default = nil)
  if valid_402657835 != nil:
    section.add "X-Amz-Security-Token", valid_402657835
  var valid_402657836 = header.getOrDefault("X-Amz-Signature")
  valid_402657836 = validateParameter(valid_402657836, JString,
                                      required = false, default = nil)
  if valid_402657836 != nil:
    section.add "X-Amz-Signature", valid_402657836
  var valid_402657837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657837 = validateParameter(valid_402657837, JString,
                                      required = false, default = nil)
  if valid_402657837 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657837
  var valid_402657838 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657838 = validateParameter(valid_402657838, JString,
                                      required = false, default = nil)
  if valid_402657838 != nil:
    section.add "X-Amz-Algorithm", valid_402657838
  var valid_402657839 = header.getOrDefault("X-Amz-Date")
  valid_402657839 = validateParameter(valid_402657839, JString,
                                      required = false, default = nil)
  if valid_402657839 != nil:
    section.add "X-Amz-Date", valid_402657839
  var valid_402657840 = header.getOrDefault("X-Amz-Credential")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "X-Amz-Credential", valid_402657840
  var valid_402657841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657841 = validateParameter(valid_402657841, JString,
                                      required = false, default = nil)
  if valid_402657841 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657842: Call_UntagResource_402657830; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove resource tags from a Greengrass Resource.
                                                                                         ## 
  let valid = call_402657842.validator(path, query, header, formData, body, _)
  let scheme = call_402657842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657842.makeUrl(scheme.get, call_402657842.host, call_402657842.base,
                                   call_402657842.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657842, uri, valid, _)

proc call*(call_402657843: Call_UntagResource_402657830; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   tagKeys: JArray (required)
                                                     ##          : An array of tag keys to delete
  ##   
                                                                                                 ## resourceArn: string (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## Amazon 
                                                                                                 ## Resource 
                                                                                                 ## Name 
                                                                                                 ## (ARN) 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## resource.
  var path_402657844 = newJObject()
  var query_402657845 = newJObject()
  if tagKeys != nil:
    query_402657845.add "tagKeys", tagKeys
  add(path_402657844, "resource-arn", newJString(resourceArn))
  result = call_402657843.call(path_402657844, query_402657845, nil, nil, nil)

var untagResource* = Call_UntagResource_402657830(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402657831,
    base: "/", makeUrl: url_UntagResource_402657832,
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